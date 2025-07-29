import SwiftUI

// MARK: - Custom Button Styles

struct TodomaiButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let textColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .heavy))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black, lineWidth: 6)
            )
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(nil, value: configuration.isPressed) // Remove animation
    }
}

struct CircleButtonStyle: ButtonStyle {
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .heavy))
            .foregroundColor(foregroundColor)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 4)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(nil, value: configuration.isPressed) // Remove animation
    }
}

// MARK: - View Extensions

extension View {
    func todomaiBorder(width: CGFloat = 6) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: width)
        )
    }
    
    func todomaiCard() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .todomaiBorder()
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Custom Colors (EXACT from watchOS)

extension Color {
    // Original watchOS colors
    static let todomaiLife = Color(red: 1.0, green: 0.584, blue: 0.0) // Orange
    static let todomaiWork = Color(red: 0.0, green: 0.478, blue: 1.0) // Blue
    static let todomaiSchool = Color(red: 0.557, green: 0.267, blue: 0.678) // Purple
    static let todomaiThisWeek = Color(red: 0.478, green: 0.686, blue: 0.961) // Light Blue
    static let todomaiCalendar = Color(red: 1.0, green: 0.431, blue: 0.431) // Pastel Red
    static let todomaiLater = Color(red: 1.0, green: 0.584, blue: 0.0) // Orange
}

// MARK: - Typography (EXACT from watchOS)

extension Font {
    static let todomaiTitle = Font.system(size: 34, weight: .heavy)
    static let todomaiHeadline = Font.system(size: 20, weight: .heavy)
    static let todomaiBody = Font.system(size: 17, weight: .regular)
    static let todomaiBodyBold = Font.system(size: 17, weight: .heavy)
    static let todomaiCaption = Font.system(size: 13, weight: .regular)
    static let todomaiCaptionBold = Font.system(size: 13, weight: .heavy)
    
    // Additional specific sizes
    static let todomaiAppTitle = Font.system(size: 48, weight: .heavy)
    static let todomaiBackButton = Font.system(size: 20, weight: .heavy)
    static let todomaiEmptyIcon = Font.system(size: 60, weight: .light)
    static let todomaiSmallIcon = Font.system(size: 11)
    static let todomaiDayToggle = Font.system(size: 14, weight: .medium)
}

// MARK: - Layout Constants (EXACT from watchOS)

struct TodomaiLayout {
    // Padding
    static let standardHorizontalPadding: CGFloat = 24
    static let sectionVerticalPadding: CGFloat = 20
    static let taskRowVerticalPadding: CGFloat = 12
    static let taskRowHorizontalPadding: CGFloat = 16
    static let mainTitleTopPadding: CGFloat = 40
    static let floatingButtonBottomPadding: CGFloat = 24
    static let emptyStateTopPadding: CGFloat = 100
    
    // Spacing
    static let mainMenuButtonSpacing: CGFloat = 20
    static let taskListItemSpacing: CGFloat = 16
    static let titleToContentSpacing: CGFloat = 24
    static let dayButtonSpacing: CGFloat = 8
    static let taskRowCheckboxSpacing: CGFloat = 16
    static let taskMetadataSpacing: CGFloat = 12
    static let floatingButtonSpacing: CGFloat = 20
    
    // Frame Sizes
    static let standardButtonHeight: CGFloat = 56
    static let circleButtonSize: CGFloat = 64
    static let modeSwitcherSize: CGFloat = 64
    static let modeSwitcherInnerSize: CGFloat = 20
    static let checkboxSize: CGFloat = 28
    static let taskColorIndicatorWidth: CGFloat = 6
    static let taskColorIndicatorHeight: CGFloat = 40
    static let dayButtonWidth: CGFloat = 60
    static let dayButtonHeight: CGFloat = 80
    static let colorSelectionCircleSize: CGFloat = 56
    static let listIconSize: CGFloat = 48
    static let strikethroughHeight: CGFloat = 2
    static let dayToggleSize: CGFloat = 40
    static let smallIconSize: CGFloat = 16
    static let settingsModeIndicatorSize: CGFloat = 30
    static let smallColorDotSize: CGFloat = 12
    
    // Corner Radius
    static let standardCornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 4
    
    // Border Widths
    static let standardButtonBorder: CGFloat = 6
    static let circleButtonBorder: CGFloat = 4
    static let checkboxBorder: CGFloat = 3
    static let selectedDayButtonBorder: CGFloat = 4
    static let unselectedDayButtonBorder: CGFloat = 2
    static let taskCardBorder: CGFloat = 4
    static let modeSwitcherBorder: CGFloat = 4
    static let listCardBorder: CGFloat = 3
}

// MARK: - Animation Values (EXACT from watchOS)

struct TodomaiAnimation {
    static let standardSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let taskCompletionSpring = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let buttonPressEaseInOut = Animation.easeInOut(duration: 0.1)
    static let taskCompletionEaseInOut = Animation.easeInOut(duration: 0.2)
    static let strikethroughEaseInOut = Animation.easeInOut(duration: 0.3)
    static let taskDeletionEaseOut = Animation.easeOut(duration: 0.3)
}

// MARK: - Task Completion Animation

struct TaskCompletionModifier: ViewModifier {
    @Binding var isCompleted: Bool
    let onComplete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isCompleted ? 1.1 : 1.0)
            .animation(nil, value: isCompleted) // Remove animation
            .onChange(of: isCompleted) { oldValue, newValue in
                if newValue {
                    onComplete()
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
    }
}

// MARK: - Checkbox View (EXACT from watchOS)

struct TodomaiCheckbox: View {
    @Binding var isChecked: Bool
    let color: Color
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            ZStack {
                Circle()
                    .strokeBorder(Color.black, lineWidth: TodomaiLayout.checkboxBorder)
                    .background(
                        Circle()
                            .fill(isChecked ? color : Color.clear)
                    )
                    .frame(width: TodomaiLayout.checkboxSize, height: TodomaiLayout.checkboxSize)
                
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: TodomaiLayout.checkboxSize * 0.5, weight: .heavy))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

