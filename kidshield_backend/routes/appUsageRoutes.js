const express = require('express');
const router = express.Router();
const {
  syncAppUsage,
  getAppUsage,
  getDailyActivityHistory,
  syncInstalledApps,
  getInstalledApps,
  toggleAppBlock,
  approveApp,
  rejectApp,
} = require('../controllers/appUsageController');
const { protect } = require('../middleware/authMiddleware');

// Screen time & usage
router.post('/sync', syncAppUsage);
router.get('/:childId/daily-history', getDailyActivityHistory);
router.get('/:childId', getAppUsage);

// Installed Apps
router.post('/installed/sync', syncInstalledApps);
router.get('/installed/:childId', getInstalledApps);
router.put('/installed/:childId/block', protect, toggleAppBlock);
router.put('/installed/:childId/approve', protect, approveApp);
router.put('/installed/:childId/reject', protect, rejectApp);

module.exports = router;

