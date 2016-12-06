#if SQLITE_SWIFT_SQLCIPHER
import SQLCipher

extension Connection {
    public func key(_ key: String) throws {
        try _key(keyPointer: key, keySize: key.utf8.count)
    }

    public func key(_ key: Blob) throws {
        try _key(keyPointer: key.bytes, keySize: key.bytes.count)
    }

    public func rekey(_ key: String) throws {
        try _rekey(keyPointer: key, keySize: key.utf8.count)
    }

    public func rekey(_ key: Blob) throws {
        try _rekey(keyPointer: key.bytes, keySize: key.bytes.count)
    }

    // MARK: - private
    private func _key(keyPointer: UnsafePointer<UInt8>, keySize: Int) throws {
        try check(sqlite3_key(handle, keyPointer, Int32(keySize)))
        try execute(
            "CREATE TABLE \"__SQLCipher.swift__\" (\"cipher key check\");\n" +
            "DROP TABLE \"__SQLCipher.swift__\";"
        )
    }

    private func _rekey(keyPointer: UnsafePointer<UInt8>, keySize: Int) throws {
        try check(sqlite3_rekey(handle, keyPointer, Int32(keySize)))
    }
}
#endif
