import './HomePage.css';

export function HomePage() {
  return (
    <div className="home-page">
      <section className="hero">
        <h1>Welcome to Ploff</h1>
        <p className="hero-subtitle">
          A monorepo boilerplate with React + Vite frontend and .NET API backend.
        </p>
      </section>

      <section className="features-grid">
        <div className="feature-card">
          <h3>React + TypeScript</h3>
          <p>Modern frontend with Vite, React Router, and TanStack Query.</p>
        </div>
        <div className="feature-card">
          <h3>.NET 10 API</h3>
          <p>Minimal API backend with health checks and integration tests.</p>
        </div>
        <div className="feature-card">
          <h3>Monorepo</h3>
          <p>Independent releases per app with automated versioning.</p>
        </div>
        <div className="feature-card">
          <h3>CI/CD Ready</h3>
          <p>GitHub Actions with change detection and per-app deployments.</p>
        </div>
      </section>
    </div>
  );
}
