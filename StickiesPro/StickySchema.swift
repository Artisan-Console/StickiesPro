//
//  StickySchema.swift
//  StickiesPro
//

import SwiftData

enum StickiesSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] {
        [Sticky.self, Vault.self, ExternalNote.self, CatalogNode.self]
    }
}

enum StickiesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [StickiesSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}

enum StickiesModelContainer {
    static func make() throws -> ModelContainer {
        let schema = Schema(versionedSchema: StickiesSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema)
        return try ModelContainer(
            for: schema,
            migrationPlan: StickiesMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
