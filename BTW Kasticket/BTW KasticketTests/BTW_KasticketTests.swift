//
//  BTW_KasticketTests.swift
//  BTW KasticketTests
//
//  Created by Nicolaï Gosselin on 20/02/2026.
//

import Foundation
import Testing
import SwiftData
@testable import BTW_Kasticket

struct BTW_KasticketTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

struct BackupServiceTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([ExpenseReceipt.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func makeTempImagesDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func manifestEncodeDecodeRoundTripsFields() throws {
        let receipt = ExpenseReceipt(
            id: UUID(),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            restaurantName: "Café De Kroon",
            totalPrice: 12.5,
            imageData: Data([0x01, 0x02, 0x03]),
            modifiedAt: Date(timeIntervalSince1970: 1_700_000_500)
        )

        let manifest = BackupService.shared.buildManifest(receipts: [receipt])
        let data = try BackupService.shared.encode(manifest)
        let decoded = try BackupService.shared.decode(data)

        #expect(decoded.receipts.count == 1)
        let dto = try #require(decoded.receipts.first)
        #expect(dto.id == receipt.id)
        #expect(dto.restaurantName == receipt.restaurantName)
        #expect(dto.totalPrice == receipt.totalPrice)
        #expect(dto.imageFilename == "\(receipt.id.uuidString).jpg")
    }

    @Test func restoreReadsPhotoFromImagesDirectory() throws {
        let context = try makeContext()
        let imagesURL = try makeTempImagesDirectory()
        defer { try? FileManager.default.removeItem(at: imagesURL) }

        let id = UUID()
        let photoData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        try photoData.write(to: imagesURL.appendingPathComponent("\(id.uuidString).jpg"))

        let dto = ReceiptBackupDTO(id: id, date: .now, restaurantName: "Bakker", totalPrice: 4.2, modifiedAt: .now, imageFilename: "\(id.uuidString).jpg")
        let manifest = BackupManifest(formatVersion: 2, exportedAt: .now, receipts: [dto])

        let summary = try BackupService.shared.restore(manifest: manifest, imagesDirectory: imagesURL, into: context)

        #expect(summary.imported == 1)
        let stored = try context.fetch(FetchDescriptor<ExpenseReceipt>())
        #expect(stored.first?.imageData == photoData)
    }

    @Test func restoreIntoEmptyStoreInsertsAll() throws {
        let context = try makeContext()
        let imagesURL = try makeTempImagesDirectory()
        defer { try? FileManager.default.removeItem(at: imagesURL) }

        let dto = ReceiptBackupDTO(id: UUID(), date: .now, restaurantName: "Bakker", totalPrice: 4.2, modifiedAt: .now, imageFilename: nil)
        let manifest = BackupManifest(formatVersion: 2, exportedAt: .now, receipts: [dto])

        let summary = try BackupService.shared.restore(manifest: manifest, imagesDirectory: imagesURL, into: context)

        #expect(summary.imported == 1)
        #expect(summary.updated == 0)
        #expect(summary.skippedDuplicates == 0)
        #expect(try context.fetch(FetchDescriptor<ExpenseReceipt>()).count == 1)
    }

    @Test func reimportingSameManifestIsIdempotent() throws {
        let context = try makeContext()
        let imagesURL = try makeTempImagesDirectory()
        defer { try? FileManager.default.removeItem(at: imagesURL) }

        let dto = ReceiptBackupDTO(id: UUID(), date: .now, restaurantName: "Bakker", totalPrice: 4.2, modifiedAt: .now, imageFilename: nil)
        let manifest = BackupManifest(formatVersion: 2, exportedAt: .now, receipts: [dto])

        _ = try BackupService.shared.restore(manifest: manifest, imagesDirectory: imagesURL, into: context)
        let secondSummary = try BackupService.shared.restore(manifest: manifest, imagesDirectory: imagesURL, into: context)

        #expect(secondSummary.imported == 0)
        #expect(secondSummary.updated == 0)
        #expect(secondSummary.skippedDuplicates == 1)
        #expect(try context.fetch(FetchDescriptor<ExpenseReceipt>()).count == 1)
    }

    @Test func newerModifiedAtUpdatesExistingRecord() throws {
        let context = try makeContext()
        let imagesURL = try makeTempImagesDirectory()
        defer { try? FileManager.default.removeItem(at: imagesURL) }

        let id = UUID()
        let original = ExpenseReceipt(id: id, date: .now, restaurantName: "Oud", totalPrice: 1.0, imageData: nil, modifiedAt: Date(timeIntervalSince1970: 1000))
        context.insert(original)

        let newerDTO = ReceiptBackupDTO(id: id, date: .now, restaurantName: "Nieuw", totalPrice: 2.0, modifiedAt: Date(timeIntervalSince1970: 2000), imageFilename: nil)
        let manifest = BackupManifest(formatVersion: 2, exportedAt: .now, receipts: [newerDTO])

        let summary = try BackupService.shared.restore(manifest: manifest, imagesDirectory: imagesURL, into: context)

        #expect(summary.updated == 1)
        #expect(original.restaurantName == "Nieuw")
    }

    @Test func olderModifiedAtIsSkippedAndDoesNotClobberExistingData() throws {
        let context = try makeContext()
        let imagesURL = try makeTempImagesDirectory()
        defer { try? FileManager.default.removeItem(at: imagesURL) }

        let id = UUID()
        let original = ExpenseReceipt(id: id, date: .now, restaurantName: "Behoud", totalPrice: 1.0, imageData: Data([0xAA]), modifiedAt: Date(timeIntervalSince1970: 2000))
        context.insert(original)

        let olderDTO = ReceiptBackupDTO(id: id, date: .now, restaurantName: "Oud", totalPrice: 2.0, modifiedAt: Date(timeIntervalSince1970: 1000), imageFilename: nil)
        let manifest = BackupManifest(formatVersion: 2, exportedAt: .now, receipts: [olderDTO])

        let summary = try BackupService.shared.restore(manifest: manifest, imagesDirectory: imagesURL, into: context)

        #expect(summary.skippedDuplicates == 1)
        #expect(original.restaurantName == "Behoud")
        #expect(original.imageData == Data([0xAA]))
    }

    @Test func rejectsIncompatibleFormatVersion() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let manifest = BackupManifest(formatVersion: 1, exportedAt: .now, receipts: [])
        let data = try encoder.encode(manifest)

        #expect(throws: BackupServiceError.self) {
            try BackupService.shared.decode(data)
        }
    }
}
