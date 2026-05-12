import Foundation
import HelperIPC

let listener = NSXPCListener(machServiceName: HelperConstants.machServiceName)
let delegate = HelperListener()
listener.delegate = delegate
listener.resume()

dispatchMain()
