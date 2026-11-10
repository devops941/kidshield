const Restriction = require('../models/Restriction');
const Child = require('../models/Child');
const Notification = require('../models/Notification');

// @desc    Get restrictions for a child
// @route   GET /api/restrictions/:childId
// @access  Public or Private
exports.getRestrictions = async (req, res, next) => {
  try {
    let restrictions = await Restriction.findOne({ childId: req.params.childId });
    if (!restrictions) {
      // Create defaults
      restrictions = await Restriction.create({ childId: req.params.childId });
    }

    // Fetch unread notices for child device (e.g. app approved or rejected by parent)
    const childNotices = await Notification.find({
      childId: req.params.childId,
      target: 'child',
      isRead: false,
    }).sort({ timestamp: -1 }).limit(5);

    res.status(200).json({ success: true, restrictions, notices: childNotices });
  } catch (error) {
    next(error);
  }
};

// @desc    Update restrictions for a child
// @route   PUT /api/restrictions/:childId
// @access  Private (Parent)
exports.updateRestrictions = async (req, res, next) => {
  try {
    const {
      dailyScreenTimeMinutes,
      bedtimeStart,
      bedtimeEnd,
      studyTimeStart,
      studyTimeEnd,
      blockedPackageNames,
      isDailyLimitEnabled,
      isBedtimeEnabled,
      isStudyTimeEnabled,
    } = req.body;

    const restrictions = await Restriction.findOneAndUpdate(
      { childId: req.params.childId },
      {
        dailyScreenTimeMinutes,
        bedtimeStart,
        bedtimeEnd,
        studyTimeStart,
        studyTimeEnd,
        blockedPackageNames,
        isDailyLimitEnabled,
        isBedtimeEnabled,
        isStudyTimeEnabled,
      },
      { new: true, upsert: true }
    );

    // Also update cached fields on Child document
    await Child.findByIdAndUpdate(req.params.childId, {
      dailyScreenTimeLimitMinutes: dailyScreenTimeMinutes,
      bedtimeStart,
      bedtimeEnd,
      studyTimeStart,
      studyTimeEnd,
    });

    res.status(200).json({
      success: true,
      message: 'Restrictions updated and synchronized with child device',
      restrictions,
    });
  } catch (error) {
    next(error);
  }
};

