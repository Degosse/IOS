import { Platform } from 'react-native';

interface OcrResult {
  vendor: string;
  amount: number;
  date: string;
  category?: string;
  error?: string;
}

// This is a simplified OCR service that simulates extracting data from receipts
// In a real app, you would use a proper OCR library or service
export async function analyzeReceiptWithOcr(imageUri: string): Promise<OcrResult> {
  try {
    // Simulate processing time
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // In a real app, this would actually analyze the image
    // For this demo, we'll return mock data based on the image URI
    
    // Generate somewhat random but plausible data
    const vendors = [
      'Starbucks', 'Office Depot', 'Amazon', 'Uber', 
      'Walmart', 'Target', 'Best Buy', 'Home Depot',
      'Staples', 'Costco', 'Whole Foods', 'CVS Pharmacy'
    ];
    
    const categories = [
      'Office Supplies', 'Travel', 'Meals & Entertainment', 
      'Software & Subscriptions', 'Equipment', 'Marketing',
      'Professional Services', 'Rent & Utilities', 'Insurance', 'Other'
    ];
    
    // Use parts of the image URI to create deterministic but seemingly random values
    const hashCode = (str: string) => {
      let hash = 0;
      for (let i = 0; i < str.length; i++) {
        hash = ((hash << 5) - hash) + str.charCodeAt(i);
        hash |= 0; // Convert to 32bit integer
      }
      return Math.abs(hash);
    };
    
    const hash = hashCode(imageUri);
    
    // Select vendor based on hash
    const vendorIndex = hash % vendors.length;
    const vendor = vendors[vendorIndex];
    
    // Generate amount between $5 and $500
    const amount = (hash % 49500 + 500) / 100;
    
    // Generate date within the last 30 days
    const today = new Date();
    const daysAgo = hash % 30;
    const receiptDate = new Date(today);
    receiptDate.setDate(today.getDate() - daysAgo);
    const date = receiptDate.toISOString().split('T')[0];
    
    // Select category based on vendor
    const categoryIndex = (hash + vendorIndex) % categories.length;
    const category = categories[categoryIndex];
    
    return {
      vendor,
      amount,
      date,
      category
    };
  } catch (error) {
    console.error('Error in OCR analysis:', error);
    return {
      vendor: '',
      amount: 0,
      date: new Date().toISOString().split('T')[0],
      error: 'Failed to analyze receipt image. Please try again or enter details manually.'
    };
  }
}