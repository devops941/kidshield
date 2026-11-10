const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Child',
      required: true,
      index: true,
    },
    latitude: {
      type: Number,
      required: true,
    },
    longitude: {
      type: Number,
      required: true,
    },
    address: {
      type: String,
      default: 'Unknown location',
    },
    accuracy: {
      type: Number,
      default: 5.0,
    },
    speed: {
      type: Number,
      default: 0.0,
    },
    batteryAtLocation: {
      type: Number,
      default: 100,
    },
    isOffline: {
      type: Boolean,
      default: false,
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

// Compound index for querying a child's recent locations
locationSchema.index({ childId: 1, timestamp: -1 });

module.exports = mongoose.model('Location', locationSchema);

