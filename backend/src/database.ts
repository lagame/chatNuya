import sqlite3 from 'sqlite3';

const dbPath = process.env.DATABASE_PATH || './chat.db';

export const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Database connection error:', err);
  } else {
    console.log('Connected to SQLite database');
  }
});

export async function initializeDatabase(): Promise<void> {
  // Create users table
  await runAsync(
    `CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      birthDate TEXT,
      gender TEXT,
      avatarUrl TEXT,
      language TEXT,
      createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )`
  );
  console.log('Users table initialized');

  // Ensure language column exists for older databases
  const userColumns = await allAsync(`PRAGMA table_info(users)`);
  const hasLanguage = userColumns.some((col: any) => col.name === 'language');
  if (!hasLanguage) {
    await runAsync('ALTER TABLE users ADD COLUMN language TEXT');
  }

  // Create contacts table
  await runAsync(
    `CREATE TABLE IF NOT EXISTS contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL,
      contactId INTEGER NOT NULL,
      createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(userId, contactId),
      FOREIGN KEY (userId) REFERENCES users(id),
      FOREIGN KEY (contactId) REFERENCES users(id)
    )`
  );
  console.log('Contacts table initialized');

  // Create messages table
  await runAsync(
    `CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      senderId INTEGER NOT NULL,
      receiverId INTEGER NOT NULL,
      content TEXT NOT NULL,
      createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (senderId) REFERENCES users(id),
      FOREIGN KEY (receiverId) REFERENCES users(id)
    )`
  );
  console.log('Messages table initialized');
}

export function runAsync(sql: string, params: any[] = []): Promise<any> {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
}

export function getAsync(sql: string, params: any[] = []): Promise<any> {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
}

export function allAsync(sql: string, params: any[] = []): Promise<any[]> {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows || []);
    });
  });
}
