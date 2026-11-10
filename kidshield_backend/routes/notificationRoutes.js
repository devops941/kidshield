const express = require('express');
const router = express.Router();
const {
  getNotifications,
  markAsRead,
  markAllAsRead,
  getChildNotifications,
  markChildNotificationRead,
} = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');

// Parent notifications
router.get('/', protect, getNotifications);
router.put('/read-all', protect, markAllAsRead);
router.put('/:id/read', protect, markAsRead);

// Child notifications
router.get('/child/:childId', getChildNotifications);
router.put('/child/:id/read', markChildNotificationRead);

module.exports = router;

