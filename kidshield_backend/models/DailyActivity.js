const mongoose = require('mongoose');

const dailyActivitySchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Child',
      required: true,
      index: true,
    },
    date: {
      type: String, // ISO date string "YYYY-MM-DD" e.g. "2026-11-06"
      required: true,
      index: true,
    },
    timezone: {
      type: String,
      default: 'Asia/Kolkata',
    },
    totalScreenTimeMinutes: {
      type: Number,
      default: 0,
    },
    hourlyBreakdown: [{ type: Number }],
    weeklyBreakdown: [{ type: Number }],
    monthlyBreakdown: [{ type: Number }],
    appBreakdown: [
      {
        packageName: { type: String, required: true },
        appName: { type: String, default: '' },
        category: { type: String, default: 'General' },
        icon: { type: String, default: '' },
        usageMinutes: { type: Number, default: 0 },
        launchCount: { type: Number, default: 0 },
      },
    ],
    lastSyncedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// Idempotent compound unique index to guarantee one document per child per calendar day
dailyActivitySchema.index({ childId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('DailyActivity', dailyActivitySchema);

