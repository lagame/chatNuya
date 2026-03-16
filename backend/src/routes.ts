import express, { Router, Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { runAsync, getAsync, allAsync } from './database';

const router = Router();

// Configure multer for file uploads
const uploadsDir = process.env.UPLOADS_PATH || './uploads';
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'avatar-' + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only images are allowed.'));
    }
  },
});

// POST /register - Register a new user
router.post('/register', upload.single('avatar'), async (req: Request, res: Response) => {
  try {
    const { username, email, password, birthDate, gender, language } = req.body;
    const normalizedLanguage =
      typeof language === 'string'
        ? language.replace('_', '-').toLowerCase().replace(/-(\w{2})$/, (m, g1) => `-${g1.toUpperCase()}`)
        : null;

    // Validation
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    let avatarUrl = null;
    if (req.file) {
      avatarUrl = `/uploads/${req.file.filename}`;
    }

    // Insert user into database
    const result = await runAsync(
      `INSERT INTO users (username, email, password, "birthDate", gender, "avatarUrl", language) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        username,
        email,
        password,
        birthDate || null,
        gender || null,
        avatarUrl,
        normalizedLanguage || null,
      ]
    );

    res.status(201).json({
      id: result.id,
      username,
      email,
      birthDate: birthDate || null,
      gender: gender || null,
      avatarUrl,
      language: normalizedLanguage || null,
    });
  } catch (error: any) {
    console.error('Register error:', error);
    if (error?.code === '23505') {
      return res.status(409).json({ error: 'Username or email already exists' });
    }
    res.status(500).json({ error: 'Registration failed' });
  }
});

// POST /login - Login user
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { identifier, password } = req.body;

    if (!identifier || !password) {
      return res.status(400).json({ error: 'Email or username and password are required' });
    }

    const user = await getAsync(
      `SELECT id, username, email, "birthDate", gender, "avatarUrl", language
       FROM users
       WHERE (email = ? OR username = ?) AND password = ?`,
      [identifier, identifier, password]
    );

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    res.json(user);
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// GET /users - Get all users
router.get('/users', async (req: Request, res: Response) => {
  try {
    const users = await allAsync(
      `SELECT id, username, email, "birthDate", gender, "avatarUrl", language FROM users`
    );
    res.json(users);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// GET /users/:id - Get specific user
router.get('/users/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const user = await getAsync(
      `SELECT id, username, email, "birthDate", gender, "avatarUrl", language FROM users WHERE id = ?`,
      [id]
    );

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

// PUT /users/:id/language - Update user language
router.put('/users/:id/language', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { language } = req.body;
    const normalizedLanguage =
      typeof language === 'string'
        ? language.replace('_', '-').toLowerCase().replace(/-(\w{2})$/, (m, g1) => `-${g1.toUpperCase()}`)
        : null;

    if (!normalizedLanguage) {
      return res.status(400).json({ error: 'Invalid language' });
    }

    await runAsync(`UPDATE users SET language = ? WHERE id = ?`, [normalizedLanguage, id]);

    const user = await getAsync(
      `SELECT id, username, email, "birthDate", gender, "avatarUrl", language FROM users WHERE id = ?`,
      [id]
    );

    res.json(user);
  } catch (error) {
    console.error('Update language error:', error);
    res.status(500).json({ error: 'Failed to update language' });
  }
});

// GET /contacts/:userId - Get contacts for user
router.get('/contacts/:userId', async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const contacts = await allAsync(
      `SELECT u.id, u.username, u.email, u."birthDate", u.gender, u."avatarUrl", u.language
       FROM contacts c
       JOIN users u ON u.id = c."contactId"
       WHERE c."userId" = ?
       ORDER BY u.username ASC`,
      [userId]
    );
    res.json(contacts);
  } catch (error) {
    console.error('Get contacts error:', error);
    res.status(500).json({ error: 'Failed to fetch contacts' });
  }
});

// POST /contacts - Add contact by username or email
router.post('/contacts', async (req: Request, res: Response) => {
  try {
    const { userId, query } = req.body;

    if (!userId || !query) {
      return res.status(400).json({ error: 'Invalid contact' });
    }

    const normalized = String(query).trim().toLowerCase();
    if (!normalized) {
      return res.status(400).json({ error: 'Invalid contact' });
    }

    const contact = await getAsync(
      `SELECT id, username, email, "birthDate", gender, "avatarUrl", language
       FROM users WHERE lower(username) = ? OR lower(email) = ?`,
      [normalized, normalized]
    );

    if (!contact) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (contact.id === Number(userId)) {
      return res.status(400).json({ error: 'Invalid contact' });
    }

    const existing = await getAsync(
      `SELECT 1 FROM contacts WHERE "userId" = ? AND "contactId" = ?`,
      [userId, contact.id]
    );

    if (existing) {
      return res.status(409).json({ error: 'Contact already exists' });
    }

    await runAsync(`INSERT INTO contacts ("userId", "contactId") VALUES (?, ?)`, [
      userId,
      contact.id,
    ]);
    await runAsync(`INSERT INTO contacts ("userId", "contactId") VALUES (?, ?)`, [
      contact.id,
      userId,
    ]);

    res.json(contact);
  } catch (error) {
    console.error('Add contact error:', error);
    res.status(500).json({ error: 'Failed to add contact' });
  }
});

export default router;
