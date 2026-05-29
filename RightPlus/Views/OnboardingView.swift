import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0

    private let steps: [(title: String, description: String, icon: String, action: () -> Void, required: Bool)] = [
        (
            "开启 Finder 扩展",
            "RightPlus 需要 Finder 扩展才能在右键菜单中显示功能。\n\n请在系统设置中找到 RightPlus 并启用。",
            "puzzlepiece.extension",
            { openSystemPreferences("com.apple.ExtensionsPreferences") },
            true
        ),
        (
            "授予完全磁盘访问",
            "授予完全磁盘访问后，RightPlus 可以在任意文件夹中创建文件。\n\n如果不授予，部分受保护目录可能无法使用新建文件功能。",
            "lock.shield",
            { openSystemPreferences("com.apple.preference.security?Privacy_AllFiles") },
            false
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                Text("欢迎使用 RightPlus")
                    .font(.title)
                    .fontWeight(.bold)
                Text("让 Finder 右键菜单真正好用")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            Divider()

            // Step content
            if currentStep < steps.count {
                let step = steps[currentStep]
                VStack(spacing: 16) {
                    HStack {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 20)

                    Image(systemName: step.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                        .padding(.top, 8)

                    Text("第 \(currentStep + 1) 步：\(step.title)")
                        .font(.headline)

                    Text(step.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)

                    if step.required {
                        Label("必须", systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Label("推荐", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Button("打开系统设置") {
                        step.action()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Navigation buttons
                HStack {
                    if !step.required {
                        Button("跳过") {
                            nextStep()
                        }
                    }
                    Spacer()
                    Button(currentStep < steps.count - 1 ? "下一步" : "完成设置") {
                        nextStep()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 520, height: 480)
    }

    private func nextStep() {
        if currentStep < steps.count - 1 {
            currentStep += 1
        } else {
            SettingsManager.shared.set(true, for: .onboardingCompleted)
            isPresented = false
        }
    }

    private static func openSystemPreferences(_ pane: String) {
        if let url = URL(string: "x-apple.systempreferences:\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}

private func openSystemPreferences(_ pane: String) {
    if let url = URL(string: "x-apple.systempreferences:\(pane)") {
        NSWorkspace.shared.open(url)
    }
}
