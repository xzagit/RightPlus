import SwiftUI

struct NewFileSettingsView: View {
    var body: some View {
        Form {
            Section("已配置的新建文件类型") {
                FileTypeRow(
                    name: "Markdown 文件",
                    ext: ".md",
                    defaultName: "新建 Markdown 文件",
                    method: "创建空文件"
                )
                FileTypeRow(
                    name: "Word 文档",
                    ext: ".docx",
                    defaultName: "新建 Word 文档",
                    method: "模板复制"
                )
                FileTypeRow(
                    name: "Excel 表格",
                    ext: ".xlsx",
                    defaultName: "新建 Excel 表格",
                    method: "模板复制"
                )
                FileTypeRow(
                    name: "PowerPoint 演示",
                    ext: ".pptx",
                    defaultName: "新建 PowerPoint 演示",
                    method: "模板复制"
                )
                FileTypeRow(
                    name: "空白文件",
                    ext: "无",
                    defaultName: "新建文件",
                    method: "创建空文件"
                )
                FileTypeRow(
                    name: "文件夹",
                    ext: "无",
                    defaultName: "新建文件夹",
                    method: "创建目录"
                )
            }

            Section {
                Text("重名时自动递增编号（如「新建文件 2」「新建文件 3」）。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("新建文件")
    }
}

struct FileTypeRow: View {
    let name: String
    let ext: String
    let defaultName: String
    let method: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
            HStack {
                Label(ext, systemImage: "doc")
                Spacer()
                Text("默认名: \(defaultName)")
                Spacer()
                Text(method)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
