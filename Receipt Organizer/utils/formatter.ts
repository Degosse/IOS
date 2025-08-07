export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('nl-NL', {
    style: 'currency',
    currency: 'EUR',
  }).format(amount);
}

export function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString('nl-NL', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

export function getMonthName(month: number): string {
  const date = new Date();
  date.setMonth(month);
  return date.toLocaleString('nl-NL', { month: 'long' });
}

export function getQuarterRange(date: Date): { start: Date; end: Date } {
  const quarter = Math.floor(date.getMonth() / 3);
  const startMonth = quarter * 3;
  const endMonth = startMonth + 2;
  
  const startDate = new Date(date.getFullYear(), startMonth, 1);
  const endDate = new Date(date.getFullYear(), endMonth + 1, 0);
  
  return { start: startDate, end: endDate };
}

export function getYearRange(date: Date): { start: Date; end: Date } {
  const startDate = new Date(date.getFullYear(), 0, 1);
  const endDate = new Date(date.getFullYear(), 11, 31);
  
  return { start: startDate, end: endDate };
}