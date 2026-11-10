const express = require('express');
const router = express.Router();
const { triggerSos } = require('../controllers/sosController');

router.post('/trigger', triggerSos); // Child triggers emergency SOS alert

module.exports = router;

