const nodemailer = require('nodemailer');

// Create reusable transporter object using SMTP transport
const createTransporter = () => {
  const host = process.env.SMTP_HOST || 'smtp.gmail.com';
  const port = parseInt(process.env.SMTP_PORT || '587', 10);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465, // true for 465, false for other ports (587)
    auth: {
      user,
      pass,
    },
  });
};

/**
 * Send 6-Digit Password Reset OTP Email
 */
const sendPasswordResetOtpEmail = async (toEmail, otp, recipientName = 'Parent') => {
  const fromName = process.env.FROM_NAME || 'KidShield Security';
  const fromEmail = process.env.SMTP_FROM || process.env.SMTP_USER || 'no-reply@kidshield.app';

  const transporter = createTransporter();

  const mailOptions = {
    from: `"${fromName}" <${fromEmail}>`,
    to: toEmail,
    subject: `🛡️ KidShield Password Reset OTP: ${otp}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f1f5f9; margin: 0; padding: 20px; }
          .container { max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); border: 1px solid #e2e8f0; }
          .header { background: linear-gradient(135deg, #1E40AF 0%, #3B82F6 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
          .header h1 { margin: 0; font-size: 24px; font-weight: 800; letter-spacing: 1px; }
          .header p { margin: 6px 0 0; font-size: 13px; opacity: 0.9; }
          .content { padding: 32px 24px; color: #1e293b; }
          .greeting { font-size: 16px; font-weight: 700; margin-bottom: 12px; }
          .desc { font-size: 14px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
          .otp-card { background: #f8fafc; border: 2px dashed #3b82f6; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 24px; }
          .otp-code { font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #1e40af; font-family: monospace; }
          .expiry { font-size: 12px; color: #dc2626; font-weight: 600; margin-top: 8px; }
          .security-note { background: #fef2f2; border-left: 4px solid #ef4444; padding: 12px 16px; border-radius: 6px; font-size: 12px; color: #991b1b; line-height: 1.5; margin-bottom: 24px; }
          .footer { background: #f8fafc; padding: 20px 24px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🛡️ KIDSHIELD</h1>
            <p>Smart Child Safety & Parental Monitoring Console</p>
          </div>
          <div class="content">
            <div class="greeting">Hello ${recipientName},</div>
            <div class="desc">
              We received a request to reset your <strong>KidShield Parent</strong> account password. Use the verification code below to authorize your new password:
            </div>
            <div class="otp-card">
              <div class="otp-code">${otp}</div>
              <div class="expiry">⏱️ This code expires in 15 minutes.</div>
            </div>
            <div class="security-note">
              <strong>Security Warning:</strong> Never share this verification code with anyone. KidShield representatives will never ask for your reset OTP. If you did not make this request, your account is secure and you can safely ignore this email.
            </div>
          </div>
          <div class="footer">
            &copy; 2026 KidShield Safety Platform. All rights reserved.<br>
            Sent via KidShield Secure Notification Gateway.
          </div>
        </div>
      </body>
      </html>
    `,
  };

  const info = await transporter.sendMail(mailOptions);
  console.log(`[Email] Password reset OTP sent to ${toEmail} (MessageId: ${info.messageId})`);
  return info;
};

/**
 * Send Password Reset Confirmation Email
 */
const sendPasswordResetConfirmationEmail = async (toEmail, recipientName = 'Parent') => {
  const fromName = process.env.FROM_NAME || 'KidShield Security';
  const fromEmail = process.env.SMTP_FROM || process.env.SMTP_USER || 'no-reply@kidshield.app';

  const transporter = createTransporter();

  const mailOptions = {
    from: `"${fromName}" <${fromEmail}>`,
    to: toEmail,
    subject: `✅ KidShield Password Changed Successfully`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f1f5f9; margin: 0; padding: 20px; }
          .container { max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); border: 1px solid #e2e8f0; }
          .header { background: linear-gradient(135deg, #059669 0%, #10B981 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
          .header h1 { margin: 0; font-size: 24px; font-weight: 800; letter-spacing: 1px; }
          .content { padding: 32px 24px; color: #1e293b; }
          .greeting { font-size: 16px; font-weight: 700; margin-bottom: 12px; }
          .desc { font-size: 14px; line-height: 1.6; color: #475569; margin-bottom: 20px; }
          .footer { background: #f8fafc; padding: 20px 24px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🛡️ KIDSHIELD</h1>
            <p>Password Update Confirmation</p>
          </div>
          <div class="content">
            <div class="greeting">Hello ${recipientName},</div>
            <div class="desc">
              Your <strong>KidShield Parent</strong> account password has been successfully updated on <strong>${new Date().toLocaleString()}</strong>.
            </div>
            <div class="desc">
              You can now log in to the KidShield Parent application with your new password.
            </div>
            <div class="desc" style="color: #dc2626; font-size: 12px;">
              If you did not perform this change, please contact safety support immediately to secure your monitored children profiles.
            </div>
          </div>
          <div class="footer">
            &copy; 2026 KidShield Safety Platform. All rights reserved.
          </div>
        </div>
      </body>
      </html>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
  } catch (err) {
    console.warn(`[Email Warning] Could not send confirmation email: ${err.message}`);
  }
};

module.exports = {
  sendPasswordResetOtpEmail,
  sendPasswordResetConfirmationEmail,
};

