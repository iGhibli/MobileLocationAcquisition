//
//  DataBaseEngine.h
//  QuWenLieQi
//
//  Created by 赛驰 on 16/4/19.
//  Copyright © 2016年 SaiChi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataBaseEngine : NSObject

/*************Sort***********/
+ (void)deleteAllGPXs;

+ (void)saveGPXDataLatitude:(double)lat andLongitude:(double)lon;

+ (NSArray *)getGPXDatas;

@end
