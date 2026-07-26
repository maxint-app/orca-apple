import SwiftUI
import Orca

@main
struct OrcaExampleApp: App {
    init() {
        Orca.configure(configuration: OrcaConfiguration(
            publicKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJjcm9zc3BheSIsInN1YiI6IjU0OTUwNGMwLTZlMjQtNDE2NS1hMjgxLWQyMTE4NGE0ZGNmZSIsImF1ZCI6WyJwdWJsaWMiLCJhMzhlYmMzYy0xZjFjLTRhMTgtOTFiNy1iYzZlMDIyMGZkMWMiXX0.ojYDgb25aRD68c0WgGS08XDXtrfBGM8sPaDacdZF69I",
            environment: .sandbox,
            baseURL: "http://192.168.1.101:8081",
            enableNetworkLogging: false,
            customerEmail: nil
        ))
    }

    var body: some Scene {
        WindowGroup {
            PaywallView(customerEmail: "krtirtho@maxint.com")
        }
    }
}
