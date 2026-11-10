const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendPasswordResetOtpEmail, sendPasswordResetConfirmationEmail } = require('../utils/emailService');

// Helper to generate JWT token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'kidshield_default_jwt_secret', {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

// @desc    Register a new parent
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res, next) => {
  try {
    const { fullName, email, password, phoneNumber, fcmToken } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ success: false, message: 'An account with this email already exists' });
    }

    const user = await User.create({
      fullName,
      email,
      password,
      phoneNumber,
      fcmToken,
    });

    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Login parent
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { email, password, fcmToken } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide email and password' });
    }

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    // Update FCM token if provided
    if (fcmToken && user.fcmToken !== fcmToken) {
      user.fcmToken = fcmToken;
      await user.save();
    }

    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current logged in parent profile
// @route   GET /api/auth/me
// @access  Private
exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    res.status(200).json({
      success: true,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update FCM Token for Push Notifications
// @route   PUT /api/auth/fcm-token
// @access  Private
exports.updateFCMToken = async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    await User.findByIdAndUpdate(req.user.id, { fcmToken });
    res.status(200).json({ success: true, message: 'FCM Token updated successfully' });
  } catch (error) {
    next(error);
  }
};

// @desc    Request Password Reset (Sends 6-digit OTP to parent email via Gmail SMTP)
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Please provide your registered email address' });
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'No parent account found with this email address.',
      });
    }

    // Generate 6-digit numeric OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expire = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes validity

    user.resetPasswordOtp = otp;
    user.resetPasswordExpire = expire;
    await user.save({ validateBeforeSave: false });

    // Send email via Gmail SMTP
    try {
      await sendPasswordResetOtpEmail(user.email, otp, user.fullName);
    } catch (mailError) {
      user.resetPasswordOtp = undefined;
      user.resetPasswordExpire = undefined;
      await user.save({ validateBeforeSave: false });
      return res.status(500).json({
        success: false,
        message: `Failed to deliver email: ${mailError.message}`,
      });
    }

    res.status(200).json({
      success: true,
      message: `A 6-digit verification code has been sent to ${user.email}. Please check your inbox.`,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Verify OTP for Password Reset
// @route   POST /api/auth/verify-reset-otp
// @access  Public
exports.verifyResetOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ success: false, message: 'Please provide both email and 6-digit OTP' });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    }).select('+resetPasswordOtp +resetPasswordExpire');

    if (!user || !user.resetPasswordOtp) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP. Please request a new one.' });
    }

    if (user.resetPasswordOtp !== otp.trim()) {
      return res.status(400).json({ success: false, message: 'Incorrect OTP. Please enter the valid 6-digit code.' });
    }

    if (new Date() > user.resetPasswordExpire) {
      return res.status(400).json({ success: false, message: 'This OTP has expired. Please request a fresh code.' });
    }

    res.status(200).json({
      success: true,
      message: 'OTP verified successfully! Please enter your new password.',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reset Password with OTP
// @route   POST /api/auth/reset-password
// @access  Public
exports.resetPassword = async (req, res, next) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email, verification code, and your new password.',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters long.',
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    }).select('+password +resetPasswordOtp +resetPasswordExpire');

    if (!user || !user.resetPasswordOtp) {
      return res.status(400).json({
        success: false,
        message: 'Invalid request or reset code has expired. Please request a new code.',
      });
    }

    if (user.resetPasswordOtp !== otp.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Incorrect verification code. Please check your email.',
      });
    }

    if (new Date() > user.resetPasswordExpire) {
      return res.status(400).json({
        success: false,
        message: 'This verification code has expired. Please request a new one.',
      });
    }

    // Set new password (pre('save') hook in User model handles bcrypt hashing automatically)
    user.password = newPassword;
    user.resetPasswordOtp = undefined;
    user.resetPasswordExpire = undefined;
    await user.save();

    // Send confirmation email
    sendPasswordResetConfirmationEmail(user.email, user.fullName);

    // Issue fresh JWT token for instant seamless login
    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      message: 'Password reset successful! You can now log in with your new password.',
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

