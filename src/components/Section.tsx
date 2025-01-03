import { ReactNode } from "react";

interface SectionProps {
  id: string;
  title: string;
  subtitle: string;
  children: ReactNode;
  className?: string;
}

const Section = ({ id, title, subtitle, children, className = "" }: SectionProps) => {
  return (
    <section
      id={id}
      className={`min-h-screen py-20 ${className}`}
    >
      <div className="container mx-auto px-6">
        <div className="space-y-4 text-center mb-16">
          <div className="inline-block px-3 py-1 bg-black/5 rounded-full text-sm font-medium mb-4">
            {subtitle}
          </div>
          <h2 className="text-4xl md:text-5xl font-bold tracking-tight">{title}</h2>
        </div>
        {children}
      </div>
    </section>
  );
};

export default Section;