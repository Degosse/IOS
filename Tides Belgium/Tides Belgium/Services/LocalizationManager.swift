//
//  LocalizationManager.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: AppLanguage = .english {
        didSet {
            saveLanguagePreference()
        }
    }
    
    enum AppLanguage: String, CaseIterable, Identifiable {
        case english = "en"
        case dutch = "nl"
        case french = "fr"
        case german = "de"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .dutch: return "Nederlands"
            case .french: return "Français"
            case .german: return "Deutsch"
            }
        }
        
        var flagEmoji: String {
            switch self {
            case .english: return "🇬🇧"
            case .dutch: return "🇳🇱"
            case .french: return "🇫🇷"
            case .german: return "🇩🇪"
            }
        }
    }
    
    private let languageKey = "selectedLanguage"
    
    // Callback for when language changes - called after settings dismissal
    var onLanguageChanged: (() -> Void)?
    
    // Track if language was changed during this session
    @Published var languageChangedPending: Bool = false
    
    init() {
        loadLanguagePreference()
    }
    
    func localizedString(for key: String) -> String {
        return LocalizedStrings.string(for: key, language: currentLanguage)
    }
    
    func changeLanguage(to language: AppLanguage) {
        if currentLanguage != language {
            currentLanguage = language
            languageChangedPending = true
        }
    }
    
    func triggerRefreshIfNeeded() {
        if languageChangedPending {
            languageChangedPending = false
            onLanguageChanged?()
        }
    }
    
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }
    
    private func loadLanguagePreference() {
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // Default to English for international users
            currentLanguage = .english
        }
    }
}

// Localized strings structure
struct LocalizedStrings {
    static func string(for key: String, language: LocalizationManager.AppLanguage) -> String {
        let translations = getTranslations()
        return translations[language]?[key] ?? translations[.english]?[key] ?? key
    }
    
    private static func getTranslations() -> [LocalizationManager.AppLanguage: [String: String]] {
        return [
            .english: englishStrings,
            .dutch: dutchStrings,
            .french: frenchStrings,
            .german: germanStrings
        ]
    }
    
    // MARK: - English Translations
    private static let englishStrings: [String: String] = [
        // App Title
        "app_title": "Tides Belgium",
        "app_subtitle": "Belgian Tide Times & Charts",
        
        // Navigation
        "select_location": "Select Location",
        "settings": "Settings",
        "language": "Language",
        "cancel": "Cancel",
        "done": "Done",
        
        // Location
        "current_location": "Use Current Location",
        "search_stations": "Search tide stations...",
        "location_permission_title": "Location Access Needed",
        "location_permission_message": "Please enable location access in Settings to use this feature.",
        "settings_button": "Settings",
        "km_away": "km away",
        
        // Tide Information
        "tide_chart": "Tide Chart",
        "tide_chart_24h": "24-Hour Tide Chart",
        "tide_chart_48h": "48-Hour Continuous Chart",
        "continuous_flow": "Today + Tomorrow",
        "current_level": "Current",
        "current_tide": "Current Tide",
        "next_high_tide": "Next High Tide",
        "next_low_tide": "Next Low Tide",
        "high_tide": "High Tide",
        "low_tide": "Low Tide",
        "current": "Current",
        "current_time": "Current Time",
        "todays_tides": "Today's Tides",
        "in_time": "in %@",
        "past": "Past",
        
        // Units
        "meters": "m",
        "hours_short": "h",
        "minutes_short": "m",
        
        // Status Messages
        "loading": "Loading tide data...",
        "error_loading": "Error loading tide data",
        "retry": "Retry",
        "welcome_title": "Welcome to Tides Belgium",
        "welcome_message": "Select a location to view tide information",
        "choose_location": "Choose Location",
        
        // Date Selection
        "today": "Today",
        "tomorrow": "Tomorrow",
        
        // Stations
        "oostende": "Ostend",
        "zeebrugge": "Zeebrugge",
        "nieuwpoort": "Nieuwpoort",
        "knokkeheist": "Knokke-Heist",
        "blankenberge": "Blankenberge",
        "dehaan": "De Haan",
        "middelkerke": "Middelkerke",
        "depanne": "De Panne",
        "vlissingen": "Vlissingen",
        "calais": "Calais",
        
        // Tide Table
        "tide_schedule_24h": "24-Hour Tide Schedule",
        "next_tides": "Next %d tides",
        "table_time": "Time",
        "table_type": "Type",
        "table_height": "Height",
        "table_in": "In",
        "no_tide_data": "No tide data available",
        "check_connection": "Please check your connection and try again",
        "todays_tide_summary": "Today's Tide Summary",
        "high": "High",
        "low": "Low",
        "average": "Average:",
        "highest": "Highest:",
        "lowest": "Lowest:",
        "next": "Next:",
        "no_data": "No data",
        
        // Data Source Disclaimer
        "data_source": "Data Source",
        "data_disclaimer": "All tide data is static data based on the official 'Getij Tafels' (Tide Tables) published by the Flemish Government. This data is provided for informational purposes only."
    ]
    
    // MARK: - Dutch Translations
    private static let dutchStrings: [String: String] = [
        // App Title
        "app_title": "Getijden België",
        "app_subtitle": "Belgische Getijdentijden & Grafieken",
        
        // Navigation
        "select_location": "Locatie Selecteren",
        "settings": "Instellingen",
        "language": "Taal",
        "cancel": "Annuleren",
        "done": "Klaar",
        
        // Location
        "current_location": "Huidige Locatie Gebruiken",
        "search_stations": "Zoek getijdenstations...",
        "location_permission_title": "Locatietoegang Nodig",
        "location_permission_message": "Schakel locatietoegang in bij Instellingen om deze functie te gebruiken.",
        "settings_button": "Instellingen",
        "km_away": "km verderop",
        
        // Tide Information
        "tide_chart": "Getijdengrafiek",
        "tide_chart_24h": "24-Uurs Getijdengrafiek",
        "tide_chart_48h": "48-Uurs Continue Grafiek",
        "continuous_flow": "Vandaag + Morgen",
        "current_level": "Huidig",
        "current_tide": "Huidig Getij",
        "next_high_tide": "Volgende Hoogwater",
        "next_low_tide": "Volgende Laagwater",
        "high_tide": "Hoogwater",
        "low_tide": "Laagwater",
        "current": "Huidig",
        "current_time": "Huidige Tijd",
        "todays_tides": "Getijden van Vandaag",
        "in_time": "over %@",
        "past": "Voorbij",
        
        // Units
        "meters": "m",
        "hours_short": "u",
        "minutes_short": "m",
        
        // Status Messages
        "loading": "Getijdengegevens laden...",
        "error_loading": "Fout bij laden van getijdengegevens",
        "retry": "Opnieuw Proberen",
        "welcome_title": "Welkom bij Getijden België",
        "welcome_message": "Selecteer een locatie om getijdeninformatie te bekijken",
        "choose_location": "Kies Locatie",
        
        // Date Selection
        "today": "Vandaag",
        "tomorrow": "Morgen",
        
        // Stations
        "oostende": "Oostende",
        "zeebrugge": "Zeebrugge",
        "nieuwpoort": "Nieuwpoort",
        "knokkeheist": "Knokke-Heist",
        "blankenberge": "Blankenberge",
        "dehaan": "De Haan",
        "middelkerke": "Middelkerke",
        "depanne": "De Panne",
        "vlissingen": "Vlissingen",
        "calais": "Calais",
        
        // Tide Table
        "tide_schedule_24h": "24-Uurs Getijdenschema",
        "next_tides": "Volgende %d getijden",
        "table_time": "Tijd",
        "table_type": "Type",
        "table_height": "Hoogte",
        "table_in": "In",
        "no_tide_data": "Geen getijdengegevens beschikbaar",
        "check_connection": "Controleer uw verbinding en probeer opnieuw",
        "todays_tide_summary": "Samenvatting van Vandaag",
        "high": "Hoog",
        "low": "Laag",
        "average": "Gemiddeld:",
        "highest": "Hoogste:",
        "lowest": "Laagste:",
        "next": "Volgende:",
        "no_data": "Geen gegevens",
        
        // Data Source Disclaimer
        "data_source": "Gegevensbron",
        "data_disclaimer": "Alle getijdengegevens zijn statische gegevens gebaseerd op de officiële 'Getij Tafels' uitgegeven door de Vlaamse Regering. Deze gegevens worden alleen ter informatie verstrekt."
    ]
    
    // MARK: - French Translations
    private static let frenchStrings: [String: String] = [
        // App Title
        "app_title": "Marées Belgique",
        "app_subtitle": "Horaires & Graphiques des Marées Belges",
        
        // Navigation
        "select_location": "Sélectionner un Lieu",
        "settings": "Paramètres",
        "language": "Langue",
        "cancel": "Annuler",
        "done": "Terminé",
        
        // Location
        "current_location": "Utiliser la Position Actuelle",
        "search_stations": "Rechercher des stations de marée...",
        "location_permission_title": "Accès à la Localisation Requis",
        "location_permission_message": "Veuillez activer l'accès à la localisation dans les Paramètres pour utiliser cette fonctionnalité.",
        "settings_button": "Paramètres",
        "km_away": "km",
        
        // Tide Information
        "tide_chart": "Graphique des Marées",
        "tide_chart_24h": "Graphique des Marées 24h",
        "tide_chart_48h": "Graphique Continu 48h",
        "continuous_flow": "Aujourd'hui + Demain",
        "current_level": "Actuel",
        "current_tide": "Marée Actuelle",
        "next_high_tide": "Prochaine Marée Haute",
        "next_low_tide": "Prochaine Marée Basse",
        "high_tide": "Marée Haute",
        "low_tide": "Marée Basse",
        "current": "Actuel",
        "current_time": "Heure Actuelle",
        "todays_tides": "Marées d'Aujourd'hui",
        "in_time": "dans %@",
        "past": "Passé",
        
        // Units
        "meters": "m",
        "hours_short": "h",
        "minutes_short": "m",
        
        // Status Messages
        "loading": "Chargement des données de marée...",
        "error_loading": "Erreur lors du chargement des données de marée",
        "retry": "Réessayer",
        "welcome_title": "Bienvenue dans Marées Belgique",
        "welcome_message": "Sélectionnez un lieu pour voir les informations de marée",
        "choose_location": "Choisir un Lieu",
        
        // Date Selection
        "today": "Aujourd'hui",
        "tomorrow": "Demain",
        
        // Stations
        "oostende": "Ostende",
        "zeebrugge": "Zeebruges",
        "nieuwpoort": "Nieuport",
        "knokkeheist": "Knokke-Heist",
        "blankenberge": "Blankenberge",
        "dehaan": "De Haan",
        "middelkerke": "Middelkerke",
        "depanne": "De Panne",
        "vlissingen": "Flessingue",
        "calais": "Calais",
        
        // Tide Table
        "tide_schedule_24h": "Horaires des Marées 24h",
        "next_tides": "Prochaines %d marées",
        "table_time": "Heure",
        "table_type": "Type",
        "table_height": "Hauteur",
        "table_in": "Dans",
        "no_tide_data": "Aucune donnée de marée disponible",
        "check_connection": "Veuillez vérifier votre connexion et réessayer",
        "todays_tide_summary": "Résumé des Marées d'Aujourd'hui",
        "high": "Haute",
        "low": "Basse",
        "average": "Moyenne:",
        "highest": "Plus haute:",
        "lowest": "Plus basse:",
        "next": "Prochaine:",
        "no_data": "Aucune donnée",
        
        // Data Source Disclaimer
        "data_source": "Source de Données",
        "data_disclaimer": "Toutes les données de marée sont des données statiques basées sur les 'Tables de Marée' officielles publiées par le Gouvernement Flamand. Ces données sont fournies à titre informatif uniquement."
    ]
    
    // MARK: - German Translations
    private static let germanStrings: [String: String] = [
        // App Title
        "app_title": "Gezeiten Belgien",
        "app_subtitle": "Belgische Gezeitenzeiten & Diagramme",
        
        // Navigation
        "select_location": "Standort Auswählen",
        "settings": "Einstellungen",
        "language": "Sprache",
        "cancel": "Abbrechen",
        "done": "Fertig",
        
        // Location
        "current_location": "Aktuellen Standort Verwenden",
        "search_stations": "Gezeitenstationen suchen...",
        "location_permission_title": "Standortzugriff Erforderlich",
        "location_permission_message": "Bitte aktivieren Sie den Standortzugriff in den Einstellungen, um diese Funktion zu nutzen.",
        "settings_button": "Einstellungen",
        "km_away": "km entfernt",
        
        // Tide Information
        "tide_chart": "Gezeitendiagramm",
        "tide_chart_24h": "24-Stunden Gezeitendiagramm",
        "tide_chart_48h": "48-Stunden Kontinuierliches Diagramm",
        "continuous_flow": "Heute + Morgen",
        "current_level": "Aktuell",
        "current_tide": "Aktuelle Gezeit",
        "next_high_tide": "Nächste Flut",
        "next_low_tide": "Nächste Ebbe",
        "high_tide": "Flut",
        "low_tide": "Ebbe",
        "current": "Aktuell",
        "current_time": "Aktuelle Zeit",
        "todays_tides": "Heutige Gezeiten",
        "in_time": "in %@",
        "past": "Vergangen",
        
        // Units
        "meters": "m",
        "hours_short": "Std",
        "minutes_short": "Min",
        
        // Status Messages
        "loading": "Gezeitendaten werden geladen...",
        "error_loading": "Fehler beim Laden der Gezeitendaten",
        "retry": "Wiederholen",
        "welcome_title": "Willkommen bei Gezeiten Belgien",
        "welcome_message": "Wählen Sie einen Standort aus, um Gezeiteninfos anzuzeigen",
        "choose_location": "Standort Wählen",
        
        // Date Selection
        "today": "Heute",
        "tomorrow": "Morgen",
        
        // Stations
        "oostende": "Ostende",
        "zeebrugge": "Zeebrügge",
        "nieuwpoort": "Nieuwpoort",
        "knokkeheist": "Knokke-Heist",
        "blankenberge": "Blankenberge",
        "dehaan": "De Haan",
        "middelkerke": "Middelkerke",
        "depanne": "De Panne",
        "vlissingen": "Vlissingen",
        "calais": "Calais",
        
        // Tide Table
        "tide_schedule_24h": "24-Stunden Gezeitenplan",
        "next_tides": "Nächste %d Gezeiten",
        "table_time": "Zeit",
        "table_type": "Typ",
        "table_height": "Höhe",
        "table_in": "In",
        "no_tide_data": "Keine Gezeitendaten verfügbar",
        "check_connection": "Bitte überprüfen Sie Ihre Verbindung und versuchen Sie es erneut",
        "todays_tide_summary": "Heutige Gezeitenzusammenfassung",
        "high": "Flut",
        "low": "Ebbe",
        "average": "Durchschnitt:",
        "highest": "Höchste:",
        "lowest": "Niedrigste:",
        "next": "Nächste:",
        "no_data": "Keine Daten",
        
        // Data Source Disclaimer
        "data_source": "Datenquelle",
        "data_disclaimer": "Alle Gezeitendaten sind statische Daten basierend auf den offiziellen 'Gezeiten Tafeln', die von der Flämischen Regierung veröffentlicht wurden. Diese Daten werden nur zu Informationszwecken bereitgestellt."
    ]
}
