import { render, screen } from '@testing-library/react';
import App from './App';

test('renders Admin Login header', () => {
  render(<App />);
  const headerElement = screen.getByText(/Ali Bin Ali Takip Merkezi/i);
  expect(headerElement).toBeInTheDocument();
});
