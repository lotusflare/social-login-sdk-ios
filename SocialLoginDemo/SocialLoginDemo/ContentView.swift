import SocialLoginSDK
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DemoLoginViewModel()

    var body: some View {
        TabView {
            NavigationView {
                socialTab
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Social", systemImage: "person.crop.circle")
            }

            NavigationView {
                DemoEmailAuthView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Email", systemImage: "envelope")
            }
        }
        .dismissKeyboardToolbar()
    }

    private var socialTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sessionStatusSection
                environmentSection
                actionSection
                resultSection
            }
            .padding()
        }
        .navigationTitle("Social Login Demo")
    }

    private var sessionStatusSection: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            if viewModel.isRestoringSession {
                ProgressView()
                    .controlSize(.small)
                Text("Restoring session...")
                    .font(.subheadline)
            } else if let session = viewModel.session {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Signed in")
                        .font(.subheadline.weight(.semibold))
                    Text(statusSubtitle(for: session))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Not signed in")
                    .font(.subheadline.weight(.semibold))
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var statusColor: Color {
        if viewModel.isRestoringSession {
            return .orange
        }
        return viewModel.isLoggedIn ? .green : .gray
    }

    private func statusSubtitle(for session: SocialLoginSession) -> String {
        let name = [session.firstName, session.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return session.primaryEmail
            ?? (name.isEmpty ? nil : name)
            ?? (session.userId.isEmpty ? "session" : session.userId)
    }

    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Environment")
                .font(.headline)

            Picker("Environment", selection: $viewModel.environment) {
                ForEach(SocialLoginEnvironment.allCases, id: \.self) { environment in
                    Text(environment.rawValue.capitalized).tag(environment)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.environment) { _ in
                viewModel.setup()
            }
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        if viewModel.isLoggedIn {
            VStack(spacing: 12) {
                Button("Refresh Session") {
                    viewModel.refreshSession()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Sign Out") {
                    viewModel.signOut()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                if viewModel.isLoading {
                    ProgressView("Working...")
                }
            }
        } else {
            VStack(spacing: 12) {
                SocialLoginButtonsSection(isLoading: viewModel.isLoading || viewModel.isRestoringSession) { provider in
                    viewModel.signIn(provider: provider)
                }

                if viewModel.isLoading {
                    ProgressView("Signing in...")
                }
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Result")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let errorMessage = viewModel.errorMessage {
                        resultRow("Error", errorMessage, monospaced: false)
                    }

                    if let session = viewModel.session {
                        resultRow("Environment", session.environment.rawValue)
                        resultRow("User ID", session.userId.isEmpty ? "-" : session.userId)
                        resultRow("Primary Email", displayValue(session.primaryEmail))
                        resultRow("First Name", displayValue(session.firstName))
                        resultRow("Last Name", displayValue(session.lastName))
                        resultRow("Is New User", session.isNewUser.map { String($0) } ?? "-")
                        resultRow("Access Expires", dateValue(session.accessTokenExpiresAt))
                        resultRow("Refresh Expires", dateValue(session.refreshTokenExpiresAt))
                        resultRow("Backend Access Token", displayValue(session.accessToken), monospaced: true)
                        resultRow("Backend Refresh Token", displayValue(session.refreshToken), monospaced: true)
                        resultRow(
                            "Providers",
                            session.providers?.map(\.provider).joined(separator: ", ") ?? "-"
                        )
                    } else if viewModel.errorMessage == nil {
                        Text("No active session.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 420)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resultRow(_ title: String, _ value: String, monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(monospaced ? .system(.subheadline, design: .monospaced) : .subheadline)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func displayValue(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        return value
    }

    private func dateValue(_ date: Date?) -> String {
        guard let date else { return "-" }
        return ISO8601DateFormatter().string(from: date)
    }
}

#Preview {
    ContentView()
}
