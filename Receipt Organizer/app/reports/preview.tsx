import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  ScrollView, 
  Image, 
  TouchableOpacity,
  Alert,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { useRouter, useLocalSearchParams, Stack } from 'expo-router';
import { Download, Share2, Printer, FileText } from 'lucide-react-native';
import Colors from '@/constants/colors';
import Button from '@/components/Button';
import { useReceiptStore } from '@/store/receiptStore';
import { formatCurrency, formatDate } from '@/utils/formatters';
import * as Haptics from 'expo-haptics';
import { shareFile } from '@/utils/sharing';
import { generateReportPdf } from '@/services/pdfService';
import { useTranslation } from '@/hooks/useTranslation';

export default function ReportPreviewScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const { getReceiptsByDateRange } = useReceiptStore();
  const { t } = useTranslation();
  
  const [isGenerating, setIsGenerating] = useState(false);
  const [pdfUri, setPdfUri] = useState<string | null>(null);
  const [businessInfo, setBusinessInfo] = useState({
    name: "Your Business Name",
    address: "Your Business Address",
    taxId: "Your Tax ID"
  });
  
  const startDate = params.startDate as string;
  const endDate = params.endDate as string;
  const title = params.title as string;
  const includeImages = params.includeImages === 'true';
  
  const receipts = getReceiptsByDateRange(startDate, endDate);
  
  // Group receipts by category
  const receiptsByCategory = receipts.reduce((acc, receipt) => {
    if (!acc[receipt.category]) {
      acc[receipt.category] = [];
    }
    acc[receipt.category].push(receipt);
    return acc;
  }, {} as Record<string, typeof receipts>);
  
  // Calculate totals
  const categoryTotals = Object.keys(receiptsByCategory).reduce((acc, category) => {
    acc[category] = receiptsByCategory[category].reduce((sum, receipt) => sum + receipt.amount, 0);
    return acc;
  }, {} as Record<string, number>);
  
  const totalAmount = receipts.reduce((sum, receipt) => sum + receipt.amount, 0);
  
  const generatePdf = async () => {
    try {
      setIsGenerating(true);
      
      if (Platform.OS !== 'web') {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      }
      
      // Generate PDF report
      const uri = await generateReportPdf(receipts, {
        title,
        startDate,
        endDate,
        includeImages,
        businessInfo,
      });
      
      setPdfUri(uri);
      return uri;
    } catch (error) {
      console.error('Error generating PDF:', error);
      Alert.alert(t('error'), 'Failed to generate PDF report. Please try again.');
      return null;
    } finally {
      setIsGenerating(false);
    }
  };
  
  const handleShare = async () => {
    try {
      const uri = pdfUri || await generatePdf();
      if (!uri) return;
      
      // Share the PDF
      if (Platform.OS === 'web') {
        // For web, we'd typically use a download link
        Alert.alert(
          t('success'),
          'In a real app, this would download the PDF on web.',
          [{ text: t('ok') }]
        );
      } else {
        await shareFile(uri, 'application/pdf');
      }
    } catch (error) {
      console.error('Error sharing PDF:', error);
      Alert.alert(t('error'), 'Failed to share PDF report. Please try again.');
    }
  };
  
  const handleDownload = async () => {
    try {
      const uri = pdfUri || await generatePdf();
      if (!uri) return;
      
      // In a real app, we would save the PDF to the device
      // For this demo, we'll just show an alert
      Alert.alert(
        t('success'),
        'Report has been saved as PDF.',
        [{ text: t('ok') }]
      );
    } catch (error) {
      console.error('Error downloading PDF:', error);
      Alert.alert(t('error'), 'Failed to save PDF report. Please try again.');
    }
  };
  
  const handlePrint = async () => {
    if (Platform.OS !== 'web') {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    }
    
    Alert.alert(
      t('print'),
      'In a real app, this would open the print dialog.',
      [
        {
          text: t('ok'),
          style: 'default',
        },
      ]
    );
  };
  
  // Format period for title
  const getPeriodTitle = () => {
    const period = params.period as string;
    const startDateObj = new Date(startDate);
    const endDateObj = new Date(endDate);
    
    if (period === 'month') {
      return `${startDateObj.toLocaleString('default', { month: 'long', year: 'numeric' })}`;
    } else if (period === 'quarter') {
      const quarter = Math.floor(startDateObj.getMonth() / 3) + 1;
      return `${quarter}${getOrdinalSuffix(quarter)} Quarter ${startDateObj.getFullYear()}`;
    } else if (period === 'year') {
      return `${startDateObj.getFullYear()}`;
    } else {
      return `${formatDate(startDate)} - ${formatDate(endDate)}`;
    }
  };
  
  const getOrdinalSuffix = (num: number) => {
    const j = num % 10;
    const k = num % 100;
    if (j === 1 && k !== 11) {
      return 'st';
    }
    if (j === 2 && k !== 12) {
      return 'nd';
    }
    if (j === 3 && k !== 13) {
      return 'rd';
    }
    return 'th';
  };
  
  return (
    <>
      <Stack.Screen
        options={{
          title: t('reportPreview'),
        }}
      />
      
      <View style={styles.container}>
        <ScrollView style={styles.scrollView} contentContainerStyle={styles.content}>
          {/* PDF Header */}
          <View style={styles.pdfHeader}>
            <Text style={styles.pdfTitle}>{t('expenseReport')}</Text>
            <Text style={styles.pdfSubtitle}>{getPeriodTitle()}</Text>
          </View>
          
          {/* Business Information */}
          <View style={styles.businessInfoContainer}>
            <View style={styles.businessInfoLeft}>
              <Text style={styles.businessInfoLabel}>{t('business')}</Text>
              <Text style={styles.businessInfoValue}>{businessInfo.name}</Text>
              <Text style={styles.businessInfoValue}>{businessInfo.address}</Text>
            </View>
            <View style={styles.businessInfoRight}>
              <Text style={styles.businessInfoLabel}>{t('taxId')}</Text>
              <Text style={styles.businessInfoValue}>{businessInfo.taxId}</Text>
              <Text style={styles.businessInfoLabel}>{t('period')}</Text>
              <Text style={styles.businessInfoValue}>{formatDate(startDate)} - {formatDate(endDate)}</Text>
            </View>
          </View>
          
          {/* Summary Section */}
          <View style={styles.summarySection}>
            <Text style={styles.sectionTitle}>{t('summary')}</Text>
            <View style={styles.summaryTable}>
              <View style={styles.summaryRow}>
                <Text style={styles.summaryLabel}>{t('totalExpenses')}</Text>
                <Text style={styles.summaryValue}>{formatCurrency(totalAmount)}</Text>
              </View>
              <View style={styles.summaryRow}>
                <Text style={styles.summaryLabel}>{t('receipts')}</Text>
                <Text style={styles.summaryValue}>{receipts.length}</Text>
              </View>
              <View style={styles.summaryRow}>
                <Text style={styles.summaryLabel}>{t('category')}</Text>
                <Text style={styles.summaryValue}>{Object.keys(receiptsByCategory).length}</Text>
              </View>
            </View>
          </View>
          
          {/* Expense Categories */}
          <View style={styles.categoriesSection}>
            <Text style={styles.sectionTitle}>{t('expensesByCategory')}</Text>
            
            {Object.keys(receiptsByCategory).map((category) => (
              <View key={category} style={styles.categorySection}>
                <View style={styles.categoryHeader}>
                  <Text style={styles.categoryTitle}>{category}</Text>
                  <Text style={styles.categoryAmount}>{formatCurrency(categoryTotals[category])}</Text>
                </View>
                
                {/* Table Header */}
                <View style={styles.tableHeader}>
                  <Text style={[styles.tableHeaderCell, styles.dateColumn]}>{t('date')}</Text>
                  <Text style={[styles.tableHeaderCell, styles.vendorColumn]}>{t('vendor')}</Text>
                  <Text style={[styles.tableHeaderCell, styles.amountColumn]}>{t('amount')}</Text>
                </View>
                
                {/* Table Rows */}
                {receiptsByCategory[category].map((receipt) => (
                  <View key={receipt.id} style={styles.tableRow}>
                    <Text style={[styles.tableCell, styles.dateColumn]}>
                      {new Date(receipt.date).toLocaleDateString('en-US', {
                        day: '2-digit',
                        month: '2-digit',
                        year: '2-digit'
                      })}
                    </Text>
                    <Text style={[styles.tableCell, styles.vendorColumn]} numberOfLines={1}>
                      {receipt.vendor}
                    </Text>
                    <Text style={[styles.tableCell, styles.amountColumn]}>
                      {formatCurrency(receipt.amount)}
                    </Text>
                  </View>
                ))}
              </View>
            ))}
          </View>
          
          {/* Grand Total */}
          <View style={styles.grandTotalContainer}>
            <Text style={styles.grandTotalLabel}>{t('totalExpensesReport')}</Text>
            <Text style={styles.grandTotalValue}>{formatCurrency(totalAmount)}</Text>
          </View>
          
          {/* Signature Section */}
          <View style={styles.signatureSection}>
            <View style={styles.signatureDate}>
              <Text style={styles.signatureLabel}>{t('date')}</Text>
              <Text style={styles.signatureValue}>
                {new Date().toLocaleDateString('en-US', {
                  day: '2-digit',
                  month: '2-digit',
                  year: 'numeric'
                })}
              </Text>
              <View style={styles.signatureLine} />
            </View>
            <View style={styles.signatureBox}>
              <Text style={styles.signatureLabel}>{t('signature')}</Text>
              <View style={styles.signatureLine} />
            </View>
          </View>
          
          <Text style={styles.pageNumber}>{t('page')} 1 {t('of')} 1</Text>
        </ScrollView>
        
        <View style={styles.footer}>
          <View style={styles.actionButtons}>
            <TouchableOpacity 
              style={styles.actionButton}
              onPress={handleShare}
              disabled={isGenerating}
            >
              <Share2 size={24} color={Colors.primary} />
              <Text style={styles.actionButtonText}>{t('share')}</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.actionButton}
              onPress={handleDownload}
              disabled={isGenerating}
            >
              <Download size={24} color={Colors.primary} />
              <Text style={styles.actionButtonText}>{t('save')}</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.actionButton}
              onPress={handlePrint}
              disabled={isGenerating}
            >
              <Printer size={24} color={Colors.primary} />
              <Text style={styles.actionButtonText}>{t('print')}</Text>
            </TouchableOpacity>
          </View>
          
          <Button
            title={isGenerating ? t('loading') : t('generatePdfReport')}
            onPress={handleShare}
            loading={isGenerating}
            disabled={isGenerating}
            icon={<FileText size={18} color="#FFFFFF" />}
          />
        </View>
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  scrollView: {
    flex: 1,
  },
  content: {
    padding: 20,
    paddingBottom: 100,
  },
  pdfHeader: {
    backgroundColor: '#F8F9FA',
    padding: 20,
    alignItems: 'center',
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    borderRadius: 8,
  },
  pdfTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#000000',
    marginBottom: 4,
  },
  pdfSubtitle: {
    fontSize: 16,
    fontWeight: '500',
    color: '#4B5563',
  },
  businessInfoContainer: {
    flexDirection: 'row',
    marginBottom: 20,
    padding: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  businessInfoLeft: {
    flex: 2,
  },
  businessInfoRight: {
    flex: 1,
  },
  businessInfoLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: '#6B7280',
    marginBottom: 4,
  },
  businessInfoValue: {
    fontSize: 14,
    color: '#000000',
    marginBottom: 8,
  },
  summarySection: {
    marginBottom: 20,
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    overflow: 'hidden',
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#FFFFFF',
    backgroundColor: Colors.primary,
    padding: 10,
  },
  summaryTable: {
    padding: 16,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  summaryLabel: {
    fontSize: 14,
    color: '#4B5563',
  },
  summaryValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000000',
  },
  categoriesSection: {
    marginBottom: 20,
  },
  categorySection: {
    marginBottom: 16,
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    overflow: 'hidden',
  },
  categoryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 12,
    backgroundColor: '#F3F4F6',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  categoryTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#000000',
  },
  categoryAmount: {
    fontSize: 14,
    fontWeight: '700',
    color: '#000000',
  },
  tableHeader: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    backgroundColor: '#F9FAFB',
  },
  tableHeaderCell: {
    padding: 10,
    fontSize: 12,
    fontWeight: '600',
    color: '#4B5563',
  },
  tableRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  tableCell: {
    padding: 10,
    fontSize: 12,
    color: '#000000',
  },
  dateColumn: {
    width: '25%',
  },
  vendorColumn: {
    width: '50%',
  },
  amountColumn: {
    width: '25%',
    textAlign: 'right',
  },
  grandTotalContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 16,
    backgroundColor: '#F3F4F6',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#000000',
    marginBottom: 20,
  },
  grandTotalLabel: {
    fontSize: 16,
    fontWeight: '700',
    color: '#000000',
  },
  grandTotalValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#000000',
  },
  signatureSection: {
    flexDirection: 'row',
    marginTop: 20,
    marginBottom: 20,
  },
  signatureDate: {
    flex: 1,
    marginRight: 20,
  },
  signatureBox: {
    flex: 1,
  },
  signatureLabel: {
    fontSize: 12,
    color: '#6B7280',
    marginBottom: 16,
  },
  signatureValue: {
    fontSize: 12,
    color: '#000000',
    marginBottom: 8,
  },
  signatureLine: {
    height: 1,
    backgroundColor: '#000000',
  },
  pageNumber: {
    textAlign: 'center',
    fontSize: 10,
    color: '#6B7280',
    marginTop: 10,
  },
  footer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: Colors.background,
    borderTopWidth: 1,
    borderTopColor: Colors.border,
    padding: 16,
    paddingBottom: Platform.OS === 'ios' ? 40 : 16,
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 16,
  },
  actionButton: {
    alignItems: 'center',
  },
  actionButtonText: {
    marginTop: 4,
    fontSize: 12,
    color: Colors.primary,
    fontWeight: '500',
  },
});