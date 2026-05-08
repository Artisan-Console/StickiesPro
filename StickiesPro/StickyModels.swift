//
//  StickyModels.swift
//  StickiesPro
//

import Foundation
import SwiftData

@Model
final class Sticky {
    var id: UUID
    var content: String
    var color: String
    var positionX: Double
    var positionY: Double
    var createdAt: Date
    var modifiedAt: Date
    var catalogAddress: String?
    var vault: Vault?
    
    init(
        id: UUID = UUID(),
        content: String = "",
        color: String = "#FFFF00",
        positionX: Double = 0,
        positionY: Double = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        catalogAddress: String? = nil,
        vault: Vault? = nil
    ) {
        self.id = id
        self.content = content
        self.color = color
        self.positionX = positionX
        self.positionY = positionY
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.catalogAddress = catalogAddress
        self.vault = vault
    }
}

@Model
final class Vault {
    var id: UUID
    var displayName: String
    var type: String
    var path: String?
    var lastIndexed: Date?
    @Relationship(deleteRule: .cascade, inverse: \Sticky.vault) var stickies: [Sticky]
    @Relationship(deleteRule: .cascade, inverse: \ExternalNote.vault) var externalNotes: [ExternalNote]
    
    init(
        id: UUID = UUID(),
        displayName: String,
        type: String,
        path: String? = nil,
        lastIndexed: Date? = nil,
        stickies: [Sticky] = [],
        externalNotes: [ExternalNote] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.type = type
        self.path = path
        self.lastIndexed = lastIndexed
        self.stickies = stickies
        self.externalNotes = externalNotes
    }
}

@Model
final class ExternalNote {
    var id: UUID
    var sourceId: String
    var title: String
    var content: String
    var modifiedAt: Date
    var catalogAddress: String?
    var vault: Vault
    
    init(
        id: UUID = UUID(),
        sourceId: String,
        title: String,
        content: String,
        modifiedAt: Date = Date(),
        catalogAddress: String? = nil,
        vault: Vault
    ) {
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.content = content
        self.modifiedAt = modifiedAt
        self.catalogAddress = catalogAddress
        self.vault = vault
    }
}

@Model
final class CatalogNode {
    var id: UUID
    var address: String
    var label: String
    var parentAddress: String?
    var noteIds: [UUID]
    
    init(
        id: UUID = UUID(),
        address: String,
        label: String,
        parentAddress: String? = nil,
        noteIds: [UUID] = []
    ) {
        self.id = id
        self.address = address
        self.label = label
        self.parentAddress = parentAddress
        self.noteIds = noteIds
    }
}
