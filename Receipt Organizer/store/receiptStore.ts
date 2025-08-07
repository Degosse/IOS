import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Receipt, ReportOptions } from '@/types/receipt';

interface ReceiptState {
  receipts: Receipt[];
  addReceipt: (receipt: Omit<Receipt, 'id' | 'createdAt'>) => void;
  updateReceipt: (id: string, receipt: Partial<Receipt>) => void;
  deleteReceipt: (id: string) => void;
  getReceiptById: (id: string) => Receipt | undefined;
  getReceiptsByDateRange: (startDate: string, endDate: string) => Receipt[];
  clearAllReceipts: () => void;
}

export const useReceiptStore = create<ReceiptState>()(
  persist(
    (set, get) => ({
      receipts: [],
      
      addReceipt: (receiptData) => {
        const newReceipt: Receipt = {
          ...receiptData,
          id: Date.now().toString(),
          createdAt: new Date().toISOString(),
        };
        
        set((state) => ({
          receipts: [newReceipt, ...state.receipts],
        }));
      },
      
      updateReceipt: (id, updatedData) => {
        set((state) => ({
          receipts: state.receipts.map((receipt) => 
            receipt.id === id ? { ...receipt, ...updatedData } : receipt
          ),
        }));
      },
      
      deleteReceipt: (id) => {
        set((state) => ({
          receipts: state.receipts.filter((receipt) => receipt.id !== id),
        }));
      },
      
      getReceiptById: (id) => {
        return get().receipts.find((receipt) => receipt.id === id);
      },
      
      getReceiptsByDateRange: (startDate, endDate) => {
        const start = new Date(startDate).getTime();
        const end = new Date(endDate).getTime();
        
        return get().receipts.filter((receipt) => {
          const receiptDate = new Date(receipt.date).getTime();
          return receiptDate >= start && receiptDate <= end;
        });
      },
      
      clearAllReceipts: () => {
        set({ receipts: [] });
      },
    }),
    {
      name: 'receipt-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);