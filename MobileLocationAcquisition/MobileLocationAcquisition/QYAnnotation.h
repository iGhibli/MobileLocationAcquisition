//
//  QYAnnotation.h
//  RunPath
//
//  Created by qingyun on 16/7/5.
//  Copyright © 2016年 QingYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>

@interface QYAnnotation : NSObject<BMKAnnotation>

@property(nonatomic)CLLocationCoordinate2D coordinate;//遵守Annotation协议
@property (nonatomic, copy)NSString *title;

//自定义属性
@property (nonatomic)NSInteger type;//0,当前点,1开始点,2暂停点,3结束点

@end
