//
//  ViewController.h
//  MobileLocationAcquisition
//
//  Created by 赛驰 on 2017/1/9.
//  Copyright © 2017年 iGhibli. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SJPathDrawTypeNone = 0,      ///< 不绘制
    SJPathDrawTypeDraw = 1,      ///< 绘制
}SJPathDrawType;

typedef enum {
    SJCoordinateSpanTypeAuto = 0,       ///< 自动
    SJCoordinateSpanTypeCustom = 1,     ///< 用户更改
}SJCoordinateSpanType;

@interface ViewController : UIViewController


@end

