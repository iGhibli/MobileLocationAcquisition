//
//  NSString+FilePath.h
//  QuWenLieQi
//
//  Created by 赛驰 on 16/4/5.
//  Copyright © 2016年 SaiChi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FilePath)

/**
 * 根据文件名，返回文件在Documents下的路径
 *
 ＊ @param fileName 文件名字
 ＊
 ＊ @return 文件路径
 */
+ (NSString *)filePathInDocumentsWithFileName:(NSString *)fileName;


@end
