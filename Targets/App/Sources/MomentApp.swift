import SwiftUI

@main
struct MomentApp: App {
    @State var isLoggedIn = false
    @State var hasActiveSpace = false

    var body: some Scene {
        WindowGroup {
            AppView(isLoggedIn: $isLoggedIn, hasActiveSpace: $hasActiveSpace)
        }
    }
}
