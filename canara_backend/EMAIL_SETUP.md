# Email Setup Guide for Account Lockout Notifications

This guide explains how to configure email notifications for the account lockout system.

## Overview

When a user's account is locked due to multiple failed authentication attempts, the system can send an email notification to the user. This helps with:

- **Security Awareness**: Users are immediately notified of potential security breaches
- **Account Recovery**: Users know their account is locked and need to contact support
- **Compliance**: Many financial applications require user notification of security events

## Gmail Setup (Recommended)

### 1. Enable 2-Factor Authentication
1. Go to your Google Account settings
2. Navigate to Security
3. Enable 2-Step Verification

### 2. Generate App Password
1. Go to Google Account settings
2. Navigate to Security → 2-Step Verification
3. Click on "App passwords"
4. Generate a new app password for "Mail"
5. Copy the 16-character password

### 3. Configure Environment Variables
Add these to your `.env` file:

```env
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_16_character_app_password
```

## Other Email Providers

### Outlook/Hotmail
```env
SMTP_SERVER=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USERNAME=your_email@outlook.com
SMTP_PASSWORD=your_password_or_app_password
```

### Yahoo Mail
```env
SMTP_SERVER=smtp.mail.yahoo.com
SMTP_PORT=587
SMTP_USERNAME=your_email@yahoo.com
SMTP_PASSWORD=your_app_password
```

## Testing Email Configuration

### 1. Manual Test
You can test the email functionality by:

1. Starting the backend server
2. Creating a test user
3. Intentionally failing login attempts 3 times
4. Check if the email is sent

### 2. Using the Test Script
Run the lockout test script:
```bash
python test_lockout.py
```

This will create a test user and trigger the lockout mechanism.

## Email Template

The system sends emails with this template:

```
Dear [username],

Your account has been locked due to multiple failed authentication attempts.

Lockout Reason: [pin_failed/rhythm_failed]
Time: [timestamp]

For security reasons, your account is now locked. Please contact our support team to unlock your account.

If you did not attempt to access your account, please contact us immediately as this may indicate unauthorized access attempts.

Best regards,
Canara Bank Security Team
```

## Troubleshooting

### Common Issues

1. **"Authentication failed"**
   - Check that you're using an app password, not your regular password
   - Ensure 2FA is enabled on your Google account

2. **"Connection refused"**
   - Check your internet connection
   - Verify SMTP server and port settings

3. **"Email not received"**
   - Check spam/junk folder
   - Verify email address is correct
   - Check email provider's sending limits

### Debug Mode

To enable email debugging, add this to your `.env`:
```env
EMAIL_DEBUG=true
```

This will print detailed SMTP communication logs.

## Security Considerations

1. **App Passwords**: Always use app passwords, never regular passwords
2. **Environment Variables**: Keep email credentials in environment variables, not in code
3. **Rate Limiting**: Email providers have sending limits
4. **Privacy**: Ensure compliance with data protection regulations

## Production Deployment

For production use:

1. Use a dedicated email service (SendGrid, Mailgun, etc.)
2. Set up proper SPF/DKIM records
3. Monitor email delivery rates
4. Implement email templates with your branding
5. Add email queue for high-volume scenarios

## Disabling Email Notifications

If you don't want email notifications:

1. Don't set the SMTP environment variables
2. The system will still lock accounts but won't send emails
3. Users will need to contact support to unlock accounts

## Support

If you encounter issues:

1. Check the backend logs for error messages
2. Verify your email configuration
3. Test with a simple SMTP client
4. Contact the development team for assistance 