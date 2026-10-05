import AppKit
import SwiftUI

@main
@MainActor
struct CyberBlessingApp: App {
    init() {
        if let index = CommandLine.arguments.firstIndex(of: "--self-check"), CommandLine.arguments.count > index + 1 {
            let directory = CommandLine.arguments[index + 1]
            Task { await AppValidation.run(outputDirectory: directory) }
        }
    }

    var body: some Scene {
        MenuBarExtra("赛博祈福", systemImage: "flame.fill") {
            ContentView()
                .frame(width: AppMetadata.width)
        }
        .menuBarExtraStyle(.window)
    }
}
