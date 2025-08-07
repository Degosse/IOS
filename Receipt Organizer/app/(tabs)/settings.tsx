import React, { useState } from 'react';
import { View, Text, StyleSheet, Switch, ScrollView, Alert, Platform, TouchableOpacity } from 'react-native';
import { useRouter } from 'expo-router';
import { ChevronRight, Trash2, HelpCircle, BellRing, Globe } from 'lucide-react-native';
import Colors from '@/constants/colors';
import Button from '@/components/Button';
import { useReceiptStore } from '@/store/receiptStore';
import { useLanguageStore, Language } from '@/store/languageStore';
import { useTranslation } from '@/hooks/useTranslation';

export default function SettingsScreen() {
  const router = useRouter();
  const { clearAllReceipts } = useReceiptStore();
  const { language, setLanguage } = useLanguageStore();
  const { t } = useTranslation();
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [showLanguagePicker, setShowLanguagePicker] = useState(false);
  
  const handleClearData = () => {
    Alert.alert(
      t('clearAllData'),
      t('clearAllDataConfirm'),
      [
        {
          text: t('cancel'),
          style: 'cancel',
        },
        {
          text: t('delete'),
          onPress: () => {
            clearAllReceipts();
            Alert.alert(t('success'), 'All receipts have been deleted.');
          },
          style: 'destructive',
        },
      ]
    );
  };
  
  const handleLanguageChange = (newLanguage: Language) => {
    setLanguage(newLanguage);
    setShowLanguagePicker(false);
  };
  
  const getLanguageDisplayName = (lang: Language) => {
    switch (lang) {
      case 'en': return t('english');
      case 'nl': return t('dutch');
      case 'de': return t('german');
      case 'fr': return t('french');
      default: return t('english');
    }
  };
  
  const renderSettingItem = (
    icon: React.ReactNode,
    title: string,
    subtitle?: string,
    rightElement?: React.ReactNode,
    onPress?: () => void,
  ) => (
    <TouchableOpacity 
      style={styles.settingItem} 
      onPress={onPress}
      disabled={!onPress}
    >
      <View style={styles.settingIconContainer}>{icon}</View>
      <View style={styles.settingContent}>
        <Text style={styles.settingTitle}>{title}</Text>
        {subtitle && <Text style={styles.settingSubtitle}>{subtitle}</Text>}
      </View>
      {rightElement || (
        onPress && <ChevronRight size={20} color={Colors.textSecondary} />
      )}
    </TouchableOpacity>
  );
  
  const renderLanguagePicker = () => (
    <View style={styles.languagePickerContainer}>
      <View style={styles.languagePickerHeader}>
        <Text style={styles.languagePickerTitle}>{t('language')}</Text>
        <TouchableOpacity onPress={() => setShowLanguagePicker(false)}>
          <Text style={styles.languagePickerClose}>{t('cancel')}</Text>
        </TouchableOpacity>
      </View>
      <View style={styles.languageList}>
        <TouchableOpacity
          style={[
            styles.languageItem,
            language === 'en' && styles.languageItemSelected,
          ]}
          onPress={() => handleLanguageChange('en')}
        >
          <Text
            style={[
              styles.languageItemText,
              language === 'en' && styles.languageItemTextSelected,
            ]}
          >
            {t('english')}
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[
            styles.languageItem,
            language === 'nl' && styles.languageItemSelected,
          ]}
          onPress={() => handleLanguageChange('nl')}
        >
          <Text
            style={[
              styles.languageItemText,
              language === 'nl' && styles.languageItemTextSelected,
            ]}
          >
            {t('dutch')}
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[
            styles.languageItem,
            language === 'de' && styles.languageItemSelected,
          ]}
          onPress={() => handleLanguageChange('de')}
        >
          <Text
            style={[
              styles.languageItemText,
              language === 'de' && styles.languageItemTextSelected,
            ]}
          >
            {t('german')}
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[
            styles.languageItem,
            language === 'fr' && styles.languageItemSelected,
          ]}
          onPress={() => handleLanguageChange('fr')}
        >
          <Text
            style={[
              styles.languageItemText,
              language === 'fr' && styles.languageItemTextSelected,
            ]}
          >
            {t('french')}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
  
  return (
    <View style={styles.container}>
      <ScrollView 
        style={styles.scrollView} 
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.title}>{t('settings')}</Text>
        
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('preferences')}</Text>
          
          {renderSettingItem(
            <Globe size={22} color={Colors.primary} />,
            t('language'),
            getLanguageDisplayName(language),
            undefined,
            () => setShowLanguagePicker(true)
          )}
          
          {renderSettingItem(
            <BellRing size={22} color={Colors.primary} />,
            t('notifications'),
            t('notificationsDescription'),
            <Switch
              value={notificationsEnabled}
              onValueChange={setNotificationsEnabled}
              trackColor={{ false: Colors.border, true: Colors.primary + '80' }}
              thumbColor={notificationsEnabled ? Colors.primary : '#f4f3f4'}
            />
          )}
        </View>
        
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('support')}</Text>
          
          {renderSettingItem(
            <HelpCircle size={22} color={Colors.primary} />,
            t('helpAndSupport'),
            t('helpAndSupportDescription'),
            undefined,
            () => {
              // In a real app, this would navigate to help screen
              Alert.alert(t('support'), 'Contact us at support@receipttracker.com');
            }
          )}
        </View>
        
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('data')}</Text>
          
          <Button
            title={t('clearAllData')}
            onPress={handleClearData}
            variant="outline"
            style={styles.dangerButton}
            textStyle={styles.dangerButtonText}
            icon={<Trash2 size={18} color={Colors.error} />}
          />
        </View>
        
        <View style={styles.footer}>
          <Text style={styles.version}>{t('version')} 1.0.0</Text>
        </View>
      </ScrollView>
      
      {showLanguagePicker && renderLanguagePicker()}
    </View>
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
    paddingBottom: Platform.OS === 'ios' ? 100 : 80,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: 24,
  },
  section: {
    marginBottom: 32,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.textSecondary,
    marginBottom: 16,
    textTransform: 'uppercase',
  },
  settingItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  settingIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.primary + '15',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  settingContent: {
    flex: 1,
  },
  settingTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 4,
  },
  settingSubtitle: {
    fontSize: 14,
    color: Colors.textSecondary,
  },
  dangerButton: {
    borderColor: Colors.error,
  },
  dangerButtonText: {
    color: Colors.error,
  },
  footer: {
    alignItems: 'center',
    marginTop: 32,
    marginBottom: 20,
  },
  version: {
    fontSize: 14,
    color: Colors.textSecondary,
  },
  languagePickerContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: Colors.background,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    paddingTop: 16,
    paddingHorizontal: 20,
    paddingBottom: Platform.OS === 'ios' ? 100 : 80,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 5,
    maxHeight: '60%',
  },
  languagePickerHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  languagePickerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
  },
  languagePickerClose: {
    fontSize: 16,
    color: Colors.primary,
    fontWeight: '500',
  },
  languageList: {
    marginBottom: 20,
    maxHeight: 200,
  },
  languageItem: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    marginBottom: 8,
  },
  languageItemSelected: {
    backgroundColor: Colors.primary + '20',
  },
  languageItemText: {
    fontSize: 16,
    color: Colors.text,
  },
  languageItemTextSelected: {
    color: Colors.primary,
    fontWeight: '600',
  },
});