//
//  AppDelegate.h
//  MobileLocationAcquisition
//
//  Created by 赛驰 on 2017/1/9.
//  Copyright © 2017年 iGhibli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    BMKMapManager *_mapManager;
}

@property (strong, nonatomic) UIWindow *window;


@end

