const express = require('express');
const router = express.Router();
const {
  updateLocation,
  getLatestLocation,
  getLocationHistory,
} = require('../controllers/locationController');

router.post('/', updateLocation); // Child posts GPS location
router.get('/:childId/latest', getLatestLocation); // Parent gets current location
router.get('/:childId/history', getLocationHistory); // Parent gets route history

module.exports = router;

