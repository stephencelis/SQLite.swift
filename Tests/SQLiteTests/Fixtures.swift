import Foundation

func fixture(_ name: String, withExtension: String?) -> String {
    let testBundle = Bundle(for: SQLiteTestCase.self)

    for resource in [name, "fixtures/\(name)"] {
        if let url = testBundle.url(
            forResource: resource,
            withExtension: withExtension) {
            return url.path
        }
    }
    fatalError("Cannot find \(name).\(withExtension ?? "")")
}
