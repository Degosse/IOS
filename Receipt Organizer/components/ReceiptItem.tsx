import React from 'react';
import { View, Text, StyleSheet, Pressable, Image } from 'react-native';
import { useRouter } from 'expo-router';
import { Receipt } from '@/types/receipt';
import Colors from '@/constants/colors';
import { formatCurrency } from '@/utils/formatter';

interface ReceiptItemProps {
  receipt: Receipt;
}

export default function ReceiptItem({ receipt }: ReceiptItemProps) {
  const router = useRouter();
  
  const handlePress = () => {
    router.push(`/receipt/${receipt.id}`);
  };
  
  return (
    <Pressable 
      style={({ pressed }) => [
        styles.container,
        pressed && styles.pressed,
      ]}
      onPress={handlePress}
    >
      <View style={styles.imageContainer}>
        <Image 
          source={{ uri: receipt.imageUri }} 
          style={styles.image} 
          resizeMode="cover"
        />
      </View>
      
      <View style={styles.details}>
        <Text style={styles.vendor} numberOfLines={1}>
          {receipt.vendor}
        </Text>
        <Text style={styles.date}>
          {new Date(receipt.date).toLocaleDateString()}
        </Text>
        <View style={styles.categoryContainer}>
          <Text style={styles.category}>{receipt.category}</Text>
        </View>
      </View>
      
      <View style={styles.amountContainer}>
        <Text style={styles.amount}>{formatCurrency(receipt.amount)}</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: Colors.card,
    borderRadius: 12,
    marginBottom: 12,
    padding: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  pressed: {
    opacity: 0.7,
  },
  imageContainer: {
    width: 60,
    height: 60,
    borderRadius: 8,
    overflow: 'hidden',
    marginRight: 12,
  },
  image: {
    width: '100%',
    height: '100%',
  },
  details: {
    flex: 1,
    justifyContent: 'center',
  },
  vendor: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 4,
  },
  date: {
    fontSize: 14,
    color: Colors.textSecondary,
    marginBottom: 6,
  },
  categoryContainer: {
    backgroundColor: Colors.primary + '20',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    alignSelf: 'flex-start',
  },
  category: {
    fontSize: 12,
    color: Colors.primary,
    fontWeight: '500',
  },
  amountContainer: {
    justifyContent: 'center',
    paddingLeft: 12,
  },
  amount: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.text,
  },
});