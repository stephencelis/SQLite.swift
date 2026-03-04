import SwiftUI
import SQLite

let connection = try! SQLite.Connection(.inMemory)

@main
struct SQLiteTestApp: App {
    var body: some Scene {
        WindowGroup {
            Text("version: \(connection.sqliteVersion.description)").padding()
        }
    }
}
