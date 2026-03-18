import { Server as SocketIOServer, Socket } from 'socket.io';
import { runAsync, getAsync, allAsync } from './database';
import { AuthPayload, verifyAuthToken } from './auth';

// Store online users
const onlineUsers = new Map<number, string>();

type AuthenticatedSocket = Socket & {
  data: {
    auth?: AuthPayload;
  };
};

function extractToken(socket: Socket): string | null {
  const authToken = socket.handshake.auth?.token;
  if (typeof authToken === 'string' && authToken.length > 0) {
    return authToken;
  }

  const headerToken = socket.handshake.headers.authorization;
  if (typeof headerToken === 'string' && headerToken.startsWith('Bearer ')) {
    return headerToken.slice(7);
  }

  return null;
}

export function setupSocket(io: SocketIOServer) {
  io.use((socket, next) => {
    try {
      const token = extractToken(socket);
      if (!token) {
        return next(new Error('Unauthorized'));
      }

      const auth = verifyAuthToken(token);
      (socket as AuthenticatedSocket).data.auth = auth;
      return next();
    } catch (_error) {
      return next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket: Socket) => {
    console.log('User connected:', socket.id);
    const authSocket = socket as AuthenticatedSocket;
    const authUserId = authSocket.data.auth?.userId;
    if (!authUserId) {
      socket.disconnect(true);
      return;
    }

    onlineUsers.set(authUserId, socket.id);
    io.emit('online_users', Array.from(onlineUsers.keys()));

    // User joins with their ID
    socket.on('user_join', (userId: number) => {
      const safeUserId = authUserId;
      if (Number(userId) !== safeUserId) {
        socket.emit('message_error', { error: 'Forbidden' });
        return;
      }

      onlineUsers.set(safeUserId, socket.id);
      console.log(`User ${safeUserId} joined. Online users:`, Array.from(onlineUsers.keys()));
      
      // Broadcast online users list
      io.emit('online_users', Array.from(onlineUsers.keys()));
    });

    // Send message
    socket.on('send_message', async (data: { senderId: number; receiverId: number; content: string }) => {
      try {
        const { receiverId, content } = data;
        const senderId = authUserId;

        if (!receiverId || !content || !String(content).trim()) {
          socket.emit('message_error', { error: 'Invalid message' });
          return;
        }

        // Save message to database
        await runAsync(
          `INSERT INTO messages ("senderId", "receiverId", content) VALUES (?, ?, ?)`,
          [senderId, receiverId, content]
        );

        // Get receiver's socket ID
        const receiverSocketId = onlineUsers.get(receiverId);

        // Send message to receiver if online
        if (receiverSocketId) {
          io.to(receiverSocketId).emit('receive_message', {
            senderId,
            receiverId,
            content,
            timestamp: new Date().toISOString(),
          });
        }

        // Confirm to sender
        socket.emit('message_sent', {
          senderId,
          receiverId,
          content,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        console.error('Error sending message:', error);
        socket.emit('message_error', { error: 'Failed to send message' });
      }
    });

    // Get message history
    socket.on('get_messages', async (data: { userId1: number; userId2: number }, callback: Function) => {
      try {
        const requestedA = Number(data.userId1);
        const requestedB = Number(data.userId2);
        if (requestedA !== authUserId && requestedB !== authUserId) {
          callback([]);
          return;
        }

        const messages = await allAsync(
          `SELECT * FROM messages 
           WHERE ("senderId" = ? AND "receiverId" = ?) OR ("senderId" = ? AND "receiverId" = ?)
           ORDER BY "createdAt" ASC`,
          [requestedA, requestedB, requestedB, requestedA]
        );
        callback(messages);
      } catch (error) {
        console.error('Error fetching messages:', error);
        callback([]);
      }
    });

    // User typing indicator
    socket.on('typing', (data: { senderId: number; receiverId: number }) => {
      if (Number(data.senderId) !== authUserId) {
        socket.emit('message_error', { error: 'Forbidden' });
        return;
      }

      const receiverSocketId = onlineUsers.get(data.receiverId);
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('user_typing', { senderId: authUserId });
      }
    });

    // User stopped typing
    socket.on('stop_typing', (data: { senderId: number; receiverId: number }) => {
      if (Number(data.senderId) !== authUserId) {
        socket.emit('message_error', { error: 'Forbidden' });
        return;
      }

      const receiverSocketId = onlineUsers.get(data.receiverId);
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('user_stop_typing', { senderId: authUserId });
      }
    });

    // User disconnects
    socket.on('disconnect', () => {
      // Find and remove user from online list
      const mappedSocket = onlineUsers.get(authUserId);
      if (mappedSocket === socket.id) {
        onlineUsers.delete(authUserId);
        console.log(`User ${authUserId} disconnected. Online users:`, Array.from(onlineUsers.keys()));
        io.emit('online_users', Array.from(onlineUsers.keys()));
      }
    });
  });
}

export function getOnlineUsers(): number[] {
  return Array.from(onlineUsers.keys());
}
