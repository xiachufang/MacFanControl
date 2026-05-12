import Foundation
import SMCKit
import FanDomain

enum Composition {
    static func bootstrap() -> (FanListModel, HelperInstaller) {
        let connection = AppXPCConnection()
        let reader = realReader()
        let writer = XPCFanWriter(connection: connection)
        let service = DefaultFanService(reader: reader, writer: writer)
        let model = FanListModel(service: service)
        let installer = HelperInstaller { try await connection.ping() }
        return (model, installer)
    }

    private static func realReader() -> any SMCClient {
        do {
            return try IOKitSMCClient()
        } catch {
            NSLog("[MacFanControl] IOKit SMC unavailable, falling back to mock: %@",
                  String(describing: error))
            return MockSMCClient()
        }
    }
}
