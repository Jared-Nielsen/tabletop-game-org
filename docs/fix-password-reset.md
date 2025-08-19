# Fix Password Reset Flow

## Steps to Configure Password Reset in Supabase Dashboard

### 1. Configure Redirect URLs
Go to: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/auth/url-configuration

**Site URL:** 
```
http://localhost:8090
```

**Redirect URLs (add all of these):**
```
http://localhost:8090/auth/callback
http://localhost:8090/auth
http://localhost:8090/*
http://localhost:8091/auth/callback
http://localhost:8091/*
```

### 2. Check Email Templates
Go to: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/auth/templates

Check the **Reset Password** template:
- Make sure it's enabled
- The template should contain `{{ .ConfirmationURL }}`
- This generates the recovery link

### 3. Email Settings
Go to: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/settings/auth

Under **Email Settings**:
- Ensure "Enable email confirmations" is configured as needed
- Check the "Password recovery email" is enabled

### 4. Test the Flow

1. Go to http://localhost:8090
2. Click "Forgot your password?"
3. Enter your email
4. Check email (including spam)
5. Click the reset link
6. You should be redirected to the password update form

### Common Issues

**"Invalid or expired link" error:**
- The link was already used (they're single-use)
- The link expired (default 1 hour)
- Redirect URLs not properly configured
- Solution: Request a new reset link after fixing settings

**Not seeing update password form:**
- Check browser console for errors
- Ensure you're logged out before clicking reset link
- Clear browser cache/cookies for localhost

**Email not arriving:**
- Check spam folder
- Verify email settings in Supabase
- Consider configuring custom SMTP for better deliverability