const Terms = () => {
  return (
    <div className="container mx-auto px-4 pt-24 pb-8">
      <h1 className="text-3xl font-bold mb-6">Terms and Conditions</h1>
      <div className="prose max-w-none">
        <p className="mb-4">Last updated: {new Date().toLocaleDateString()}</p>
        
        <section className="mb-6">
          <h2 className="text-2xl font-semibold mb-4">1. Acceptance of Terms</h2>
          <p>By accessing and using this website, you accept and agree to be bound by the terms and provision of this agreement.</p>
        </section>

        <section className="mb-6">
          <h2 className="text-2xl font-semibold mb-4">2. Use License</h2>
          <p>Permission is granted to temporarily download one copy of the materials (information or software) on our website for personal, non-commercial transitory viewing only.</p>
        </section>

        <section className="mb-6">
          <h2 className="text-2xl font-semibold mb-4">3. Disclaimer</h2>
          <p>The materials on our website are provided on an 'as is' basis. We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.</p>
        </section>

        <section className="mb-6">
          <h2 className="text-2xl font-semibold mb-4">4. Limitations</h2>
          <p>In no event shall we or our suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on our website.</p>
        </section>
      </div>
    </div>
  );
};

export default Terms;