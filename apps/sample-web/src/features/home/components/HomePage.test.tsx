import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { describe, it, expect } from 'vitest';
import { HomePage } from '@/features/home';

function renderWithProviders(ui: React.ReactElement) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>{ui}</MemoryRouter>
    </QueryClientProvider>,
  );
}

describe('HomePage', () => {
  it('renders the welcome heading', () => {
    renderWithProviders(<HomePage />);
    expect(screen.getByText('Welcome to Ploff')).toBeInTheDocument();
  });

  it('renders feature cards', () => {
    renderWithProviders(<HomePage />);
    expect(screen.getByText('React + TypeScript')).toBeInTheDocument();
    expect(screen.getByText('.NET 10 API')).toBeInTheDocument();
    expect(screen.getByText('Monorepo')).toBeInTheDocument();
    expect(screen.getByText('CI/CD Ready')).toBeInTheDocument();
  });
});
