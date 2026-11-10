const mongoose = require('mongoose');

const appUsageSchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Child',
      required: true,
      index: true,
    },
    packageName: {
      type: String,
      required: true,
    },
    appName: {
      type: String,
      required: true,
    },
    category: {
      type: String,
      default: 'General',
    },
    icon: {
      type: String,
      default: '',
    },
    usageMinutesToday: {
      type: Number,
      default: 0,
    },
    usageMinutesWeekly: {
      type: Number,
      default: 0,
    },
    usageMinutesMonthly: {
      type: Number,
      default: 0,
    },
    launchCountToday: {
      type: Number,
      default: 0,
    },
    isRestricted: {
      type: Boolean,
      default: false,
    },
    lastSyncDate: {
      type: String, // "YYYY-MM-DD" e.g. "2026-11-06"
      default: '',
    },
    lastUsed: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

appUsageSchema.index({ childId: 1, packageName: 1 }, { unique: true });

module.exports = mongoose.model('AppUsage', appUsageSchema);

