//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright (c) 2014-2015 Stephen Celis.
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

#include "SQLite-Bridging.h"

@import Foundation;

static int _SQLiteBusyHandler(void * context, int tries) {
    return ((__bridge SQLiteBusyHandlerCallback)context)(tries);
}

int SQLiteBusyHandler(sqlite3 * handle, SQLiteBusyHandlerCallback callback) {
    if (callback) {
        return sqlite3_busy_handler(handle, _SQLiteBusyHandler, (__bridge_retained void *)callback); // FIXME: leak
    } else {
        return sqlite3_busy_handler(handle, 0, 0);
    }
}

static void _SQLiteTrace(void * context, const char * SQL) {
    ((__bridge SQLiteTraceCallback)context)(SQL);
}

void SQLiteTrace(sqlite3 * handle, SQLiteTraceCallback callback) {
    if (callback) {
        sqlite3_trace(handle, _SQLiteTrace, (__bridge_retained void *)callback); // FIXME: leak
    } else {
        sqlite3_trace(handle, 0, 0);
    }
}

static void _SQLiteCreateFunction(sqlite3_context * context, int argc, sqlite3_value ** argv) {
    ((__bridge SQLiteCreateFunctionCallback)sqlite3_user_data(context))(context, argc, argv);
}

int SQLiteCreateFunction(sqlite3 * handle, const char * name, int argc, int deterministic, SQLiteCreateFunctionCallback callback) {
    if (callback) {
        int flags = SQLITE_UTF8;
        if (deterministic) {
#ifdef SQLITE_DETERMINISTIC
            flags |= SQLITE_DETERMINISTIC;
#endif
        }
        return sqlite3_create_function_v2(handle, name, -1, flags, (__bridge_retained void *)callback, &_SQLiteCreateFunction, 0, 0, 0); // FIXME: leak
    } else {
        return sqlite3_create_function_v2(handle, name, 0, 0, 0, 0, 0, 0, 0);
    }
}

static int _SQLiteCreateCollation(void * context, int len_lhs, const void * lhs, int len_rhs, const void * rhs) {
    return ((__bridge SQLiteCreateCollationCallback)context)(lhs, rhs);
}

int SQLiteCreateCollation(sqlite3 * handle, const char * name, SQLiteCreateCollationCallback callback) {
    if (callback) {
        return sqlite3_create_collation_v2(handle, name, SQLITE_UTF8, (__bridge_retained void *)callback, &_SQLiteCreateCollation, 0); // FIXME: leak
    } else {
        return sqlite3_create_collation_v2(handle, name, 0, 0, 0, 0);
    }
}

#pragma mark - FTS

typedef struct _SQLiteTokenizer {
    sqlite3_tokenizer base;
    __unsafe_unretained SQLiteTokenizerNextCallback callback;
} _SQLiteTokenizer;

typedef struct _SQLiteTokenizerCursor {
    void * base;
    const char * input;
    int inputOffset;
    int inputLength;
    int idx;
} _SQLiteTokenizerCursor;


static NSMutableDictionary * _SQLiteTokenizerMap;

static int _SQLiteTokenizerCreate(int argc, const char * const * argv, sqlite3_tokenizer ** ppTokenizer) {
    _SQLiteTokenizer * tokenizer = (_SQLiteTokenizer *)sqlite3_malloc(sizeof(_SQLiteTokenizer));
    if (!tokenizer) {
        return SQLITE_NOMEM;
    }
    memset(tokenizer, 0, sizeof(* tokenizer)); // FIXME: needed?

    NSString * key = [NSString stringWithUTF8String:argv[0]];
    tokenizer->callback = [_SQLiteTokenizerMap objectForKey:key];
    if (!tokenizer->callback) {
        return SQLITE_ERROR;
    }

    *ppTokenizer = &tokenizer->base;
    return SQLITE_OK;
}

static int _SQLiteTokenizerDestroy(sqlite3_tokenizer * pTokenizer) {
    sqlite3_free(pTokenizer);
    return SQLITE_OK;
}

static int _SQLiteTokenizerOpen(sqlite3_tokenizer * pTokenizer, const char * pInput, int nBytes, sqlite3_tokenizer_cursor ** ppCursor) {
    _SQLiteTokenizerCursor * cursor = (_SQLiteTokenizerCursor *)sqlite3_malloc(sizeof(_SQLiteTokenizerCursor));
    if (!cursor) {
        return SQLITE_NOMEM;
    }

    cursor->input = pInput;
    cursor->inputOffset = 0;
    cursor->inputLength = 0;
    cursor->idx = 0;

    *ppCursor = (sqlite3_tokenizer_cursor *)cursor;
    return SQLITE_OK;
}

static int _SQLiteTokenizerClose(sqlite3_tokenizer_cursor * pCursor) {
    sqlite3_free(pCursor);
    return SQLITE_OK;
}

static int _SQLiteTokenizerNext(sqlite3_tokenizer_cursor * pCursor, const char ** ppToken, int * pnBytes, int * piStartOffset, int * piEndOffset, int * piPosition) {
    _SQLiteTokenizerCursor * cursor = (_SQLiteTokenizerCursor *)pCursor;
    _SQLiteTokenizer * tokenizer = (_SQLiteTokenizer *)cursor->base;

    cursor->inputOffset += cursor->inputLength;
    const char * input = cursor->input + cursor->inputOffset;
    const char * token = [tokenizer->callback(input, &cursor->inputOffset, &cursor->inputLength) cStringUsingEncoding:NSUTF8StringEncoding];
    if (!token) {
        return SQLITE_DONE;
    }

    *ppToken = token;
    *pnBytes = (int)strlen(token);
    *piStartOffset = cursor->inputOffset;
    *piEndOffset = cursor->inputOffset + cursor->inputLength;
    *piPosition = cursor->idx++;
    return SQLITE_OK;
}

static const sqlite3_tokenizer_module _SQLiteTokenizerModule = {
    0,
    _SQLiteTokenizerCreate,
    _SQLiteTokenizerDestroy,
    _SQLiteTokenizerOpen,
    _SQLiteTokenizerClose,
    _SQLiteTokenizerNext
};

int SQLiteRegisterTokenizer(sqlite3 * db, const char * moduleName, const char * submoduleName, SQLiteTokenizerNextCallback callback) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _SQLiteTokenizerMap = [NSMutableDictionary new];
    });

    sqlite3_stmt * stmt;
    int status = sqlite3_prepare_v2(db, "SELECT fts3_tokenizer(?, ?)", -1, &stmt, 0);
    if (status != SQLITE_OK ){
        return status;
    }
    const sqlite3_tokenizer_module * pModule = &_SQLiteTokenizerModule;
    sqlite3_bind_text(stmt, 1, moduleName, -1, SQLITE_STATIC);
    sqlite3_bind_blob(stmt, 2, &pModule, sizeof(pModule), SQLITE_STATIC);
    sqlite3_step(stmt);
    status = sqlite3_finalize(stmt);
    if (status != SQLITE_OK ){
        return status;
    }

    [_SQLiteTokenizerMap setObject:[callback copy] forKey:[NSString stringWithUTF8String:submoduleName]];

    return SQLITE_OK;
}
