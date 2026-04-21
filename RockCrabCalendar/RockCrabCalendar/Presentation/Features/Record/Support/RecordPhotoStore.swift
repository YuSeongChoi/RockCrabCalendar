//
//  RecordPhotoStore.swift
//  RockCrabCalendar
//
//  Created by Codex on 2026/04/21.
//

import Foundation
import UIKit

enum RecordPhotoStoreError: Error {
    case invalidImageData
    case jpegEncodingFailed
}

struct RecordPhotoStore {
    private let fileManager: FileManager
    private let directoryName: String

    init(
        fileManager: FileManager = .default,
        directoryName: String = "ScheduleRecordPhotos"
    ) {
        self.fileManager = fileManager
        self.directoryName = directoryName
    }

    func saveImageData(
        _ data: Data,
        maxPixelLength: CGFloat = 1600,
        compressionQuality: CGFloat = 0.82
    ) throws -> String {
        guard let image = UIImage(data: data) else {
            throw RecordPhotoStoreError.invalidImageData
        }

        let resizedImage = image.resizedForRecord(maxPixelLength: maxPixelLength)
        guard let jpegData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw RecordPhotoStoreError.jpegEncodingFailed
        }

        let filename = "\(UUID().uuidString).jpg"
        try ensureDirectoryExists()
        try jpegData.write(to: fileURL(for: filename), options: [.atomic])
        return filename
    }

    func imageData(fileName: String) -> Data? {
        try? Data(contentsOf: fileURL(for: fileName))
    }

    func image(fileName: String) -> UIImage? {
        guard let data = imageData(fileName: fileName) else { return nil }
        return UIImage(data: data)
    }

    func delete(fileName: String) {
        try? fileManager.removeItem(at: fileURL(for: fileName))
    }
}

private extension RecordPhotoStore {
    var directoryURL: URL {
        let baseURL = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory

        return baseURL.appendingPathComponent(directoryName, isDirectory: true)
    }

    func ensureDirectoryExists() throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    func fileURL(for fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }
}

private extension UIImage {
    func resizedForRecord(maxPixelLength: CGFloat) -> UIImage {
        let currentMaxLength = max(size.width, size.height)
        guard currentMaxLength > maxPixelLength else { return self }

        let scale = maxPixelLength / currentMaxLength
        let targetSize = CGSize(
            width: floor(size.width * scale),
            height: floor(size.height * scale)
        )

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
