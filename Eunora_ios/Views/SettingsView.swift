import SwiftUI

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: EunoraSession?
    @State private var email = ""
    @State private var password = ""
    @State private var sailorName = ""
    @State private var creating = false
    @State private var busy = false
    @State private var message: String?

    private static let api = EunoraAPI.configured

    var body: some View {
        Form {
            Section("Account protection") {
                if let api = Self.api {
                    if session != nil {
                        Text(session?.needsRefresh == true ? "Reconnect to verify your session." : "You’re signed in.")
                        Button("Log out", role: .destructive) { Task { await logout(api) } }
                            .frame(minHeight: 44)
                        Text("Account deletion is currently unavailable in the app.")
                            .font(.footnote)
                    } else {
                        Toggle("Create an account", isOn: $creating)
                        if creating {
                            TextField("Sailor name", text: $sailorName)
                                .textContentType(.nickname)
                        }
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Password", text: $password)
                            .textContentType(creating ? .newPassword : .password)
                        Button(creating ? "Create account" : "Log in") {
                            Task { await authenticate(api) }
                        }
                        .frame(minHeight: 44)
                        .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  password.isEmpty || (creating && sailorName.trimmingCharacters(in: .whitespacesAndNewlines).count < 3))
                    }
                } else {
                    Text("Account protection is unavailable in this build. You can keep sailing as a guest.")
                }
                if busy { ProgressView("Connecting…") }
                if let message { Text(message).font(.footnote) }
            }
            .disabled(busy)

            Section("Data and privacy") {
                Text("Quest progress, check-ins, and private reflections stay on this device. Signing in doesn’t upload them.")
            }

            Section("Accessibility") {
                Text("Eunora follows your iPhone’s text size and Reduce Motion settings. You can change them under Accessibility in Settings.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .task(id: scenePhase) {
            if let api = Self.api, scenePhase == .active { await restore(api) }
        }
    }

    private func authenticate(_ api: EunoraAPI) async {
        guard !busy else { return }
        busy = true
        message = nil
        defer { busy = false; password = "" }
        do {
            let reply = try await api.authenticate(email: email, password: password, sailorName: creating ? sailorName : nil)
            if let received = reply.session {
                try SessionKeychain(origin: api.baseURL).save(received)
                session = received
                email = ""
                sailorName = ""
            } else if reply.needsConfirm == true {
                creating = false
                message = "Check your email to confirm your account, then log in."
            } else {
                throw EunoraAPI.Failure.invalidResponse
            }
        } catch {
            show(error)
        }
    }

    private func restore(_ api: EunoraAPI) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        let keychain = SessionKeychain(origin: api.baseURL)
        do {
            session = try keychain.load()
            if let stored = session, stored.needsRefresh {
                let refreshed = try await api.refresh(stored)
                try keychain.save(refreshed)
                session = refreshed
            }
        } catch EunoraAPI.Failure.response(status: 401, message: _) {
            do {
                try keychain.clear()
                session = nil
                message = "Your login expired. Please log in again."
            } catch {
                show(error)
            }
        } catch {
            show(error)
        }
    }

    private func logout(_ api: EunoraAPI) async {
        guard !busy, let stored = session else { return }
        busy = true
        defer { busy = false }
        do {
            try SessionKeychain(origin: api.baseURL).clear()
            session = nil
            message = nil
        } catch {
            show(error)
            return
        }
        do {
            let current = stored.needsRefresh ? try await api.refresh(stored) : stored
            try await api.logout(current)
        } catch {
            message = "You’re logged out on this device. Eunora couldn’t end the server session."
        }
    }

    private func show(_ error: Error) {
        if Task.isCancelled { return }
        if let failure = error as? EunoraAPI.Failure {
            message = failure.errorDescription
        } else if error is URLError {
            message = "Check your connection and try again."
        } else {
            message = "Eunora couldn’t finish that account action."
        }
    }
}
