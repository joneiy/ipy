//
//  PYKeyedDb.m
//  PYData
//
//  Created by Push Chen on 1/19/13.
//  Copyright (c) 2013 Push Lab. All rights reserved.
//

/*
 LISENCE FOR IPY
 COPYRIGHT (c) 2013, Push Chen.
 ALL RIGHTS RESERVED.
 
 REDISTRIBUTION AND USE IN SOURCE AND BINARY
 FORMS, WITH OR WITHOUT MODIFICATION, ARE
 PERMITTED PROVIDED THAT THE FOLLOWING CONDITIONS
 ARE MET:
 
 YOU USE IT, AND YOU JUST USE IT!.
 WHY NOT USE THIS LIBRARY IN YOUR CODE TO MAKE
 THE DEVELOPMENT HAPPIER!
 ENJOY YOUR LIFE AND BE FAR AWAY FROM BUGS.
 */

#import "PYKeyedDb.h"
#import "PYSqlStatement.h"

static NSMutableDictionary			*_gPYKeyedDBCache;
#define		kKeyedDBTableName		@"_PYkeyedCache"

// The Row
@implementation PYKeyedDbRow
@synthesize value, expire;
@end

@interface PYKeyedDb ()

- (BOOL)initializeDbWithPath:(NSString *)dbPath;

// Create the db at specified path if the database is not existed.
- (BOOL)createDbWithPath:(NSString *)dbPath;

@end

@implementation PYKeyedDb

+ (void)initialize
{
	// Initialize the global cache
	_gPYKeyedDBCache = [NSMutableDictionary dictionary];
}

+ (PYKeyedDb *)keyedDbWithPath:(NSString *)dbPath
{
	NSString *_dbKey = [dbPath md5sum];
	if ( [_gPYKeyedDBCache objectForKey:_dbKey] != nil ) {
		return [_gPYKeyedDBCache objectForKey:_dbKey];
	}
	
	PYKeyedDb *_newDb = [[PYKeyedDb alloc] init];
	if ( [_newDb initializeDbWithPath:dbPath] == NO ) {
		if ( [_newDb createDbWithPath:dbPath] == NO ) return nil;
	}
	[_gPYKeyedDBCache setObject:_newDb forKey:_dbKey];
	return _newDb;
}

// 
- (id)init
{
	self = [super init];
	if ( self ) {
		// Do something if needed.
	}
	return self;
}

- (void)dealloc
{
	if ( _innerDb != NULL ) sqlite3_close(_innerDb);
}

- (BOOL)initializeDbWithPath:(NSString *)dbPath
{
    _dbPath = dbPath;
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:dbPath] ) {
		return NO;
	}
    
	if (sqlite3_open([dbPath UTF8String], &_innerDb) == SQLITE_OK) {
        char *_errorMsg = NULL;
        sqlite3_exec(_innerDb, "PRAGMA synchronous = OFF", NULL, NULL, &_errorMsg);
        if ( _errorMsg != NULL ) {
            NSLog(@"Failed to set the sqlite to be async mode: %s", _errorMsg);
            _errorMsg = NULL;
        }
        sqlite3_exec(_innerDb, "PRAGMA journal_mode = MEMORY", NULL, NULL, &_errorMsg);
        if ( _errorMsg != NULL ) {
            NSLog(@"Failed to set the journal_mode to memory: %s", _errorMsg);
            _errorMsg = NULL;
        }
        
        // Initialize the sql statements
        
        // Insert
        NSString *_insertSql = @"INSERT INTO " kKeyedDBTableName @" VALUES(?, ?, ?);";
        _insertStat = [PYSqlStatement sqlStatementWithSQL:_insertSql];
        if (sqlite3_prepare_v2(_innerDb, _insertSql.UTF8String, -1,
                               &_insertStat->sqlstmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to initialize the insert statement");
            return NO;
        }

        // Update
        NSString *_updateSql = @"UPDATE " kKeyedDBTableName @" set dbValue=?, dbExpire=? WHERE dbKey=?";
        _updateStat = [PYSqlStatement sqlStatementWithSQL:_updateSql];
        if (sqlite3_prepare_v2(_innerDb, _updateSql.UTF8String, -1,
                               &_updateStat->sqlstmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to initialize the update statement");
            return NO;
        }
        
        // Delete
        NSString *_deleteSql = @"DELETE FROM " kKeyedDBTableName @" WHERE dbKey=?";
        _deleteStat = [PYSqlStatement sqlStatementWithSQL:_deleteSql];
        if (sqlite3_prepare_v2(_innerDb, _deleteSql.UTF8String, -1,
                               &_deleteStat->sqlstmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to initialize the delete statement");
            return NO;
        }
        
        // Check
        NSString *_checkSql = @"SELECT dbKey FROM " kKeyedDBTableName @" WHERE dbKey=?";
        _checkStat = [PYSqlStatement sqlStatementWithSQL:_checkSql];
        if (sqlite3_prepare_v2(_innerDb, _checkSql.UTF8String, -1,
                               &_checkStat->sqlstmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to initialize the check statement");
            return NO;
        }
        
        // Select
        NSString *_selectSql = @"SELECT dbValue, dbExpire FROM " kKeyedDBTableName @" WHERE dbKey=?";
        _selectStat = [PYSqlStatement sqlStatementWithSQL:_selectSql];
        if (sqlite3_prepare_v2(_innerDb, _selectSql.UTF8String, -1,
                               &_selectStat->sqlstmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to initialize the select statement");
            return NO;
        }
        
        // Count
        NSString *_countSql = @"SELECT COUNT(dbKey) FROM " kKeyedDBTableName;
        _countStat = [PYSqlStatement sqlStatementWithSQL:_countSql];
        if (sqlite3_prepare_v2(_innerDb, _countSql.UTF8String, -1,
                               &_countStat->sqlstmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to initialize the count statement");
            return NO;
        }
        
		return YES;
	} else {
        NSLog(@"Failed to open sqlite at path: %@, error: %s", dbPath, sqlite3_errmsg(_innerDb));
    }
	return NO;
}

// Create the db at specified path if the database is not existed.
- (BOOL)createDbWithPath:(NSString *)dbPath
{
    _dbPath = dbPath;
	NSFileManager *fm = [NSFileManager defaultManager];
	if ( [fm fileExistsAtPath:dbPath] ) return NO;
	// Create the empty file
	[fm createFileAtPath:dbPath contents:nil attributes:nil];
	if ( sqlite3_open([dbPath UTF8String], &_innerDb) != SQLITE_OK )
		return NO;
		
	// Create the table
	static const char * _createTableSql =
		"CREATE TABLE _PYkeyedCache("	\
		"dbKey TEXT PRIMARY KEY,"		\
		"dbValue BLOB,"                 \
        "dbExpire INT);";
	char *_error;
	if( sqlite3_exec(_innerDb, _createTableSql, nil, nil, &_error) != SQLITE_OK ) {
		sqlite3_close(_innerDb);
		_innerDb = NULL;
		[fm removeItemAtPath:dbPath error:nil];
		return NO;
	}
	
	sqlite3_close(_innerDb);
	return [self initializeDbWithPath:dbPath];
}

- (BOOL)beginBatchOperation
{
    char *_errorMsg = NULL;
    sqlite3_exec(_innerDb, "BEGIN TRANSACTION", NULL, NULL, &_errorMsg);
    if ( _errorMsg != NULL ) {
        PYLog(@"Failed to begin transaction");
        return NO;
    }
    return YES;
}

- (BOOL)endBatchOperation
{
    char *_errorMsg = NULL;
    sqlite3_exec(_innerDb, "END TRANSACTION", NULL, NULL, &_errorMsg);
    if ( _errorMsg != NULL ) {
        PYLog(@"Failed to end transaction");
        return NO;
    }
    return YES;
}

- (BOOL)addValue:(NSData *)formatedValue forKey:(NSString *)key expireOn:(PYDate *)expire
{
    PYSingletonLock
    [_insertStat resetBinding];
	BOOL _statue = NO;
    [_insertStat bindInOrderText:key];
    [_insertStat bindInOrderData:formatedValue];
    [_insertStat bindInOrderInt:expire.timestamp];
    if (sqlite3_step(_insertStat.statement) == SQLITE_DONE ) {
        _statue = YES;
    }
	return _statue;
    PYSingletonUnLock
}

- (BOOL)updateValue:(NSData *)formatedValue forKey:(NSString *)key expireOn:(PYDate *)expire
{
    PYSingletonLock
    [_updateStat resetBinding];
	BOOL _statue = NO;
    [_updateStat bindInOrderData:formatedValue];
    [_updateStat bindInOrderInt:expire.timestamp];
    [_updateStat bindInOrderText:key];
    if (sqlite3_step(_updateStat.statement) == SQLITE_DONE ) {
        _statue = YES;
    }
	return _statue;
    PYSingletonUnLock
}

- (void)deleteValueForKey:(NSString *)key
{
	// Delete
    PYSingletonLock
    [_deleteStat resetBinding];
    [_deleteStat bindInOrderText:key];
    sqlite3_step(_deleteStat.statement);
    PYSingletonUnLock
}

- (BOOL)containsKey:(NSString *)key
{
	// Select
    PYSingletonLock
    [_checkStat resetBinding];
	BOOL _statue = NO;
    [_checkStat bindInOrderText:key];
    if (sqlite3_step(_checkStat.statement) == SQLITE_ROW ) {
        _statue = YES;
    }
	return _statue;
    PYSingletonUnLock
}

- (PYKeyedDbRow *)valueForKey:(NSString *)key
{
    PYSingletonLock
    [_selectStat resetBinding];
    [_selectStat bindInOrderText:key];
    if (sqlite3_step(_selectStat.statement) == SQLITE_ROW )
    {
        [_selectStat prepareForReading];
        NSData *_value = [_selectStat getInOrderData];
        PYDate *_expire = [PYDate dateWithTimpstamp:[_selectStat getInOrderInt]];
        PYKeyedDbRow *_row = [PYKeyedDbRow object];
        _row.value = _value;
        _row.expire = _expire;
        return _row;
    }
	return nil;
    PYSingletonUnLock
}

- (int)count
{
    PYSingletonLock
    [_countStat resetBinding];
    if (sqlite3_step(_countStat.statement) == SQLITE_ROW )
    {
        [_countStat prepareForReading];
        return [_countStat getInOrderInt];
    }
	return -1;
    PYSingletonUnLock
}

- (void)clearDBData
{
	if ( _innerDb != NULL ) sqlite3_close(_innerDb);
    _innerDb = NULL;
    NSError *_error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:_dbPath error:&_error];
    if ( _error ) @throw _error;
    [self createDbWithPath:_dbPath];
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab
