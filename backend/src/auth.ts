import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

const JWT_SECRET = process.env.JWT_SECRET || 'change-me-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

export type AuthPayload = {
  userId: number;
  username: string;
  email: string;
};

export type AuthenticatedRequest = Request & {
  auth?: AuthPayload;
};

export function signAuthToken(payload: AuthPayload): string {
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  } as jwt.SignOptions);
}

export function verifyAuthToken(token: string): AuthPayload {
  return jwt.verify(token, JWT_SECRET) as AuthPayload;
}

export async function hashPassword(password: string): Promise<string> {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
}

export async function verifyPassword(
  plainPassword: string,
  storedPassword: string
): Promise<boolean> {
  // Backward compatibility: allow old plain-text records and migrate on login.
  if (!storedPassword.startsWith('$2a$') &&
      !storedPassword.startsWith('$2b$') &&
      !storedPassword.startsWith('$2y$')) {
    return plainPassword === storedPassword;
  }

  return bcrypt.compare(plainPassword, storedPassword);
}

export function authenticateToken(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ')
    ? authHeader.slice(7)
    : null;

  if (!token) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as AuthPayload;
    req.auth = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

export function ensureSelfByParam(paramName: string) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    const authUserId = req.auth?.userId;
    const targetUserId = Number(req.params[paramName]);

    if (!authUserId || Number.isNaN(targetUserId) || authUserId !== targetUserId) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    next();
  };
}

export function ensureSelfByBody(bodyKey: string) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    const authUserId = req.auth?.userId;
    const targetUserId = Number(req.body?.[bodyKey]);

    if (!authUserId || Number.isNaN(targetUserId) || authUserId !== targetUserId) {
      res.status(403).json({ error: 'Forbidden' });
      return;
    }

    next();
  };
}
