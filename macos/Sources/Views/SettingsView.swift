import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("设置")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Toggle("开机自启动", isOn: $settings.launchAtLogin)
                        .toggleStyle(.switch)
                }

                Divider()

                Text("显示按钮")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("复制全部", isOn: $settings.showCopyAll)
                        .toggleStyle(.switch)
                    Toggle("逐条复制", isOn: $settings.showCopyOne)
                        .toggleStyle(.switch)
                    Toggle("去重", isOn: $settings.showDedup)
                        .toggleStyle(.switch)
                    Toggle("去空白", isOn: $settings.showTrim)
                        .toggleStyle(.switch)
                    Toggle("清空", isOn: $settings.showClear)
                        .toggleStyle(.switch)
                }
            }

            Spacer()

            Text("Clipboard10 v1.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .frame(width: 280, height: 380)
        .background(Color(hex: "FFF8E7"))
    }
}
