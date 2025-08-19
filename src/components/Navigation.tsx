import { useState } from "react";
import { LogIn } from "lucide-react";
import ProfileMenu from "./ProfileMenu";
import { useLocation, useNavigate, useSearchParams } from "react-router-dom";
import { useAuth } from "@/contexts/auth";
import { Button } from "@/components/ui/button";
import { useIsMobile } from "@/hooks/use-mobile";
import QualifyNav from "./navigation/QualifyNav";
import PlayNav from "./navigation/PlayNav";
import RecruitNav from "./navigation/RecruitNav";
import EarnNav from "./navigation/EarnNav";
import MobileNav from "./navigation/MobileNav";
import Logo from "./navigation/Logo";

const Navigation = () => {
  const { user } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [activeSection, setActiveSection] = useState<string | null>(null);
  const isMobile = useIsMobile();
  
  // Check if we're on the password reset view
  const isPasswordReset = location.pathname === '/auth' && searchParams.get('view') === 'update_password';

  const scrollToSection = (id: string) => {
    if (location.pathname !== '/') {
      navigate('/', { state: { scrollTo: id } });
      return;
    }
    const element = document.getElementById(id);
    if (element) {
      const navHeight = 64; // Height of the navigation bar
      const offset = navHeight + 16; // Add some additional padding
      const elementPosition = element.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.pageYOffset - offset;
      
      window.scrollTo({
        top: offsetPosition,
        behavior: "smooth"
      });
    }
    setActiveSection(id);
  };

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-black transition-all duration-300">
      <div className="container mx-auto px-6">
        <div className="relative flex items-center justify-between h-16">
          <Logo />

          {/* Hide navigation items during password reset */}
          {!isPasswordReset && (
            <>
              {/* Desktop Navigation */}
              <div className="hidden md:flex items-center space-x-8">
                <QualifyNav activeSection={activeSection} scrollToSection={scrollToSection} />
                <PlayNav activeSection={activeSection} scrollToSection={scrollToSection} />
                <RecruitNav activeSection={activeSection} scrollToSection={scrollToSection} />
                <EarnNav activeSection={activeSection} scrollToSection={scrollToSection} />
                <div className="ml-4">
                  {user ? (
                    <ProfileMenu />
                  ) : (
                    <Button
                      variant="ghost"
                      className="text-white hover:text-gold relative z-[60]"
                      onClick={() => navigate('/auth')}
                    >
                      <LogIn className="w-4 h-4 mr-2" />
                      Login
                    </Button>
                  )}
                </div>
              </div>

              {/* Mobile Navigation */}
              <div className="flex items-center md:hidden">
                <div className="mr-2">
                  {user ? (
                    <ProfileMenu />
                  ) : (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="text-white hover:text-gold relative z-[60]"
                      onClick={() => navigate('/auth')}
                    >
                      <LogIn className="h-4 w-4" />
                      <span className="sr-only">Login</span>
                    </Button>
                  )}
                </div>
                <MobileNav
                  activeSection={activeSection}
                  scrollToSection={scrollToSection}
                />
              </div>
            </>
          )}
          
          {/* Show minimal text during password reset */}
          {isPasswordReset && (
            <div className="text-white text-sm">
              Reset Your Password
            </div>
          )}
        </div>
      </div>
    </nav>
  );
};

export default Navigation;