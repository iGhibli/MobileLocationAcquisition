//
//  ViewController.m
//  MobileLocationAcquisition
//
//  Created by 赛驰 on 2017/1/9.
//  Copyright © 2017年 iGhibli. All rights reserved.
//
//#import <BaiduMapAPI_Base/BMKBaseComponent.h>//引入base相关所有的头文件
//
//#import <BaiduMapAPI_Map/BMKMapComponent.h>//引入地图功能所有的头文件
//
//#import <BaiduMapAPI_Search/BMKSearchComponent.h>//引入检索功能所有的头文件
//
//#import <BaiduMapAPI_Cloud/BMKCloudSearchComponent.h>//引入云检索功能所有的头文件
//
//#import <BaiduMapAPI_Location/BMKLocationComponent.h>//引入定位功能所有的头文件
//
//#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>//引入计算工具所有的头文件
//
//#import <BaiduMapAPI_Radar/BMKRadarComponent.h>//引入周边雷达功能所有的头文件
//
//#import <BaiduMapAPI_Map/BMKMapView.h>//只引入所需的单个头文件


#import "ViewController.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>

@interface ViewController ()<BMKMapViewDelegate> {
    BMKMapView *mapView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    mapView = [[BMKMapView alloc]initWithFrame:self.view.bounds];
    mapView.mapType = BMKMapTypeStandard;// 设置地图为空白类型
    // 打开实时路况图层
    [mapView setTrafficEnabled:NO];
    // 设置指南针的位置
    mapView.mapPadding = UIEdgeInsetsMake(20, 0, 20, 0);
    // 地图比例尺级别，在手机上当前可使用的级别为3-19级(3为世界地图)
    mapView.zoomLevel = 19.f;
    //设置隐藏地图标注
    [mapView setShowMapPoi:NO];
    
    //以下_mapView为BMKMapView对象
    mapView.showsUserLocation = YES;//显示定位图层
//    [mapView updateLocationData:userLocation];
    self.view = mapView;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [mapView viewWillAppear];
    mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
}
- (void)viewWillDisappear:(BOOL)animated
{
    [mapView viewWillDisappear];
    mapView.delegate = nil; // 不用时，置nil
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
