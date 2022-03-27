0.13.3 (25-01-2022), [diff][diff-0.13.3]
========================================

* UUID Fix ([#1112][])
* Add prepareRowIterator method to an extension of Statement. ([#1119][])
* Adding primary key support to column with references ([#1121][])

0.13.2 (25-01-2022), [diff][diff-0.13.2]
========================================

* Closing bracket position ([#1100][])
* Native user_version support in Connection ([#1105][])

0.13.1 (17-11-2021), [diff][diff-0.13.1]
========================================

* Support for database backup ([#919][])
* Support for custom SQL aggregates ([#881][])
* Restore previous behavior in `FailableIterator` ([#1075][])
* Fix compilation on Linux ([#1077][])
* Align platform versions in SPM manifest and Xcode ([#1094][])
* Revert OSX deployment target back to 10.10 ([#1095][])

0.13.0 (22-08-2021), [diff][diff-0.13.0]
========================================

* Swift 5.3 support
* Xcode 12.5 support
* Bumps minimum deployment versions
* Fixes up Package.swift to build SQLiteObjc module

0.12.1, 0.12.2 (21-06-2019) [diff][diff-0.12.2]
========================================

* CocoaPods modular headers support

0.12.0 (24-04-2019) [diff][diff-0.12.0]
========================================

* Version with Swift 5 Support

0.11.6 (19-04-2019), [diff][diff-0.11.6]
========================================

* Swift 4.2, SQLCipher 4.x ([#866][])

0.11.5 (04-14-2018), [diff][diff-0.11.5]
========================================

* Swift 4.1 ([#797][])

0.11.4 (30-09-2017), [diff][diff-0.11.4]
========================================

* Collate `.nocase` strictly enforces `NOT NULL` even when using Optional ([#697][])
* Fix transactions not being rolled back when committing fails ([#426][])
* Add possibility to have expression on right hand side of like ([#591][])
* Added Date and Time functions ([#142][])
* Add Swift4 Coding support ([#733][])
* Preliminary Linux support ([#315][], [#681][])
* Add `RowIterator` for more safety ([#647][], [#726][])
* Make `Row.get` throw instead of crash ([#649][])
* Fix create/drop index functions ([#666][])
* Revert deployment target to 8.0 ([#625][], [#671][], [#717][])
* Added support for the union query clause ([#723][])
* Add support for `ORDER` and `LIMIT` on `UPDATE` and `DELETE` ([#657][], [#722][])
* Swift 4 support ([#668][])

0.11.3 (30-03-2017), [diff][diff-0.11.3]
========================================

* Fix compilation problems when using Carthage ([#615][])
* Add `WITHOUT ROWID` table option ([#541][])
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
* Fix for `~=` operator used with Double ranges
* Various documentation updates

0.11.0 (19-10-2016)
===================

* Swift3 migration ([diff][diff-0.11.0])


[diff-0.11.0]: https://github.com/stephencelis/SQLite.swift/compare/0.10.1...0.11.0
[diff-0.11.1]: https://github.com/stephencelis/SQLite.swift/compare/0.11.0...0.11.1
[diff-0.11.2]: https://github.com/stephencelis/SQLite.swift/compare/0.11.1...0.11.2
[diff-0.11.3]: https://github.com/stephencelis/SQLite.swift/compare/0.11.2...0.11.3
[diff-0.11.4]: https://github.com/stephencelis/SQLite.swift/compare/0.11.3...0.11.4
[diff-0.11.5]: https://github.com/stephencelis/SQLite.swift/compare/0.11.4...0.11.5
[diff-0.11.6]: https://github.com/stephencelis/SQLite.swift/compare/0.11.5...0.11.6
[diff-0.12.0]: https://github.com/stephencelis/SQLite.swift/compare/0.11.6...0.12.0
[diff-0.12.2]: https://github.com/stephencelis/SQLite.swift/compare/0.12.0...0.12.2
[diff-0.13.0]: https://github.com/stephencelis/SQLite.swift/compare/0.12.2...0.13.0
[diff-0.13.1]: https://github.com/stephencelis/SQLite.swift/compare/0.13.0...0.13.1
[diff-0.13.2]: https://github.com/stephencelis/SQLite.swift/compare/0.13.1...0.13.2
[diff-0.13.3]: https://github.com/stephencelis/SQLite.swift/compare/0.13.2...0.13.3

[#142]: https://github.com/stephencelis/SQLite.swift/issues/142
[#315]: https://github.com/stephencelis/SQLite.swift/issues/315
[#426]: https://github.com/stephencelis/SQLite.swift/pull/426
[#481]: https://github.com/stephencelis/SQLite.swift/pull/481
[#532]: https://github.com/stephencelis/SQLite.swift/issues/532
[#541]: https://github.com/stephencelis/SQLite.swift/issues/541
[#546]: https://github.com/stephencelis/SQLite.swift/issues/546
[#548]: https://github.com/stephencelis/SQLite.swift/pull/548
[#553]: https://github.com/stephencelis/SQLite.swift/pull/553
[#559]: https://github.com/stephencelis/SQLite.swift/pull/559
[#560]: https://github.com/stephencelis/SQLite.swift/pull/560
[#561]: https://github.com/stephencelis/SQLite.swift/issues/561
[#571]: https://github.com/stephencelis/SQLite.swift/issues/571
[#591]: https://github.com/stephencelis/SQLite.swift/pull/591
[#615]: https://github.com/stephencelis/SQLite.swift/pull/615
[#625]: https://github.com/stephencelis/SQLite.swift/issues/625
[#647]: https://github.com/stephencelis/SQLite.swift/pull/647
[#649]: https://github.com/stephencelis/SQLite.swift/pull/649
[#657]: https://github.com/stephencelis/SQLite.swift/issues/657
[#666]: https://github.com/stephencelis/SQLite.swift/pull/666
[#668]: https://github.com/stephencelis/SQLite.swift/pull/668
[#671]: https://github.com/stephencelis/SQLite.swift/issues/671
[#681]: https://github.com/stephencelis/SQLite.swift/issues/681
[#697]: https://github.com/stephencelis/SQLite.swift/issues/697
[#717]: https://github.com/stephencelis/SQLite.swift/issues/717
[#722]: https://github.com/stephencelis/SQLite.swift/pull/722
[#723]: https://github.com/stephencelis/SQLite.swift/pull/723
[#733]: https://github.com/stephencelis/SQLite.swift/pull/733
[#726]: https://github.com/stephencelis/SQLite.swift/pull/726
[#797]: https://github.com/stephencelis/SQLite.swift/pull/797
[#866]: https://github.com/stephencelis/SQLite.swift/pull/866
[#881]: https://github.com/stephencelis/SQLite.swift/pull/881
[#919]: https://github.com/stephencelis/SQLite.swift/pull/919
[#1075]: https://github.com/stephencelis/SQLite.swift/pull/1075
[#1077]: https://github.com/stephencelis/SQLite.swift/issues/1077
[#1094]: https://github.com/stephencelis/SQLite.swift/pull/1094
[#1095]: https://github.com/stephencelis/SQLite.swift/pull/1095
[#1100]: https://github.com/stephencelis/SQLite.swift/pull/1100
[#1105]: https://github.com/stephencelis/SQLite.swift/pull/1105
[#1112]: https://github.com/stephencelis/SQLite.swift/pull/1112
[#1119]: https://github.com/stephencelis/SQLite.swift/pull/1119
[#1121]: https://github.com/stephencelis/SQLite.swift/pull/1121
