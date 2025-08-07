export interface Receipt {
  id: string;
  imageUri: string;
  vendor: string;
  amount: number;
  date: string;
  category: string;
  notes: string;
  createdAt: string;
}

export type ReceiptFormData = Omit<Receipt, 'id' | 'createdAt'>;

export interface ReportOptions {
  startDate: string;
  endDate: string;
  title: string;
  includeImages: boolean;
}

export type ReportPeriod = 'month' | 'quarter' | 'year' | 'custom';

export interface ReportData {
  period: ReportPeriod;
  receipts: Receipt[];
  totalAmount: number;
  startDate: string;
  endDate: string;
}