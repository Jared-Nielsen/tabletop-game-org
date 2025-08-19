-- CHECK AUTH SETTINGS
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/kwpptrhywkyuzadwxgdl/editor

-- Check auth config
SELECT 
    key,
    value
FROM auth.config
WHERE key IN ('password_recovery_template', 'external_email_enabled', 'mailer_autoconfirm');

-- IMPORTANT: Also check these settings in your Supabase Dashboard:
-- 1. Go to Authentication > URL Configuration
-- 2. Make sure "Site URL" is set to: http://localhost:8090
-- 3. Add to "Redirect URLs": 
--    - http://localhost:8090/auth/callback
--    - http://localhost:8090/auth
--    - http://localhost:8090/auth?view=update_password
--    - http://localhost:8091/auth/callback (if using port 8091)

-- 4. Go to Authentication > Email Templates
-- 5. Check the "Reset Password" template
-- 6. Make sure the link in the template uses: {{ .ConfirmationURL }}

SELECT 'Please check the dashboard settings mentioned above!' as important_note;