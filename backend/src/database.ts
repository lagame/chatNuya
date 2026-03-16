import { Pool } from 'pg';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is required for PostgreSQL connection');
}

const useSsl =
  process.env.DATABASE_SSL === 'true' ||
  process.env.NODE_ENV === 'production';

const pool = new Pool({
  connectionString,
  ssl: useSsl ? { rejectUnauthorized: false } : false,
});

pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

pool.on('error', (err: Error) => {
  console.error('PostgreSQL pool error:', err);
});

export async function initializeDatabase(): Promise<void> {
  // Create users table
  await runAsync(
    `CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      "birthDate" TEXT,
      gender TEXT,
      "avatarUrl" TEXT,
      language TEXT,
      "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`
  );
  console.log('Users table initialized');

  // Ensure language column exists for older schemas
  await runAsync(`ALTER TABLE users ADD COLUMN IF NOT EXISTS language TEXT`);

  // Create contacts table
  await runAsync(
    `CREATE TABLE IF NOT EXISTS contacts (
      id SERIAL PRIMARY KEY,
      "userId" INTEGER NOT NULL,
      "contactId" INTEGER NOT NULL,
      "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE("userId", "contactId"),
      FOREIGN KEY ("userId") REFERENCES users(id),
      FOREIGN KEY ("contactId") REFERENCES users(id)
    )`
  );
  console.log('Contacts table initialized');

  // Create messages table
  await runAsync(
    `CREATE TABLE IF NOT EXISTS messages (
      id SERIAL PRIMARY KEY,
      "senderId" INTEGER NOT NULL,
      "receiverId" INTEGER NOT NULL,
      content TEXT NOT NULL,
      "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY ("senderId") REFERENCES users(id),
      FOREIGN KEY ("receiverId") REFERENCES users(id)
    )`
  );
  console.log('Messages table initialized');
}

function toPgQuery(sql: string, params: any[]): { text: string; values: any[] } {
  let index = 0;
  const text = sql.replace(/\?/g, () => {
    index += 1;
    return `$${index}`;
  });
  return { text, values: params };
}

export function runAsync(sql: string, params: any[] = []): Promise<any> {
  return (async () => {
    const { text, values } = toPgQuery(sql, params);
    const normalized = text.trim();
    const shouldReturnId =
      /^INSERT\s+INTO/i.test(normalized) && !/\sRETURNING\s/i.test(normalized);
    const queryText = shouldReturnId ? `${normalized} RETURNING id` : normalized;
    const result = await pool.query(queryText, values);
    return {
      id: result.rows?.[0]?.id ?? null,
      changes: result.rowCount ?? 0,
    };
  })();
}

export function getAsync(sql: string, params: any[] = []): Promise<any> {
  return (async () => {
    const { text, values } = toPgQuery(sql, params);
    const result = await pool.query(text, values);
    return result.rows[0] ?? null;
  })();
}

export function allAsync(sql: string, params: any[] = []): Promise<any[]> {
  return (async () => {
    const { text, values } = toPgQuery(sql, params);
    const result = await pool.query(text, values);
    return result.rows || [];
  })();
}
