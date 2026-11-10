# 🛡️ KidShield — Smart Child Safety & Parental Monitoring Platform

KidShield is an end-to-end child safety and parental supervision system designed to help parents monitor, protect, and stay connected with their children in real time. It combines real-time GPS tracking, emergency SOS alerts, geofencing, app usage monitoring, screen time limits, and direct emergency calling with strict security and privacy standards.

---

## 🌟 Key Features

### 👨‍👩‍👧 For Parents (Parent App)
- **Live GPS Tracking & Geofencing**: Real-time child location updates on interactive maps, route history, and instant alerts when entering or leaving safe zones (Home, School, etc.).
- **1-Tap Emergency SOS Response**: Receive instant high-priority distress alerts with one-tap direct calling to the child's SIM number and live Google Maps navigation to their coordinates.
- **Screen Time & Bedtime Controls**: Daily screen time limits, scheduled bedtime app lockdowns, and instant device pause.
- **App Usage Insights**: Monitor which apps are used and for how long with daily/weekly breakdown charts.
- **Battery & Network Monitoring**: Real-time battery percentage and network connectivity status of child devices.
- **Secure Authentication & Account Recovery**: JWT-based authentication with automated 6-digit OTP password reset delivered via Gmail SMTP.

### 📱 For Children (Child App)
- **Interactive Interface**: Clean, friendly UI with quick SOS alert trigger.
- **Background Safety Service**: Lightweight background sync for location, battery status, and safety heartbeats.
- **Emergency SOS Button**: One-touch panic button that instantly broadcasts exact GPS coordinates to parents.
- **Transparency by Design**: Compliant with Android background location policies and child safety regulations.

### ⚡ Backend API & Real-time Server
- **Serverless Ready (Vercel)**: Global Mongoose connection caching and serverless API handlers.
- **Real-Time Communication**: Socket.io / WebSocket support for low-latency live telemetry.
- **Automated Email Service**: Nodemailer integration with HTML templates for instant OTP delivery.
- **Secure REST APIs**: Role-based access control, input validation, and password hashing with bcrypt.

---

## 📂 Repository Structure

```text
kidshield/
├── kidshield_backend/       # Node.js / Express / MongoDB REST API & Serverless functions
│   ├── api/                 # Vercel serverless entrypoint (index.js)
│   ├── config/              # MongoDB connection & Firebase admin configs
│   ├── controllers/         # Auth, Child, Alert, Geofence, & Monitoring controllers
│   ├── models/              # Mongoose data schemas (Parent, Child, Alert, Geofence, etc.)
│   ├── routes/              # Express API route declarations
│   ├── utils/               # Email service (Nodemailer) & token helpers
│   ├── vercel.json          # Vercel deployment configuration
│   └── server.js            # Standalone Node.js server entrypoint
│
├── kidshield_parent/        # Flutter Parental Control App (Android & iOS)
│   ├── lib/
│   │   ├── config/          # App constants, routes, theme & API configuration
│   │   ├── models/          # Dart data models (Parent, Child, Geofence, Alert, etc.)
│   │   ├── providers/       # State management (Provider pattern)
│   │   ├── screens/         # UI Screens (Auth, Dashboard, Map, Children, Alerts, Profile)
│   │   ├── services/        # HTTP API, WebSocket, Location & Notification services
│   │   └── widgets/         # Reusable UI components & dialogs
│   └── pubspec.yaml
│
└── kidshield_child/         # Flutter Child Companion App
    ├── lib/                 # Core tracking, SOS triggers & background services
    └── pubspec.yaml
```

---

## 🚀 Getting Started

### 1. Prerequisites
- **Node.js**: v18.x or higher
- **Flutter SDK**: 3.x or higher
- **MongoDB**: MongoDB Atlas cluster or local instance
- **Android Studio / VS Code** with Flutter & Dart extensions

---

### 2. Backend Setup (`kidshield_backend`)

1. Navigate to the backend directory:
   ```bash
   cd kidshield_backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create your `.env` file based on `.env.example`:
   ```env
   PORT=5000
   NODE_ENV=development
   MONGODB_URI=mongodb+srv://<username>:<password>@cluster0.mongodb.net/kidshield?retryWrites=true&w=majority
   JWT_SECRET=your_jwt_secret_key
   JWT_EXPIRES_IN=30d

   # Gmail SMTP for OTP Password Reset
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your_email@gmail.com
   SMTP_PASS=your_app_password
   SMTP_FROM=your_email@gmail.com
   FROM_NAME=KidShield Security
   ```
4. Start the development server:
   ```bash
   npm run dev
   ```

---

### 3. Parent App Setup (`kidshield_parent`)

1. Navigate to the parent app directory:
   ```bash
   cd kidshield_parent
   ```
2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Set your backend URL in `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_SERVER_IP:5000/api';
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

### 4. Child App Setup (`kidshield_child`)

1. Navigate to the child app directory:
   ```bash
   cd kidshield_child
   ```
2. Get dependencies & run:
   ```bash
   flutter pub get
   flutter run
   ```

---

## 🌐 Deploying Backend to Vercel

The backend includes a preconfigured `vercel.json` and `api/index.js` for instant serverless deployment:

1. Install Vercel CLI:
   ```bash
   npm i -g vercel
   ```
2. Deploy from the `kidshield_backend` directory:
   ```bash
   cd kidshield_backend
   vercel
   ```
3. In the Vercel Project Settings, add all environment variables defined in `.env.example`.

---

## 🔒 Security & Privacy

- All sensitive keys (`.env`, service account credentials) are strictly ignored via `.gitignore`.
- Passwords are encrypted with `bcrypt` (salt rounds: 10).
- Stateless authentication using industry-standard JSON Web Tokens (JWT).
- Child phone numbers are protected and only utilized for emergency parent-to-child dialing.

---

## 📄 License

This project is licensed under the MIT License.

