import SocialLoginSDK
import SwiftUI

struct DemoEmailAuthView: View {
    @StateObject private var viewModel = DemoEmailAuthViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Email Auth (SDK networking only)")
                    .font(.headline)
                Text("Host apps must build their own UI. This screen is for API smoke tests.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let sessionHint = viewModel.sessionHint {
                    Text(sessionHint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                field("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                field("Password", text: $viewModel.password, secure: true)
                field("Code", text: $viewModel.code)
                    .keyboardType(.numberPad)
                field("New Password", text: $viewModel.newPassword, secure: true)
                field("Current Password (change)", text: $viewModel.currentPassword, secure: true)

                Group {
                    sectionTitle("Register / Sign-in")
                    buttonRow("Check Registered", viewModel.checkRegistered)
                    buttonRow("Send Sign-Up Code", viewModel.requestSignUpCode)
                    buttonRow("Check Sign-Up Code", viewModel.checkSignUpCode)
                    buttonRow("Complete Sign-Up", viewModel.completeSignUp)
                    buttonRow("Email Sign-In", viewModel.signIn)
                }

                Group {
                    sectionTitle("Session (refresh_token / sign_out)")
                    buttonRow("Refresh Token", viewModel.refreshSession)
                    buttonRow("Sign Out", viewModel.signOut)
                }

                Group {
                    sectionTitle("Forgot Password")
                    buttonRow("Send Reset Code", viewModel.requestResetCode)
                    buttonRow("Check Reset Code", viewModel.checkPasswordResetCode)
                    buttonRow("Reset Password", viewModel.resetPassword)
                }

                Group {
                    sectionTitle("Change Password (requires session)")
                    buttonRow("Send Change Code", viewModel.requestChangeCode)
                    buttonRow("Check Change Code", viewModel.checkPasswordChangeCode)
                    buttonRow("Change (Current Password)", viewModel.changePasswordWithCurrent)
                    buttonRow("Change (Code)", viewModel.changePasswordWithCode)
                }

                if viewModel.isLoading {
                    ProgressView("Working...")
                }
                if let status = viewModel.statusMessage {
                    Text(status)
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                if let registered = viewModel.isRegistered {
                    Text("is_registered = \(registered)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !viewModel.existsLoginTypes.isEmpty {
                        Text("exists_login_types = \(viewModel.existsLoginTypes.map(\.rawValue).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Email Auth")
        .modifier(ScrollDismissesKeyboardIfAvailable())
        .onAppear {
            viewModel.reloadSessionHint()
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .padding(.top, 4)
    }

    private func field(_ title: String, text: Binding<String>, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            if secure {
                SecureField(title, text: text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(title, text: text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func buttonRow(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(viewModel.isLoading)
    }
}

private struct ScrollDismissesKeyboardIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollDismissesKeyboard(.interactively)
        } else {
            content
        }
    }
}
