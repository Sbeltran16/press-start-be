# Email Domain Validation

This application validates that email addresses use real email domains (like gmail.com, yahoo.com, etc.) and not made-up domains.

## How It Works

1. **Known Valid Domains**: The validator maintains a list of common email providers (Gmail, Yahoo, Outlook, etc.) for fast validation without DNS lookups.

2. **DNS MX Record Check**: For domains not in the known list, the validator performs a DNS lookup to check if the domain has MX (Mail Exchange) records, which indicates the domain accepts email.

3. **Timeout Protection**: DNS lookups have a 3-second timeout to prevent hanging on slow or unresponsive DNS servers.

4. **Lenient on Errors**: If DNS lookup fails or times out, the validator allows the email (to avoid blocking legitimate users due to temporary DNS issues).

## Supported Email Providers

The validator recognizes these common providers instantly (no DNS lookup needed):
- Gmail (gmail.com)
- Yahoo (yahoo.com)
- Outlook/Hotmail (outlook.com, hotmail.com, live.com, msn.com)
- Apple iCloud (icloud.com, me.com, mac.com)
- AOL (aol.com)
- ProtonMail (protonmail.com)
- Zoho (zoho.com)
- GMX (gmx.com)
- Yandex (yandex.com)
- Mail.com (mail.com)
- And more...

## Custom Domains

Custom email domains (like `user@company.com`) are also validated by checking their MX records. If the domain has valid MX records, the email is accepted.

## Error Messages

If a user tries to sign up with an invalid email domain (one without MX records), they'll see:
> "Email does not appear to be a valid email domain. Please use a real email address from providers like Gmail, Yahoo, Outlook, etc."

## Configuration

The validation is enabled by default. To disable it (not recommended), you can remove the validation from `app/models/user.rb`:

```ruby
# Remove this line:
validates :email, email_domain: true, if: -> { email.present? }
```

## Performance

- **Known domains**: Validated instantly (no network call)
- **Unknown domains**: DNS lookup with 3-second timeout
- **Failed lookups**: Allowed (to avoid blocking legitimate users)

## Testing

To test the validator:

```ruby
# In Rails console
user = User.new(email: "test@fake-domain-that-does-not-exist-12345.com", username: "test", password: "password123")
user.valid?
user.errors[:email] # Should show domain validation error

user = User.new(email: "test@gmail.com", username: "test", password: "password123")
user.valid?
user.errors[:email] # Should be empty (valid domain)
```

