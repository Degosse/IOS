import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  TextInput, 
  ScrollView, 
  Image, 
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Calendar, Tag, FileText, Image as ImageIcon } from 'lucide-react-native';
import Colors from '@/constants/colors';
import Button from '@/components/Button';
import { useReceiptStore } from '@/store/receiptStore';
import { CATEGORIES } from '@/constants/categories';
import * as ImagePicker from 'expo-image-picker';
import * as Haptics from 'expo-haptics';
import { useTranslation } from '@/hooks/useTranslation';

export default function EditReceiptScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams();
  const { getReceiptById, updateReceipt } = useReceiptStore();
  const { t } = useTranslation();
  
  const receipt = getReceiptById(id as string);
  
  const [imageUri, setImageUri] = useState<string>('');
  const [vendor, setVendor] = useState('');
  const [amount, setAmount] = useState('');
  const [date, setDate] = useState('');
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showCategoryPicker, setShowCategoryPicker] = useState(false);
  
  useEffect(() => {
    if (receipt) {
      setImageUri(receipt.imageUri);
      setVendor(receipt.vendor);
      setAmount(receipt.amount.toString());
      setDate(receipt.date);
      setCategory(receipt.category);
      setNotes(receipt.notes);
    } else {
      // If receipt not found, go back
      Alert.alert(t('error'), t('noData'));
      router.back();
    }
  }, [receipt]);
  
  const handlePickImage = async () => {
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.Images,
        allowsEditing: true,
        aspect: [4, 3],
        quality: 0.8,
      });
      
      if (!result.canceled && result.assets && result.assets.length > 0) {
        setImageUri(result.assets[0].uri);
      }
    } catch (error) {
      console.error('Error picking image:', error);
      Alert.alert(t('error'), 'Failed to pick image. Please try again.');
    }
  };
  
  const handleUpdateReceipt = () => {
    if (!imageUri) {
      Alert.alert(t('error'), t('missingImage'));
      return;
    }
    
    if (!vendor) {
      Alert.alert(t('error'), t('missingVendor'));
      return;
    }
    
    if (!amount || isNaN(parseFloat(amount))) {
      Alert.alert(t('error'), t('invalidAmount'));
      return;
    }
    
    setIsSubmitting(true);
    
    try {
      updateReceipt(id as string, {
        imageUri,
        vendor,
        amount: parseFloat(amount),
        date,
        category,
        notes,
      });
      
      if (Platform.OS !== 'web') {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }
      
      // Navigate back to the receipt details
      router.back();
    } catch (error) {
      console.error('Error updating receipt:', error);
      Alert.alert(t('error'), 'Failed to update receipt. Please try again.');
      setIsSubmitting(false);
    }
  };
  
  const renderCategoryPicker = () => (
    <View style={styles.categoryPickerContainer}>
      <View style={styles.categoryPickerHeader}>
        <Text style={styles.categoryPickerTitle}>{t('selectCategory')}</Text>
        <TouchableOpacity onPress={() => setShowCategoryPicker(false)}>
          <Text style={styles.categoryPickerClose}>{t('cancel')}</Text>
        </TouchableOpacity>
      </View>
      <ScrollView style={styles.categoryList}>
        {CATEGORIES.map((cat) => (
          <TouchableOpacity
            key={cat}
            style={[
              styles.categoryItem,
              category === cat && styles.categoryItemSelected,
            ]}
            onPress={() => {
              setCategory(cat);
              setShowCategoryPicker(false);
              if (Platform.OS !== 'web') {
                Haptics.selectionAsync();
              }
            }}
          >
            <Text
              style={[
                styles.categoryItemText,
                category === cat && styles.categoryItemTextSelected,
              ]}
            >
              {cat}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
  
  if (!receipt) {
    return null;
  }
  
  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 100 : 0}
    >
      <ScrollView style={styles.scrollView} contentContainerStyle={styles.content}>
        <View style={styles.imageContainer}>
          {imageUri ? (
            <Image source={{ uri: imageUri }} style={styles.receiptImage} />
          ) : (
            <TouchableOpacity
              style={styles.imagePlaceholder}
              onPress={handlePickImage}
            >
              <ImageIcon size={40} color={Colors.primary} />
              <Text style={styles.imagePlaceholderText}>{t('addReceipt')}</Text>
            </TouchableOpacity>
          )}
          
          {imageUri && (
            <TouchableOpacity
              style={styles.changeImageButton}
              onPress={handlePickImage}
            >
              <Text style={styles.changeImageText}>{t('changeImage')}</Text>
            </TouchableOpacity>
          )}
        </View>
        
        <View style={styles.formContainer}>
          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('vendor')}</Text>
            <View style={styles.inputContainer}>
              <TextInput
                style={styles.input}
                placeholder={t('enterVendorName')}
                value={vendor}
                onChangeText={setVendor}
                placeholderTextColor={Colors.textSecondary}
              />
            </View>
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('amount')}</Text>
            <View style={styles.inputContainer}>
              <Text style={styles.currencySymbol}>€</Text>
              <TextInput
                style={styles.input}
                placeholder="0.00"
                value={amount}
                onChangeText={setAmount}
                keyboardType="decimal-pad"
                placeholderTextColor={Colors.textSecondary}
              />
            </View>
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('date')}</Text>
            <View style={styles.inputContainer}>
              <Calendar size={20} color={Colors.textSecondary} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="YYYY-MM-DD"
                value={date}
                onChangeText={setDate}
                placeholderTextColor={Colors.textSecondary}
              />
            </View>
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('category')}</Text>
            <TouchableOpacity
              style={styles.inputContainer}
              onPress={() => setShowCategoryPicker(true)}
            >
              <Tag size={20} color={Colors.textSecondary} style={styles.inputIcon} />
              <Text style={styles.categoryText}>{category}</Text>
            </TouchableOpacity>
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>{t('notes')}</Text>
            <View style={[styles.inputContainer, styles.notesContainer]}>
              <FileText size={20} color={Colors.textSecondary} style={styles.inputIcon} />
              <TextInput
                style={[styles.input, styles.notesInput]}
                placeholder={t('addNotes')}
                value={notes}
                onChangeText={setNotes}
                multiline
                placeholderTextColor={Colors.textSecondary}
              />
            </View>
          </View>
        </View>
      </ScrollView>
      
      <View style={styles.footer}>
        <Button
          title={t('updateReceipt')}
          onPress={handleUpdateReceipt}
          loading={isSubmitting}
          disabled={isSubmitting || !imageUri || !vendor || !amount}
        />
      </View>
      
      {showCategoryPicker && renderCategoryPicker()}
    </KeyboardAvoidingView>
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
  },
  imageContainer: {
    alignItems: 'center',
    marginBottom: 24,
  },
  receiptImage: {
    width: '100%',
    height: 200,
    borderRadius: 12,
    marginBottom: 8,
  },
  imagePlaceholder: {
    width: '100%',
    height: 200,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: Colors.border,
    borderStyle: 'dashed',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Colors.card,
  },
  imagePlaceholderText: {
    marginTop: 12,
    fontSize: 16,
    color: Colors.primary,
    fontWeight: '500',
  },
  changeImageButton: {
    marginTop: 8,
  },
  changeImageText: {
    fontSize: 14,
    color: Colors.primary,
    fontWeight: '500',
  },
  formContainer: {
    gap: 16,
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 8,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.card,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: 12,
    height: 48,
  },
  inputIcon: {
    marginRight: 8,
  },
  currencySymbol: {
    fontSize: 16,
    color: Colors.textSecondary,
    marginRight: 8,
  },
  input: {
    flex: 1,
    height: '100%',
    fontSize: 16,
    color: Colors.text,
  },
  notesContainer: {
    height: 100,
    alignItems: 'flex-start',
    paddingVertical: 12,
  },
  notesInput: {
    height: '100%',
    textAlignVertical: 'top',
  },
  categoryText: {
    fontSize: 16,
    color: Colors.text,
  },
  footer: {
    padding: 20,
    paddingBottom: Platform.OS === 'ios' ? 40 : 20,
    borderTopWidth: 1,
    borderTopColor: Colors.border,
    backgroundColor: Colors.background,
  },
  categoryPickerContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: Colors.background,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    paddingTop: 16,
    paddingHorizontal: 20,
    paddingBottom: Platform.OS === 'ios' ? 40 : 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 5,
    maxHeight: '60%',
  },
  categoryPickerHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
    paddingBottom: 16,
    borderBottomWidth: 1,
    borderBottomColor: Colors.border,
  },
  categoryPickerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
  },
  categoryPickerClose: {
    fontSize: 16,
    color: Colors.primary,
    fontWeight: '500',
  },
  categoryList: {
    maxHeight: 300,
  },
  categoryItem: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    marginBottom: 8,
  },
  categoryItemSelected: {
    backgroundColor: Colors.primary + '20',
  },
  categoryItemText: {
    fontSize: 16,
    color: Colors.text,
  },
  categoryItemTextSelected: {
    color: Colors.primary,
    fontWeight: '600',
  },
});