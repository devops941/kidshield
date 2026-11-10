const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    parentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Child',
      required: true,
      index: true,
    },
    childName: {
      type: String,
      default: 'Child',
    },
    type: {
      type: String,
      enum: [
        'appInstalled',
        'screenTimeLimit',
        'locationDisabled',
        'deviceOffline',
        'lowBattery',
        'deviceDisconnected',
        'sosEmergency',
        'settingsChanged',
        'general',
      ],
      default: 'general',
    },
    severity: {
      type: String,
      enum: ['info', 'warning', 'critical'],
      default: 'info',
    },
    title: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    timestamp: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

notificationSchema.index({ parentId: 1, timestamp: -1 });

module.exports = mongoose.model('Notification', notificationSchema);

