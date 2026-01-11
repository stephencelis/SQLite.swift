#if SQLITE_HAS_CODEC
import SQLCipher

/// Extension methods for [SQLCipher](https://www.zetetic.net/sqlcipher/).
/// @see [sqlcipher api](https://www.zetetic.net/sqlcipher/sqlcipher-api/)
extension Connection {

    /// Granularitly of SQLCipher log outputs
    /// Each log level is more verbose than the last
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_log_level
    public enum CipherLogLevel: String {
        case none
        case error
        case warn
        case info
        case debug
        case trace
    }

    /// - Returns: the SQLCipher version
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_version
    public var cipherVersion: String? {
        (try? scalar("PRAGMA cipher_version")) as? String
    }

    /// - Returns: the SQLCipher fips status: 1 for fips mode, 0 for non-fips mode
    /// The FIPS status will not be initialized until the database connection has been keyed
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_fips_status
    public var cipherFipsStatus: String? {
        (try? scalar("PRAGMA cipher_fips_status")) as? String
    }

    /// - Returns: The compiled crypto provider.
    /// The database must be keyed before requesting the name of the crypto provider.
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_provider
    public var cipherProvider: String? {
        (try? scalar("PRAGMA cipher_provider")) as? String
    }

    /// - Returns: the version number provided from the compiled crypto provider.
    /// This value, if known, is available only after the database has been keyed.
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_provider_version
    public var cipherProviderVersion: String? {
        (try? scalar("PRAGMA cipher_provider_version")) as? String
    }

    /// Specify the key for an encrypted database.  This routine should be
    /// called right after sqlite3_open().
    ///
    /// @param key The key to use.The key itself can be a passphrase, which is converted to a key
    ///            using [PBKDF2](https://en.wikipedia.org/wiki/PBKDF2) key derivation. The result
    ///            is used as the encryption key for the database.
    ///
    ///            Alternatively, it is possible to specify an exact byte sequence using a blob literal.
    ///            With this method, it is the calling application's responsibility to ensure that the data
    ///            provided is a 64 character hex string, which will be converted directly to 32 bytes (256 bits)
    ///            of key data.
    ///            e.g. x'2DD29CA851E7B56E4697B0E1F08507293D761A05CE4D1B628663F411A8086D99'
    /// @param db name of the database, defaults to 'main'
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#sqlite3_key
    public func key(_ key: String, db: String = "main") throws {
        try _key_v2(db: db, keyPointer: key, keySize: key.utf8.count)
    }

    public func key(_ key: Blob, db: String = "main") throws {
        try _key_v2(db: db, keyPointer: key.bytes, keySize: key.bytes.count)
    }

    /// Same as `key(_ key: String, db: String = "main")`, running "PRAGMA cipher_migrate;"
    /// immediately after calling `sqlite3_key_v2`, which performs the migration of
    /// SQLCipher database created by older major version of SQLCipher, to be able to
    /// open this database with new major version of SQLCipher
    /// (e.g. to open database created by SQLCipher version 3.x.x with SQLCipher version 4.x.x).
    /// As "PRAGMA cipher_migrate;" is time-consuming, it is recommended to use this function
    /// only after failure of `key(_ key: String, db: String = "main")`, if older versions of
    /// your app may ise older version of SQLCipher
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_migrate
    /// and https://discuss.zetetic.net/t/upgrading-to-sqlcipher-4/3283
    /// for more details regarding SQLCipher upgrade
    public func keyAndMigrate(_ key: String, db: String = "main") throws {
        try _key_v2(db: db, keyPointer: key, keySize: key.utf8.count, migrate: true)
    }

    /// Same as `[`keyAndMigrate(_ key: String, db: String = "main")` accepting byte array as key
    public func keyAndMigrate(_ key: Blob, db: String = "main") throws {
        try _key_v2(db: db, keyPointer: key.bytes, keySize: key.bytes.count, migrate: true)
    }

    /// Change the key on an open database. NB: only works if the database is already encrypted.
    ///
    /// To change the key on an existing encrypted database, it must first be unlocked with the
    /// current encryption key. Once the database is readable and writeable, rekey can be used
    /// to re-encrypt every page in the database with a new key.
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#sqlite3_rekey
    public func rekey(_ key: String, db: String = "main") throws {
        try _rekey_v2(db: db, keyPointer: key, keySize: key.utf8.count)
    }

    public func rekey(_ key: Blob, db: String = "main") throws {
        try _rekey_v2(db: db, keyPointer: key.bytes, keySize: key.bytes.count)
    }

    /// Converts a non-encrypted database to an encrypted one.
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#sqlcipher_export
    public func sqlcipher_export(_ location: Location, key: String) throws {
        let schemaName = "cipher_export"

        try attach(location, as: schemaName, key: key)
        try run("SELECT sqlcipher_export(?)", schemaName)
        try detach(schemaName)
    }

    /// When using Commercial or Enterprise SQLCipher packages you must call
    /// `PRAGMA cipher_license` with a valid license code prior to executing
    /// cryptographic operations on an encrypted database.
    /// Failure to provide a license code, or use of an expired trial code,
    /// will result in an `SQLITE_AUTH (23)` error code reported from the SQLite API
    /// License Codes will activate SQLCipher Commercial or Enterprise packages
    /// from Zetetic: https://www.zetetic.net/sqlcipher/buy/
    /// 15-day free trials are available by request: https://www.zetetic.net/sqlcipher/trial/
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_license
    /// - Parameter license: base64 SQLCipher license code to activate SQLCipher commercial
    public func applyLicense(_ license: String) throws {
        try run("PRAGMA cipher_license = '\(license)'")
    }

    /// Instructs SQLCipher to log internal debugging and operational information
    /// to the sepecified log target (device) using `os_log`
    /// The supplied logLevel will determine the granularity of the logs output
    /// Available logLevel options are: NONE, ERROR, WARN, INFO, DEBUG, TRACE
    /// Note that each level is more verbose than the last,
    /// and particularly with DEBUG and TRACE the logging system will generate
    /// a significant log volume
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_log
    /// - Parameter logLevel: CipherLogLevel The granularity to use for the logging system - defaults to `DEBUG`
    public func enableCipherLogging(logLevel: CipherLogLevel = .debug) throws {
        try run("PRAGMA cipher_log = device")
        try run("PRAGMA cipher_log_level = \(logLevel.rawValue.uppercased())")
    }

    /// Instructs SQLCipher to disable logging internal debugging and operational information
    ///
    /// See https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_log
    public func disableCipherLogging() throws {
        try run("PRAGMA cipher_log_level = \(CipherLogLevel.none.rawValue.uppercased())")
    }

    // MARK: - private
    private func _key_v2(db: String,
                         keyPointer: UnsafePointer<UInt8>,
                         keySize: Int,
                         migrate: Bool = false) throws {
        try check(sqlite3_key_v2(handle, db, keyPointer, Int32(keySize)))
        if migrate {
            // Run "PRAGMA cipher_migrate;" immediately after `sqlite3_key_v2`
            // per recommendation of SQLCipher authors
            let migrateResult = try scalar("PRAGMA cipher_migrate;")
            if (migrateResult as? String) != "0" {
                // "0" is the result of successful migration
                throw Result.error(message: "Error in cipher migration, result \(migrateResult.debugDescription)", code: 1, statement: nil)
            }
        }
        try cipher_key_check()
    }

    private func _rekey_v2(db: String, keyPointer: UnsafePointer<UInt8>, keySize: Int) throws {
        try check(sqlite3_rekey_v2(handle, db, keyPointer, Int32(keySize)))
    }

    // When opening an existing database, sqlite3_key_v2 will not immediately throw an error if
    // the key provided is incorrect. To test that the database can be successfully opened with the
    // provided key, it is necessary to perform some operation on the database (i.e. read from it).
    private func cipher_key_check() throws {
        _ = try scalar("SELECT count(*) FROM sqlite_master;")
    }
}
#endif
