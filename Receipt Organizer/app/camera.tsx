import React, { useState, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Platform, Alert, Image, Dimensions } from 'react-native';
import { useRouter } from 'expo-router';
import { CameraView, CameraType, useCameraPermissions } from 'expo-camera';
import { X, Camera, RotateCcw, Check, RotateCw, Move } from 'lucide-react-native';
import Colors from '@/constants/colors';
import * as Haptics from 'expo-haptics';
import * as ImageManipulator from 'expo-image-manipulator';
import { convertImageToPdf } from '@/services/pdfService';
import { useTranslation } from '@/hooks/useTranslation';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

export default function CameraScreen() {
  const router = useRouter();
  const { t } = useTranslation();
  const [permission, requestPermission] = useCameraPermissions();
  const [facing, setFacing] = useState<CameraType>('back');
  const [isTakingPicture, setIsTakingPicture] = useState(false);
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [isCropping, setIsCropping] = useState(false);
  const [cropMode, setCropMode] = useState<'rectangle' | 'diagonal'>('rectangle');
  const [cropArea, setCropArea] = useState({
    x: screenWidth * 0.1,
    y: screenHeight * 0.2,
    width: screenWidth * 0.8,
    height: screenHeight * 0.4,
    rotation: 0,
  });
  const cameraRef = useRef<any>(null);
  
  const handleClose = () => {
    router.back();
  };
  
  const toggleCameraFacing = () => {
    setFacing(current => (current === 'back' ? 'front' : 'back'));
    if (Platform.OS !== 'web') {
      Haptics.selectionAsync();
    }
  };
  
  const takePicture = async () => {
    if (isTakingPicture || !cameraRef.current) return;
    
    try {
      setIsTakingPicture(true);
      if (Platform.OS !== 'web') {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      }
      
      // Take a picture using the camera
      const photo = await cameraRef.current.takePictureAsync({
        quality: 0.8,
        base64: false,
      });
      
      if (photo && photo.uri) {
        setCapturedImage(photo.uri);
        setIsCropping(true);
      } else {
        // Fallback for demo
        const fallbackUri = 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80';
        setCapturedImage(fallbackUri);
        setIsCropping(true);
      }
    } catch (error) {
      console.error('Error taking picture:', error);
      Alert.alert(t('error'), 'Failed to take picture. Please try again.');
      
      // Fallback for demo
      const fallbackUri = 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80';
      setCapturedImage(fallbackUri);
      setIsCropping(true);
    } finally {
      setIsTakingPicture(false);
    }
  };
  
  const handleCropConfirm = async () => {
    if (!capturedImage) return;
    
    try {
      if (Platform.OS !== 'web') {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      }
      
      // Get image dimensions
      const imageInfo = await ImageManipulator.manipulateAsync(
        capturedImage,
        [],
        { format: ImageManipulator.SaveFormat.JPEG }
      );
      
      // Calculate crop parameters based on the crop area
      const imageWidth = imageInfo.width;
      const imageHeight = imageInfo.height;
      
      // Convert screen coordinates to image coordinates
      const scaleX = imageWidth / screenWidth;
      const scaleY = imageHeight / screenHeight;
      
      const cropX = Math.max(0, cropArea.x * scaleX);
      const cropY = Math.max(0, cropArea.y * scaleY);
      const cropWidth = Math.min(imageWidth - cropX, cropArea.width * scaleX);
      const cropHeight = Math.min(imageHeight - cropY, cropArea.height * scaleY);
      
      // Prepare manipulations array
      const manipulations: ImageManipulator.Action[] = [];
      
      // Add rotation if in diagonal mode
      if (cropMode === 'diagonal' && cropArea.rotation !== 0) {
        manipulations.push({ rotate: cropArea.rotation });
      }
      
      // Add crop
      manipulations.push({
        crop: {
          originX: cropX,
          originY: cropY,
          width: cropWidth,
          height: cropHeight,
        },
      });
      
      // Apply manipulations
      const croppedImage = await ImageManipulator.manipulateAsync(
        capturedImage,
        manipulations,
        {
          compress: 0.8,
          format: ImageManipulator.SaveFormat.JPEG,
        }
      );
      
      // Convert to PDF
      const pdfUri = await convertImageToPdf(croppedImage.uri);
      
      // Navigate to receipt form with cropped image
      router.push({
        pathname: '/receipt/new',
        params: {
          imageUri: croppedImage.uri,
          pdfUri: pdfUri,
          useOCR: 'true'
        },
      });
    } catch (error) {
      console.error('Error cropping image:', error);
      Alert.alert(t('error'), 'Failed to crop image. Please try again.');
    }
  };
  
  const handleRetake = () => {
    setCapturedImage(null);
    setIsCropping(false);
    setCropMode('rectangle');
    // Reset crop area
    setCropArea({
      x: screenWidth * 0.1,
      y: screenHeight * 0.2,
      width: screenWidth * 0.8,
      height: screenHeight * 0.4,
      rotation: 0,
    });
  };
  
  const toggleCropMode = () => {
    setCropMode(current => current === 'rectangle' ? 'diagonal' : 'rectangle');
    if (Platform.OS !== 'web') {
      Haptics.selectionAsync();
    }
  };
  
  const handleCornerDrag = (corner: 'topLeft' | 'topRight' | 'bottomLeft' | 'bottomRight', deltaX: number, deltaY: number) => {
    setCropArea(prev => {
      let newArea = { ...prev };
      
      switch (corner) {
        case 'topLeft':
          newArea.x = Math.max(0, Math.min(prev.x + deltaX, prev.x + prev.width - 50));
          newArea.y = Math.max(0, Math.min(prev.y + deltaY, prev.y + prev.height - 50));
          newArea.width = prev.width - deltaX;
          newArea.height = prev.height - deltaY;
          break;
        case 'topRight':
          newArea.y = Math.max(0, Math.min(prev.y + deltaY, prev.y + prev.height - 50));
          newArea.width = Math.max(50, Math.min(prev.width + deltaX, screenWidth - prev.x));
          newArea.height = prev.height - deltaY;
          break;
        case 'bottomLeft':
          newArea.x = Math.max(0, Math.min(prev.x + deltaX, prev.x + prev.width - 50));
          newArea.width = prev.width - deltaX;
          newArea.height = Math.max(50, Math.min(prev.height + deltaY, screenHeight - prev.y));
          break;
        case 'bottomRight':
          newArea.width = Math.max(50, Math.min(prev.width + deltaX, screenWidth - prev.x));
          newArea.height = Math.max(50, Math.min(prev.height + deltaY, screenHeight - prev.y));
          break;
      }
      
      return newArea;
    });
  };
  
  const handleRotationChange = (delta: number) => {
    setCropArea(prev => ({
      ...prev,
      rotation: (prev.rotation + delta) % 360
    }));
  };
  
  if (!permission) {
    return (
      <View style={styles.container}>
        <Text>Requesting camera permission...</Text>
      </View>
    );
  }
  
  if (!permission.granted) {
    return (
      <View style={styles.container}>
        <Text style={styles.permissionText}>
          {t('cameraPermission')}
        </Text>
        <TouchableOpacity
          style={styles.permissionButton}
          onPress={requestPermission}
        >
          <Text style={styles.permissionButtonText}>{t('grantPermission')}</Text>
        </TouchableOpacity>
      </View>
    );
  }
  
  if (isCropping && capturedImage) {
    return (
      <View style={styles.container}>
        <View style={styles.cropContainer}>
          <Image source={{ uri: capturedImage }} style={styles.cropImage} resizeMode="cover" />
          
          {/* Crop overlay */}
          <View style={styles.cropOverlay}>
            {/* Crop area */}
            <View
              style={[
                styles.cropArea,
                {
                  left: cropArea.x,
                  top: cropArea.y,
                  width: cropArea.width,
                  height: cropArea.height,
                  transform: cropMode === 'diagonal' ? [{ rotate: `${cropArea.rotation}deg` }] : undefined,
                },
              ]}
            >
              {/* Corner handles */}
              <TouchableOpacity
                style={[styles.cropHandle, styles.topLeft]}
                onPressIn={() => {}}
              />
              <TouchableOpacity
                style={[styles.cropHandle, styles.topRight]}
                onPressIn={() => {}}
              />
              <TouchableOpacity
                style={[styles.cropHandle, styles.bottomLeft]}
                onPressIn={() => {}}
              />
              <TouchableOpacity
                style={[styles.cropHandle, styles.bottomRight]}
                onPressIn={() => {}}
              />
              
              {/* Rotation handle for diagonal mode */}
              {cropMode === 'diagonal' && (
                <TouchableOpacity
                  style={styles.rotationHandle}
                  onPress={() => handleRotationChange(15)}
                >
                  <RotateCw size={16} color="#FFFFFF" />
                </TouchableOpacity>
              )}
            </View>
          </View>
          
          {/* Crop controls */}
          <View style={styles.cropControls}>
            <TouchableOpacity style={styles.cropButton} onPress={handleRetake}>
              <RotateCw size={24} color="#FFFFFF" />
              <Text style={styles.cropButtonText}>Retake</Text>
            </TouchableOpacity>
            
            <TouchableOpacity style={styles.cropButton} onPress={toggleCropMode}>
              <Move size={24} color="#FFFFFF" />
              <Text style={styles.cropButtonText}>
                {cropMode === 'rectangle' ? 'Diagonal' : 'Rectangle'}
              </Text>
            </TouchableOpacity>
            
            <TouchableOpacity style={[styles.cropButton, styles.confirmButton]} onPress={handleCropConfirm}>
              <Check size={24} color="#FFFFFF" />
              <Text style={styles.cropButtonText}>Confirm</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  }
  
  return (
    <View style={styles.container}>
      <CameraView
        ref={cameraRef}
        style={styles.camera}
        facing={facing}
      >
        <View style={styles.overlay}>
          <View style={styles.header}>
            <TouchableOpacity
              style={styles.closeButton}
              onPress={handleClose}
            >
              <X size={24} color="#FFFFFF" />
            </TouchableOpacity>
            
            <Text style={styles.headerTitle}>{t('captureReceipt')}</Text>
            
            <TouchableOpacity
              style={styles.flipButton}
              onPress={toggleCameraFacing}
            >
              <RotateCcw size={24} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
          
          {/* Rectangular guide frame for receipt */}
          <View style={styles.guideFrameContainer}>
            <View style={styles.guideFrame}>
              <View style={[styles.guideCorner, styles.topLeftGuide]} />
              <View style={[styles.guideCorner, styles.topRightGuide]} />
              <View style={[styles.guideCorner, styles.bottomLeftGuide]} />
              <View style={[styles.guideCorner, styles.bottomRightGuide]} />
            </View>
            <Text style={styles.guideText}>{t('alignReceiptWithinFrame')}</Text>
          </View>
          
          <View style={styles.footer}>
            <View style={styles.captureContainer}>
              <TouchableOpacity
                style={[
                  styles.captureButton,
                  isTakingPicture && styles.captureButtonDisabled,
                ]}
                onPress={takePicture}
                disabled={isTakingPicture}
              >
                <View style={styles.captureButtonInner} />
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </CameraView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  camera: {
    flex: 1,
  },
  overlay: {
    flex: 1,
    backgroundColor: 'transparent',
    flexDirection: 'column',
    justifyContent: 'space-between',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    paddingTop: Platform.OS === 'ios' ? 60 : 20,
  },
  closeButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '600',
  },
  flipButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  guideFrameContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  guideFrame: {
    width: screenWidth * 0.8,
    height: screenWidth * 1.2,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.5)',
    borderRadius: 8,
    position: 'relative',
  },
  guideText: {
    color: '#FFFFFF',
    fontSize: 14,
    marginTop: 12,
    textAlign: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 4,
  },
  guideCorner: {
    position: 'absolute',
    width: 20,
    height: 20,
    borderColor: '#FFFFFF',
  },
  topLeftGuide: {
    top: -2,
    left: -2,
    borderTopWidth: 2,
    borderLeftWidth: 2,
    borderTopLeftRadius: 8,
  },
  topRightGuide: {
    top: -2,
    right: -2,
    borderTopWidth: 2,
    borderRightWidth: 2,
    borderTopRightRadius: 8,
  },
  bottomLeftGuide: {
    bottom: -2,
    left: -2,
    borderBottomWidth: 2,
    borderLeftWidth: 2,
    borderBottomLeftRadius: 8,
  },
  bottomRightGuide: {
    bottom: -2,
    right: -2,
    borderBottomWidth: 2,
    borderRightWidth: 2,
    borderBottomRightRadius: 8,
  },
  footer: {
    padding: 20,
    paddingBottom: Platform.OS === 'ios' ? 40 : 20,
  },
  captureContainer: {
    alignItems: 'center',
  },
  captureButton: {
    width: 70,
    height: 70,
    borderRadius: 35,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  captureButtonDisabled: {
    opacity: 0.5,
  },
  captureButtonInner: {
    width: 54,
    height: 54,
    borderRadius: 27,
    backgroundColor: '#FFFFFF',
  },
  permissionText: {
    fontSize: 16,
    color: Colors.text,
    textAlign: 'center',
    marginBottom: 20,
    padding: 20,
  },
  permissionButton: {
    backgroundColor: Colors.primary,
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    marginHorizontal: 20,
  },
  permissionButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  cropContainer: {
    flex: 1,
    backgroundColor: '#000',
  },
  cropImage: {
    width: '100%',
    height: '100%',
  },
  cropOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  cropArea: {
    position: 'absolute',
    borderWidth: 2,
    borderColor: Colors.primary,
    borderStyle: 'dashed',
  },
  cropHandle: {
    position: 'absolute',
    width: 20,
    height: 20,
    backgroundColor: Colors.primary,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  topLeft: {
    top: -10,
    left: -10,
  },
  topRight: {
    top: -10,
    right: -10,
  },
  bottomLeft: {
    bottom: -10,
    left: -10,
  },
  bottomRight: {
    bottom: -10,
    right: -10,
  },
  rotationHandle: {
    position: 'absolute',
    top: -30,
    right: -10,
    width: 24,
    height: 24,
    backgroundColor: Colors.secondary,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  cropControls: {
    position: 'absolute',
    bottom: Platform.OS === 'ios' ? 50 : 30,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 20,
  },
  cropButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
  },
  confirmButton: {
    backgroundColor: Colors.primary,
  },
  cropButtonText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 6,
  },
});