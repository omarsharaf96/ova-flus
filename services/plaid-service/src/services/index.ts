import { Pool } from 'pg';
import {
  Configuration,
  PlaidApi,
  PlaidEnvironments,
  Products,
  CountryCode,
} from 'plaid';
import { config } from '../config';
import { AppError } from '../middleware/errorHandler';

let pool: Pool | null = null;
let plaidClient: PlaidApi | null = null;

export function getDb(): Pool {
  if (!pool) {
    pool = config.db.connectionString
      ? new Pool({ connectionString: config.db.connectionString })
      : new Pool({
          host: config.db.host,
          port: config.db.port,
          database: config.db.database,
          user: config.db.user,
          password: config.db.password,
        });
  }
  return pool;
}

export function getPlaidClient(): PlaidApi {
  if (!plaidClient) {
    const configuration = new Configuration({
      basePath: PlaidEnvironments[config.plaid.env],
      baseOptions: {
        headers: {
          'PLAID-CLIENT-ID': config.plaid.clientId,
          'PLAID-SECRET': config.plaid.secret,
        },
      },
    });
    plaidClient = new PlaidApi(configuration);
  }
  return plaidClient;
}

export async function createLinkToken(userId: string): Promise<{ link_token: string }> {
  const client = getPlaidClient();
  const response = await client.linkTokenCreate({
    user: { client_user_id: userId },
    client_name: 'OvaFlus',
    products: [Products.Transactions],
    country_codes: [CountryCode.Us],
    language: 'en',
  });
  return { link_token: response.data.link_token };
}

export async function exchangeToken(
  userId: string,
  publicToken: string,
  institutionId: string,
  institutionName: string,
): Promise<{ item_id: string; accounts: unknown[] }> {
  const client = getPlaidClient();
  const db = getDb();

  const exchangeResponse = await client.itemPublicTokenExchange({
    public_token: publicToken,
  });

  const { access_token, item_id } = exchangeResponse.data;

  // Store the plaid item with encrypted access token
  const itemResult = await db.query(
    `INSERT INTO plaid_items (user_id, institution_id, institution_name, item_id, access_token_enc, status)
     VALUES ($1, $2, $3, $4, pgp_sym_encrypt($5, $6), 'active')
     RETURNING id`,
    [userId, institutionId, institutionName, item_id, access_token, config.plaid.tokenEncryptionKey],
  );

  const plaidItemId = itemResult.rows[0].id;

  // Fetch accounts from Plaid
  const accountsResponse = await client.accountsGet({ access_token });
  const accounts = accountsResponse.data.accounts;

  // Persist accounts
  for (const account of accounts) {
    await db.query(
      `INSERT INTO bank_accounts (plaid_item_id, account_id, name, official_name, type, subtype, mask, current_balance, available_balance, iso_currency_code)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       ON CONFLICT (account_id) DO UPDATE SET
         name = EXCLUDED.name,
         current_balance = EXCLUDED.current_balance,
         available_balance = EXCLUDED.available_balance,
         updated_at = NOW()`,
      [
        plaidItemId,
        account.account_id,
        account.name,
        account.official_name,
        account.type,
        account.subtype,
        account.mask,
        account.balances.current,
        account.balances.available,
        account.balances.iso_currency_code,
      ],
    );
  }

  return { item_id, accounts };
}

export async function getAccounts(userId: string): Promise<unknown[]> {
  const db = getDb();
  const result = await db.query(
    `SELECT ba.*, pi.institution_id, pi.institution_name, pi.status as item_status
     FROM bank_accounts ba
     JOIN plaid_items pi ON ba.plaid_item_id = pi.id
     WHERE pi.user_id = $1
     ORDER BY ba.created_at DESC`,
    [userId],
  );
  return result.rows;
}

export async function syncTransactions(
  userId: string,
  accountId?: string,
): Promise<{ added: number; modified: number; removed: number }> {
  const db = getDb();
  const client = getPlaidClient();

  // Get plaid items for user, optionally filtered by account
  let itemQuery = `
    SELECT pi.id, pi.item_id, pi.cursor,
           pgp_sym_decrypt(pi.access_token_enc, $1) as access_token
    FROM plaid_items pi
    WHERE pi.user_id = $2 AND pi.status = 'active'`;
  const itemParams: unknown[] = [config.plaid.tokenEncryptionKey, userId];

  if (accountId) {
    itemQuery += ` AND pi.id IN (SELECT plaid_item_id FROM bank_accounts WHERE id = $3)`;
    itemParams.push(accountId);
  }

  const items = await db.query(itemQuery, itemParams);

  let totalAdded = 0;
  let totalModified = 0;
  let totalRemoved = 0;

  for (const item of items.rows) {
    let hasMore = true;
    let cursor = item.cursor || undefined;

    while (hasMore) {
      const response = await client.transactionsSync({
        access_token: item.access_token,
        cursor,
      });

      const { added, modified, removed, next_cursor, has_more } = response.data;

      // Upsert added transactions
      for (const txn of added) {
        const accountRow = await db.query(
          `SELECT id FROM bank_accounts WHERE account_id = $1 AND plaid_item_id = $2`,
          [txn.account_id, item.id],
        );
        if (accountRow.rows.length === 0) continue;

        await db.query(
          `INSERT INTO plaid_transactions (bank_account_id, transaction_id, amount, iso_currency_code, name, merchant_name, category, date, pending)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
           ON CONFLICT (transaction_id) DO UPDATE SET
             amount = EXCLUDED.amount,
             name = EXCLUDED.name,
             merchant_name = EXCLUDED.merchant_name,
             category = EXCLUDED.category,
             pending = EXCLUDED.pending`,
          [
            accountRow.rows[0].id,
            txn.transaction_id,
            txn.amount,
            txn.iso_currency_code,
            txn.name,
            txn.merchant_name,
            txn.category || [],
            txn.date,
            txn.pending,
          ],
        );
      }

      // Upsert modified transactions
      for (const txn of modified) {
        await db.query(
          `UPDATE plaid_transactions SET
             amount = $1, name = $2, merchant_name = $3, category = $4, pending = $5
           WHERE transaction_id = $6`,
          [txn.amount, txn.name, txn.merchant_name, txn.category || [], txn.pending, txn.transaction_id],
        );
      }

      // Remove transactions
      for (const txn of removed) {
        await db.query(
          `DELETE FROM plaid_transactions WHERE transaction_id = $1`,
          [txn.transaction_id],
        );
      }

      totalAdded += added.length;
      totalModified += modified.length;
      totalRemoved += removed.length;

      cursor = next_cursor;
      hasMore = has_more;
    }

    // Update cursor on the plaid item
    await db.query(
      `UPDATE plaid_items SET cursor = $1, updated_at = NOW() WHERE id = $2`,
      [cursor, item.id],
    );
  }

  return { added: totalAdded, modified: totalModified, removed: totalRemoved };
}

export async function handleWebhook(payload: {
  webhook_type: string;
  webhook_code: string;
  item_id: string;
  error?: Record<string, unknown>;
}): Promise<void> {
  const db = getDb();

  if (payload.webhook_type === 'TRANSACTIONS') {
    if (payload.webhook_code === 'DEFAULT_UPDATE') {
      // Find the item and its user, then sync
      const itemResult = await db.query(
        `SELECT user_id FROM plaid_items WHERE item_id = $1`,
        [payload.item_id],
      );
      if (itemResult.rows.length > 0) {
        await syncTransactions(itemResult.rows[0].user_id);
      }
    }
  } else if (payload.webhook_type === 'ITEM') {
    if (payload.webhook_code === 'ERROR') {
      await db.query(
        `UPDATE plaid_items SET status = 'error', updated_at = NOW() WHERE item_id = $1`,
        [payload.item_id],
      );
      console.error('Plaid item error:', payload.item_id, payload.error);
    }
  }
}

export async function deleteAccount(userId: string, accountId: string): Promise<void> {
  const db = getDb();
  const client = getPlaidClient();

  // Find the bank account and its plaid item, ensuring it belongs to the user
  const result = await db.query(
    `SELECT ba.plaid_item_id, pi.item_id,
            pgp_sym_decrypt(pi.access_token_enc, $1) as access_token
     FROM bank_accounts ba
     JOIN plaid_items pi ON ba.plaid_item_id = pi.id
     WHERE ba.id = $2 AND pi.user_id = $3`,
    [config.plaid.tokenEncryptionKey, accountId, userId],
  );

  if (result.rows.length === 0) {
    throw new AppError(404, 'Account not found');
  }

  const { access_token, plaid_item_id } = result.rows[0];

  // Remove the item from Plaid
  await client.itemRemove({ access_token });

  // Delete the plaid item (cascade will handle bank_accounts and plaid_transactions)
  await db.query(`DELETE FROM plaid_items WHERE id = $1`, [plaid_item_id]);
}
