export interface ApiInfo {
  name: string;
  version: string;
  status: string;
}

export interface HealthStatus {
  status: 'healthy' | 'unhealthy' | 'degraded' | 'unknown';
}

export interface ApiHealthReport {
  api: ApiInfo | null;
  health: HealthStatus;
  readiness: HealthStatus;
  responseTime: number | null;
  checkedAt: string;
}
