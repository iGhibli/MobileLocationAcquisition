//
//  ViewController.m
//  MobileLocationAcquisition
//
//  Created by 赛驰 on 2017/1/9.
//  Copyright © 2017年 iGhibli. All rights reserved.
//

#import "ViewController.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import "QYAnnotation.h"

@interface ViewController ()<BMKLocationServiceDelegate, BMKMapViewDelegate>
@property (weak, nonatomic) IBOutlet BMKMapView *mapView;

@property (strong, nonatomic) BMKLocationService *locationService;
@property (nonatomic, strong) NSMutableArray *allLocations;
@property (nonatomic, strong) QYAnnotation *nowAnnotation;
@property (nonatomic, assign) SJPathDrawType nowPathDrawType;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.allLocations = [NSMutableArray array];
    self.nowPathDrawType = SJPathDrawTypeNone;
    
    _locationService = [[BMKLocationService alloc] init];
    _locationService.distanceFilter = 15.f;
    _locationService.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    _locationService.delegate = self;
    //    self.mapView.mapType = BMKMapTypeStandard;// 设置地图为空白类型
    //    // 打开实时路况图层
    //    [self.mapView setTrafficEnabled:NO];
    //    // 设置指南针的位置
    //    self.mapView.mapPadding = UIEdgeInsetsMake(20, 0, 20, 0);
    //    // 地图比例尺级别，在手机上当前可使用的级别为3-19级(3为世界地图)
    //    self.mapView.zoomLevel = 19.f;
    //    //设置隐藏地图标注
    //    [self.mapView setShowMapPoi:NO];
    //
    //    //以下_mapView为BMKMapView对象
    //    self.mapView.showsUserLocation = YES;//显示定位图层
    self.mapView.delegate = self;
    // 直接开启定位
    [_locationService startUserLocationService];
    
}

- (IBAction)beginAction:(UIButton *)sender {
    // 得到第一个点,添加开始点标注
    self.nowPathDrawType = SJPathDrawTypeDraw;
    QYAnnotation *anno = [[QYAnnotation alloc] init];
    anno.coordinate = self.nowAnnotation.coordinate;
    anno.annotationType = SJAnnotationTypeStart;
    anno.title = @"开始";
    [self.mapView addAnnotation:anno];
}

- (IBAction)pauseAction:(UIButton *)sender {
    // 添加一个暂停点
    self.nowPathDrawType = SJPathDrawTypeNone;
    QYAnnotation *anno = [[QYAnnotation alloc] init];
    anno.coordinate = self.nowAnnotation.coordinate;
    anno.annotationType = SJAnnotationTypePause;
    anno.title = @"暂停";
    [self.mapView addAnnotation:anno];
}

- (IBAction)stopAction:(UIButton *)sender {
    // 添加一个结束点标注
    self.nowPathDrawType = SJPathDrawTypeNone;
    QYAnnotation *anno = [[QYAnnotation alloc] init];
    anno.coordinate = self.nowAnnotation.coordinate;
    anno.annotationType = SJAnnotationTypeStop;
    anno.title = @"结束";
    [self.mapView addAnnotation:anno];
}

- (IBAction)redisplay:(UIButton *)sender {
    
}


#pragma mark - BMK Location delegate
-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    CLLocation *location = userLocation.location;
    // 设置地图的显示区域
    BMKCoordinateSpan span;
    span.latitudeDelta = 0.005;
    span.longitudeDelta = 0.005;
    BMKCoordinateRegion region;
    region.center = location.coordinate;
    region.span = span;
    [self.mapView setRegion:region animated:YES];
    
    //添加当前点
    //每返回一个点,作为当前点添加标注,将地图的显示区域移动到定位到的位置
    QYAnnotation *nowAnno = [[QYAnnotation alloc] init];
    nowAnno.coordinate = location.coordinate;
    nowAnno.annotationType = SJAnnotationTypeNow;
    [self.mapView addAnnotation:nowAnno];
    if (self.nowAnnotation) {
        [self.mapView removeAnnotation:self.nowAnnotation];
    }
    self.nowAnnotation = nowAnno;
    if (self.nowPathDrawType == SJPathDrawTypeDraw) {
        [self.allLocations addObject:location];
        //将所有的点记录,添加行走的路线
        CLLocationCoordinate2D *coordinates = malloc(sizeof(CLLocationCoordinate2D) *self.allLocations.count);
        for (int i = 0; i < self.allLocations.count; i ++) {
            coordinates[i] = [self.allLocations[i] coordinate];
        }
        // MKPolyline
        BMKPolyline *poly = [BMKPolyline polylineWithCoordinates:coordinates count:self.allLocations.count];
        
        [self.mapView addOverlay:poly];
    }
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
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation{
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
        switch (anno.annotationType) {
            case SJAnnotationTypeNow:
            {
                annoView.image = [UIImage imageNamed:@"currentlocation"];
                annoView.centerOffset = CGPointMake(0, 0);
            }
                break;
            case SJAnnotationTypeStart:
            {
                annoView.image = [UIImage imageNamed:@"map_start_icon"];
                annoView.centerOffset = CGPointMake(0, -12);
            }
                break;
            case SJAnnotationTypePause:
            {
                annoView.image = [UIImage imageNamed:@"map_susoend_icon"];
                annoView.centerOffset = CGPointMake(0, -12);
            }
                break;
            case SJAnnotationTypeStop:
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
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay{
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

- (void)dealloc {
    [self.locationService stopUserLocationService];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
