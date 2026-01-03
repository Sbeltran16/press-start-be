# Email Confirmation Setup Guide

## Required Environment Variables

For email confirmation to work on the deployed site, you need to set these environment variables in your production environment (Render):

### Required Variables:
- `SMTP_ADDRESS` - SMTP server address (e.g., `smtp.gmail.com`, `smtp.mailgun.org`)
- `SMTP_PORT` - SMTP port (usually `587` for TLS or `465` for SSL)
- `SMTP_USERNAME` - Your SMTP username/email
- `SMTP_PASSWORD` - Your SMTP password or app password
- `SMTP_DOMAIN` - Your domain (optional, defaults to extracted from SMTP_ADDRESS)
- `MAILER_FROM` - Email address to send from (e.g., `noreply@pressstart.gg`)
- `FRONTEND_URL` - Your frontend URL (e.g., `https://pressstart.gg`)

## Gmail Setup Example

If using Gmail:

1. **Enable 2-Factor Authentication** on your Google account
2. **Generate an App Password**:
   - Go to Google Account → Security → 2-Step Verification → App passwords
   - Generate a new app password for "Mail"
   - Copy the 16-character password

3. **Set Environment Variables**:
   ```
   SMTP_ADDRESS=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=your-email@gmail.com
   SMTP_PASSWORD=your-16-char-app-password
   SMTP_DOMAIN=gmail.com
   MAILER_FROM=noreply@pressstart.gg
   FRONTEND_URL=https://pressstart.gg
   ```

## Mailgun Setup Example

If using Mailgun:

1. **Sign up for Mailgun** and verify your domain
2. **Get SMTP credentials** from Mailgun dashboard
3. **Set Environment Variables**:
   ```
   SMTP_ADDRESS=smtp.mailgun.org
   SMTP_PORT=587
   SMTP_USERNAME=postmaster@your-domain.mailgun.org
   SMTP_PASSWORD=your-mailgun-smtp-password
   SMTP_DOMAIN=your-domain.com
   MAILER_FROM=noreply@pressstart.gg
   FRONTEND_URL=https://pressstart.gg
   ```

## Testing Email Configuration

After setting up environment variables:

1. **Restart your Rails server** (environment variables require restart)
2. **Try creating a new account** - check logs for email sending status
3. **Check logs** for any SMTP errors:
   ```
   rails logs | grep -i smtp
   rails logs | grep -i email
   ```

## Troubleshooting

### Emails not sending?
- Check that all required environment variables are set
- Verify SMTP credentials are correct
- Check server logs for SMTP errors
- Ensure SMTP port is not blocked by firewall
- For Gmail: Make sure you're using an App Password, not your regular password

### Users being auto-confirmed?
- This happens when SMTP is not configured
- Check logs for "SMTP not fully configured" warnings
- Ensure all SMTP environment variables are set correctly

### Email delivery errors?
- Check SMTP server logs
- Verify FROM address is authorized
- Check spam folder
- Verify FRONTEND_URL is correct for confirmation links

## Current Behavior

- **SMTP Configured**: Emails are sent, users must confirm email to log in
- **SMTP Not Configured**: Users are auto-confirmed (can log in immediately)
- **Email Sending Fails**: User is created but not confirmed (can use resend feature)

