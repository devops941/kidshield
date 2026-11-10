const mongoose = require('mongoose');

const childSchema = new mongoose.Schema(
  {
    parentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: [true, 'Please enter child name'],
      trim: true,
    },
    age: {
      type: Number,
      required: [true, 'Please enter child age'],
      min: 3,
      max: 18,
    },
    gender: {
      type: String,
      enum: ['boy', 'girl'],
      default: 'boy',
    },
    photoUrl: {
      type: String,
      default: null,
    },
    phoneNumber: {
      type: String,
      default: '',
      trim: true,
    },
    pairingCode: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
      index: true,
    },
    pairingCodeExpiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 15 * 60 * 1000),
    },
    deviceToken: {
      type: String,
      default: null,
    },
    isPaired: {
      type: Boolean,
      default: false,
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
    batteryLevel: {
      type: Number,
      default: 100,
      min: 0,
      max: 100,
    },
    isCharging: {
      type: Boolean,
      default: false,
    },
    lastActive: {
      type: Date,
      default: Date.now,
    },
    locationPermissionEnabled: {
      type: Boolean,
      default: false,
    },
    usagePermissionEnabled: {
      type: Boolean,
      default: false,
    },
    notificationPermissionEnabled: {
      type: Boolean,
      default: false,
    },
    deviceName: {
      type: String,
      default: 'Android Device',
    },
    dailyScreenTimeLimitMinutes: {
      type: Number,
      default: 180,
    },
    bedtimeStart: {
      type: String,
      default: '21:30',
    },
    bedtimeEnd: {
      type: String,
      default: '06:30',
    },
    studyTimeStart: {
      type: String,
      default: '16:00',
    },
    studyTimeEnd: {
      type: String,
      default: '18:00',
    },
    restrictionsActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Child', childSchema);

