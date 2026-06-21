import SwiftUI

/// The shareable history card. Fixed colors (not theme-dependent) so the exported image is
/// consistent, with a subtle "Chronicle" wordmark watermark + App Store CTA for organic growth.
struct HistoryCard: View {
    let entry: HistoryEntry

    var body: some View {
        ZStack {
            Color.white
            VStack(spacing: 14) {
                Text(entry.longDateLabel.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.chronAccent)

                Text(entry.yearLabel)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)

                Text(entry.event)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color(white: 0.15))
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.7)

                Rectangle()
                    .fill(Color.chronAccent.opacity(0.25))
                    .frame(width: 64, height: 2)

                Spacer(minLength: 2)

                Text("Chronicle")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.chronAccent)
                Text("One day in history, daily · on the App Store")
                    .font(.caption)
                    .foregroundStyle(Color(white: 0.55))
            }
            .padding(34)
        }
        .frame(width: 360, height: 360)
    }

    @MainActor func render() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 3
        return renderer.uiImage
    }
}
