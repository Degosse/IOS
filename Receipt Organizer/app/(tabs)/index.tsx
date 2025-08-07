import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, FlatList, RefreshControl, Pressable, Platform } from 'react-native';
import { useFocusEffect } from 'expo-router';
import { Receipt } from '@/types/receipt';
import { useReceiptStore } from '@/store/receiptStore';
import ReceiptItem from '@/components/ReceiptItem';
import EmptyState from '@/components/EmptyState';
import Colors from '@/constants/colors';
import { formatCurrency } from '@/utils/formatters';
import { Search, Filter } from 'lucide-react-native';

export default function ReceiptsScreen() {
  const { receipts } = useReceiptStore();
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredReceipts, setFilteredReceipts] = useState<Receipt[]>(receipts);
  
  useFocusEffect(
    useCallback(() => {
      // Filter receipts based on search query
      if (searchQuery) {
        const filtered = receipts.filter(receipt => 
          receipt.vendor.toLowerCase().includes(searchQuery.toLowerCase()) ||
          receipt.category.toLowerCase().includes(searchQuery.toLowerCase())
        );
        setFilteredReceipts(filtered);
      } else {
        setFilteredReceipts(receipts);
      }
    }, [receipts, searchQuery])
  );
  
  const onRefresh = useCallback(() => {
    setRefreshing(true);
    // Just simulate a refresh
    setTimeout(() => {
      setRefreshing(false);
    }, 1000);
  }, []);
  
  const totalAmount = filteredReceipts.reduce((sum, receipt) => sum + receipt.amount, 0);
  
  const renderHeader = () => (
    <View style={styles.header}>
      <View style={styles.searchContainer}>
        <Search size={18} color={Colors.textSecondary} style={styles.searchIcon} />
        <Pressable 
          style={styles.searchInput}
          onPress={() => {
            // In a real app, this would open a search modal or focus the input
            console.log('Open search');
          }}
        >
          <Text style={styles.searchPlaceholder}>Search receipts...</Text>
        </Pressable>
        <Pressable style={styles.filterButton}>
          <Filter size={18} color={Colors.textSecondary} />
        </Pressable>
      </View>
      
      <View style={styles.summaryContainer}>
        <View style={styles.summaryItem}>
          <Text style={styles.summaryLabel}>Total Expenses</Text>
          <Text style={styles.summaryValue}>{formatCurrency(totalAmount)}</Text>
        </View>
        <View style={styles.summaryItem}>
          <Text style={styles.summaryLabel}>Receipts</Text>
          <Text style={styles.summaryValue}>{filteredReceipts.length}</Text>
        </View>
      </View>
    </View>
  );
  
  if (receipts.length === 0) {
    return <EmptyState />;
  }
  
  return (
    <View style={styles.container}>
      <FlatList
        data={filteredReceipts}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <ReceiptItem receipt={item} />}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={renderHeader}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            colors={[Colors.primary]}
            tintColor={Colors.primary}
          />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>No receipts found</Text>
          </View>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  listContent: {
    padding: 16,
    paddingBottom: Platform.OS === 'ios' ? 100 : 80,
  },
  header: {
    marginBottom: 16,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.card,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  searchIcon: {
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    height: 36,
    justifyContent: 'center',
  },
  searchPlaceholder: {
    color: Colors.textSecondary,
    fontSize: 15,
  },
  filterButton: {
    padding: 4,
  },
  summaryContainer: {
    flexDirection: 'row',
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  summaryItem: {
    flex: 1,
  },
  summaryLabel: {
    fontSize: 14,
    color: Colors.textSecondary,
    marginBottom: 4,
  },
  summaryValue: {
    fontSize: 20,
    fontWeight: '700',
    color: Colors.text,
  },
  emptyContainer: {
    padding: 24,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: Colors.textSecondary,
  },
});