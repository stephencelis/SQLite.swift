#!/usr/bin/env python
from __future__ import print_function
import json
import sys

if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise Exception('%s [tests.json]' % sys.argv[0])

    def format_testmethod(test_class, method):
        return "    (\"%s\", %s.%s)" % (method, test_class, method.replace('()', ''))

    with open(sys.argv[1]) as f:
        tests = json.load(f)
        test_cases = ["testCase([\n%s\n])" %
             ',\n'.join([format_testmethod(test_class, method) for method in methods])
             for (test_class, methods) in tests.items() if len(methods) > 0]

        print("""import XCTest
@testable import SQLiteTests

XCTMain([
%s
])
""" % ',\n'.join(test_cases))
