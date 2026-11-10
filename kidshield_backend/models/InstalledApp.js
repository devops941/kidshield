const mongoose = require('mongoose');

const installedAppSchema = new mongoose.Schema(
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
    versionName: {
      type: String,
      default: '1.0',
    },
    icon: {
      type: String,
      default: '',
    },
    installedAt: {
      type: Date,
      default: Date.now,
    },
    isBlocked: {
      type: Boolean,
      default: false,
    },
    ageRating: {
      type: String,
      default: 'Everyone',
    },
    isNewlyInstalled: {
      type: Boolean,
      default: false,
    },
    isParentApproved: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

installedAppSchema.index({ childId: 1, packageName: 1 }, { unique: true });

module.exports = mongoose.model('InstalledApp', installedAppSchema);

