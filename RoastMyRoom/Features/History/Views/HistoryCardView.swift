import SwiftUI

struct HistoryCardView: View {
    let scan: RoomScan
    let isLocked: Bool
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Fixed aspect ratio container — guarantees uniform card size
            Color.clear
                .aspectRatio(4/3, contentMode: .fit)
                .background {
                    if let uiImage = thumbnail {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.white.opacity(0.08)
                            .shimmer(isActive: true)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Score badge with glass pill
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", scan.overallScore))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if !scan.verdict.isEmpty {
                    Text(scan.verdict.uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.scoreColor(for: scan.overallScore))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(10)

            // Lock overlay for free users
            if isLocked {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.rsCardStroke, lineWidth: 1)
        )
        .task(id: scan.id) {
            guard thumbnail == nil else { return }
            let data = scan.imageData
            let decoded = await Task.detached {
                UIImage(data: data)
            }.value
            thumbnail = decoded
        }
    }
}
