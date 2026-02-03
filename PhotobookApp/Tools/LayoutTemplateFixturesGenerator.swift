import Foundation
import SwiftUI

struct PbPoint: Codable {
    let x: Double
    let y: Double
}

struct PbSize: Codable {
    let width: Double
    let height: Double
}

struct PbRect: Codable {
    let origin: PbPoint
    let size: PbSize
}

struct TemplateFixture: Codable {
    let name: String
    let slots: [PbRect]
}

struct BestTemplateFixture: Codable {
    let count: Int
    let template: String
}

struct LayoutTemplateFixtures: Codable {
    let schemaVersion: Int
    let templates: [TemplateFixture]
    let bestByPhotoCount: [BestTemplateFixture]
}

func pbRect(from rect: CGRect) -> PbRect {
    PbRect(
        origin: PbPoint(x: rect.origin.x, y: rect.origin.y),
        size: PbSize(width: rect.size.width, height: rect.size.height)
    )
}

@main
struct LayoutTemplateFixturesGeneratorMain {
    static func main() throws {
        let outputPath = CommandLine.arguments.dropFirst().first ?? "LayoutTemplateFixtures.json"
        
        let templates = LayoutTemplate.allTemplates.map { template in
            TemplateFixture(
                name: template.rawValue,
                slots: template.slots.map { pbRect(from: $0.rect) }
            )
        }
        
        let bestByPhotoCount = (0...10).map { count in
            BestTemplateFixture(count: count, template: LayoutTemplate.bestTemplate(forPhotoCount: count).rawValue)
        }
        
        let fixtures = LayoutTemplateFixtures(
            schemaVersion: 1,
            templates: templates,
            bestByPhotoCount: bestByPhotoCount
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(fixtures)
        try data.write(to: URL(fileURLWithPath: outputPath))
    }
}
