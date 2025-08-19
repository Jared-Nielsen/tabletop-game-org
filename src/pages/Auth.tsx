import { useEffect } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Auth } from '@supabase/auth-ui-react';
import { ThemeSupa } from '@supabase/auth-ui-shared';
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/auth";
import { toast } from "sonner";

const AuthPage = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { user } = useAuth();
  
  // Get the view from URL params (e.g., ?view=update_password)
  const view = searchParams.get('view') || 'sign_in';

  useEffect(() => {
    // Special handling for update_password view
    if (view === 'update_password') {
      // Don't check for user immediately - give Supabase time to establish session
      const checkSession = async () => {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
          // No session for password update - might be expired
          toast.error('Password reset link expired. Please request a new one.');
          navigate('/auth');
        }
      };
      // Check after a brief delay to allow session to establish
      const timer = setTimeout(checkSession, 500);
      return () => clearTimeout(timer);
    }
    
    // For other views, redirect if already logged in
    if (user && view === 'sign_in') {
      navigate("/");
    }
  }, [user, navigate, view]);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-md mx-auto bg-white p-8 rounded-lg shadow-xl">
        <Auth
          supabaseClient={supabase}
          view={view as any}
          appearance={{ 
            theme: ThemeSupa,
            variables: {
              default: {
                colors: {
                  brand: "#000000",
                  brandAccent: "#D4AF37",
                  inputBackground: "white",
                  inputBorder: "#e2e8f0",
                  inputBorderFocus: "#D4AF37",
                  inputBorderHover: "#D4AF37",
                },
                borderWidths: {
                  buttonBorderWidth: "1px",
                  inputBorderWidth: "1px",
                },
                radii: {
                  borderRadiusButton: "0.5rem",
                  buttonBorderRadius: "0.5rem",
                  inputBorderRadius: "0.5rem",
                },
              },
            },
            className: {
              button: "font-semibold",
              input: "font-medium",
              label: "font-medium",
            }
          }}
          providers={[]}
          redirectTo={`${window.location.origin}/auth/callback`}
          showLinks={true}
          localization={{
            variables: {
              sign_in: {
                email_label: 'Email',
                password_label: 'Password',
                button_label: 'Sign In',
                loading_button_label: "Signing in...",
                link_text: "Already have an account? Sign in"
              },
              sign_up: {
                email_label: "Email",
                password_label: "Password",
                button_label: "Create Account",
                loading_button_label: "Creating account...",
                link_text: "Don't have an account? Sign up"
              },
              forgotten_password: {
                email_label: "Email",
                button_label: "Send Reset Instructions",
                loading_button_label: "Sending instructions...",
                link_text: "Forgot your password?"
              }
            }
          }}
        />
      </div>
    </div>
  );
};

export default AuthPage;