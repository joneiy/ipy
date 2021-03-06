//
//  PYKeyedDb.h
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

#import <Foundation/Foundation.h>
#import "PYDataPredefination.h"
#import "PYSqlStatement.h"

// DB Row
@interface PYKeyedDbRow : NSObject

@property (nonatomic, strong)   NSData          *value;
@property (nonatomic, strong)   PYDate          *expire;

@end

@interface PYKeyedDb : NSObject
{
	sqlite3				*_innerDb;
    NSString            *_dbPath;
    
    PYSqlStatement      *_insertStat;
    PYSqlStatement      *_updateStat;
    PYSqlStatement      *_deleteStat;
    PYSqlStatement      *_countStat;
    PYSqlStatement      *_selectStat;
    PYSqlStatement      *_checkStat;
}

+ (PYKeyedDb *)keyedDbWithPath:(NSString *)dbPath;

- (BOOL)beginBatchOperation;
- (BOOL)endBatchOperation;
- (BOOL)addValue:(NSData *)formatedValue forKey:(NSString *)key expireOn:(PYDate *)expire;
- (BOOL)updateValue:(NSData *)formatedValue forKey:(NSString *)key expireOn:(PYDate *)expire;
- (void)deleteValueForKey:(NSString *)key;

- (BOOL)containsKey:(NSString *)key;

- (void)clearDBData;

// Get the value
- (PYKeyedDbRow *)valueForKey:(NSString *)key;

// data all count
- (int)count;

@end

@interface PYKeyedDb (Private)

// Other interface or message cannot create the
// db by alloc/init.
- (id)init;

@end

// @littlepush
// littlepush@gmail.com
// PYLab
