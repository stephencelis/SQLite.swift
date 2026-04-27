# Upgrading

## Unreleased

WAL mode and related journaling APIs are now first-class:

- Both `Connection.init(_ location:readonly:journalMode:)` and
  `Connection.init(_ filename:readonly:journalMode:)` accept an optional
  `journalMode:` parameter. When set to `.wal`, WAL is enabled with
  `synchronous = NORMAL`. The configuration step is skipped automatically for
  `.inMemory`, `.temporary`, empty URIs, and any connection that opens
  read-only — including read-only URI parameters such as
  `.uri(path, parameters: [.mode(.readOnly)])` and `.immutable(true)`.
- New `Connection.JournalMode`, `Connection.Synchronous`, and
  `Connection.WALCheckpointMode` types in `Connection+Pragmas.swift`.
- New connection API: `journalMode`, `synchronous`, `walAutoCheckpoint`
  properties, plus the throwing helpers `setJournalMode(_:)`,
  `setSynchronous(_:)`, `enableWAL()`, and `walCheckpoint(mode:schema:)`.

These additions are source-compatible with existing code; no migration is
required for callers that do not opt in.

## 0.13 → 0.14

- `Expression.asSQL()` is no longer available. Expressions now implement `CustomStringConvertible`,
  where `description` returns the SQL.
- `Statement.prepareRowIterator()` is no longer available. Instead, use the methods
  of the same name on `Connection`.
- `Connection.registerTokenizer` is no longer available to register custom FTS4 tokenizers.
- `Setter.asSQL()` is no longer available. Instead, Setter now implement `CustomStringConvertible`,
  where `description` returns the SQL.
