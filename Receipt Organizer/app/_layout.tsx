import FontAwesome from "@expo/vector-icons/FontAwesome";
import { useFonts } from "expo-font";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { useEffect } from "react";
import { StatusBar } from "expo-status-bar";
import Colors from "@/constants/colors";
import { useTranslation } from "@/hooks/useTranslation";

export const unstable_settings = {
  initialRouteName: "(tabs)",
};

// Prevent the splash screen from auto-hiding before asset loading is complete.
SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    ...FontAwesome.font,
  });
  const { t } = useTranslation();

  useEffect(() => {
    if (error) {
      console.error(error);
      throw error;
    }
  }, [error]);

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  return (
    <>
      <StatusBar style="dark" />
      <RootLayoutNav />
    </>
  );
}

function RootLayoutNav() {
  const { t } = useTranslation();
  
  return (
    <Stack
      screenOptions={{
        headerBackTitle: t('back'),
        headerStyle: {
          backgroundColor: Colors.background,
        },
        headerTintColor: Colors.primary,
        headerTitleStyle: {
          fontWeight: '600',
        },
        contentStyle: {
          backgroundColor: Colors.background,
        },
      }}
    >
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen 
        name="receipt/[id]" 
        options={{ 
          title: t('receiptDetails'),
          presentation: "card",
        }} 
      />
      <Stack.Screen 
        name="receipt/edit/[id]" 
        options={{ 
          title: t('editReceipt'),
          presentation: "card",
        }} 
      />
      <Stack.Screen 
        name="camera" 
        options={{ 
          title: t('captureReceipt'),
          headerShown: false,
        }} 
      />
      <Stack.Screen 
        name="receipt/new" 
        options={{ 
          title: t('addReceipt'),
          presentation: "card",
        }} 
      />
      <Stack.Screen 
        name="reports/generate" 
        options={{ 
          title: t('generateReport'),
          presentation: "card",
        }} 
      />
      <Stack.Screen 
        name="reports/preview" 
        options={{ 
          title: t('reportPreview'),
          presentation: "card",
        }} 
      />
    </Stack>
  );
}