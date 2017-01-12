//
//  DataBaseEngine.m
//  QuWenLieQi
//
//  Created by 赛驰 on 16/4/19.
//  Copyright © 2016年 SaiChi. All rights reserved.
//

#import "DataBaseEngine.h"
#import "NSString+FilePath.h"
#import "FMDB.h"

#define kDBFileName     @"GPX.db"   //数据库文件名

@implementation DataBaseEngine

+ (void)initialize {
    if (self == [DataBaseEngine self]) {
        //将数据库文件copy到Documents路径下
        [DataBaseEngine copyDataBaseFileToDocumentsWithDBName:kDBFileName];
    }
}

+ (void)copyDataBaseFileToDocumentsWithDBName:(NSString *)DBName {
    NSString *source = [[NSBundle mainBundle] pathForResource:DBName ofType:nil];
    NSString *toPath = [NSString filePathInDocumentsWithFileName:DBName];
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:toPath]) {
        //如果toPath路径下有数据表文件则无需Copy直接返回
        return;
    }
    [[NSFileManager defaultManager] copyItemAtPath:source toPath:toPath error:&error];
    if (error) {
        NSLog(@"!!!!!!%@",error);
    }
}

#pragma mark - GPXData
+ (void)deleteAllGPXs {
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[NSString filePathInDocumentsWithFileName:kDBFileName]];
    [queue inDatabase:^(FMDatabase *db) {
        //进行数据库的增删改查
        BOOL result = [db executeUpdate:@"delete from LocalGPXs;"];
        NSLog(@"SORT---DELETE--- %d",result);
    }];
}

+ (void)saveGPXDataLatitude:(double)lat andLongitude:(double)lon {
    //插入操作，首先创建db，写sql语句，执行操作
    //使用队列时不需要自己创建db,队列会创建
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[NSString filePathInDocumentsWithFileName:kDBFileName]];
    
    [queue inDatabase:^(FMDatabase *db) {
        //进行数据库的增删改查
        NSString *SQLStr = [NSString stringWithFormat:@"insert into LocalGPXs(lat ,lon) values('%f' ,'%f');",lat ,lon];
        BOOL result = [db executeUpdate:SQLStr];
        NSLog(@"RECORD---ADD--- %d",result);
    }];
}

+ (NSArray *)getGPXDatas {
    //创建数据库
    FMDatabase *db = [FMDatabase databaseWithPath:[NSString filePathInDocumentsWithFileName:kDBFileName]];
    //打开数据库
    [db open];
    //查询语句
    NSString *sqlString = @"select * from LocalGPXs;";
    //查询并输出结果
    FMResultSet *result = [db executeQuery:sqlString];
    NSMutableArray *GPXDicts = [NSMutableArray array];
    while ([result next]) {
        //将一条记录转化为一个字典
        NSDictionary *dict = [result resultDictionary];
        [GPXDicts addObject:dict];
    }
    [db close];
    return GPXDicts;
}

@end
