import Foundation

func fixture(_ name: String, withExtension: String?) -> String {
    let testBundle = Bundle(for: SQLiteTestCase.self)
    return testBundle.url(
        forResource: name,
        withExtension: withExtension)!.path
}
