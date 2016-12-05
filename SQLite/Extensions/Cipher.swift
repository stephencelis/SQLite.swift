#if SQLITE_SWIFT_SQLCIPHER
import SQLCipher

extension Connection {
    public func key(_ key: String) throws {
        try check(sqlite3_key(handle, key, Int32(key.utf8.count)))
        try execute(
            "CREATE TABLE \"__SQLCipher.swift__\" (\"cipher key check\");\n" +
            "DROP TABLE \"__SQLCipher.swift__\";"
        )
    }

    public func rekey(_ key: String) throws {
        try check(sqlite3_rekey(handle, key, Int32(key.utf8.count)))
    }

    public func key(_ key: Blob) throws {
        try check(sqlite3_key(handle, key.bytes, Int32(key.bytes.count)))
        try execute(
            "CREATE TABLE \"__SQLCipher.swift__\" (\"cipher key check\");\n" +
            "DROP TABLE \"__SQLCipher.swift__\";"
        )
    }

    public func rekey(_ key: Blob) throws {
        try check(sqlite3_rekey(handle, key.bytes, Int32(key.bytes.count)))
    }
}
#endif
