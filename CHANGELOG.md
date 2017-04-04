0.11.3 (30-03-2017), [diff][diff-0.11.3]
========================================

* Fix compilation problems when using Carthage ([#615][])
* Add "WITHOUT ROWID" table option ([#541][])
* Argument count fixed for binary custom functions ([#481][])
* Documentation updates
* Tested with Xcode 8.3 / iOS 10.3

0.11.2 (25-12-2016), [diff][diff-0.11.2]
========================================

* Fixed SQLCipher integration with read-only databases ([#559][])
* Preliminary Swift Package Manager support ([#548][], [#560][])
* Fixed null pointer when fetching an empty BLOB ([#561][])
* Allow `where` as alias for `filter` ([#571][])

0.11.1 (06-12-2016), [diff][diff-0.11.1]
========================================

* Integrate SQLCipher via CocoaPods ([#546][], [#553][])
* Made lastInsertRowid consistent with other SQLite wrappers ([#532][])
* Fix for ~= operator used with Double ranges
* Various documentation updates

0.11.0 (19-10-2016)
===================

* Swift3 migration ([diff][diff-0.11.0])


[diff-0.11.0]: https://github.com/stephencelis/SQLite.swift/compare/0.10.1...0.11.0
[diff-0.11.1]: https://github.com/stephencelis/SQLite.swift/compare/0.11.0...0.11.1
[diff-0.11.2]: https://github.com/stephencelis/SQLite.swift/compare/0.11.1...0.11.2
[diff-0.11.3]: https://github.com/stephencelis/SQLite.swift/compare/0.11.2...0.11.3

[#481]: https://github.com/stephencelis/SQLit1e.swift/pull/481
[#532]: https://github.com/stephencelis/SQLit1e.swift/issues/532
[#541]: https://github.com/stephencelis/SQLit1e.swift/issues/541
[#546]: https://github.com/stephencelis/SQLite.swift/issues/546
[#548]: https://github.com/stephencelis/SQLite.swift/pull/548
[#553]: https://github.com/stephencelis/SQLite.swift/pull/553
[#559]: https://github.com/stephencelis/SQLite.swift/pull/559
[#560]: https://github.com/stephencelis/SQLite.swift/pull/560
[#561]: https://github.com/stephencelis/SQLite.swift/issues/561
[#571]: https://github.com/stephencelis/SQLite.swift/issues/571
[#615]: https://github.com/stephencelis/SQLite.swift/pull/615
