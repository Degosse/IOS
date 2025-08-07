import * as Sharing from 'expo-sharing';
import * as FileSystem from 'expo-file-system';
import { Platform } from 'react-native';

export async function shareFile(fileUri: string, mimeType: string = 'application/pdf') {
  try {
    if (Platform.OS === 'web') {
      // For web, we'd typically use a download link
      console.log('Sharing not fully supported on web');
      return false;
    }
    
    const canShare = await Sharing.isAvailableAsync();
    
    if (canShare) {
      await Sharing.shareAsync(fileUri, {
        mimeType,
        UTI: 'com.adobe.pdf', // iOS only
      });
      return true;
    } else {
      console.log('Sharing is not available on this platform');
      return false;
    }
  } catch (error) {
    console.error('Error sharing file:', error);
    return false;
  }
}

export async function saveBase64ToFile(
  base64Data: string, 
  fileName: string,
  directory: string = FileSystem.documentDirectory || ''
): Promise<string | null> {
  try {
    if (!directory) {
      console.error('No valid directory available');
      return null;
    }
    
    const fileUri = `${directory}${fileName}`;
    
    await FileSystem.writeAsStringAsync(fileUri, base64Data, {
      encoding: FileSystem.EncodingType.Base64,
    });
    
    return fileUri;
  } catch (error) {
    console.error('Error saving file:', error);
    return null;
  }
}

export async function deleteFile(fileUri: string): Promise<boolean> {
  try {
    await FileSystem.deleteAsync(fileUri);
    return true;
  } catch (error) {
    console.error('Error deleting file:', error);
    return false;
  }
}