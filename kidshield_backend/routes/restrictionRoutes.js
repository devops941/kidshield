const express = require('express');
const router = express.Router();
const {
  getRestrictions,
  updateRestrictions,
} = require('../controllers/restrictionController');
const { protect } = require('../middleware/authMiddleware');

router.get('/:childId', getRestrictions);
router.put('/:childId', protect, updateRestrictions);

module.exports = router;

