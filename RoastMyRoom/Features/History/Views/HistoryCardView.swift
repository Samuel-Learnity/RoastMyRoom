import SwiftUI

struct HistoryCardView: View {
    let scan: RoomScan
    let isLocked: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Photo
            if let uiImage = UIImage(data: scan.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minHeight: 0)
                    .aspectRatio(4/3, contentMode: .fit)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.2))
                    .aspectRatio(4/3, contentMode: .fit)
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Score badge
            Text(String(format: "%.1f", scan.overallScore))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 4)
                .padding(12)

            // Lock overlay for free users
            if isLocked {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }
}
