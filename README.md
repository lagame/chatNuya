# NUYA - ICQ-Inspired Real-Time Chat Application

A modern, full-stack chat application inspired by ICQ with real-time messaging capabilities. Built with **Node.js + TypeScript + SQLite** for the backend and **Flutter** for the cross-platform frontend (Web, Windows, Android).

## 🎯 Features

- **Real-Time Messaging**: Instant message delivery using WebSocket (Socket.io)
- **User Authentication**: Register and login with email/password
- **Avatar Upload**: Upload profile pictures during registration
- **Online Status**: See who's online/offline in real-time
- **Typing Indicators**: Know when someone is typing
- **Dark Mode UI**: Modern dark theme inspired by contemporary chat apps
- **Cross-Platform**: Works on Web, Windows, Android, and more
- **Message History**: Persistent message storage in SQLite

## 📁 Project Structure

```
chat-app/
├── backend/                 # Node.js + TypeScript backend
│   ├── src/
│   │   ├── server.ts       # Main server file
│   │   ├── database.ts     # SQLite database setup
│   │   ├── routes.ts       # REST API routes
│   │   └── socket.ts       # Socket.io event handlers
│   ├── uploads/            # User avatar storage
│   ├── package.json        # Dependencies
│   ├── tsconfig.json       # TypeScript configuration
│   ├── .env                # Environment variables
│   └── .gitignore
│
├── frontend/               # Flutter application
│   ├── lib/
│   │   ├── main.dart       # App entry point
│   │   ├── models/         # Data models
│   │   │   ├── user.dart
│   │   │   └── message.dart
│   │   ├── services/       # API and Socket services
│   │   │   ├── api_service.dart
│   │   │   ├── socket_service.dart
│   │   │   └── storage_service.dart
│   │   ├── screens/        # UI screens
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   └── chat_screen.dart
│   │   ├── widgets/        # Reusable widgets
│   │   └── utils/
│   │       └── theme.dart  # Dark theme configuration
│   ├── pubspec.yaml        # Flutter dependencies
│   ├── analysis_options.yaml
│   ├── .gitignore
│   └── assets/             # Images and assets
│
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

- **Node.js** (v16 or higher)
- **npm** or **yarn**
- **Flutter** (v3.0 or higher)
- **Dart** (included with Flutter)

### Backend Setup

1. Navigate to the backend directory:

```bash
cd backend
```

2. Install dependencies:

```bash
npm install
```

3. Start the server:

```bash
npm start
```

The backend will start on `http://localhost:3000`

**Note**: The server creates a SQLite database (`chat.db`) automatically on first run.

### Frontend Setup

1. Navigate to the frontend directory:

```bash
cd frontend
```

2. Get Flutter dependencies:

```bash
flutter pub get
```

3. Run the application:

**For Web:**
```bash
flutter run -d chrome
```

**For Windows:**
```bash
flutter run -d windows
```

**For Android (Emulator):**
```bash
flutter run
```

**For Android (Physical Device):**
```bash
flutter run
```

## 🔨 Building for Production

### Backend Build

```bash
cd backend
npm run build
npm run prod
```

### Frontend Builds

**Web Build:**
```bash
cd frontend
flutter build web
```

Output: `frontend/build/web/`

**Windows Build:**
```bash
cd frontend
flutter build windows
```

Output: `frontend/build/windows/runner/Release/`

**Android APK (Release):**
```bash
cd frontend
flutter build apk --release
```

Output: `frontend/build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle:**
```bash
cd frontend
flutter build appbundle --release
```

Output: `frontend/build/app/outputs/bundle/release/app-release.aab`

## 📋 API Endpoints

### Authentication

- **POST** `/register` - Register a new user
  - Form data: `username`, `email`, `password`, `birthDate` (optional), `gender` (optional), `avatar` (file)
  - Returns: User object with ID

- **POST** `/login` - Login user
  - JSON: `{ "email": "user@example.com", "password": "password" }`
  - Returns: User object with ID

### Users

- **GET** `/users` - Get all registered users
  - Returns: Array of user objects

- **GET** `/users/:id` - Get specific user by ID
  - Returns: User object

### Health Check

- **GET** `/health` - Server health status
  - Returns: `{ "status": "ok", "timestamp": "ISO8601" }`

## 🔌 Socket.io Events

### Client → Server

- **user_join** - User connects to chat
  - Data: `userId` (integer)

- **send_message** - Send a message
  - Data: `{ "senderId": int, "receiverId": int, "content": string }`

- **get_messages** - Request message history
  - Data: `{ "userId1": int, "userId2": int }`

- **typing** - User is typing
  - Data: `{ "senderId": int, "receiverId": int }`

- **stop_typing** - User stopped typing
  - Data: `{ "senderId": int, "receiverId": int }`

### Server → Client

- **online_users** - List of online user IDs
  - Data: `[userId1, userId2, ...]`

- **receive_message** - New message received
  - Data: `{ "senderId": int, "receiverId": int, "content": string, "timestamp": ISO8601 }`

- **message_sent** - Confirmation message was sent
  - Data: `{ "senderId": int, "receiverId": int, "content": string, "timestamp": ISO8601 }`

- **user_typing** - Someone is typing
  - Data: `{ "senderId": int }`

- **user_stop_typing** - Someone stopped typing
  - Data: `{ "senderId": int }`

## 🗄️ Database Schema

### Users Table

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | User ID |
| username | TEXT UNIQUE | Username |
| email | TEXT UNIQUE | Email address |
| password | TEXT | Password (plain text for prototype) |
| birthDate | TEXT | Birth date (YYYY-MM-DD) |
| gender | TEXT | Gender (Male/Female/Other) |
| avatarUrl | TEXT | Avatar image URL |
| createdAt | DATETIME | Account creation timestamp |

### Messages Table

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Message ID |
| senderId | INTEGER FK | Sender user ID |
| receiverId | INTEGER FK | Receiver user ID |
| content | TEXT | Message content |
| createdAt | DATETIME | Message timestamp |

## 🎨 UI/UX Features

- **Dark Mode by Default**: Modern dark theme for reduced eye strain
- **Material 3 Design**: Latest Material Design components
- **Responsive Layout**: Adapts to different screen sizes
- **Avatar Display**: User profile pictures with fallback icons
- **Online Status Indicators**: Green dot for online users
- **Typing Indicators**: Real-time typing notifications
- **Message Timestamps**: Local time display for each message

## 🔐 Security Notes

**⚠️ Important**: This is a prototype application. For production use:

1. **Password Hashing**: Implement bcrypt or similar for password hashing
2. **JWT Authentication**: Use JWT tokens instead of plain text storage
3. **HTTPS/WSS**: Use secure WebSocket connections (WSS)
4. **Input Validation**: Add comprehensive input validation and sanitization
5. **Rate Limiting**: Implement rate limiting on API endpoints
6. **CORS**: Configure CORS properly for your domain
7. **File Upload Security**: Validate file types and sizes more strictly

## 🐛 Troubleshooting

### Backend won't start

- Check if port 3000 is already in use
- Ensure Node.js is installed: `node --version`
- Check for errors in the console

### Frontend can't connect to backend

- Verify backend is running on `http://localhost:3000`
- For emulators, use `10.0.2.2:3000` instead of `localhost:3000`
- Check firewall settings

### Socket.io connection issues

- Ensure WebSocket is enabled in your network
- Check browser console for errors
- Verify Socket.io version compatibility

### Image upload not working

- Check `backend/uploads/` directory exists and is writable
- Verify image file size is under 5MB
- Check file format is supported (JPEG, PNG, GIF, WebP)

## 📦 Dependencies

### Backend

- **express**: Web framework
- **socket.io**: Real-time communication
- **sqlite3**: Database
- **multer**: File upload handling
- **cors**: Cross-origin resource sharing
- **typescript**: Type safety
- **ts-node**: TypeScript execution

### Frontend

- **flutter**: UI framework
- **http**: HTTP client
- **socket_io_client**: Socket.io client
- **image_picker**: Image selection
- **cached_network_image**: Image caching
- **shared_preferences**: Local storage
- **path_provider**: File system access

## 📝 Environment Variables

### Backend (.env)

```
PORT=3000
NODE_ENV=development
DATABASE_PATH=./chat.db
UPLOADS_PATH=./uploads
```

## 🚢 Deployment

### Backend Deployment (Heroku, Railway, Render)

1. Build the project: `npm run build`
2. Set environment variables on your hosting platform
3. Deploy the `dist/` folder and `uploads/` directory
4. Ensure WebSocket support is enabled

### Frontend Deployment

**Web**: Deploy the `build/web/` folder to any static hosting (Vercel, Netlify, GitHub Pages)

**Android**: Upload APK or App Bundle to Google Play Store

**Windows**: Package as installer or distribute directly

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## 📧 Support

For issues or questions, please open an issue on the GitHub repository.

---

**Happy Chatting! 💬**
