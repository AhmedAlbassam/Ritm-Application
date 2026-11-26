import SwiftUI

/// Welcome screen with Log In / Sign Up.
struct AuthView: View {
    enum Mode: Hashable { case login, signUp }

    @Environment(SessionStore.self) private var session
    @State private var mode: Mode = .login
    @State private var logoBreath = false
    @Namespace private var modeNamespace

    var body: some View {
        // NavigationStack only to host the keyboard toolbar; its bar stays hidden.
        NavigationStack {
            authContent
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var authContent: some View {
        ZStack {
            AnimatedAuthBackground()

            ScrollView {
                VStack(spacing: 26) {
                    header
                        .padding(.top, 40)

                    VStack(spacing: 20) {
                        modePicker
                        Group {
                            switch mode {
                            case .login:
                                LoginForm()
                                    .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                            case .signUp:
                                SignUpFlow()
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                            }
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 30, y: 16)

                    if !session.isOnlineAvailable {
                        Label("Online accounts aren't set up yet. See the README to connect Firebase.", systemImage: "info.circle.fill")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }

                    #if DEBUG
                    demoButton
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: mode)
    }

    private var header: some View {
        VStack(spacing: 12) {
            RitmLogo(height: 92)
                .scaleEffect(logoBreath ? 1.04 : 0.97)
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                        logoBreath = true
                    }
                }
            Text("Build your daily rhythm — together.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            modeButton(.login, title: "Log In")
            modeButton(.signUp, title: "Sign Up")
        }
        .padding(4)
        .background(Color(.tertiarySystemFill), in: Capsule())
        .sensoryFeedback(.selection, trigger: mode)
    }

    private func modeButton(_ value: Mode, title: LocalizedStringKey) -> some View {
        Button {
            mode = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(mode == value ? Color.white : Color.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background {
                    if mode == value {
                        Capsule()
                            .fill(LinearGradient.brand)
                            .matchedGeometryEffect(id: "modePill", in: modeNamespace)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(mode == value ? .isSelected : [])
    }

    #if DEBUG
    private var demoButton: some View {
        Button {
            Task { await session.signInAsDemoAdmin() }
        } label: {
            Label("Developer: log in as admin (demo data)", systemImage: "hammer.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.white.opacity(0.18), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.96))
    }
    #endif
}

// MARK: - Log In

private struct LoginForm: View {
    enum Field: Hashable { case email, password }

    @Environment(SessionStore.self) private var session
    @FocusState private var focus: Field?
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var shakes: CGFloat = 0
    @State private var showForgotPassword = false
    @State private var failureCount = 0

    private var canSubmit: Bool { FormValidation.email(email).isValid && !password.isEmpty }

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back! 👋")
                    .font(.title2.weight(.bold))
                Text("Log in to see your goals and challenges.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let errorMessage {
                ErrorBanner(message: errorMessage)
            }

            AuthTextField(
                icon: "envelope.fill", placeholder: "Email", text: $email,
                state: FormValidation.email(email), keyboard: .emailAddress, contentType: .emailAddress,
                focus: $focus, field: .email, onSubmit: { focus = .password }
            )

            AuthTextField(
                icon: "lock.fill", placeholder: "Password", text: $password,
                isSecure: true, contentType: .password, submitLabel: .go,
                focus: $focus, field: .password, onSubmit: submit
            )

            HStack {
                Spacer()
                Button("Forgot password?") { showForgotPassword = true }
                    .font(.footnote.weight(.semibold))
                    .tint(.indigo)
            }

            PrimaryButton(title: "Log In", icon: "arrow.right", isLoading: isLoading, isEnabled: canSubmit, action: submit)
        }
        .modifier(ShakeEffect(shakes: shakes))
        .sensoryFeedback(.error, trigger: failureCount)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: errorMessage)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(initialEmail: email)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func submit() {
        guard canSubmit, !isLoading else { return }
        focus = nil
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await session.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                failureCount += 1
                withAnimation(.default) { shakes += 1 }
            }
            isLoading = false
        }
    }
}

// MARK: - Sign Up

private struct SignUpFlow: View {
    enum Field: Hashable { case name, age, email, phone, password, confirm }

    @Environment(SessionStore.self) private var session
    @FocusState private var focus: Field?
    @State private var data = SignUpData()
    @State private var step = 0
    @State private var isForward = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var shakes: CGFloat = 0
    @State private var failureCount = 0

    private let stepCount = 3

    private var stepIsValid: Bool {
        switch step {
        case 0: FormValidation.name(data.name).isValid && FormValidation.age(data.age).isValid
        case 1: FormValidation.email(data.email).isValid && FormValidation.phone(data.phone).isValid
        default: FormValidation.password(data.password).isValid && FormValidation.confirm(data.confirmPassword, matches: data.password).isValid
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            stepIndicator

            if let errorMessage {
                ErrorBanner(message: errorMessage)
            }

            ZStack {
                switch step {
                case 0: aboutYouStep.transition(stepTransition)
                case 1: contactStep.transition(stepTransition)
                default: passwordStep.transition(stepTransition)
                }
            }

            HStack(spacing: 12) {
                if step > 0 {
                    Button {
                        go(to: step - 1)
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.headline)
                            .foregroundStyle(.indigo)
                            .frame(width: 54, height: 54)
                            .background(Color.indigo.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel(Text("Back"))
                    .transition(.scale.combined(with: .opacity))
                }

                if step < stepCount - 1 {
                    PrimaryButton(title: "Next", icon: "arrow.right", isEnabled: stepIsValid) {
                        go(to: step + 1)
                    }
                } else {
                    PrimaryButton(title: "Create Account", icon: "sparkles", isLoading: isLoading, isEnabled: stepIsValid, action: submit)
                }
            }
        }
        .modifier(ShakeEffect(shakes: shakes))
        .sensoryFeedback(.error, trigger: failureCount)
        .sensoryFeedback(.selection, trigger: step)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: errorMessage)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var stepIndicator: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color(.tertiarySystemFill)))
                        .frame(height: 6)
                }
            }
            Text("Step \(step + 1) of \(stepCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func stepHeader(_ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.bold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var aboutYouStep: some View {
        VStack(spacing: 14) {
            stepHeader("Nice to meet you! 👋", "Tell us a little about yourself.")
            AuthTextField(
                icon: "person.fill", placeholder: "Full name", text: $data.name,
                state: FormValidation.name(data.name), contentType: .name, capitalization: .words,
                focus: $focus, field: .name, onSubmit: { focus = .age }
            )
            AuthTextField(
                icon: "birthday.cake.fill", placeholder: "Age", text: $data.age,
                state: FormValidation.age(data.age), keyboard: .numberPad,
                focus: $focus, field: .age
            )
        }
    }

    private var contactStep: some View {
        VStack(spacing: 14) {
            stepHeader("How can friends find you? 🔎", "Friends add you by your email or phone number.")
            AuthTextField(
                icon: "envelope.fill", placeholder: "Email", text: $data.email,
                state: FormValidation.email(data.email), keyboard: .emailAddress, contentType: .emailAddress,
                focus: $focus, field: .email, onSubmit: { focus = .phone }
            )
            AuthTextField(
                icon: "phone.fill", placeholder: "Phone number (+966…)", text: $data.phone,
                state: FormValidation.phone(data.phone), keyboard: .phonePad, contentType: .telephoneNumber,
                focus: $focus, field: .phone
            )
        }
    }

    private var passwordStep: some View {
        let strength = PasswordStrength(data.password)
        return VStack(spacing: 14) {
            stepHeader("Secure your account 🔒", "Choose a password you don't use anywhere else.")
            AuthTextField(
                icon: "lock.fill", placeholder: "Password", text: $data.password,
                state: FormValidation.password(data.password), isSecure: true, contentType: .newPassword,
                focus: $focus, field: .password, onSubmit: { focus = .confirm }
            )

            if !data.password.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 5) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(index < strength.score ? strength.color : Color(.tertiarySystemFill))
                                .frame(height: 5)
                        }
                        Text(strength.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(strength.color)
                            .frame(minWidth: 70, alignment: .trailing)
                    }
                    requirement("At least 8 characters", met: strength.hasLength)
                    requirement("Letters and numbers", met: strength.hasLetter && strength.hasNumber)
                    requirement("A symbol for extra strength (optional)", met: strength.hasSymbol)
                }
                .padding(.horizontal, 4)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: strength.score)
                .transition(.opacity)
            }

            AuthTextField(
                icon: "lock.rotation", placeholder: "Confirm password", text: $data.confirmPassword,
                state: FormValidation.confirm(data.confirmPassword, matches: data.password), isSecure: true,
                contentType: .newPassword, submitLabel: .done,
                focus: $focus, field: .confirm, onSubmit: submit
            )
        }
    }

    private func requirement(_ text: LocalizedStringKey, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? Color.green : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
            Text(text)
                .foregroundStyle(met ? Color.primary : Color.secondary)
        }
        .font(.caption.weight(.medium))
    }

    private func go(to newStep: Int) {
        isForward = newStep > step
        errorMessage = nil
        focus = nil
        step = newStep
    }

    private func submit() {
        guard stepIsValid, !isLoading else { return }
        focus = nil
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await session.signUp(data)
            } catch {
                errorMessage = error.localizedDescription
                failureCount += 1
                withAnimation(.default) { shakes += 1 }
                // Send them back to the step that needs fixing.
                if let backendError = error as? BackendError {
                    switch backendError {
                    case .emailInUse, .invalidEmail: go(to: 1)
                    default: break
                    }
                }
            }
            isLoading = false
        }
    }
}

// MARK: - Forgot password

private struct ForgotPasswordSheet: View {
    enum Field: Hashable { case email }

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?
    @State private var email: String
    @State private var isLoading = false
    @State private var didSend = false
    @State private var errorMessage: String?

    init(initialEmail: String) {
        _email = State(initialValue: initialEmail)
    }

    var body: some View {
        VStack(spacing: 18) {
            if didSend {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(LinearGradient.brand)
                    .symbolEffect(.bounce, value: didSend)
                    .padding(.top, 20)
                Text("Check your inbox")
                    .font(.title2.weight(.bold))
                Text("We sent a link to reset your password to \(email).")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                PrimaryButton(title: "Done") { dismiss() }
            } else {
                Image(systemName: "key.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(LinearGradient.brand)
                    .padding(.top, 20)
                Text("Reset your password")
                    .font(.title2.weight(.bold))
                Text("Enter your account email and we'll send you a reset link.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                }
                AuthTextField(
                    icon: "envelope.fill", placeholder: "Email", text: $email,
                    state: FormValidation.email(email), keyboard: .emailAddress, contentType: .emailAddress,
                    submitLabel: .send, focus: $focus, field: .email, onSubmit: send
                )
                PrimaryButton(title: "Send Reset Link", icon: "paperplane.fill", isLoading: isLoading, isEnabled: FormValidation.email(email).isValid, action: send)
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: didSend)
        .sensoryFeedback(.success, trigger: didSend)
    }

    private func send() {
        guard FormValidation.email(email).isValid, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await session.sendPasswordReset(email: email)
                didSend = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

/// Shown for a moment while the saved session is restored.
struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            AnimatedAuthBackground()
            RitmLogo(height: 96)
                .scaleEffect(pulse ? 1.06 : 0.94)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
                }
        }
    }
}

#if DEBUG
#Preview {
    AuthView()
        .environment(SessionStore())
}
#endif
