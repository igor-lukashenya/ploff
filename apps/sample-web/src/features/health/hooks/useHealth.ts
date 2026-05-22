import { useQuery } from '@tanstack/react-query';
import { healthService } from '../services/health.service';

export function useApiInfo() {
  return useQuery({
    queryKey: ['api-info'],
    queryFn: () => healthService.getApiInfo(),
    retry: false,
  });
}

export function useHealthCheck() {
  return useQuery({
    queryKey: ['health'],
    queryFn: () => healthService.getHealth(),
    refetchInterval: 30000, // Check every 30 seconds
    retry: false,
  });
}

export function useReadinessCheck() {
  return useQuery({
    queryKey: ['readiness'],
    queryFn: () => healthService.getReadiness(),
    refetchInterval: 30000,
    retry: false,
  });
}
