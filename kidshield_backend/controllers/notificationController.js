const Notification = require('../models/Notification');

// @desc    Get all notifications for logged in parent
// @route   GET /api/notifications
// @access  Private (Parent)
exports.getNotifications = async (req, res, next) => {
  try {
    const { childId } = req.query;
    const query = { parentId: req.user.id };
    if (childId) query.childId = childId;

    const notifications = await Notification.find(query).sort({ timestamp: -1 }).limit(100);
    const unreadCount = await Notification.countDocuments({ ...query, isRead: false });

    res.status(200).json({
      success: true,
      count: notifications.length,
      unreadCount,
      notifications,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mark a notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private (Parent)
exports.markAsRead = async (req, res, next) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, parentId: req.user.id },
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.status(200).json({ success: true, notification });
  } catch (error) {
    next(error);
  }
};

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/read-all
// @access  Private (Parent)
exports.markAllAsRead = async (req, res, next) => {
  try {
    await Notification.updateMany({ parentId: req.user.id, isRead: false }, { isRead: true });
    res.status(200).json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    next(error);
  }
};

// @desc    Get notices / notifications for child device
// @route   GET /api/notifications/child/:childId
// @access  Public (Child Device)
exports.getChildNotifications = async (req, res, next) => {
  try {
    const { childId } = req.params;
    const notifications = await Notification.find({
      childId,
      target: 'child',
    }).sort({ timestamp: -1 }).limit(50);

    const unreadCount = await Notification.countDocuments({
      childId,
      target: 'child',
      isRead: false,
    });

    res.status(200).json({
      success: true,
      count: notifications.length,
      unreadCount,
      notifications,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mark child notification as read
// @route   PUT /api/notifications/child/:id/read
// @access  Public (Child Device)
exports.markChildNotificationRead = async (req, res, next) => {
  try {
    const notification = await Notification.findByIdAndUpdate(
      req.params.id,
      { isRead: true },
      { new: true }
    );
    res.status(200).json({ success: true, notification });
  } catch (error) {
    next(error);
  }
};

