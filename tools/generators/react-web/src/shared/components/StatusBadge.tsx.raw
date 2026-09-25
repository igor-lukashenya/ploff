import './StatusBadge.css';

interface StatusBadgeProps {
  status: 'healthy' | 'unhealthy' | 'degraded' | 'unknown';
  label?: string;
}

export function StatusBadge({ status, label }: StatusBadgeProps) {
  return (
    <span className={`status-badge status-badge--${status}`}>
      <span className="status-dot" />
      {label || status}
    </span>
  );
}
