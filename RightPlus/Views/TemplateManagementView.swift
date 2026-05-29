import SwiftUI
import UniformTypeIdentifiers

struct TemplateManagementView: View {
    @State private var builtinTemplates: [TemplateConfig] = []
    @State private var customTemplates: [TemplateConfig] = []
    @State private var editingTemplate: TemplateConfig?
    @State private var editingName: String = ""

    var body: some View {
        Form {
            Section("内置模板") {
                ForEach(builtinTemplates) { template in
                    BuiltinTemplateRow(template: template, onReplace: { replaceBuiltin(template) })
                }
                Text("内置模板可替换为自己的文件，替换后新建时将使用你的版本。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("自定义模板") {
                if customTemplates.isEmpty {
                    Text("暂无自定义模板")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(customTemplates) { template in
                        CustomTemplateRow(
                            template: template,
                            onRename: { startRename(template) },
                            onDelete: { deleteCustom(template) }
                        )
                    }
                }

                Button("添加模板…") {
                    addTemplate()
                }
            }

            if editingTemplate != nil {
                Section("重命名") {
                    HStack {
                        TextField("菜单显示名称", text: $editingName)
                            .textFieldStyle(.roundedBorder)
                        Button("保存") {
                            saveRename()
                        }
                        Button("取消") {
                            editingTemplate = nil
                        }
                    }
                }
            }

            Section {
                Text("添加的模板文件将存储在:\n~/Library/Application Support/RightPlus/Templates/\n\n新建文件时会复制对应模板，菜单名称可自定义。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("模板管理")
        .onAppear { reload() }
    }

    private func reload() {
        builtinTemplates = TemplateStore.builtinTemplates()
        customTemplates = TemplateStore.loadCustom()
    }

    private func addTemplate() {
        let panel = NSOpenPanel()
        panel.title = "选择模板文件"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let sourceURL = panel.url else { return }

        let fileName = sourceURL.lastPathComponent
        let destURL = AppConstants.templateDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destURL.path) {
            try? FileManager.default.removeItem(at: destURL)
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            NSLog("RightPlus: copy template failed: \(error)")
            return
        }

        let baseName = (fileName as NSString).deletingPathExtension
        let displayName = "新建 \(baseName)"
        let config = TemplateConfig(fileName: fileName, displayName: displayName, isBuiltin: false)
        TemplateStore.addCustom(config)
        reload()
    }

    private func replaceBuiltin(_ template: TemplateConfig) {
        let panel = NSOpenPanel()
        panel.title = "选择替换文件"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if let ext = UTType(filenameExtension: template.fileExtension) {
            panel.allowedContentTypes = [ext]
        }

        guard panel.runModal() == .OK, let sourceURL = panel.url else { return }

        let destURL = template.fileURL

        if FileManager.default.fileExists(atPath: destURL.path) {
            try? FileManager.default.removeItem(at: destURL)
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            NSLog("RightPlus: replace template failed: \(error)")
        }
        reload()
    }

    private func deleteCustom(_ template: TemplateConfig) {
        TemplateStore.removeCustom(fileName: template.fileName)
        reload()
    }

    private func startRename(_ template: TemplateConfig) {
        editingTemplate = template
        editingName = template.displayName
    }

    private func saveRename() {
        guard let template = editingTemplate, !editingName.isEmpty else { return }
        TemplateStore.updateDisplayName(fileName: template.fileName, newName: editingName)
        editingTemplate = nil
        reload()
    }
}

struct BuiltinTemplateRow: View {
    let template: TemplateConfig
    let onReplace: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(template.displayName)
                Text(template.fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if FileManager.default.fileExists(atPath: template.fileURL.path) {
                Text("已自定义")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("使用内置")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            Button("替换") { onReplace() }
                .buttonStyle(.borderless)
        }
    }
}

struct CustomTemplateRow: View {
    let template: TemplateConfig
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(template.displayName)
                Text(template.fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("重命名") { onRename() }
                .buttonStyle(.borderless)
            Button("删除") { onDelete() }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
        }
    }
}
