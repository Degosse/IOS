import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { FileText, Download, Share2, Calendar } from 'lucide-react-native';
import Colors from '@/constants/colors';
import Button from '@/components/Button';
import { useReceiptStore } from '@/store/receiptStore';
import { formatCurrency } from '@/utils/formatter';

export default function ReportsScreen() {
  const router = useRouter();
  const { receipts } = useReceiptStore();
  const [selectedPeriod, setSelectedPeriod] = useState<'month' | 'quarter' | 'year'>('month');
  
  const handleGenerateReport = () => {
    router.push('/reports/generate');
  };
  
  // Calculate totals for different time periods
  const now = new Date();
  const currentMonth = now.getMonth();
  const currentYear = now.getFullYear();
  
  const monthlyTotal = receipts
    .filter(receipt => {
      const receiptDate = new Date(receipt.date);
      return receiptDate.getMonth() === currentMonth && 
             receiptDate.getFullYear() === currentYear;
    })
    .reduce((sum, receipt) => sum + receipt.amount, 0);
  
  const quarterlyTotal = receipts
    .filter(receipt => {
      const receiptDate = new Date(receipt.date);
      const receiptQuarter = Math.floor(receiptDate.getMonth() / 3);
      const currentQuarter = Math.floor(currentMonth / 3);
      return receiptQuarter === currentQuarter && 
             receiptDate.getFullYear() === currentYear;
    })
    .reduce((sum, receipt) => sum + receipt.amount, 0);
  
  const yearlyTotal = receipts
    .filter(receipt => {
      const receiptDate = new Date(receipt.date);
      return receiptDate.getFullYear() === currentYear;
    })
    .reduce((sum, receipt) => sum + receipt.amount, 0);
  
  const renderPeriodButton = (period: 'month' | 'quarter' | 'year', label: string) => (
    <TouchableOpacity
      style={[
        styles.periodButton,
        selectedPeriod === period && styles.periodButtonActive,
      ]}
      onPress={() => setSelectedPeriod(period)}
    >
      <Text
        style={[
          styles.periodButtonText,
          selectedPeriod === period && styles.periodButtonTextActive,
        ]}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );
  
  return (
    <ScrollView 
      style={styles.container} 
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
    >
      <Text style={styles.title}>Reports</Text>
      
      <View style={styles.periodSelector}>
        {renderPeriodButton('month', 'Month')}
        {renderPeriodButton('quarter', 'Quarter')}
        {renderPeriodButton('year', 'Year')}
      </View>
      
      <View style={styles.summaryCard}>
        <View style={styles.summaryHeader}>
          <Calendar size={20} color={Colors.primary} />
          <Text style={styles.summaryPeriod}>
            {selectedPeriod === 'month' 
              ? 'This Month' 
              : selectedPeriod === 'quarter' 
                ? 'This Quarter' 
                : 'This Year'}
          </Text>
        </View>
        
        <Text style={styles.summaryAmount}>
          {formatCurrency(
            selectedPeriod === 'month' 
              ? monthlyTotal 
              : selectedPeriod === 'quarter' 
                ? quarterlyTotal 
                : yearlyTotal
          )}
        </Text>
        
        <Text style={styles.summaryLabel}>Total Expenses</Text>
        
        <View style={styles.summaryDetails}>
          <Text style={styles.summaryDetailLabel}>Receipts</Text>
          <Text style={styles.summaryDetailValue}>
            {receipts.filter(receipt => {
              const receiptDate = new Date(receipt.date);
              if (selectedPeriod === 'month') {
                return receiptDate.getMonth() === currentMonth && 
                       receiptDate.getFullYear() === currentYear;
              } else if (selectedPeriod === 'quarter') {
                const receiptQuarter = Math.floor(receiptDate.getMonth() / 3);
                const currentQuarter = Math.floor(currentMonth / 3);
                return receiptQuarter === currentQuarter && 
                       receiptDate.getFullYear() === currentYear;
              } else {
                return receiptDate.getFullYear() === currentYear;
              }
            }).length}
          </Text>
        </View>
      </View>
      
      <Button
        title="Generate Report"
        onPress={handleGenerateReport}
        style={styles.generateButton}
        icon={<FileText size={18} color="#FFFFFF" />}
      />
      
      <View style={styles.recentReportsContainer}>
        <Text style={styles.sectionTitle}>Recent Reports</Text>
        
        {receipts.length > 0 ? (
          <View style={styles.recentReportCard}>
            <View style={styles.recentReportHeader}>
              <FileText size={20} color={Colors.primary} />
              <Text style={styles.recentReportTitle}>Monthly Report</Text>
            </View>
            <Text style={styles.recentReportDate}>
              {new Date().toLocaleDateString('en-US', { 
                month: 'long', 
                year: 'numeric' 
              })}
            </Text>
            <View style={styles.recentReportActions}>
              <TouchableOpacity style={styles.recentReportAction}>
                <Download size={16} color={Colors.primary} />
                <Text style={styles.recentReportActionText}>Download</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.recentReportAction}>
                <Share2 size={16} color={Colors.primary} />
                <Text style={styles.recentReportActionText}>Share</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          <View style={styles.emptyReports}>
            <Text style={styles.emptyReportsText}>
              No reports generated yet. Add some receipts and generate your first report.
            </Text>
          </View>
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    padding: 20,
    paddingBottom: Platform.OS === 'ios' ? 100 : 80,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: 20,
  },
  periodSelector: {
    flexDirection: 'row',
    backgroundColor: Colors.card,
    borderRadius: 8,
    marginBottom: 20,
    padding: 4,
  },
  periodButton: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 6,
  },
  periodButtonActive: {
    backgroundColor: Colors.primary,
  },
  periodButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: Colors.textSecondary,
  },
  periodButtonTextActive: {
    color: '#FFFFFF',
  },
  summaryCard: {
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: 20,
    marginBottom: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  summaryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  summaryPeriod: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text,
    marginLeft: 8,
  },
  summaryAmount: {
    fontSize: 32,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: 4,
  },
  summaryLabel: {
    fontSize: 14,
    color: Colors.textSecondary,
    marginBottom: 16,
  },
  summaryDetails: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: Colors.border,
  },
  summaryDetailLabel: {
    fontSize: 14,
    color: Colors.textSecondary,
  },
  summaryDetailValue: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.text,
  },
  generateButton: {
    marginBottom: 32,
  },
  recentReportsContainer: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 16,
  },
  recentReportCard: {
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  recentReportHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  recentReportTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text,
    marginLeft: 8,
  },
  recentReportDate: {
    fontSize: 14,
    color: Colors.textSecondary,
    marginBottom: 16,
  },
  recentReportActions: {
    flexDirection: 'row',
    borderTopWidth: 1,
    borderTopColor: Colors.border,
    paddingTop: 12,
  },
  recentReportAction: {
    flexDirection: 'row',
    alignItems: 'center',
    marginRight: 24,
  },
  recentReportActionText: {
    fontSize: 14,
    color: Colors.primary,
    fontWeight: '500',
    marginLeft: 6,
  },
  emptyReports: {
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: 20,
    alignItems: 'center',
  },
  emptyReportsText: {
    fontSize: 14,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 20,
  },
});