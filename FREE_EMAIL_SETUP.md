# Free Email Setup - Hide Personal Email Address

## The Problem
Gmail forces the "From" address to match your authenticated email, but we can hide your personal name and make it look professional.

## Solution: Use Display Name + Dedicated Gmail Account

### Option 1: Create a Dedicated Gmail Account (Recommended)

**Best approach - completely hides your personal email:**

1. **Create a new Gmail account:**
   - Go to https://accounts.google.com/signup
   - Create: `pressstart.noreply@gmail.com` or `noreply.pressstart@gmail.com`
   - Use a strong password

2. **Get App Password:**
   - Go to https://myaccount.google.com/apppasswords
   - Generate an App Password for "Mail"
   - Copy the 16-character password

3. **Update Render Environment Variables:**
   ```
   SMTP_ADDRESS=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=pressstart.noreply@gmail.com
   SMTP_PASSWORD=your-16-char-app-password
   SMTP_DOMAIN=gmail.com
   MAILER_DISPLAY_NAME=Press Start
   MAILER_REPLY_TO=noreply@pressstart.gg
   FRONTEND_URL=https://pressstart.gg
   ```

4. **Result:** Emails will show as:
   - **From:** "Press Start <pressstart.noreply@gmail.com>"
   - Your personal email (`sbeltran16@gmail.com`) will NOT appear ✅

---

### Option 2: Use Display Name with Current Gmail (Quick Fix)

**Hides your name but email address still visible:**

1. **Update Render Environment Variables:**
   ```
   MAILER_DISPLAY_NAME=Press Start
   MAILER_REPLY_TO=noreply@pressstart.gg
   ```
   (Keep your existing SMTP variables)

2. **Result:** Emails will show as:
   - **From:** "Press Start <sbeltran16@gmail.com>"
   - Shows "Press Start" instead of your name, but email is still visible

---

## What Users Will See:

### With Option 1 (Dedicated Account):
```
From: Press Start <pressstart.noreply@gmail.com>
```
✅ Professional, no personal email visible

### With Option 2 (Display Name Only):
```
From: Press Start <sbeltran16@gmail.com>
```
⚠️ Shows "Press Start" but your email is still visible

---

## Recommendation

**Use Option 1** - Create a dedicated Gmail account. It's:
- ✅ Free
- ✅ Completely hides your personal email
- ✅ Looks professional
- ✅ Takes 5 minutes to set up

The dedicated account (`pressstart.noreply@gmail.com`) will be used only for sending app emails, keeping your personal account separate.

