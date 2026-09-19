import SwiftUI

struct MenuPanel<Content: View>: View {
    var title: String
    var systemImage: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct MenuChoice: Identifiable {
    var id: String
    var title: String
    var accessibilityLabel: String
    var accessibilityIdentifier: String
    var isSelected: Bool
    var action: () -> Void
}

struct MenuChoiceRow: View {
    var choices: [MenuChoice]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(choices) { choice in
                choiceButton(choice)
            }
        }
    }

    @ViewBuilder
    private func choiceButton(_ choice: MenuChoice) -> some View {
        let button = Button(action: choice.action) {
            Text(choice.title)
                .font(.subheadline.weight(choice.isSelected ? .semibold : .medium))
                .frame(maxWidth: .infinity)
        }
        .controlSize(.small)
        .accessibilityLabel(choice.accessibilityLabel)
        .accessibilityIdentifier(choice.accessibilityIdentifier)
        .accessibilityAddTraits(choice.isSelected ? .isSelected : [])

        if choice.isSelected {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }
}
