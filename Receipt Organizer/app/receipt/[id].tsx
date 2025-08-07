import React, { useState } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  Image, 
  ScrollView, 
  TouchableOpacity,
  Alert,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { useRouter, useLocalSearchParams, Stack } from 'expo-router';
import { Edit2, Trash2, Share2, FileText, Download } from 'lucide-react-native';
import Colors from '@/constants/colors';
import { useReceiptStore } from '@/store/receiptStore';
import { formatCurrency, formatDate } from '@/utils/formatters';
import * as Haptics from 'expo-haptics';
import { shareFile } from '@/utils/sharing';
import { generateReceiptPdf, convertImageToPdf } from '@/services/pdfService';
import { useTranslation } from '@/hooks/useTranslation';

export default function ReceiptDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams();
  const { getReceiptById, deleteReceipt } = useReceiptStore();
  const [isGeneratingPdf, setIsGeneratingPdf] = useState(false);
  const { t } = useTranslation();
  
  const receipt = getReceiptById(id as string);
  
  if (!receipt) {
    return (
      <View style={styles.notFound}>
        <Text style={styles.notFoundText}>{t('noData')}</Text>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.notFoundButton}>{t('back')}</Text>
        </TouchableOpacity>
      </View>
    );
  }
  
  const handleEdit = () => {
    router.push(`/receipt/edit/${id}`);
  };
  
  const handleDelete = () => {
    Alert.alert(
      t('deleteReceipt'),
      t('deleteReceiptConfirm'),
      [
        {
          text: t('cancel'),
          style: 'cancel',
        },
        {
          text: t('delete'),
          onPress: () => {
            deleteReceipt(id as string);
            if (Platform.OS !== 'web') {
              Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            }
            router.back();
          },
          style: 'destructive',
        },
      ]
    );
  };
  
  const handleShare = async () => {
    try {
      setIsGeneratingPdf(true);
      
      if (Platform.OS !== 'web') {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      }
      
      // Generate PDF from receipt
      const pdfUri = await generateReceiptPdf(receipt);
      
      // Share the PDF
      if (Platform.OS === 'web') {
        // For web, we'd typically use a download link
        Alert.alert(
          t('success'),
          'In a real app, this would download the PDF on web.',
          [{ text: t('ok') }]
        );
      } else {
        await shareFile(pdfUri, 'application/pdf');
      }
    } catch (error) {
      console.error('Error sharing receipt as PDF:', error);
      Alert.alert(t('error'), 'Failed to share receipt as PDF. Please try again.');
    } finally {
      setIsGeneratingPdf(false);
    }
  };
  
  const handleDownloadPdf = async () => {
    try {
      setIsGeneratingPdf(true);
      
      if (Platform.OS !== 'web') {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      }
      
      // Convert receipt image to PDF
      const pdfUri = await convertImageToPdf(receipt.imageUri);
      
      // In a real app, we would save the PDF to the device
      // For this demo, we'll just show an alert
      Alert.alert(
        t('success'),
        'Receipt has been converted to PDF and saved.',
        [{ text: t('ok') }]
      );
    } catch (error) {
      console.error('Error converting to PDF:', error);
      Alert.alert(t('error'), 'Failed to convert receipt to PDF. Please try again.');
    } finally {
      setIsGeneratingPdf(false);
    }
  };
  
  return (
    <>
      <Stack.Screen
        options={{
          headerRight: () => (
            <View style={styles.headerButtons}>
              <TouchableOpacity style={styles.headerButton} onPress={handleEdit}>
                <Edit2 size={20} color={Colors.primary} />
              </TouchableOpacity>
              <TouchableOpacity style={styles.headerButton} onPress={handleDelete}>
                <Trash2 size={20} color={Colors.error} />
              </TouchableOpacity>
            </View>
          ),
        }}
      />
      
      <ScrollView style={styles.container} contentContainerStyle={styles.content}>
        <View style={styles.imageContainer}>
          <Image source={{ uri: receipt.imageUri }} style={styles.receiptImage} resizeMode="cover" />
        </View>
        
        <View style={styles.detailsContainer}>
          <View style={styles.header}>
            <Text style={styles.vendor}>{receipt.vendor}</Text>
            <Text style={styles.amount}>{formatCurrency(receipt.amount)}</Text>
          </View>
          
          <View style={styles.infoContainer}>
            <View style={styles.infoItem}>
              <Text style={styles.infoLabel}>{t('date')}</Text>
              <Text style={styles.infoValue}>{formatDate(receipt.date)}</Text>
            </View>
            
            <View style={styles.infoItem}>
              <Text style={styles.infoLabel}>{t('category')}</Text>
              <View style={styles.categoryContainer}>
                <Text style={styles.categoryText}>{receipt.category}</Text>
              </View>
            </View>
            
            {receipt.notes ? (
              <View style={styles.notesContainer}>
                <Text style={styles.infoLabel}>{t('notes')}</Text>
                <Text style={styles.notesText}>{receipt.notes}</Text>
              </View>
            ) : null}
          </View>
        </View>
        
        <View style={styles.actionsContainer}>
          <TouchableOpacity 
            style={styles.actionButton}
            onPress={handleShare}
            disabled={isGeneratingPdf}
          >
            {isGeneratingPdf ? (
              <ActivityIndicator size="small" color="#FFFFFF" />
            ) : (
              <>
                <Share2 size={20} color="#FFFFFF" />
                <Text style={styles.actionButtonText}>{t('shareReceipt')}</Text>
              </>
            )}
          </TouchableOpacity>
          
          <TouchableOpacity 
            style={[styles.actionButton, styles.secondaryButton]}
            onPress={handleDownloadPdf}
            disabled={isGeneratingPdf}
          >
            {isGeneratingPdf ? (
              <ActivityIndicator size="small" color={Colors.primary} />
            ) : (
              <>
                <FileText size={20} color={Colors.primary} />
                <Text style={[styles.actionButtonText, styles.secondaryButtonText]}>
                  {t('saveAsPdf')}
                </Text>
              </>
            )}
          </TouchableOpacity>
        </View>
      </ScrollView>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    padding: 20,
  },
  headerButtons: {
    flexDirection: 'row',
  },
  headerButton: {
    marginLeft: 16,
  },
  imageContainer: {
    marginBottom: 20,
    borderRadius: 12,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  receiptImage: {
    width: '100%',
    height: 250,
    backgroundColor: Colors.card,
  },
  detailsContainer: {
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: 20,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  vendor: {
    fontSize: 20,
    fontWeight: '700',
    color: Colors.text,
  },
  amount: {
    fontSize: 20,
    fontWeight: '700',
    color: Colors.text,
  },
  infoContainer: {
    gap: 16,
  },
  infoItem: {
    marginBottom: 12,
  },
  infoLabel: {
    fontSize: 14,
    color: Colors.textSecondary,
    marginBottom: 4,
  },
  infoValue: {
    fontSize: 16,
    color: Colors.text,
    fontWeight: '500',
  },
  categoryContainer: {
    backgroundColor: Colors.primary + '20',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 4,
    alignSelf: 'flex-start',
  },
  categoryText: {
    fontSize: 14,
    color: Colors.primary,
    fontWeight: '500',
  },
  notesContainer: {
    marginTop: 8,
  },
  notesText: {
    fontSize: 16,
    color: Colors.text,
    lineHeight: 22,
  },
  actionsContainer: {
    gap: 12,
    marginBottom: 20,
  },
  actionButton: {
    flexDirection: 'row',
    backgroundColor: Colors.primary,
    borderRadius: 8,
    paddingVertical: 12,
    paddingHorizontal: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  actionButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  secondaryButton: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: Colors.primary,
  },
  secondaryButtonText: {
    color: Colors.primary,
  },
  notFound: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  notFoundText: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 16,
  },
  notFoundButton: {
    fontSize: 16,
    color: Colors.primary,
    fontWeight: '500',
  },
});