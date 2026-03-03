import SwiftUI

struct HistoryCardView: View {
    let scan: RoomScan
    let isLocked: Bool
    @State private var thumbnail: UIImage?

    private var glowColors: [Color] {
        switch scan.overallScore {
        case 0..<4: [Color.aiCoral, Color.aiPeach, Color.aiPink]
        case 4..<6: [Color.aiPeach, Color.aiCoral, Color.aiLavender]
        case 6..<8: [Color.aiLightBlue, Color.aiPurple, Color.aiLavender]
        default:    [Color.aiPurple, Color.aiPink, Color.aiLightBlue]
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Fixed aspect ratio container
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
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // Score + verdict bottom-left
            HStack(spacing: 6) {
                Text(String(format: "%.1f", scan.overallScore))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if !scan.verdict.isEmpty {
                    Text(scan.verdict)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .neonGlow(colors: glowColors, radius: 8, opacity: 0.5)

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
