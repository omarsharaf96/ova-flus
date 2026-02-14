export interface PlaidItem {
  id: string;
  userId: string;
  itemId: string;
  institutionId?: string;
  institutionName?: string;
  status: 'active' | 'error' | 'disconnected';
  cursor?: string;
  errorCode?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface BankAccount {
  id: string;
  itemId: string;
  plaidAccountId: string;
  name: string;
  officialName?: string;
  type: string;
  subtype?: string;
  mask?: string;
  currentBalance?: number;
  availableBalance?: number;
  isoCurrencyCode: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface PlaidTransaction {
  id: string;
  bankAccountId: string;
  plaidTransactionId: string;
  amount: number;
  isoCurrencyCode: string;
  date: string;
  name: string;
  merchantName?: string;
  category?: string[];
  pending: boolean;
  linkedTransactionId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateLinkTokenResponse {
  linkToken: string;
  expiration: string;
}

export interface ExchangeTokenRequest {
  publicToken: string;
  institutionId: string;
  institutionName: string;
}

export interface ExchangeTokenResponse {
  item: PlaidItem;
  accounts: BankAccount[];
}

export interface SyncTransactionsResponse {
  added: number;
  modified: number;
  removed: number;
}

export interface WebhookPayload {
  webhook_type: string;
  webhook_code: string;
  item_id: string;
  error?: {
    error_code: string;
    error_message: string;
  };
}
