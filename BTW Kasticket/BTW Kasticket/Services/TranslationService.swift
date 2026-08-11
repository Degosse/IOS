import Foundation

enum AppLanguage: String, CaseIterable {
    case nl = "nl"
    case en = "en"
    
    var displayName: String {
        switch self {
        case .nl: return "Nederlands"
        case .en: return "English"
        }
    }
}

extension String {
    func localized(_ lang: String) -> String {
        let nlTranslations: [String: String] = [
            "History": "Geschiedenis",
            "Scan": "Scannen",
            "Overview": "Overzicht",
            "Receipt History": "Kasticket Geschiedenis",
            "No Receipts": "Geen Kastickets",
            "Scan a receipt to see it here.": "Scan een kasticket om het hier te zien.",
            "Scan Receipt": "Kasticket Scannen",
            "Extracting with Mistral AI...": "Gegevens ophalen met Mistral AI...",
            "Review Scanned Data": "Gescande Gegevens Nakijken",
            "Restaurant Name": "Naam Restaurant",
            "Date": "Datum",
            "Total (€)": "Totaal (€)",
            "Total Price": "Totale Prijs",
            "Receipt Image": "Afbeelding Kasticket",
            "Save to History": "Opslaan in Geschiedenis",
            "Scan a new Receipt": "Nieuw Kasticket Scannen",
            "Open Camera": "Camera Openen",
            "Filter": "Filter",
            "Time Period": "Periode",
            "Weekly": "Wekelijks",
            "Monthly": "Maandelijks",
            "Quarterly": "Kwartaal",
            "Yearly": "Jaarlijks",
            "Totaal Overzicht": "Totaal Overzicht",
            "Total Expenses": "Totale Uitgaven",
            "Add Signature": "Handtekening Toevoegen",
            "Update Signature": "Handtekening Aanpassen",
            "Generating PDF...": "PDF Genereren...",
            "Export to Accountant": "Exporteren naar Boekhouder",
            "Zipping PDFs...": "PDF's inpakken (ZIP)...",
            "Export ZIP": "Exporteer ZIP",
            "Receipt Details": "Details Kasticket",
            "No image saved for this receipt": "Geen afbeelding opgeslagen voor dit kasticket",
            "Draw your signature below": "Teken uw handtekening hieronder",
            "Clear": "Wissen",
            "Save Signature": "Handtekening Opslaan",
            "Signature": "Handtekening",
            "Cancel": "Annuleren",
            "Language": "Taal",
            "Settings": "Instellingen",
            "Backup & Restore": "Back-up & Herstel",
            "Choose Backup Folder": "Kies Back-up-map",
            "Change Backup Folder": "Wijzig Back-up-map",
            "Back up now": "Nu Back-uppen",
            "Backing up...": "Back-up maken...",
            "Restore from Backup": "Herstel vanuit Back-up",
            "Restoring...": "Herstellen...",
            "Export Backup File": "Exporteer Back-upbestand",
            "Last backup": "Laatste back-up",
            "Never backed up": "Nog geen back-up",
            "Backup folder not configured": "Back-up-map niet ingesteld",
            "Backup folder needs attention — tap to reselect": "Back-up-map heeft aandacht nodig — tik om opnieuw te kiezen",
            "Restore Successful": "Herstel Geslaagd",
            "New receipts imported": "Nieuwe kastickets geïmporteerd",
            "Receipts updated": "Kastickets bijgewerkt",
            "Duplicates skipped": "Duplicaten overgeslagen",
            "Invalid backup file": "Ongeldig back-upbestand",
            "OK": "OK",
            "Backup Failed": "Back-up Mislukt",
            "Restore Failed": "Herstel Mislukt"
        ]
        
        let enTranslations: [String: String] = [
            "Totaal Overzicht": "Total Overview"
        ]
        
        if lang == "nl" {
            return nlTranslations[self] ?? self
        } else {
            return enTranslations[self] ?? self
        }
    }
}
