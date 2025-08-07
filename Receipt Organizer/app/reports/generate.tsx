import React, { useState } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  ScrollView, 
  TouchableOpacity,
  Switch,
  Platform,
  Alert,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Calendar, FileText, ChevronRight } from 'lucide-react-native';
import Colors from '@/constants/colors';
import Button from '@/components/Button';
import { useReceiptStore } from '@/store/receiptStore';
import { formatDate } from '@/utils/formatter';
import { useTranslation } from '@/hooks/useTranslation';

export default function GenerateReportScreen() {
  const router = useRouter();
  const { receipts } = useReceiptStore();
  const { t } = useTranslation();
  
  const now = new Date();
  const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const lastDayOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  
  const [reportPeriod, setReportPeriod] = useState<'month' | 'quarter' | 'year' | 'custom'>('month');
  const [startDate, setStartDate] = useState(firstDayOfMonth.toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState(lastDayOfMonth.toISOString().split('T')[0]);
  const [includeImages, setIncludeImages] = useState(true);
  const [reportTitle, setReportTitle] = useState(`Expense Report - ${now.toLocaleString('default', { month: 'long', year: 'numeric' })}`);
  
  const handlePeriodChange = (period: 'month' | 'quarter' | 'year' | 'custom') => {
    setReportPeriod(period);
    
    const now = new Date();
    
    if (period === 'month') {
      const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
      const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      
      setStartDate(firstDay.toISOString().split('T')[0]);
      setEndDate(lastDay.toISOString().split('T')[0]);
      setReportTitle(`Expense Report - ${now.toLocaleString('default', { month: 'long', year: 'numeric' })}`);
    } else if (period === 'quarter') {
      // Fixed quarter calculation: Q1: Jan-Mar, Q2: Apr-Jun, Q3: Jul-Sep, Q4: Oct-Dec
      const currentMonth = now.getMonth(); // 0-based (0 = January)
      const quarter = Math.floor(currentMonth / 3); // 0, 1, 2, or 3
      const firstMonth = quarter * 3; // 0, 3, 6, or 9
      
      const firstDay = new Date(now.getFullYear(), firstMonth, 1);
      const lastDay = new Date(now.getFullYear(), firstMonth + 3, 0); // Last day of the quarter
      
      setStartDate(firstDay.toISOString().split('T')[0]);
      setEndDate(lastDay.toISOString().split('T')[0]);
      setReportTitle(`Q${quarter + 1} ${now.getFullYear()} Expense Report`);
    } else if (period === 'year') {
      const firstDay = new Date(now.getFullYear(), 0, 1);
      const lastDay = new Date(now.getFullYear(), 11, 31);
      
      setStartDate(firstDay.toISOString().split('T')[0]);
      setEndDate(lastDay.toISOString().split('T')[0]);
      setReportTitle(`${now.getFullYear()} Annual Expense Report`);
    }
  };
  
  const handleGenerateReport = () => {
    // Get receipts for the selected period
    const filteredReceipts = receipts.filter(receipt => {
      const receiptDate = new Date(receipt.date).getTime();
      const start = new Date(startDate).getTime();
      const end = new Date(endDate).getTime();
      
      return receiptDate >= start && receiptDate <= end;
    });
    
    if (filteredReceipts.length === 0) {
      Alert.alert(t('noData'), t('noReceiptsFound'));
      return;
    }
    
    // Navigate to report preview
    router.push({
      pathname: '/reports/preview',
      params: {
        period: reportPeriod,
        startDate,
        endDate,
        title: reportTitle,
        includeImages: includeImages ? 'true' : 'false',
      },
    });
  };
  
  const renderPeriodButton = (period: 'month' | 'quarter' | 'year' | 'custom', label: string) => (
    <TouchableOpacity
      style={[
        styles.periodButton,
        reportPeriod === period && styles.periodButtonActive,
      ]}
      onPress={() => handlePeriodChange(period)}
    >
      <Text
        style={[
          styles.periodButtonText,
          reportPeriod === period && styles.periodButtonTextActive,
        ]}
      >
        {t(period as any)}
      </Text>
    </TouchableOpacity>
  );
  
  return (
    <ScrollView 
      style={styles.container} 
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
    >
      <Text style={styles.title}>{t('generateReport')}</Text>
      <Text style={styles.subtitle}>
        Create detailed expense reports for your business needs
      </Text>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('reportPeriod')}</Text>
        
        <View style={styles.periodSelector}>
          {renderPeriodButton('month', t('month'))}
          {renderPeriodButton('quarter', t('quarter'))}
          {renderPeriodButton('year', t('year'))}
          {renderPeriodButton('custom', t('custom'))}
        </View>
        
        <View style={styles.dateRangeContainer}>
          <View style={styles.dateItem}>
            <Text style={styles.dateLabel}>{t('startDate')}</Text>
            <TouchableOpacity 
              style={styles.dateButton}
              onPress={() => {
                // TODO: Implement date picker for start date
              }}
            >
              <Calendar size={18} color={Colors.textSecondary} style={styles.dateIcon} />
              <Text style={styles.dateText}>{formatDate(startDate)}</Text>
              <ChevronRight size={16} color={Colors.textSecondary} />
            </TouchableOpacity>
          </View>
          
          <View style={styles.dateItem}>
            <Text style={styles.dateLabel}>{t('endDate')}</Text>
            <TouchableOpacity 
              style={styles.dateButton}
              onPress={() => {
                // TODO: Implement date picker for end date
              }}
            >
              <Calendar size={18} color={Colors.textSecondary} style={styles.dateIcon} />
              <Text style={styles.dateText}>{formatDate(endDate)}</Text>
              <ChevronRight size={16} color={Colors.textSecondary} />
            </TouchableOpacity>
          </View>
        </View>
      </View>
      
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>{t('reportOptions')}</Text>
        
        <View style={styles.optionItem}>
          <View style={styles.optionTextContainer}>
            <Text style={styles.optionTitle}>{t('includeImages')}</Text>
            <Text style={styles.optionDescription}>
              {t('includeImages')}
            </Text>
          </View>
          <Switch
            value={includeImages}
            onValueChange={setIncludeImages}
            trackColor={{ false: Colors.border, true: Colors.primary + '80' }}
            thumbColor={includeImages ? Colors.primary : '#f4f3f4'}
          />
        </View>
        
        <View style={styles.optionItem}>
          <View style={styles.optionTextContainer}>
            <Text style={styles.optionTitle}>{t('reportTitle')}</Text>
            <Text style={styles.optionDescription}>{reportTitle}</Text>
          </View>
          <TouchableOpacity
            onPress={() => {
              // TODO: Implement report title editing
            }}
          >
            <ChevronRight size={20} color={Colors.textSecondary} />
          </TouchableOpacity>
        </View>
      </View>
      
      <View style={styles.summaryContainer}>
        <View style={styles.summaryHeader}>
          <FileText size={20} color={Colors.primary} />
          <Text style={styles.summaryTitle}>{t('reportSummary')}</Text>
        </View>
        
        <View style={styles.summaryItem}>
          <Text style={styles.summaryLabel}>{t('period')}</Text>
          <Text style={styles.summaryValue}>
            {formatDate(startDate)} - {formatDate(endDate)}
          </Text>
        </View>
        
        <View style={styles.summaryItem}>
          <Text style={styles.summaryLabel}>{t('receipts')}</Text>
          <Text style={styles.summaryValue}>
            {receipts.filter(receipt => {
              const receiptDate = new Date(receipt.date).getTime();
              const start = new Date(startDate).getTime();
              const end = new Date(endDate).getTime();
              return receiptDate >= start && receiptDate <= end;
            }).length}
          </Text>
        </View>
        
        <View style={styles.summaryItem}>
          <Text style={styles.summaryLabel}>{t('totalExpenses')}</Text>
          <Text style={styles.summaryValue}>
            €{receipts
              .filter(receipt => {
                const receiptDate = new Date(receipt.date).getTime();
                const start = new Date(startDate).getTime();
                const end = new Date(endDate).getTime();
                return receiptDate >= start && receiptDate <= end;
              })
              .reduce((sum, receipt) => sum + receipt.amount, 0)
              .toFixed(2)}
          </Text>
        </View>
      </View>
      
      <Button
        title={t('generatePdfReport')}
        onPress={handleGenerateReport}
        style={styles.generateButton}
        icon={<FileText size={18} color="#FFFFFF" />}
      />
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
    paddingBottom: Platform.OS === 'ios' ? 40 : 20,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: Colors.textSecondary,
    marginBottom: 24,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 16,
  },
  periodSelector: {
    flexDirection: 'row',
    backgroundColor: Colors.card,
    borderRadius: 8,
    marginBottom: 16,
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
  dateRangeContainer: {
    gap: 12,
  },
  dateItem: {
    marginBottom: 8,
  },
  dateLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 8,
  },
  dateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.card,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: 12,
    paddingVertical: 12,
  },
  dateIcon: {
    marginRight: 8,
  },
  dateText: {
    flex: 1,
    fontSize: 16,
    color: Colors.text,
  },
  optionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  optionTextContainer: {
    flex: 1,
  },
  optionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 4,
  },
  optionDescription: {
    fontSize: 14,
    color: Colors.textSecondary,
  },
  summaryContainer: {
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
    marginBottom: 16,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  summaryTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
    marginLeft: 8,
  },
  summaryItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  summaryLabel: {
    fontSize: 14,
    color: Colors.textSecondary,
  },
  summaryValue: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.text,
  },
  generateButton: {
    marginBottom: 20,
  },
});