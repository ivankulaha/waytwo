import SwiftUI
import UIKit

struct ProfileAvatarView: View {
    let colorId: String
    let photo: UIImage?
    let displayName: String
    var showsName: Bool = true

    private var initial: String? {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let char = trimmed.first else { return nil }
        return String(char).uppercased()
    }

    var body: some View {
        VStack(spacing: Tokens.Spacing.lg) {
            avatarCircle
                .frame(width: Tokens.Size.avatar, height: Tokens.Size.avatar)
                .clipShape(Circle())

            if showsName {
                Text(displayName)
                    .font(.system(size: Tokens.FontSize.xl, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    @ViewBuilder
    private var avatarCircle: some View {
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle()
                    .fill(AppColors.avatarGlassBg)

                if let initial {
                    Text(initial)
                        .font(.system(size: Tokens.FontSize.avatarInitial, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: Tokens.FontSize.avatarInitial, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
    }
}
