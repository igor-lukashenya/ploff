import { apiClient } from '@/services/api';
import type { ApiInfo, HealthStatus } from '../types/health.types';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export const healthService = {
  getApiInfo: async (): Promise<ApiInfo> => {
    const response = await apiClient.get('/');
    return response as unknown as ApiInfo;
  },

  getHealth: async (): Promise<HealthStatus> => {
    try {
      const response = await fetch(`${API_URL}/health`);
      if (response.ok) {
        return { status: 'healthy' };
      }
      return { status: 'unhealthy' };
    } catch {
      return { status: 'unknown' };
    }
  },

  getReadiness: async (): Promise<HealthStatus> => {
    try {
      const response = await fetch(`${API_URL}/health/ready`);
      if (response.ok) {
        return { status: 'healthy' };
      }
      return { status: 'unhealthy' };
    } catch {
      return { status: 'unknown' };
    }
  },
};
