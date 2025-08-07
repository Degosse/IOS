import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { Camera, Image as ImageIcon } from 'lucide-react-native';
import Colors from '@/constants/colors';
import { useTranslation } from '@/hooks/useTranslation';

export default function AddScreen() {
  const router = useRouter();
  const { t } = useTranslation();
  
  const handleCameraCapture = () => {
    router.push('/camera');
  };
  
  const handleGalleryPick = () => {
    router.push({
      pathname: '/receipt/new',
      params: {
        useGallery: 'true'
      }
    });
  };
  
  return (
    <ScrollView 
      style={styles.container} 
      contentContainerStyle={styles.content}
      showsVerticalScrollIndicator={false}
    >
      <Text style={styles.title}>{t('addReceipt')}</Text>
      <Text style={styles.subtitle}>
        {t('captureReceipt')}
      </Text>
      
      <View style={styles.optionsContainer}>
        <TouchableOpacity 
          style={styles.optionCard}
          onPress={handleCameraCapture}
        >
          <View style={[styles.iconContainer, { backgroundColor: Colors.primary + '20' }]}>
            <Camera size={48} color={Colors.primary} />
          </View>
          <Text style={styles.optionTitle}>{t('takePhoto')}</Text>
          <Text style={styles.optionDescription}>
            {t('useCamera')}
          </Text>
          <View style={styles.aiTag}>
            <Text style={styles.aiTagText}>{t('aiPowered')}</Text>
          </View>
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={[styles.optionCard, styles.secondaryCard]}
          onPress={handleGalleryPick}
        >
          <View style={[styles.iconContainer, { backgroundColor: Colors.secondary + '20' }]}>
            <ImageIcon size={48} color={Colors.secondary} />
          </View>
          <Text style={styles.optionTitle}>{t('chooseFromGallery')}</Text>
          <Text style={styles.optionDescription}>
            {t('selectFromGallery')}
          </Text>
          <View style={[styles.aiTag, { backgroundColor: Colors.secondary + '20' }]}>
            <Text style={[styles.aiTagText, { color: Colors.secondary }]}>{t('aiPowered')}</Text>
          </View>
        </TouchableOpacity>
      </View>
      
      <View style={styles.tipContainer}>
        <Text style={styles.tipTitle}>💡 {t('aiPowered')}</Text>
        <Text style={styles.tipText}>
          {t('aiPoweredTip')}
        </Text>
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
    flexGrow: 1,
    padding: 20,
    paddingBottom: Platform.OS === 'ios' ? 100 : 80,
    justifyContent: 'center',
    minHeight: '100%',
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: Colors.textSecondary,
    marginBottom: 48,
    textAlign: 'center',
  },
  optionsContainer: {
    alignItems: 'center',
    marginBottom: 48,
    gap: 20,
  },
  optionCard: {
    backgroundColor: Colors.card,
    borderRadius: 20,
    padding: 32,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
    position: 'relative',
    alignItems: 'center',
    width: '100%',
    maxWidth: 300,
  },
  secondaryCard: {
    borderWidth: 2,
    borderColor: Colors.secondary + '30',
  },
  iconContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 20,
  },
  optionTitle: {
    fontSize: 22,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 8,
    textAlign: 'center',
  },
  optionDescription: {
    fontSize: 16,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 22,
  },
  aiTag: {
    position: 'absolute',
    top: 16,
    right: 16,
    backgroundColor: Colors.primary + '20',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
  },
  aiTagText: {
    fontSize: 12,
    color: Colors.primary,
    fontWeight: '600',
  },
  tipContainer: {
    backgroundColor: Colors.primary + '15',
    borderRadius: 16,
    padding: 20,
    borderLeftWidth: 4,
    borderLeftColor: Colors.primary,
  },
  tipTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
    color: Colors.text,
  },
  tipText: {
    fontSize: 14,
    color: Colors.text,
    lineHeight: 20,
  },
});