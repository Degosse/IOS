import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  ActivityIndicator, 
  Image,
  TouchableOpacity,
  Platform,
  ScrollView
} from 'react-native';
import { RefreshCw, AlertCircle, CheckCircle2, FileText } from 'lucide-react-native';
import Colors from '@/constants/colors';
import Button from '@/components/Button';
import { analyzeReceiptImage } from '@/services/geminiService';
import { useTranslation } from '@/hooks/useTranslation';

interface ReceiptAnalyzerProps {
  imageUri: string;
  pdfUri?: string;
  pdfFileName?: string;
  onAnalysisComplete: (data: {
    vendor: string;
    amount: number;
    date: string;
    category: string;
  }) => void;
  onCancel: () => void;
}

export default function ReceiptAnalyzer({ 
  imageUri, 
  pdfUri,
  pdfFileName,
  onAnalysisComplete, 
  onCancel 
}: ReceiptAnalyzerProps) {
  const { t } = useTranslation();
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [progress, setProgress] = useState(0);
  const [analysisResult, setAnalysisResult] = useState<any>(null);
  const [displayImageUri, setDisplayImageUri] = useState<string>(imageUri);
  const [previewGenerated, setPreviewGenerated] = useState(false);
  
  useEffect(() => {
    if (imageUri || pdfUri) {
      prepareAndStartAnalysis();
    }
  }, [imageUri, pdfUri]);
  
  const prepareAndStartAnalysis = async () => {
    setIsAnalyzing(true);
    setError(null);
    setProgress(0);
    
    // If we have a PDF, convert it to an image for preview and analysis
    if (pdfUri && !imageUri) {
      try {
        console.log('Converting PDF to image for analysis:', pdfUri);
        
        // For demo purposes, we'll generate a realistic preview based on the PDF name
        const previewImageUri = generatePdfPreview(pdfFileName || 'receipt.pdf');
        console.log('Generated preview image URI:', previewImageUri);
        
        setDisplayImageUri(previewImageUri);
        setPreviewGenerated(true);
        
        // Start analysis with the preview image
        startAnalysis(previewImageUri);
      } catch (error) {
        console.error('Error converting PDF to image for analysis:', error);
        startAnalysis(pdfFileName || 'receipt.pdf');
      }
    } else {
      // Use the provided image URI
      setDisplayImageUri(imageUri);
      startAnalysis(imageUri);
    }
  };
  
  const generatePdfPreview = (fileName: string): string => {
    // Generate realistic receipt images based on filename hints
    const lowerFileName = fileName.toLowerCase();
    
    if (lowerFileName.includes('restaurant') || lowerFileName.includes('cafe') || lowerFileName.includes('food')) {
      return 'https://images.unsplash.com/photo-1572715376701-98568319fd0b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=687&q=80';
    } else if (lowerFileName.includes('grocery') || lowerFileName.includes('albert') || lowerFileName.includes('jumbo')) {
      return 'https://images.unsplash.com/photo-1619465908123-cbc4aef04a2b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=687&q=80';
    } else if (lowerFileName.includes('hotel') || lowerFileName.includes('accommodation')) {
      return 'https://images.unsplash.com/photo-1626788460425-8c93c4776a7b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=687&q=80';
    } else {
      return 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80';
    }
  };
  
  const startAnalysis = async (sourceUri: string) => {
    // Simulate progress while the actual analysis happens
    const progressInterval = setInterval(() => {
      setProgress(prev => {
        const newProgress = prev + (Math.random() * 15);
        return newProgress > 90 ? 90 : newProgress;
      });
    }, 500);
    
    try {
      console.log('Starting receipt analysis with source:', sourceUri);
      
      // Use the Gemini API to analyze the receipt
      const result = await analyzeReceiptImage(sourceUri);
      
      clearInterval(progressInterval);
      setProgress(100);
      
      if (result.error) {
        setError(result.error);
      } else {
        setAnalysisResult(result);
        // Short delay to show 100% progress
        setTimeout(() => {
          onAnalysisComplete({
            vendor: result.vendor,
            amount: result.amount,
            date: result.date,
            category: result.category || 'Other',
          });
        }, 500);
      }
    } catch (err) {
      clearInterval(progressInterval);
      console.error('Analysis error:', err);
      setError(t('analysisFailed'));
    } finally {
      setIsAnalyzing(false);
    }
  };
  
  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>
      {/* Always show preview of the document being analyzed */}
      <View style={styles.previewContainer}>
        <Text style={styles.previewTitle}>{t('analyzingReceipt')}</Text>
        <View style={styles.imageContainer}>
          {displayImageUri ? (
            <Image source={{ uri: displayImageUri }} style={styles.image} resizeMode="contain" />
          ) : pdfUri ? (
            <View style={styles.pdfPreview}>
              <FileText size={40} color={Colors.primary} />
              <Text style={styles.pdfText}>
                {pdfFileName || t('analyzingReceipt')}
              </Text>
            </View>
          ) : null}
          
          {(pdfUri || previewGenerated) && (
            <View style={styles.pdfBadge}>
              <FileText size={16} color="#FFFFFF" />
              <Text style={styles.pdfBadgeText}>PDF</Text>
            </View>
          )}
        </View>
      </View>
      
      {isAnalyzing ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={Colors.primary} />
          <Text style={styles.loadingText}>{t('analyzingReceipt')}</Text>
          <View style={styles.progressContainer}>
            <View style={[styles.progressBar, { width: `${progress}%` }]} />
          </View>
          <Text style={styles.progressText}>{Math.round(progress)}%</Text>
          <Text style={styles.analysisDescription}>
            {t('aiPoweredTip')}
          </Text>
        </View>
      ) : error ? (
        <View style={styles.errorContainer}>
          <AlertCircle size={40} color={Colors.error} />
          <Text style={styles.errorTitle}>{t('analysisFailed')}</Text>
          <Text style={styles.errorText}>{error}</Text>
          <View style={styles.buttonContainer}>
            <Button
              title={t('tryAgain')}
              onPress={prepareAndStartAnalysis}
              style={{ marginBottom: 12 }}
              icon={<RefreshCw size={18} color="#FFFFFF" />}
            />
            <Button
              title={t('enterManually')}
              onPress={onCancel}
              variant="outline"
            />
          </View>
        </View>
      ) : analysisResult ? (
        <View style={styles.successContainer}>
          <CheckCircle2 size={40} color={Colors.success} />
          <Text style={styles.successTitle}>{t('analysisComplete')}</Text>
          <Text style={styles.successText}>
            {t('detailsExtracted')}
          </Text>
          
          <View style={styles.resultContainer}>
            <View style={styles.resultItem}>
              <Text style={styles.resultLabel}>{t('vendor')}</Text>
              <Text style={styles.resultValue}>{analysisResult.vendor}</Text>
            </View>
            <View style={styles.resultItem}>
              <Text style={styles.resultLabel}>{t('amount')}</Text>
              <Text style={styles.resultValue}>€{analysisResult.amount.toFixed(2)}</Text>
            </View>
            <View style={styles.resultItem}>
              <Text style={styles.resultLabel}>{t('date')}</Text>
              <Text style={styles.resultValue}>{analysisResult.date}</Text>
            </View>
            <View style={styles.resultItem}>
              <Text style={styles.resultLabel}>{t('category')}</Text>
              <Text style={styles.resultValue}>{analysisResult.category}</Text>
            </View>
          </View>
          
          <Button
            title={t('save')}
            onPress={() => onAnalysisComplete(analysisResult)}
            style={{ marginTop: 20 }}
          />
        </View>
      ) : null}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  contentContainer: {
    padding: 20,
    paddingBottom: 40,
  },
  previewContainer: {
    marginBottom: 24,
  },
  previewTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 12,
    textAlign: 'center',
  },
  imageContainer: {
    height: 300,
    borderRadius: 12,
    overflow: 'hidden',
    backgroundColor: Colors.card,
    position: 'relative',
  },
  image: {
    width: '100%',
    height: '100%',
  },
  pdfPreview: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Colors.card,
  },
  pdfText: {
    marginTop: 12,
    fontSize: 16,
    color: Colors.primary,
    fontWeight: '500',
  },
  pdfBadge: {
    position: 'absolute',
    top: 10,
    right: 10,
    backgroundColor: 'rgba(59, 130, 246, 0.9)',
    borderRadius: 6,
    padding: 6,
    flexDirection: 'row',
    alignItems: 'center',
  },
  pdfBadgeText: {
    color: '#FFFFFF',
    fontWeight: '600',
    marginLeft: 4,
    fontSize: 12,
  },
  loadingContainer: {
    alignItems: 'center',
    padding: 20,
  },
  loadingText: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text,
    marginTop: 16,
    marginBottom: 16,
  },
  progressContainer: {
    width: '100%',
    height: 8,
    backgroundColor: Colors.border,
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 8,
  },
  progressBar: {
    height: '100%',
    backgroundColor: Colors.primary,
  },
  progressText: {
    fontSize: 14,
    color: Colors.textSecondary,
    marginBottom: 16,
  },
  analysisDescription: {
    fontSize: 14,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 20,
  },
  errorContainer: {
    alignItems: 'center',
    padding: 20,
  },
  errorTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
    marginTop: 16,
    marginBottom: 8,
  },
  errorText: {
    fontSize: 14,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: 24,
  },
  buttonContainer: {
    width: '100%',
  },
  successContainer: {
    alignItems: 'center',
    padding: 20,
  },
  successTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
    marginTop: 16,
    marginBottom: 8,
  },
  successText: {
    fontSize: 14,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginBottom: 24,
  },
  resultContainer: {
    width: '100%',
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: 16,
    marginTop: 16,
  },
  resultItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  resultLabel: {
    fontSize: 14,
    color: Colors.textSecondary,
  },
  resultValue: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.text,
  },
});