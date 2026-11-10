const mongoose = require('mongoose');

const restrictionSchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Child',
      required: true,
      unique: true,
      index: true,
    },
    dailyScreenTimeMinutes: {
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
    blockedPackageNames: {
      type: [String],
      default: [],
    },
    isDailyLimitEnabled: {
      type: Boolean,
      default: true,
    },
    isBedtimeEnabled: {
      type: Boolean,
      default: true,
    },
    isStudyTimeEnabled: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Restriction', restrictionSchema);

