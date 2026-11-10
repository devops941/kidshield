const express = require('express');
const router = express.Router();
const {
  syncInstalledApps,
  getInstalledApps,
  toggleAppBlock,
  approveApp,
  rejectApp,
} = require('../controllers/appUsageController');
const { protect } = require('../middleware/authMiddleware');

// Matches /api/installed-apps/...
router.post('/sync', syncInstalledApps);
router.get('/:childId', getInstalledApps);
router.put('/:childId/block', protect, toggleAppBlock);
router.put('/:childId/approve', protect, approveApp);
router.put('/:childId/reject', protect, rejectApp);

module.exports = router;

