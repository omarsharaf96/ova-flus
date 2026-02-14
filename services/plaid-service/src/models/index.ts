import { z } from 'zod';

// DB row interfaces
export interface PlaidItemRow {
  id: string;
  user_id: string;
  institution_id: string;
  institution_name: string;
  item_id: string;
  access_token_enc: Buffer;
  cursor: string | null;
  status: string;
  created_at: Date;
  updated_at: Date;
}

export interface BankAccountRow {
  id: string;
  plaid_item_id: string;
  account_id: string;
  name: string;
  official_name: string | null;
  type: string;
  subtype: string | null;
  mask: string | null;
  current_balance: number | null;
  available_balance: number | null;
  iso_currency_code: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface PlaidTransactionRow {
  id: string;
  bank_account_id: string;
  transaction_id: string;
  amount: number;
  iso_currency_code: string | null;
  name: string;
  merchant_name: string | null;
  category: string[];
  date: string;
  pending: boolean;
  created_at: Date;
}

// Zod schemas
export const exchangeTokenSchema = z.object({
  publicToken: z.string(),
  institutionId: z.string(),
  institutionName: z.string(),
});

export const webhookSchema = z.object({
  webhook_type: z.string(),
  webhook_code: z.string(),
  item_id: z.string(),
  error: z.object({}).passthrough().optional(),
});
