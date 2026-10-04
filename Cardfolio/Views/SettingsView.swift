import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(PassSigningStore.self) private var signing
    @Environment(\.dismiss) private var dismiss

    @State private var isPickingFile = false
    @State private var pickedCertificate: Data?
    @State private var isAskingForPassword = false
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isConfirmingRemoval = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let signer = signing.signer {
                        LabeledContent("Pass Type ID", value: signer.passTypeIdentifier)
                        LabeledContent("Team ID", value: signer.teamIdentifier)
                        LabeledContent("Expires", value: signer.expiresAt.formatted(date: .abbreviated, time: .omitted))
                        Button("Replace Certificate…") { isPickingFile = true }
                        Button("Remove Certificate", role: .destructive) { isConfirmingRemoval = true }
                    } else {
                        if let problem = signing.problem {
                            Label(problem, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                        Button {
                            isPickingFile = true
                        } label: {
                            Label("Import Certificate…", systemImage: "key")
                        }
                    }
                } header: {
                    Text("Wallet Signing")
                } footer: {
                    Text(signing.signer == nil ? Self.setupHint : Self.signedHint)
                }

                Section {
                    LabeledContent("Version", value: Self.version)
                } footer: {
                    Text("Your cards stay on this iPhone. Nothing is uploaded anywhere.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.pkcs12], onCompletion: readCertificate)
            .alert("Certificate Password", isPresented: $isAskingForPassword) {
                SecureField("Password", text: $password)
                Button("Cancel", role: .cancel) { pickedCertificate = nil }
                Button("Import", action: importCertificate)
            } message: {
                Text("The password you chose when exporting the .p12 from Keychain Access.")
            }
            .alert("Couldn't Import", isPresented: isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .confirmationDialog("Remove the certificate?", isPresented: $isConfirmingRemoval, titleVisibility: .visible) {
                Button("Remove", role: .destructive) { signing.removeCertificate() }
            } message: {
                Text("Cards already in Wallet stay there. You'll need to import it again to add new ones.")
            }
        }
    }

    private static let setupHint = """
        Wallet only accepts passes signed with a Pass Type ID certificate from \
        your Apple Developer account. Export it from Keychain Access as a .p12 \
        and import it here.
        """

    private static let signedHint = "Passes are signed on this iPhone. The certificate is kept in the keychain."

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func readCertificate(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let isScoped = url.startAccessingSecurityScopedResource()
            defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
            pickedCertificate = try Data(contentsOf: url)
            password = ""
            isAskingForPassword = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importCertificate() {
        guard let certificate = pickedCertificate else { return }
        pickedCertificate = nil
        do {
            try signing.importCertificate(certificate, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        password = ""
    }
}

#Preview {
    SettingsView()
        .environment(PassSigningStore())
}
