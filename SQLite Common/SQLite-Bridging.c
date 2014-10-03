//
// SQLite-Bridging.c
// Copyright (c) 2014 Stephen Celis.
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

#include <Block.h>

int _SQLiteBusyHandler(void * context, int tries) {
    return ((SQLiteBusyHandlerCallback)context)(tries);
}

void SQLiteBusyHandler(sqlite3 * handle, SQLiteBusyHandlerCallback callback) {
    if (callback) {
        sqlite3_busy_handler(handle, _SQLiteBusyHandler, Block_copy(callback)); // FIXME: leak
    } else {
        sqlite3_busy_handler(handle, 0, 0);
    }
}

void _SQLiteTrace(void * context, const char * SQL) {
    ((SQLiteTraceCallback)context)(SQL);
}

void SQLiteTrace(sqlite3 * handle, SQLiteTraceCallback callback) {
    if (callback) {
        sqlite3_trace(handle, _SQLiteTrace, Block_copy(callback)); // FIXME: leak
    } else {
        sqlite3_trace(handle, 0, 0);
    }
}
