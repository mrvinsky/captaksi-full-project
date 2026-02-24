import { render, screen } from '@testing-library/react';
import App from './App';

test('renders Admin Login header', () => {
  render(<App />);
  const headerElement = screen.getByText(/Captaksi Takip Merkezi/i);
  expect(headerElement).toBeInTheDocument();
});
