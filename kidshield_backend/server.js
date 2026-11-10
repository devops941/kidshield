const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Connect to MongoDB
const connectDB = require('./config/db');

// Initialize Firebase Admin for FCM
require('./config/firebaseAdmin');

const app = express();

// Core Middleware
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

// Ensure database connection is ready for every request (Serverless friendly)
app.use(async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Database connection failed',
      error: err.message,
    });
  }
});

// Health Check Endpoint
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    system: 'KidShield Smart Child Safety & Parental Monitoring Backend API',
    version: '1.0.0',
    deployment: process.env.VERCEL ? 'Vercel Serverless' : 'Local Node.js Server',
    timestamp: new Date().toISOString(),
    endpoints: {
      auth: '/api/auth',
      children: '/api/children',
      locations: '/api/locations',
      appUsage: '/api/app-usage',
      restrictions: '/api/restrictions',
      notifications: '/api/notifications',
      sos: '/api/sos',
    },
  });
});

// Mount Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/children', require('./routes/childRoutes'));
app.use('/api/locations', require('./routes/locationRoutes'));
app.use('/api/app-usage', require('./routes/appUsageRoutes'));
app.use('/api/installed-apps', require('./routes/installedAppRoutes'));
app.use('/api/restrictions', require('./routes/restrictionRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/sos', require('./routes/sosRoutes'));

// Error Handler Middleware
const errorHandler = require('./middleware/errorHandler');
app.use(errorHandler);

// Only listen locally if not deployed as a Vercel serverless function
if (!process.env.VERCEL) {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`====================================================`);
    console.log(`  🛡️  KIDSHIELD REST API SERVER RUNNING            `);
    console.log(`  🚀 Port: http://0.0.0.0:${PORT}                   `);
    console.log(`  📡 LAN:  http://192.168.1.9:${PORT}               `);
    console.log(`  📡 Mode: ${process.env.NODE_ENV || 'development'} `);
    console.log(`====================================================`);
  });
}

module.exports = app;
