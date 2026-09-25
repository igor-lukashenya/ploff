import { Routes, Route } from 'react-router-dom';
import { Layout } from '../shared/components/Layout';
import { HomePage } from '../features/home';
import { HealthPage } from '../features/health';
import { NotFoundPage } from '../shared/components/NotFoundPage';

export function AppRoutes() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/health" element={<HealthPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}
