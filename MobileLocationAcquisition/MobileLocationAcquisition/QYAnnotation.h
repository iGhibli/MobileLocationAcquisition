//
//  QYAnnotation.h
//  RunPath
//
//  Created by qingyun on 16/7/5.
//  Copyright © 2016年 QingYun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>

typedef enum {
    SJAnnotationTypeNow = 0,    ///< 当前点
    SJAnnotationTypeStart = 1,  ///< 开始点
    SJAnnotationTypePause = 2,  ///< 暂停点
    SJAnnotationTypeStop = 3,   ///< 结束点
}SJAnnotationType;

@interface QYAnnotation : NSObject<BMKAnnotation>

@property(nonatomic)CLLocationCoordinate2D coordinate;    // 遵守Annotation协议
@property (nonatomic, copy)NSString *title;
//自定义属性
@property (nonatomic) SJAnnotationType annotationType;    // 0,当前点,1开始点,2暂停点,3结束点
@property (nonatomic) CLLocation *nowLocation;            // 保存当前的CLLocation

@end
