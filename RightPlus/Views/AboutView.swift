import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cursorarrow.click.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("RightPlus")
                .font(.title)
                .fontWeight(.bold)

            Text("macOS Finder 右键增强工具")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("版本 1.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}
