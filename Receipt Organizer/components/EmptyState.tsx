import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Receipt } from 'lucide-react-native';
import Colors from '@/constants/colors';

interface EmptyStateProps {
  message?: string;
}

export default function EmptyState({ message = "No receipts found" }: EmptyStateProps) {
  return (
    <View style={styles.container}>
      <Receipt size={64} color={Colors.primary} />
      <Text style={styles.message}>{message}</Text>
      <Text style={styles.subMessage}>
        Tap the camera button to add your first receipt
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  message: {
    fontSize: 18,
    fontWeight: '600',
    color: Colors.text,
    marginTop: 16,
    marginBottom: 8,
  },
  subMessage: {
    fontSize: 14,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});