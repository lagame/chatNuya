import { Server as SocketIOServer, Socket } from 'socket.io';
import { runAsync, getAsync, allAsync } from './database';

// Store online users
const onlineUsers = new Map<number, string>();

export function setupSocket(io: SocketIOServer) {
  io.on('connection', (socket: Socket) => {
    console.log('User connected:', socket.id);

    // User joins with their ID
    socket.on('user_join', (userId: number) => {
      onlineUsers.set(userId, socket.id);
      console.log(`User ${userId} joined. Online users:`, Array.from(onlineUsers.keys()));
      
      // Broadcast online users list
      io.emit('online_users', Array.from(onlineUsers.keys()));
    });

    // Send message
    socket.on('send_message', async (data: { senderId: number; receiverId: number; content: string }) => {
      try {
        const { senderId, receiverId, content } = data;

        // Save message to database
        await runAsync(
          `INSERT INTO messages (senderId, receiverId, content) VALUES (?, ?, ?)`,
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
        const messages = await allAsync(
          `SELECT * FROM messages 
           WHERE (senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?)
           ORDER BY createdAt ASC`,
          [data.userId1, data.userId2, data.userId2, data.userId1]
        );
        callback(messages);
      } catch (error) {
        console.error('Error fetching messages:', error);
        callback([]);
      }
    });

    // User typing indicator
    socket.on('typing', (data: { senderId: number; receiverId: number }) => {
      const receiverSocketId = onlineUsers.get(data.receiverId);
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('user_typing', { senderId: data.senderId });
      }
    });

    // User stopped typing
    socket.on('stop_typing', (data: { senderId: number; receiverId: number }) => {
      const receiverSocketId = onlineUsers.get(data.receiverId);
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('user_stop_typing', { senderId: data.senderId });
      }
    });

    // User disconnects
    socket.on('disconnect', () => {
      // Find and remove user from online list
      for (const [userId, socketId] of onlineUsers.entries()) {
        if (socketId === socket.id) {
          onlineUsers.delete(userId);
          console.log(`User ${userId} disconnected. Online users:`, Array.from(onlineUsers.keys()));
          io.emit('online_users', Array.from(onlineUsers.keys()));
          break;
        }
      }
    });
  });
}

export function getOnlineUsers(): number[] {
  return Array.from(onlineUsers.keys());
}
