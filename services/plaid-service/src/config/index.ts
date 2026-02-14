export const config = {
  port: parseInt(process.env.PORT || '3008', 10),
  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret',
  },
  plaid: {
    clientId: process.env.PLAID_CLIENT_ID || '',
    secret: process.env.PLAID_SECRET || '',
    env: (process.env.PLAID_ENV || 'sandbox') as 'sandbox' | 'development' | 'production',
    tokenEncryptionKey: process.env.PLAID_TOKEN_ENCRYPTION_KEY || 'dev-encryption-key',
  },
  db: {
    connectionString: process.env.DATABASE_URL,
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME || 'ovaflus',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
  },
};
