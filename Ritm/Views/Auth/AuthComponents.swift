import SwiftUI

/// Brand gradient with soft, drifting color blobs and floating habit icons.
struct AnimatedAuthBackground: View {
    @State private var animate = false

    private let symbols: [(String, CGFloat, CGFloat, CGFloat)] = [
        ("flame.fill", -0.36, -0.40, 26), ("checkmark.circle.fill", 0.34, -0.30, 30),
        ("trophy.fill", -0.30, 0.18, 24), ("heart.fill", 0.38, 0.10, 22),
        ("star.fill", 0.05, -0.46, 18), ("figure.run", -0.08, 0.42, 28),
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.28, green: 0.30, blue: 0.92), Color(red: 0.50, green: 0.27, blue: 0.90), Color(red: 0.78, green: 0.25, blue: 0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.cyan.opacity(0.45))
                    .frame(width: 320, height: 320)
                    .blur(radius: 70)
                    .offset(x: animate ? -110 : 90, y: animate ? -250 : -140)
                Circle()
                    .fill(Color.pink.opacity(0.45))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: animate ? 120 : -60, y: animate ? 260 : 120)
                Circle()
                    .fill(Color.mint.opacity(0.30))
                    .frame(width: 220, height: 220)
                    .blur(radius: 60)
                    .offset(x: animate ? 80 : -120, y: animate ? -20 : 60)

                ForEach(symbols.indices, id: \.self) { index in
                    let symbol = symbols[index]
                    Image(systemName: symbol.0)
                        .font(.system(size: symbol.3, weight: .bold))
                        .foregroundStyle(.white.opacity(0.14))
                        .rotationEffect(.degrees(animate ? 12 : -12))
                        .offset(
                            x: proxy.size.width * symbol.1,
                            y: proxy.size.height * symbol.2 + (animate ? -14 : 14)
                        )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
        .accessibilityHidden(true)
    }
}

/// A rounded input with an icon, focus glow, live validation tick and error text.
struct AuthTextField<Field: Hashable>: View {
    let icon: String
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var state: FieldState = .empty
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var capitalization: TextInputAutocapitalization = .never
    var submitLabel: SubmitLabel = .next
    var focus: FocusState<Field?>.Binding
    let field: Field
    var onSubmit: () -> Void = {}

    @State private var isRevealed = false
    @State private var hasLeftField = false

    private var isFocused: Bool { focus.wrappedValue == field }
    private var showsError: Bool { state.message != nil && (hasLeftField || !isFocused) && !text.isEmpty }

    private var borderColor: Color {
        if showsError { return .red }
        if isFocused { return .indigo }
        if state.isValid { return .green.opacity(0.6) }
        return Color(.separator).opacity(0.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isFocused ? Color.indigo : Color.secondary)
                    .frame(width: 22)
                    .symbolEffect(.bounce, value: isFocused)

                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .submitLabel(submitLabel)
                .focused(focus, equals: field)
                .onSubmit(onSubmit)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? Text("Hide password") : Text("Show password"))
                }

                if state.isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color(.secondarySystemBackground).opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused || showsError ? 2 : 1)
            )
            .shadow(color: isFocused ? Color.indigo.opacity(0.25) : .clear, radius: 10, y: 4)

            if showsError, let message = state.message {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showsError)
        .onChange(of: isFocused) { wasFocused, nowFocused in
            if wasFocused && !nowFocused { hasLeftField = true }
        }
    }
}

/// Big gradient call-to-action with a loading state.
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var icon: String?
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Text(title)
                        if let icon {
                            Image(systemName: icon)
                                .flipsForRightToLeftLayoutDirection(true)
                        }
                    }
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(LinearGradient.brand).opacity(isEnabled ? 1 : 0.45))
            .shadow(color: .indigo.opacity(isEnabled ? 0.35 : 0), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

/// Horizontal shake used when something goes wrong.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(shakes * .pi * 4), y: 0))
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
        .padding(14)
        .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
