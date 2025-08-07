import { useCallback } from 'react';
import { useLanguageStore } from '@/store/languageStore';
import { t } from '@/constants/translations';

export function useTranslation() {
  const { language } = useLanguageStore();
  
  const translate = useCallback((key: Parameters<typeof t>[0]) => {
    return t(key, language);
  }, [language]);
  
  return { t: translate, language };
}