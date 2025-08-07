import { Language } from '@/store/languageStore';

export type TranslationKey = 
  // Common
  | 'back'
  | 'cancel'
  | 'save'
  | 'edit'
  | 'delete'
  | 'share'
  | 'download'
  | 'print'
  | 'ok'
  | 'error'
  | 'success'
  | 'loading'
  | 'noData'
  
  // Tabs
  | 'receipts'
  | 'add'
  | 'reports'
  | 'settings'
  
  // Receipts
  | 'totalExpenses'
  | 'searchReceipts'
  | 'noReceiptsFound'
  | 'receiptDetails'
  | 'editReceipt'
  | 'deleteReceipt'
  | 'deleteReceiptConfirm'
  | 'shareReceipt'
  | 'saveAsPdf'
  
  // Add Receipt
  | 'addReceipt'
  | 'captureReceipt'
  | 'takePhoto'
  | 'chooseFromGallery'
  | 'selectFromGallery'
  | 'uploadImage'
  | 'uploadPdf'
  | 'manualEntry'
  | 'useCamera'
  | 'useGallery'
  | 'aiPowered'
  | 'aiPoweredTip'
  | 'alignReceiptWithinFrame'
  | 'cropReceipt'
  | 'confirmCrop'
  | 'rectangleCropMode'
  | 'autoCropMode'
  | 'grantPermission'
  | 'changeImage'
  | 'changePDF'
  | 'enterVendorName'
  | 'enterManually'
  | 'cameraPermission'
  | 'adjustCrop'
  | 'pdfPreview'
  
  // Receipt Form
  | 'vendor'
  | 'amount'
  | 'date'
  | 'category'
  | 'notes'
  | 'addNotes'
  | 'selectCategory'
  | 'saveReceipt'
  | 'updateReceipt'
  | 'missingImage'
  | 'missingVendor'
  | 'invalidAmount'
  
  // Receipt Analysis
  | 'analyzingReceipt'
  | 'analysisFailed'
  | 'analysisComplete'
  | 'tryAgain'
  | 'detailsExtracted'
  
  // Reports
  | 'generateReport'
  | 'reportPeriod'
  | 'month'
  | 'quarter'
  | 'year'
  | 'custom'
  | 'startDate'
  | 'endDate'
  | 'reportOptions'
  | 'includeImages'
  | 'reportTitle'
  | 'reportSummary'
  | 'period'
  | 'generatePdfReport'
  | 'reportPreview'
  | 'expenseReport'
  | 'business'
  | 'taxId'
  | 'summary'
  | 'expensesByCategory'
  | 'totalExpensesReport'
  | 'signature'
  | 'page'
  | 'of'
  
  // Settings
  | 'preferences'
  | 'language'
  | 'english'
  | 'dutch'
  | 'german'
  | 'french'
  | 'notifications'
  | 'notificationsDescription'
  | 'support'
  | 'helpAndSupport'
  | 'helpAndSupportDescription'
  | 'data'
  | 'clearAllData'
  | 'clearAllDataConfirm'
  | 'version';

type Translations = {
  [key in Language]: {
    [key in TranslationKey]: string;
  };
};

export const translations: Translations = {
  en: {
    // Common
    back: 'Back',
    cancel: 'Cancel',
    save: 'Save',
    edit: 'Edit',
    delete: 'Delete',
    share: 'Share',
    download: 'Download',
    print: 'Print',
    ok: 'OK',
    error: 'Error',
    success: 'Success',
    loading: 'Loading',
    noData: 'No data available',
    
    // Tabs
    receipts: 'Receipts',
    add: 'Add',
    reports: 'Reports',
    settings: 'Settings',
    
    // Receipts
    totalExpenses: 'Total Expenses',
    searchReceipts: 'Search receipts...',
    noReceiptsFound: 'No receipts found',
    receiptDetails: 'Receipt Details',
    editReceipt: 'Edit Receipt',
    deleteReceipt: 'Delete Receipt',
    deleteReceiptConfirm: 'Are you sure you want to delete this receipt?',
    shareReceipt: 'Share Receipt',
    saveAsPdf: 'Save as PDF',
    
    // Add Receipt
    addReceipt: 'Add a Receipt',
    captureReceipt: 'Capture Receipt',
    takePhoto: 'Take Photo',
    chooseFromGallery: 'Choose from Gallery',
    selectFromGallery: 'Select a receipt image from your gallery',
    uploadImage: 'Upload Image',
    uploadPdf: 'Upload PDF',
    manualEntry: 'Manual Entry',
    useCamera: 'Use your camera to capture a receipt',
    useGallery: 'Select a receipt image from your gallery',
    aiPowered: 'AI-Powered',
    aiPoweredTip: 'Your receipts will be automatically analyzed using AI technology to extract vendor, amount, and date information.',
    alignReceiptWithinFrame: 'Align receipt within frame',
    cropReceipt: 'Crop Receipt',
    confirmCrop: 'Confirm Crop',
    rectangleCropMode: 'Using rectangular crop mode - perfect for standard receipts',
    autoCropMode: 'Using auto crop mode - drag corners to adjust',
    grantPermission: 'Grant Permission',
    changeImage: 'Change Image',
    changePDF: 'Change PDF',
    enterVendorName: 'Enter vendor name',
    enterManually: 'Enter Manually',
    cameraPermission: 'We need your permission to use the camera',
    adjustCrop: 'Adjust Crop',
    pdfPreview: 'PDF Preview',
    
    // Receipt Form
    vendor: 'Vendor',
    amount: 'Amount',
    date: 'Date',
    category: 'Category',
    notes: 'Notes',
    addNotes: 'Add notes (optional)',
    selectCategory: 'Select Category',
    saveReceipt: 'Save Receipt',
    updateReceipt: 'Update Receipt',
    missingImage: 'Please add a receipt image',
    missingVendor: 'Please enter the vendor name',
    invalidAmount: 'Please enter a valid amount',
    
    // Receipt Analysis
    analyzingReceipt: 'Analyzing receipt...',
    analysisFailed: 'Analysis Failed',
    analysisComplete: 'Analysis Complete',
    tryAgain: 'Try Again',
    detailsExtracted: 'Receipt details extracted successfully!',
    
    // Reports
    generateReport: 'Generate Report',
    reportPeriod: 'Report Period',
    month: 'Month',
    quarter: 'Quarter',
    year: 'Year',
    custom: 'Custom',
    startDate: 'Start Date',
    endDate: 'End Date',
    reportOptions: 'Report Options',
    includeImages: 'Include Receipt Images',
    reportTitle: 'Report Title',
    reportSummary: 'Report Summary',
    period: 'Period',
    generatePdfReport: 'Generate PDF Report',
    reportPreview: 'Report Preview',
    expenseReport: 'EXPENSE REPORT',
    business: 'BUSINESS',
    taxId: 'TAX ID',
    summary: 'SUMMARY',
    expensesByCategory: 'EXPENSES BY CATEGORY',
    totalExpensesReport: 'TOTAL EXPENSES',
    signature: 'Signature',
    page: 'Page',
    of: 'of',
    
    // Settings
    preferences: 'Preferences',
    language: 'Language',
    english: 'English',
    dutch: 'Dutch',
    german: 'German',
    french: 'French',
    notifications: 'Notifications',
    notificationsDescription: 'Receive reminders for reports',
    support: 'Support',
    helpAndSupport: 'Help & Support',
    helpAndSupportDescription: 'FAQs, contact us, privacy policy',
    data: 'Data',
    clearAllData: 'Clear All Data',
    clearAllDataConfirm: 'Are you sure you want to delete all receipts? This action cannot be undone.',
    version: 'Version'
  },
  nl: {
    // Common
    back: 'Terug',
    cancel: 'Annuleren',
    save: 'Opslaan',
    edit: 'Bewerken',
    delete: 'Verwijderen',
    share: 'Delen',
    download: 'Downloaden',
    print: 'Afdrukken',
    ok: 'OK',
    error: 'Fout',
    success: 'Succes',
    loading: 'Laden',
    noData: 'Geen gegevens beschikbaar',
    
    // Tabs
    receipts: 'Bonnetjes',
    add: 'Toevoegen',
    reports: 'Rapporten',
    settings: 'Instellingen',
    
    // Receipts
    totalExpenses: 'Totale Uitgaven',
    searchReceipts: 'Zoek bonnetjes...',
    noReceiptsFound: 'Geen bonnetjes gevonden',
    receiptDetails: 'Bonnetje Details',
    editReceipt: 'Bonnetje Bewerken',
    deleteReceipt: 'Bonnetje Verwijderen',
    deleteReceiptConfirm: 'Weet je zeker dat je dit bonnetje wilt verwijderen?',
    shareReceipt: 'Bonnetje Delen',
    saveAsPdf: 'Opslaan als PDF',
    
    // Add Receipt
    addReceipt: 'Bonnetje Toevoegen',
    captureReceipt: 'Bonnetje Vastleggen',
    takePhoto: 'Foto Maken',
    chooseFromGallery: 'Kies uit Galerij',
    selectFromGallery: 'Selecteer een bonnetje uit je galerij',
    uploadImage: 'Afbeelding Uploaden',
    uploadPdf: 'PDF Uploaden',
    manualEntry: 'Handmatige Invoer',
    useCamera: 'Gebruik je camera om een bonnetje vast te leggen',
    useGallery: 'Selecteer een bonnetje uit je galerij',
    aiPowered: 'AI-Ondersteund',
    aiPoweredTip: 'Je bonnetjes worden automatisch geanalyseerd met AI-technologie om verkoper, bedrag en datum te extraheren.',
    alignReceiptWithinFrame: 'Plaats bonnetje binnen het kader',
    cropReceipt: 'Bonnetje Bijsnijden',
    confirmCrop: 'Bijsnijden Bevestigen',
    rectangleCropMode: 'Rechthoekige bijsnijmodus - perfect voor standaard bonnetjes',
    autoCropMode: 'Automatische bijsnijmodus - sleep hoeken om aan te passen',
    grantPermission: 'Toestemming Verlenen',
    changeImage: 'Afbeelding Wijzigen',
    changePDF: 'PDF Wijzigen',
    enterVendorName: 'Voer verkoper naam in',
    enterManually: 'Handmatig Invoeren',
    cameraPermission: 'We hebben je toestemming nodig om de camera te gebruiken',
    adjustCrop: 'Bijsnijden Aanpassen',
    pdfPreview: 'PDF Voorbeeld',
    
    // Receipt Form
    vendor: 'Verkoper',
    amount: 'Bedrag',
    date: 'Datum',
    category: 'Categorie',
    notes: 'Notities',
    addNotes: 'Notities toevoegen (optioneel)',
    selectCategory: 'Selecteer Categorie',
    saveReceipt: 'Bonnetje Opslaan',
    updateReceipt: 'Bonnetje Bijwerken',
    missingImage: 'Voeg een afbeelding van het bonnetje toe',
    missingVendor: 'Voer de naam van de verkoper in',
    invalidAmount: 'Voer een geldig bedrag in',
    
    // Receipt Analysis
    analyzingReceipt: 'Bonnetje analyseren...',
    analysisFailed: 'Analyse Mislukt',
    analysisComplete: 'Analyse Voltooid',
    tryAgain: 'Opnieuw Proberen',
    detailsExtracted: 'Bonnetje details succesvol geëxtraheerd!',
    
    // Reports
    generateReport: 'Rapport Genereren',
    reportPeriod: 'Rapportperiode',
    month: 'Maand',
    quarter: 'Kwartaal',
    year: 'Jaar',
    custom: 'Aangepast',
    startDate: 'Startdatum',
    endDate: 'Einddatum',
    reportOptions: 'Rapport Opties',
    includeImages: 'Bonnetje Afbeeldingen Toevoegen',
    reportTitle: 'Rapport Titel',
    reportSummary: 'Rapport Samenvatting',
    period: 'Periode',
    generatePdfReport: 'PDF Rapport Genereren',
    reportPreview: 'Rapport Voorbeeld',
    expenseReport: 'UITGAVENRAPPORT',
    business: 'BEDRIJF',
    taxId: 'BTW-NUMMER',
    summary: 'SAMENVATTING',
    expensesByCategory: 'UITGAVEN PER CATEGORIE',
    totalExpensesReport: 'TOTALE UITGAVEN',
    signature: 'Handtekening',
    page: 'Pagina',
    of: 'van',
    
    // Settings
    preferences: 'Voorkeuren',
    language: 'Taal',
    english: 'Engels',
    dutch: 'Nederlands',
    german: 'Duits',
    french: 'Frans',
    notifications: 'Notificaties',
    notificationsDescription: 'Ontvang herinneringen voor rapporten',
    support: 'Ondersteuning',
    helpAndSupport: 'Hulp & Ondersteuning',
    helpAndSupportDescription: "FAQ's, neem contact op, privacybeleid",
    data: 'Gegevens',
    clearAllData: 'Alle Gegevens Wissen',
    clearAllDataConfirm: 'Weet je zeker dat je alle bonnetjes wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.',
    version: 'Versie'
  },
  de: {
    // Common
    back: 'Zurück',
    cancel: 'Abbrechen',
    save: 'Speichern',
    edit: 'Bearbeiten',
    delete: 'Löschen',
    share: 'Teilen',
    download: 'Herunterladen',
    print: 'Drucken',
    ok: 'OK',
    error: 'Fehler',
    success: 'Erfolg',
    loading: 'Laden',
    noData: 'Keine Daten verfügbar',
    
    // Tabs
    receipts: 'Belege',
    add: 'Hinzufügen',
    reports: 'Berichte',
    settings: 'Einstellungen',
    
    // Receipts
    totalExpenses: 'Gesamtausgaben',
    searchReceipts: 'Belege suchen...',
    noReceiptsFound: 'Keine Belege gefunden',
    receiptDetails: 'Beleg Details',
    editReceipt: 'Beleg Bearbeiten',
    deleteReceipt: 'Beleg Löschen',
    deleteReceiptConfirm: 'Sind Sie sicher, dass Sie diesen Beleg löschen möchten?',
    shareReceipt: 'Beleg Teilen',
    saveAsPdf: 'Als PDF Speichern',
    
    // Add Receipt
    addReceipt: 'Beleg Hinzufügen',
    captureReceipt: 'Beleg Erfassen',
    takePhoto: 'Foto Aufnehmen',
    chooseFromGallery: 'Aus Galerie Wählen',
    selectFromGallery: 'Wählen Sie ein Belegbild aus Ihrer Galerie',
    uploadImage: 'Bild Hochladen',
    uploadPdf: 'PDF Hochladen',
    manualEntry: 'Manuelle Eingabe',
    useCamera: 'Verwenden Sie Ihre Kamera, um einen Beleg zu erfassen',
    useGallery: 'Wählen Sie ein Belegbild aus Ihrer Galerie',
    aiPowered: 'KI-Unterstützt',
    aiPoweredTip: 'Ihre Belege werden automatisch mit KI-Technologie analysiert, um Anbieter, Betrag und Datum zu extrahieren.',
    alignReceiptWithinFrame: 'Beleg im Rahmen ausrichten',
    cropReceipt: 'Beleg Zuschneiden',
    confirmCrop: 'Zuschnitt Bestätigen',
    rectangleCropMode: 'Rechteckiger Zuschnittmodus - perfekt für Standardbelege',
    autoCropMode: 'Automatischer Zuschnittmodus - Ecken ziehen zum Anpassen',
    grantPermission: 'Berechtigung Erteilen',
    changeImage: 'Bild Ändern',
    changePDF: 'PDF Ändern',
    enterVendorName: 'Anbietername eingeben',
    enterManually: 'Manuell Eingeben',
    cameraPermission: 'Wir benötigen Ihre Berechtigung zur Kameranutzung',
    adjustCrop: 'Zuschnitt Anpassen',
    pdfPreview: 'PDF Vorschau',
    
    // Receipt Form
    vendor: 'Anbieter',
    amount: 'Betrag',
    date: 'Datum',
    category: 'Kategorie',
    notes: 'Notizen',
    addNotes: 'Notizen hinzufügen (optional)',
    selectCategory: 'Kategorie Auswählen',
    saveReceipt: 'Beleg Speichern',
    updateReceipt: 'Beleg Aktualisieren',
    missingImage: 'Bitte fügen Sie ein Belegbild hinzu',
    missingVendor: 'Bitte geben Sie den Anbieternamen ein',
    invalidAmount: 'Bitte geben Sie einen gültigen Betrag ein',
    
    // Receipt Analysis
    analyzingReceipt: 'Beleg wird analysiert...',
    analysisFailed: 'Analyse Fehlgeschlagen',
    analysisComplete: 'Analyse Abgeschlossen',
    tryAgain: 'Erneut Versuchen',
    detailsExtracted: 'Belegdetails erfolgreich extrahiert!',
    
    // Reports
    generateReport: 'Bericht Erstellen',
    reportPeriod: 'Berichtszeitraum',
    month: 'Monat',
    quarter: 'Quartal',
    year: 'Jahr',
    custom: 'Benutzerdefiniert',
    startDate: 'Startdatum',
    endDate: 'Enddatum',
    reportOptions: 'Berichtsoptionen',
    includeImages: 'Belegbilder Einschließen',
    reportTitle: 'Berichtstitel',
    reportSummary: 'Berichtszusammenfassung',
    period: 'Zeitraum',
    generatePdfReport: 'PDF-Bericht Erstellen',
    reportPreview: 'Berichtsvorschau',
    expenseReport: 'AUSGABENBERICHT',
    business: 'UNTERNEHMEN',
    taxId: 'STEUERNUMMER',
    summary: 'ZUSAMMENFASSUNG',
    expensesByCategory: 'AUSGABEN NACH KATEGORIE',
    totalExpensesReport: 'GESAMTAUSGABEN',
    signature: 'Unterschrift',
    page: 'Seite',
    of: 'von',
    
    // Settings
    preferences: 'Einstellungen',
    language: 'Sprache',
    english: 'Englisch',
    dutch: 'Niederländisch',
    german: 'Deutsch',
    french: 'Französisch',
    notifications: 'Benachrichtigungen',
    notificationsDescription: 'Erinnerungen für Berichte erhalten',
    support: 'Support',
    helpAndSupport: 'Hilfe & Support',
    helpAndSupportDescription: 'FAQs, Kontakt, Datenschutzrichtlinie',
    data: 'Daten',
    clearAllData: 'Alle Daten Löschen',
    clearAllDataConfirm: 'Sind Sie sicher, dass Sie alle Belege löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.',
    version: 'Version'
  },
  fr: {
    // Common
    back: 'Retour',
    cancel: 'Annuler',
    save: 'Enregistrer',
    edit: 'Modifier',
    delete: 'Supprimer',
    share: 'Partager',
    download: 'Télécharger',
    print: 'Imprimer',
    ok: 'OK',
    error: 'Erreur',
    success: 'Succès',
    loading: 'Chargement',
    noData: 'Aucune donnée disponible',
    
    // Tabs
    receipts: 'Reçus',
    add: 'Ajouter',
    reports: 'Rapports',
    settings: 'Paramètres',
    
    // Receipts
    totalExpenses: 'Dépenses Totales',
    searchReceipts: 'Rechercher des reçus...',
    noReceiptsFound: 'Aucun reçu trouvé',
    receiptDetails: 'Détails du Reçu',
    editReceipt: 'Modifier le Reçu',
    deleteReceipt: 'Supprimer le Reçu',
    deleteReceiptConfirm: 'Êtes-vous sûr de vouloir supprimer ce reçu?',
    shareReceipt: 'Partager le Reçu',
    saveAsPdf: 'Enregistrer en PDF',
    
    // Add Receipt
    addReceipt: 'Ajouter un Reçu',
    captureReceipt: 'Capturer un Reçu',
    takePhoto: 'Prendre une Photo',
    chooseFromGallery: 'Choisir dans la Galerie',
    selectFromGallery: 'Sélectionnez une image de reçu dans votre galerie',
    uploadImage: 'Télécharger une Image',
    uploadPdf: 'Télécharger un PDF',
    manualEntry: 'Saisie Manuelle',
    useCamera: 'Utilisez votre appareil photo pour capturer un reçu',
    useGallery: 'Sélectionnez une image de reçu dans votre galerie',
    aiPowered: 'Alimenté par IA',
    aiPoweredTip: 'Vos reçus seront automatiquement analysés avec la technologie IA pour extraire le fournisseur, le montant et la date.',
    alignReceiptWithinFrame: 'Alignez le reçu dans le cadre',
    cropReceipt: 'Recadrer le Reçu',
    confirmCrop: 'Confirmer le Recadrage',
    rectangleCropMode: 'Mode de recadrage rectangulaire - parfait pour les reçus standards',
    autoCropMode: 'Mode de recadrage automatique - faites glisser les coins pour ajuster',
    grantPermission: 'Accorder la Permission',
    changeImage: 'Changer l\'Image',
    changePDF: 'Changer le PDF',
    enterVendorName: 'Entrez le nom du fournisseur',
    enterManually: 'Saisir Manuellement',
    cameraPermission: 'Nous avons besoin de votre permission pour utiliser l\'appareil photo',
    adjustCrop: 'Ajuster le Recadrage',
    pdfPreview: 'Aperçu PDF',
    
    // Receipt Form
    vendor: 'Fournisseur',
    amount: 'Montant',
    date: 'Date',
    category: 'Catégorie',
    notes: 'Notes',
    addNotes: 'Ajouter des notes (optionnel)',
    selectCategory: 'Sélectionner une Catégorie',
    saveReceipt: 'Enregistrer le Reçu',
    updateReceipt: 'Mettre à Jour le Reçu',
    missingImage: 'Veuillez ajouter une image de reçu',
    missingVendor: 'Veuillez entrer le nom du fournisseur',
    invalidAmount: 'Veuillez entrer un montant valide',
    
    // Receipt Analysis
    analyzingReceipt: 'Analyse du reçu...',
    analysisFailed: 'Analyse Échouée',
    analysisComplete: 'Analyse Terminée',
    tryAgain: 'Réessayer',
    detailsExtracted: 'Détails du reçu extraits avec succès!',
    
    // Reports
    generateReport: 'Générer un Rapport',
    reportPeriod: 'Période du Rapport',
    month: 'Mois',
    quarter: 'Trimestre',
    year: 'Année',
    custom: 'Personnalisé',
    startDate: 'Date de Début',
    endDate: 'Date de Fin',
    reportOptions: 'Options du Rapport',
    includeImages: 'Inclure les Images de Reçus',
    reportTitle: 'Titre du Rapport',
    reportSummary: 'Résumé du Rapport',
    period: 'Période',
    generatePdfReport: 'Générer un Rapport PDF',
    reportPreview: 'Aperçu du Rapport',
    expenseReport: 'RAPPORT DE DÉPENSES',
    business: 'ENTREPRISE',
    taxId: 'NUMÉRO DE TVA',
    summary: 'RÉSUMÉ',
    expensesByCategory: 'DÉPENSES PAR CATÉGORIE',
    totalExpensesReport: 'DÉPENSES TOTALES',
    signature: 'Signature',
    page: 'Page',
    of: 'de',
    
    // Settings
    preferences: 'Préférences',
    language: 'Langue',
    english: 'Anglais',
    dutch: 'Néerlandais',
    german: 'Allemand',
    french: 'Français',
    notifications: 'Notifications',
    notificationsDescription: 'Recevoir des rappels pour les rapports',
    support: 'Support',
    helpAndSupport: 'Aide & Support',
    helpAndSupportDescription: 'FAQ, nous contacter, politique de confidentialité',
    data: 'Données',
    clearAllData: 'Effacer Toutes les Données',
    clearAllDataConfirm: 'Êtes-vous sûr de vouloir supprimer tous les reçus? Cette action ne peut pas être annulée.',
    version: 'Version'
  }
};

export function t(key: TranslationKey, language: Language): string {
  return translations[language][key];
}