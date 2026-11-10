const jwt = require('jsonwebtoken');
const Child = require('../models/Child');
const Restriction = require('../models/Restriction');
const { generatePairingCode } = require('../utils/pairingCodeGenerator');

// @desc    Add a new child profile
// @route   POST /api/children
// @access  Private (Parent)
exports.addChild = async (req, res, next) => {
  try {
    const { name, age, photoUrl, dailyScreenTimeLimitMinutes, gender, bedtimeStart, bedtimeEnd, phoneNumber } = req.body;

    let pairingCode = generatePairingCode();
    // Ensure pairing code uniqueness
    let existing = await Child.findOne({ pairingCode });
    while (existing) {
      pairingCode = generatePairingCode();
      existing = await Child.findOne({ pairingCode });
    }

    const child = await Child.create({
      parentId: req.user.id,
      name,
      age,
      gender: gender || 'boy',
      photoUrl,
      phoneNumber: phoneNumber || '',
      pairingCode,
      dailyScreenTimeLimitMinutes: dailyScreenTimeLimitMinutes || 180,
      bedtimeStart: bedtimeStart || '21:30',
      bedtimeEnd: bedtimeEnd || '06:30',
    });

    // Create default restrictions for this child
    await Restriction.create({
      childId: child._id,
      dailyScreenTimeMinutes: dailyScreenTimeLimitMinutes || 180,
      bedtimeStart: bedtimeStart || '21:30',
      bedtimeEnd: bedtimeEnd || '06:30',
      isBedtimeEnabled: true,
      isDailyLimitEnabled: true,
    });

    res.status(201).json({
      success: true,
      child,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all children for current parent
// @route   GET /api/children
// @access  Private (Parent)
exports.getChildren = async (req, res, next) => {
  try {
    const children = await Child.find({ parentId: req.user.id }).sort({ createdAt: -1 });
    // Ensure paired children have location permission enabled
    for (const child of children) {
      if (child.isPaired && !child.locationPermissionEnabled) {
        child.locationPermissionEnabled = true;
        await child.save();
      }
    }
    res.status(200).json({
      success: true,
      count: children.length,
      children,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get specific child details
// @route   GET /api/children/:id
// @access  Public or Private
exports.getChildById = async (req, res, next) => {
  try {
    const child = await Child.findById(req.params.id);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }
    res.status(200).json({ success: true, child });
  } catch (error) {
    next(error);
  }
};

// @desc    Pair a child device using 6-character code
// @route   POST /api/children/pair
// @access  Public (Called by Child app)
exports.pairChildDevice = async (req, res, next) => {
  try {
    const { pairingCode, deviceName } = req.body;

    if (!pairingCode) {
      return res.status(400).json({ success: false, message: 'Please provide a pairing code' });
    }

    const child = await Child.findOne({ pairingCode: pairingCode.trim().toUpperCase() });
    if (!child) {
      return res.status(404).json({ success: false, message: 'Invalid pairing code. Device not found.' });
    }

    // Check expiration (only if not already paired)
    if (child.pairingCodeExpiresAt && new Date() > child.pairingCodeExpiresAt && !child.isPaired) {
      return res.status(400).json({
        success: false,
        message: 'This pairing code has expired. Please ask your parent to generate a fresh code.',
      });
    }

    // Generate signed device token (valid for 365 days)
    const deviceToken = jwt.sign(
      { childId: child._id, parentId: child.parentId, role: 'child_device' },
      process.env.JWT_SECRET || 'kidshield_default_jwt_secret',
      { expiresIn: '365d' }
    );

    child.isPaired = true;
    child.isOnline = true;
    child.deviceToken = deviceToken;
    child.locationPermissionEnabled = true;
    child.usagePermissionEnabled = true;
    child.lastActive = new Date();
    if (deviceName) child.deviceName = deviceName;
    await child.save();

    res.status(200).json({
      success: true,
      message: 'Device paired successfully!',
      deviceToken,
      child,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Regenerate pairing code with fresh 15-minute expiration
// @route   PUT /api/children/:id/regenerate-code
// @access  Private (Parent)
exports.regeneratePairingCode = async (req, res, next) => {
  try {
    const child = await Child.findOne({ _id: req.params.id, parentId: req.user.id });
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }

    let pairingCode = generatePairingCode();
    let existing = await Child.findOne({ pairingCode, _id: { $ne: child._id } });
    while (existing) {
      pairingCode = generatePairingCode();
      existing = await Child.findOne({ pairingCode, _id: { $ne: child._id } });
    }

    child.pairingCode = pairingCode;
    child.pairingCodeExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    await child.save();

    res.status(200).json({
      success: true,
      message: 'Fresh pairing code generated',
      pairingCode: child.pairingCode,
      pairingCodeExpiresAt: child.pairingCodeExpiresAt,
      child,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Unpair / disconnect a child device
// @route   PUT /api/children/:id/unpair
// @access  Private (Parent)
exports.unpairChildDevice = async (req, res, next) => {
  try {
    const child = await Child.findOne({ _id: req.params.id, parentId: req.user.id });
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }

    child.isPaired = false;
    child.isOnline = false;
    child.deviceToken = null;
    await child.save();

    res.status(200).json({
      success: true,
      message: 'Device unpaired successfully',
      child,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update child device permission status
// @route   PUT /api/children/:id/permissions
// @access  Public (Child device)
exports.updatePermissions = async (req, res, next) => {
  try {
    const { locationPermissionEnabled, usagePermissionEnabled, notificationPermissionEnabled, batteryLevel } = req.body;
    const child = await Child.findById(req.params.id);
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }

    if (locationPermissionEnabled !== undefined) child.locationPermissionEnabled = locationPermissionEnabled;
    if (usagePermissionEnabled !== undefined) child.usagePermissionEnabled = usagePermissionEnabled;
    if (notificationPermissionEnabled !== undefined) child.notificationPermissionEnabled = notificationPermissionEnabled;
    if (batteryLevel !== undefined) child.batteryLevel = batteryLevel;
    child.lastActive = new Date();
    await child.save();

    res.status(200).json({
      success: true,
      message: 'Permissions synchronized successfully',
      child,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update child profile details (name, age, gender, phoneNumber, etc.)
// @route   PUT /api/children/:id
// @access  Private (Parent)
exports.updateChild = async (req, res, next) => {
  try {
    const child = await Child.findOne({ _id: req.params.id, parentId: req.user.id });
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child profile not found or unauthorized' });
    }

    const { name, age, gender, photoUrl, phoneNumber, dailyScreenTimeLimitMinutes, bedtimeStart, bedtimeEnd } = req.body;
    if (name !== undefined) child.name = name;
    if (age !== undefined) child.age = age;
    if (gender !== undefined) child.gender = gender;
    if (photoUrl !== undefined) child.photoUrl = photoUrl;
    if (phoneNumber !== undefined) child.phoneNumber = phoneNumber;
    if (dailyScreenTimeLimitMinutes !== undefined) child.dailyScreenTimeLimitMinutes = dailyScreenTimeLimitMinutes;
    if (bedtimeStart !== undefined) child.bedtimeStart = bedtimeStart;
    if (bedtimeEnd !== undefined) child.bedtimeEnd = bedtimeEnd;

    await child.save();

    res.status(200).json({
      success: true,
      message: 'Child profile updated successfully',
      child,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove or disconnect a child profile
// @route   DELETE /api/children/:id
// @access  Private (Parent)
exports.removeChild = async (req, res, next) => {
  try {
    const child = await Child.findOne({ _id: req.params.id, parentId: req.user.id });
    if (!child) {
      return res.status(404).json({ success: false, message: 'Child profile not found or unauthorized' });
    }

    await child.deleteOne();
    await Restriction.deleteOne({ childId: req.params.id });

    res.status(200).json({ success: true, message: 'Child profile removed successfully' });
  } catch (error) {
    next(error);
  }
};

