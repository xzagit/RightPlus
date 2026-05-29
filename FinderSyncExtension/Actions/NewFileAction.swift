import AppKit

enum NewFileAction {

    enum FileType {
        case markdown
        case word
        case excel
        case powerpoint
        case blank
        case folder
        case custom(TemplateConfig)

        var baseName: String {
            switch self {
            case .markdown: return "新建 Markdown 文件"
            case .word: return "新建 Word 文档"
            case .excel: return "新建 Excel 表格"
            case .powerpoint: return "新建 PowerPoint 演示"
            case .blank: return "新建文件"
            case .folder: return "新建文件夹"
            case .custom(let config): return config.displayName
            }
        }

        var fileExtension: String? {
            switch self {
            case .markdown: return "md"
            case .word: return "docx"
            case .excel: return "xlsx"
            case .powerpoint: return "pptx"
            case .blank: return nil
            case .folder: return nil
            case .custom(let config): return config.fileExtension.isEmpty ? nil : config.fileExtension
            }
        }

        var isFolder: Bool {
            if case .folder = self { return true }
            return false
        }
    }

    static func createFile(type: FileType, in directory: URL) {
        let targetURL = uniqueFileURL(baseName: type.baseName, extension: type.fileExtension, in: directory)

        if type.isFolder {
            do {
                try FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: false)
            } catch {
                NSLog("RightPlus: create folder failed: \(error)")
                return
            }
        } else if let templateURL = resolveTemplate(for: type) {
            do {
                try FileManager.default.copyItem(at: templateURL, to: targetURL)
            } catch {
                NSLog("RightPlus: copy template failed: \(error)")
                return
            }
        } else {
            FileManager.default.createFile(atPath: targetURL.path, contents: nil)
        }

        selectInFinder(targetURL)
    }

    private static func resolveTemplate(for type: FileType) -> URL? {
        switch type {
        case .word:
            return userTemplate(fileName: "未命名.docx") ?? Bundle.main.url(forResource: "未命名", withExtension: "docx")
        case .excel:
            return userTemplate(fileName: "未命名.xlsx") ?? Bundle.main.url(forResource: "未命名", withExtension: "xlsx")
        case .powerpoint:
            return userTemplate(fileName: "未命名.pptx") ?? Bundle.main.url(forResource: "未命名", withExtension: "pptx")
        case .custom(let config):
            return config.fileURL
        default:
            return nil
        }
    }

    private static func userTemplate(fileName: String) -> URL? {
        let url = AppConstants.templateDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static func uniqueFileURL(baseName: String, extension ext: String?, in directory: URL) -> URL {
        let fm = FileManager.default

        func buildURL(_ name: String) -> URL {
            if let ext = ext {
                return directory.appendingPathComponent("\(name).\(ext)")
            } else {
                return directory.appendingPathComponent(name)
            }
        }

        let firstAttempt = buildURL(baseName)
        if !fm.fileExists(atPath: firstAttempt.path) {
            return firstAttempt
        }

        var counter = 2
        while true {
            let url = buildURL("\(baseName) \(counter)")
            if !fm.fileExists(atPath: url.path) {
                return url
            }
            counter += 1
        }
    }

    private static func selectInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
}
