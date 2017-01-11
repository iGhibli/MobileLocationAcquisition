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
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import "QYAnnotation.h"

@interface ViewController ()<BMKLocationServiceDelegate, BMKMapViewDelegate>
@property (weak, nonatomic) IBOutlet BMKMapView *mapView;

@property (strong, nonatomic) BMKLocationService *locationService;
@property (nonatomic, strong) NSMutableArray *allLocations;
@property (nonatomic, strong) QYAnnotation *nowAnnotation;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.allLocations = [NSMutableArray array];
    
    _locationService = [[BMKLocationService alloc] init];
    _locationService.distanceFilter = 15.f;
    _locationService.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    _locationService.delegate = self;
    
    self.mapView.delegate = self;
    
//    mapView = [[BMKMapView alloc]initWithFrame:self.view.bounds];
//    mapView.mapType = BMKMapTypeStandard;// 设置地图为空白类型
//    // 打开实时路况图层
//    [mapView setTrafficEnabled:NO];
//    // 设置指南针的位置
//    mapView.mapPadding = UIEdgeInsetsMake(20, 0, 20, 0);
//    // 地图比例尺级别，在手机上当前可使用的级别为3-19级(3为世界地图)
//    mapView.zoomLevel = 19.f;
//    //设置隐藏地图标注
//    [mapView setShowMapPoi:NO];
//    
//    //以下_mapView为BMKMapView对象
//    mapView.showsUserLocation = YES;//显示定位图层
////    [mapView updateLocationData:userLocation];
    
}

//- (void)viewWillAppear:(BOOL)animated {
//    [self.mapView viewWillAppear];
//    self.mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
//}
//- (void)viewWillDisappear:(BOOL)animated {
//    [self.mapView viewWillDisappear];
//    self.mapView.delegate = nil; // 不用时，置nil
//}

- (IBAction)beginAction:(UIButton *)sender {
    //开启定位
    //    [self.manager startUpdatingLocation];
    [_locationService startUserLocationService];
}

- (IBAction)pauseAction:(UIButton *)sender {
    //停止定位,添加一个暂停点
    //    [self.manager stopUpdatingLocation];
    [_locationService stopUserLocationService];
    
    QYAnnotation *anno = [[QYAnnotation alloc] init];
    anno.coordinate = self.nowAnnotation.coordinate;
    anno.type = 2;
    anno.title = @"暂停";
    [self.mapView addAnnotation:anno];
}

- (IBAction)stopAction:(UIButton *)sender {
    //停止定位,添加一个结束点标注
    //    [self.manager stopUpdatingLocation];
    [self.locationService stopUserLocationService];
    
    QYAnnotation *anno = [[QYAnnotation alloc] init];
    anno.coordinate = self.nowAnnotation.coordinate;
    anno.type = 3;
    anno.title = @"结束";
    [self.mapView addAnnotation:anno];
}


#pragma mark - BMK Location delegate

-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    CLLocation *location = userLocation.location;
    
    //当存放位置的数组为空,则为定位到的第一个点, 同时要设置地图的显示区域
    if (self.allLocations.count == 0) {
        //得到第一个点,添加开始点标注
        QYAnnotation *anno = [[QYAnnotation alloc] init];
        anno.coordinate = location.coordinate;
        anno.title = @"开始";
        anno.type = 1;
        [self.mapView addAnnotation:anno];
        
        BMKCoordinateSpan span;
        span.latitudeDelta = 0.005;
        span.longitudeDelta = 0.005;
        BMKCoordinateRegion region;
        region.center = location.coordinate;
        region.span = span;
        [self.mapView setRegion:region animated:YES];
    }
    
    [self.allLocations addObject:location];
    
    
    //添加当前点
    //每返回一个点,作为当前点添加标注,将地图的显示区域移动到定位到的位置
    QYAnnotation *nowAnno = [[QYAnnotation alloc] init];
    nowAnno.coordinate = location.coordinate;
    nowAnno.type = 0;
    [self.mapView addAnnotation:nowAnno];
    if (self.nowAnnotation) {
        [self.mapView removeAnnotation:self.nowAnnotation];
    }
    self.nowAnnotation = nowAnno;
    
    //将所有的点记录,添加行走的路线
    
    CLLocationCoordinate2D *coordinates = malloc(sizeof(CLLocationCoordinate2D) *self.allLocations.count);
    for (int i = 0; i < self.allLocations.count; i ++) {
        coordinates[i] = [self.allLocations[i] coordinate];
    }
    //    MKPolyline
    BMKPolyline *poly = [BMKPolyline polylineWithCoordinates:coordinates count:self.allLocations.count];
    
    [self.mapView addOverlay:poly];
}


#pragma mark - location manager delegate

//
//-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
//
//    CLLocation *location = locations.lastObject;
//
//    //当存放位置的数组为空,则为定位到的第一个点, 同时要设置地图的显示区域
//    if (self.allLocations.count == 0) {
//        //得到第一个点,添加开始点标注
//        QYAnnotation *anno = [[QYAnnotation alloc] init];
//        anno.coordinate = location.coordinate;
//        anno.title = @"开始";
//        anno.type = 1;
//        [self.mapView addAnnotation:anno];
//
//        MKCoordinateSpan span = MKCoordinateSpanMake(0.005, 0.005);
//        MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, span);
//        [self.mapView setRegion:region animated:YES];
//    }
//
//    [self.allLocations addObject:location];
//
//
//    //添加当前点
//     //每返回一个点,作为当前点添加标注,将地图的显示区域移动到定位到的位置
//    QYAnnotation *nowAnno = [[QYAnnotation alloc] init];
//    nowAnno.coordinate = location.coordinate;
//    nowAnno.type = 0;
//    [self.mapView addAnnotation:nowAnno];
//    if (self.nowAnnotation) {
//        [self.mapView removeAnnotation:self.nowAnnotation];
//    }
//    self.nowAnnotation = nowAnno;
//
//    //将所有的点记录,添加行走的路线
//
//    CLLocationCoordinate2D *coordinates = malloc(sizeof(CLLocationCoordinate2D) *self.allLocations.count);
//    for (int i = 0; i < self.allLocations.count; i ++) {
//        coordinates[i] = [self.allLocations[i] coordinate];
//    }
////    MKPolyline
//    MKPolyline *poly = [MKPolyline polylineWithCoordinates:coordinates count:self.allLocations.count];
//
//    [self.mapView addOverlay:poly];
//
//}

//返回标注视图



-(BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation{
    if ([annotation isKindOfClass:[QYAnnotation class]]) {
        QYAnnotation *anno = (QYAnnotation *)annotation;
        static NSString *identifier = @"qyannotation";
        //从复用队列出队标注视图
        BMKAnnotationView *annoView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!annoView){
            annoView = [[BMKAnnotationView alloc] initWithAnnotation:anno reuseIdentifier:identifier];
        }
        
        //给视图绑定数据
        annoView.annotation = annotation;
        annoView.canShowCallout = YES;//显示 callout
        //自定义图片
        switch (anno.type) {
            case 0:
            {
                annoView.image = [UIImage imageNamed:@"currentlocation"];
                annoView.centerOffset = CGPointMake(0, 0);
            }
                break;
            case 1:
            {
                annoView.image = [UIImage imageNamed:@"map_start_icon"];
                annoView.centerOffset = CGPointMake(0, -12);
            }
                break;
            case 2:
            {
                annoView.image = [UIImage imageNamed:@"map_susoend_icon"];
                annoView.centerOffset = CGPointMake(0, -12);
            }
                break;
            case 3:
            {
                annoView.image = [UIImage imageNamed:@"map_stop_icon"];
                annoView.centerOffset = CGPointMake(0, -12);
            }
                break;
            default:
                break;
        }
        
        return annoView;
        
    }
    return nil;
}


//返回曲线视图
-(BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView *renderer = [[BMKPolylineView alloc] initWithPolyline:overlay];
        //配置渲染图层的属性
        renderer.strokeColor = [UIColor blueColor];
        renderer.lineWidth = 3.f;
        return renderer;
    }
    return nil;
}

//-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
//    if ([overlay isKindOfClass:[MKPolyline class]]) {
//        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
//        //配置渲染图层的属性
//        renderer.strokeColor = [UIColor blueColor];
//        renderer.lineWidth = 3.f;
//        return renderer;
//    }
//    return nil;
//}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
