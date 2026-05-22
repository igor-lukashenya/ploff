import { Outlet, NavLink } from 'react-router-dom';
import './Layout.css';

export function Layout() {
  return (
    <div className="layout">
      <header className="layout-header">
        <div className="layout-header-content">
          <NavLink to="/" className="layout-logo">
            Ploff
          </NavLink>
          <nav className="layout-nav">
            <NavLink to="/" className="nav-link" end>
              Home
            </NavLink>
            <NavLink to="/health" className="nav-link">
              Health
            </NavLink>
          </nav>
        </div>
      </header>
      <main className="layout-main">
        <Outlet />
      </main>
      <footer className="layout-footer">
        <p>Ploff - Sample Web Application</p>
      </footer>
    </div>
  );
}
