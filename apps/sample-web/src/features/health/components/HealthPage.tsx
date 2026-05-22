import { useApiInfo, useHealthCheck, useReadinessCheck } from '../hooks/useHealth';
import { StatusBadge } from '@/shared/components';
import { LoadingSpinner } from '@/shared/components';
import './HealthPage.css';

export function HealthPage() {
  const apiInfo = useApiInfo();
  const health = useHealthCheck();
  const readiness = useReadinessCheck();

  return (
    <div className="health-page">
      <h1>System Health</h1>
      <p className="health-subtitle">Real-time status of the Sample API backend.</p>

      <div className="health-grid">
        {/* API Info Card */}
        <div className="health-card">
          <h3>API Info</h3>
          {apiInfo.isLoading && <LoadingSpinner size="sm" />}
          {apiInfo.error && (
            <div className="health-error">
              <StatusBadge status="unhealthy" label="Unreachable" />
              <p>Cannot connect to API</p>
            </div>
          )}
          {apiInfo.data && (
            <dl className="health-info">
              <dt>Name</dt>
              <dd>{apiInfo.data.name}</dd>
              <dt>Version</dt>
              <dd><code>{apiInfo.data.version}</code></dd>
              <dt>Status</dt>
              <dd>{apiInfo.data.status}</dd>
            </dl>
          )}
        </div>

        {/* Health Check Card */}
        <div className="health-card">
          <h3>Health Check</h3>
          <div className="health-status-row">
            <span>Liveness</span>
            {health.isLoading ? (
              <LoadingSpinner size="sm" label="" />
            ) : (
              <StatusBadge status={health.data?.status || 'unknown'} />
            )}
          </div>
          <div className="health-status-row">
            <span>Readiness</span>
            {readiness.isLoading ? (
              <LoadingSpinner size="sm" label="" />
            ) : (
              <StatusBadge status={readiness.data?.status || 'unknown'} />
            )}
          </div>
          <p className="health-note">Auto-refreshes every 30 seconds</p>
        </div>

        {/* Connection Info Card */}
        <div className="health-card">
          <h3>Connection</h3>
          <dl className="health-info">
            <dt>API URL</dt>
            <dd><code>{import.meta.env.VITE_API_URL || 'http://localhost:8080'}</code></dd>
            <dt>Last Checked</dt>
            <dd>{new Date().toLocaleTimeString()}</dd>
          </dl>
          <button
            className="health-refresh-btn"
            onClick={() => {
              apiInfo.refetch();
              health.refetch();
              readiness.refetch();
            }}
          >
            Refresh Now
          </button>
        </div>
      </div>
    </div>
  );
}
