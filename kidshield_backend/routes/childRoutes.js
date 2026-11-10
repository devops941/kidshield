const express = require('express');
const router = express.Router();
const {
  addChild,
  getChildren,
  getChildById,
  updateChild,
  pairChildDevice,
  updatePermissions,
  regeneratePairingCode,
  unpairChildDevice,
  removeChild,
} = require('../controllers/childController');
const { protect } = require('../middleware/authMiddleware');

router.post('/pair', pairChildDevice); // Child device claims pairing code
router.put('/:id/permissions', updatePermissions); // Child device syncs permissions
router.put('/:id/regenerate-code', protect, regeneratePairingCode); // Parent regenerates pairing code
router.put('/:id/unpair', protect, unpairChildDevice); // Parent unpairs device

router.route('/')
  .post(protect, addChild)
  .get(protect, getChildren);

router.route('/:id')
  .get(getChildById)
  .put(protect, updateChild)
  .delete(protect, removeChild);

module.exports = router;

