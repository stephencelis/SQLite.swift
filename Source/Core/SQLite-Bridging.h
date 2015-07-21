//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

@import Foundation;

#ifndef COCOAPODS
#import "sqlite3.h"
#endif

// CocoaPods workaround
typedef struct SQLiteHandle SQLiteHandle;
typedef struct SQLiteContext SQLiteContext;
typedef struct SQLiteValue SQLiteValue;

NS_ASSUME_NONNULL_BEGIN
typedef int (^_SQLiteBusyHandlerCallback)(int times);
int _SQLiteBusyHandler(SQLiteHandle * db, _SQLiteBusyHandlerCallback _Nullable callback);

typedef void (^_SQLiteTraceCallback)(const char * SQL);
void _SQLiteTrace(SQLiteHandle * db, _SQLiteTraceCallback _Nullable callback);

typedef void (^_SQLiteUpdateHookCallback)(int operation, const char * db, const char * table, long long rowid);
void _SQLiteUpdateHook(SQLiteHandle * db, _SQLiteUpdateHookCallback _Nullable callback);

typedef int (^_SQLiteCommitHookCallback)();
void _SQLiteCommitHook(SQLiteHandle * db, _SQLiteCommitHookCallback _Nullable callback);

typedef void (^_SQLiteRollbackHookCallback)();
void _SQLiteRollbackHook(SQLiteHandle * db, _SQLiteRollbackHookCallback _Nullable callback);

typedef void (^_SQLiteCreateFunctionCallback)(SQLiteContext * context, int argc, SQLiteValue * _Nonnull * _Nonnull argv);
int _SQLiteCreateFunction(SQLiteHandle * db, const char * name, int argc, int deterministic, _SQLiteCreateFunctionCallback _Nullable callback);

typedef int (^_SQLiteCreateCollationCallback)(const char * lhs, const char * rhs);
int _SQLiteCreateCollation(SQLiteHandle * db, const char * name, _SQLiteCreateCollationCallback _Nullable callback);

typedef NSString * _Nullable (^_SQLiteTokenizerNextCallback)(const char * input, int * inputOffset, int * inputLength);
int _SQLiteRegisterTokenizer(SQLiteHandle * db, const char * module, const char * tokenizer, _Nullable _SQLiteTokenizerNextCallback callback);
NS_ASSUME_NONNULL_END

