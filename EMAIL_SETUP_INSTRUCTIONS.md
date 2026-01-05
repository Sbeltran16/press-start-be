# Email Setup Instructions - Stop Using Personal Gmail

## The Problem
When using Gmail's SMTP server, Gmail **forces** the "From" address to match your authenticated email (`sbeltran16@gmail.com`). This is a Gmail security feature and cannot be changed.

## The Solution
Use **Mailgun** or **SendGrid** instead. These services allow you to send from any email address (like `noreply@pressstart.gg`).

---

## Option 1: Mailgun (Recommended)

### Why Mailgun?
- ✅ Free tier: 5,000 emails/month for 3 months, then 1,000/month
- ✅ Allows custom "From" addresses (e.g., `noreply@pressstart.gg`)
- ✅ Better deliverability
- ✅ Easy setup

### Setup Steps:

1. **Sign up for Mailgun:**
   - Go to https://www.mailgun.com/
   - Create a free account
   - Verify your email

2. **Add and Verify Your Domain:**
   - Go to Mailgun Dashboard → Sending → Domains
   - Click "Add New Domain"
   - Enter `pressstart.gg`
   - Mailgun will give you DNS records to add to your domain
   - Add these DNS records to your domain's DNS settings
   - Wait for verification (usually a few minutes)

3. **Get SMTP Credentials:**
   - In Mailgun Dashboard → Sending → Domains
   - Click on your verified domain (`pressstart.gg`)
   - Scroll to "SMTP credentials" section
   - You'll see:
     - **SMTP hostname**: `smtp.mailgun.org`
     - **Port**: `587`
     - **Default SMTP Login**: Usually `postmaster@pressstart.gg.mailgun.org`
     - **Default Password**: (shown in dashboard)

4. **Set Environment Variables in Render:**
   - Go to Render Dashboard → Your Backend Service → Environment
   - **Remove or keep** your old Gmail variables (they won't be used)
   - **Add these new variables:**
     ```
     MAILGUN_SMTP_SERVER=smtp.mailgun.org
     MAILGUN_SMTP_PORT=587
     MAILGUN_SMTP_LOGIN=postmaster@pressstart.gg.mailgun.org
     MAILGUN_SMTP_PASSWORD=your-mailgun-password-here
     MAILGUN_DOMAIN=pressstart.gg
     MAILER_FROM=noreply@pressstart.gg
     FRONTEND_URL=https://pressstart.gg
     ```

5. **Redeploy** your service

6. **Test:** Create a test account and check that emails come from `noreply@pressstart.gg` ✅

---

## Option 2: SendGrid

### Why SendGrid?
- ✅ Free tier: 100 emails/day forever
- ✅ Allows custom "From" addresses
- ✅ Easy setup

### Setup Steps:

1. **Sign up for SendGrid:**
   - Go to https://sendgrid.com/
   - Create a free account
   - Verify your email

2. **Create API Key:**
   - Go to SendGrid Dashboard → Settings → API Keys
   - Click "Create API Key"
   - Name it (e.g., "Press Start API")
   - Select "Full Access" or "Mail Send" permissions
   - **Copy the API key** (you'll only see it once!)

3. **Verify Sender (for Custom From Address):**
   - Go to Settings → Sender Authentication
   - Click "Verify a Single Sender" (for quick setup)
   - Enter: `noreply@pressstart.gg`
   - Fill in the form and verify
   - OR verify your entire domain for better deliverability

4. **Set Environment Variables in Render:**
   - Go to Render Dashboard → Your Backend Service → Environment
   - **Add these variables:**
     ```
     SENDGRID_USERNAME=apikey
     SENDGRID_API_KEY=your-sendgrid-api-key-here
     SENDGRID_DOMAIN=pressstart.gg
     MAILER_FROM=noreply@pressstart.gg
     FRONTEND_URL=https://pressstart.gg
     ```

5. **Redeploy** your service

6. **Test:** Create a test account and check that emails come from `noreply@pressstart.gg` ✅

---

## Which One to Choose?

**Mailgun** if you:
- Want more free emails (5,000/month initially)
- Want better analytics
- Don't mind verifying your domain

**SendGrid** if you:
- Want the simplest setup
- Are okay with 100 emails/day limit
- Want to verify just a single sender quickly

---

## After Setup

Once configured, all confirmation emails will be sent **FROM** `noreply@pressstart.gg` instead of your personal Gmail address.

Your personal Gmail (`sbeltran16@gmail.com`) will **NOT** appear in the "From" field anymore! ✅

