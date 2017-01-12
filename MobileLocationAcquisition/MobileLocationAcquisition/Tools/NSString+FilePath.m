//
//  NSString+FilePath.m
//  QuWenLieQi
//
//  Created by 赛驰 on 16/4/5.
//  Copyright © 2016年 SaiChi. All rights reserved.
//

#import "NSString+FilePath.h"

@implementation NSString (FilePath)

+ (NSString *)filePathInDocumentsWithFileName:(NSString *)fileName {
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
    return filePath;
}

@end
