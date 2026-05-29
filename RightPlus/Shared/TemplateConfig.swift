import Foundation

struct TemplateConfig: Codable, Identifiable {
    var id: String { fileName }
    let fileName: String
    var displayName: String
    let isBuiltin: Bool

    var fileURL: URL {
        AppConstants.templateDirectory.appendingPathComponent(fileName)
    }

    var fileExtension: String {
        (fileName as NSString).pathExtension
    }
}

enum TemplateStore {
    private static var storeURL: URL {
        AppConstants.appSupportDirectory.appendingPathComponent("custom_templates.json")
    }

    static func loadAll() -> [TemplateConfig] {
        var templates = builtinTemplates()
        templates.append(contentsOf: loadCustom())
        return templates
    }

    static func builtinTemplates() -> [TemplateConfig] {
        [
            TemplateConfig(fileName: "未命名.docx", displayName: "新建 Word 文档", isBuiltin: true),
            TemplateConfig(fileName: "未命名.xlsx", displayName: "新建 Excel 表格", isBuiltin: true),
            TemplateConfig(fileName: "未命名.pptx", displayName: "新建 PowerPoint 演示", isBuiltin: true),
        ]
    }

    static func loadCustom() -> [TemplateConfig] {
        guard let data = try? Data(contentsOf: storeURL) else { return [] }
        return (try? JSONDecoder().decode([TemplateConfig].self, from: data)) ?? []
    }

    static func saveCustom(_ templates: [TemplateConfig]) {
        let data = try? JSONEncoder().encode(templates)
        try? data?.write(to: storeURL, options: .atomic)
    }

    static func addCustom(_ template: TemplateConfig) {
        var customs = loadCustom()
        customs.append(template)
        saveCustom(customs)
    }

    static func removeCustom(fileName: String) {
        var customs = loadCustom()
        customs.removeAll { $0.fileName == fileName }
        saveCustom(customs)
        let fileURL = AppConstants.templateDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func updateDisplayName(fileName: String, newName: String) {
        var customs = loadCustom()
        if let idx = customs.firstIndex(where: { $0.fileName == fileName }) {
            customs[idx].displayName = newName
            saveCustom(customs)
        }
    }
}
