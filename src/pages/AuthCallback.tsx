import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';

const AuthCallback = () => {
  const navigate = useNavigate();

  useEffect(() => {
    // Handle the auth callback - let Supabase process it first
    supabase.auth.onAuthStateChange((event, session) => {
      // Get URL parameters to determine the flow type
      const hashParams = new URLSearchParams(window.location.hash.substring(1));
      const searchParams = new URLSearchParams(window.location.search);
      const type = searchParams.get('type') || hashParams.get('type');
      
      if (event === 'SIGNED_IN') {
        // Check if this is a recovery flow
        if (type === 'recovery') {
          toast.info('Please enter your new password');
          navigate('/auth?view=update_password');
        } else if (type === 'signup') {
          toast.success('Email confirmed! Welcome!');
          navigate('/');
        } else {
          toast.success('Successfully signed in!');
          navigate('/');
        }
      } else if (event === 'PASSWORD_RECOVERY') {
        toast.info('Please enter your new password');
        navigate('/auth?view=update_password');
      } else if (event === 'USER_UPDATED') {
        toast.success('Password updated successfully!');
        navigate('/');
      }
    });
  }, [navigate]);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="animate-pulse">Processing authentication...</div>
    </div>
  );
};

export default AuthCallback;