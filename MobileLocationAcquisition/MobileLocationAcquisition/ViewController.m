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
#import "DataBaseEngine.h"

@interface ViewController ()<BMKLocationServiceDelegate, BMKMapViewDelegate>
@property (weak, nonatomic) IBOutlet BMKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *nowSpanBtn;

@property (strong, nonatomic) BMKLocationService *locationService;
@property (nonatomic, strong) NSMutableArray *allLocations;
@property (nonatomic, strong) QYAnnotation *nowAnnotation;
@property (nonatomic, assign) SJPathDrawType nowPathDrawType;
@property (nonatomic, assign) SJCoordinateSpanType nowCoordinateSpanType;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nowSpanBtn.layer.cornerRadius = 25.f;
    self.nowSpanBtn.clipsToBounds = YES;
    
    self.allLocations = [NSMutableArray array];
    self.nowPathDrawType = SJPathDrawTypeNone;
    self.nowCoordinateSpanType = SJCoordinateSpanTypeAuto;
    
    _locationService = [[BMKLocationService alloc] init];
    _locationService.distanceFilter = 15.f;
    _locationService.desiredAccuracy = kCLLocationAccuracyBest;
    _locationService.allowsBackgroundLocationUpdates = YES;
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
    // 读取是否有暂存
    NSArray *DBArray = [DataBaseEngine getGPXDatas];
    if (DBArray.count > 0) {
        for (NSDictionary *dict in DBArray) {
            CLLocation *tempLocation = [[CLLocation alloc]initWithLatitude:[dict[@"lat"] doubleValue] longitude:[dict[@"lon"] doubleValue]];
            [self.allLocations addObject:tempLocation];
        }
        if (self.allLocations.count > 0) {
            [self displayTemporaryStorageData];
        }
    }
}
// 显示暂存信息
- (void)displayTemporaryStorageData {
    // 得到第一个点,添加开始点标注
    QYAnnotation *startAnno = [[QYAnnotation alloc] init];
    CLLocation *startLoc = self.allLocations.firstObject;
    startAnno.coordinate = startLoc.coordinate;
    startAnno.annotationType = SJAnnotationTypeStart;
    startAnno.title = @"开始";
    [self.mapView addAnnotation:startAnno];
    //将所有的点记录,添加行走的路线
    CLLocationCoordinate2D *coordinates = malloc(sizeof(CLLocationCoordinate2D) *self.allLocations.count);
    for (int i = 0; i < self.allLocations.count; i ++) {
        coordinates[i] = [self.allLocations[i] coordinate];
    }
    // MKPolyline
    BMKPolyline *poly = [BMKPolyline polylineWithCoordinates:coordinates count:self.allLocations.count];
    [self.mapView addOverlay:poly];
    // 添加一个暂停点
    QYAnnotation *pauseAnno = [[QYAnnotation alloc] init];
    CLLocation *pauseLoc = self.allLocations.lastObject;
    pauseAnno.coordinate = pauseLoc.coordinate;
    pauseAnno.annotationType = SJAnnotationTypePause;
    pauseAnno.title = @"暂停";
    [self.mapView addAnnotation:pauseAnno];
}
// 存储保留坐标
- (void)saveGPXDatas:(NSArray *)gpxs {
    if (gpxs.count > 0) {
        [DataBaseEngine deleteAllGPXs];
        for (CLLocation *loca in gpxs) {
            [DataBaseEngine saveGPXDataLatitude:loca.coordinate.latitude andLongitude:loca.coordinate.longitude];
        }
    }
}

// 开始
- (IBAction)beginAction:(UIButton *)sender {
    if (self.nowPathDrawType != SJPathDrawTypeDraw) {
        // 得到第一个点,添加开始点标注
        self.nowPathDrawType = SJPathDrawTypeDraw;
        QYAnnotation *anno = [[QYAnnotation alloc] init];
        anno.coordinate = self.nowAnnotation.coordinate;
        anno.annotationType = SJAnnotationTypeStart;
        anno.title = @"开始";
        [self.mapView addAnnotation:anno];
        if (self.nowAnnotation.nowLocation != nil) {
            [self.allLocations addObject:self.nowAnnotation.nowLocation];
        }
    }
}
// 暂停(暂存)
- (IBAction)pauseAction:(UIButton *)sender {
    if (self.nowPathDrawType == SJPathDrawTypeDraw) {
        // 添加一个暂停点
        self.nowPathDrawType = SJPathDrawTypeNone;
        QYAnnotation *anno = [[QYAnnotation alloc] init];
        anno.coordinate = self.nowAnnotation.coordinate;
        anno.annotationType = SJAnnotationTypePause;
        anno.title = @"暂停";
        [self.mapView addAnnotation:anno];
        // 暂存当前坐标
        [self saveGPXDatas:self.allLocations];
    }
}
// 结束
- (IBAction)stopAction:(UIButton *)sender {
    if (self.allLocations.count > 0) {
        // 添加一个结束点标注
        self.nowPathDrawType = SJPathDrawTypeNone;
        QYAnnotation *anno = [[QYAnnotation alloc] init];
        anno.coordinate = self.nowAnnotation.coordinate;
        anno.annotationType = SJAnnotationTypeStop;
        anno.title = @"结束";
        [self.mapView addAnnotation:anno];
        // 结束保存所有坐标
        [self saveGPXDatas:self.allLocations];
    }
}
// 重做
- (IBAction)redoAction:(UIButton *)sender {
    self.nowPathDrawType = SJPathDrawTypeNone;
    [self.allLocations removeAllObjects];
    // 移除数据库坐标
    [DataBaseEngine deleteAllGPXs];
    // 移除所有绘制
    [self.mapView removeOverlays:self.mapView.overlays];
    // 移除所有标注
    [self.mapView removeAnnotations:self.mapView.annotations];
}
// 回显
- (IBAction)redisplay:(UIButton *)sender {
    [self redisplayPath];
}
- (void)redisplayPath {
    if (self.allLocations.count < 1) {
        return;
    }
    NSArray *tempArray = [NSArray arrayWithArray:self.allLocations];
    [self.allLocations removeAllObjects];
    // 移除所有绘制
    [self.mapView removeOverlays:self.mapView.overlays];
    // 移除所有标注
    [self.mapView removeAnnotations:self.mapView.annotations];
    NSMutableArray *redisplayArray = [NSMutableArray array];
    __block int j = 0;
    [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (j > tempArray.count - 2) {
            [timer invalidate];
            timer = nil;
        }
        [redisplayArray addObject:tempArray[j]];
        //将所有的点记录,添加行走的路线
        CLLocationCoordinate2D *coordinates = malloc(sizeof(CLLocationCoordinate2D) *redisplayArray.count);
        for (int i = 0; i < redisplayArray.count; i ++) {
            coordinates[i] = [redisplayArray[i] coordinate];
        }
        // MKPolyline
        BMKPolyline *poly = [BMKPolyline polylineWithCoordinates:coordinates count:redisplayArray.count];
        [self.mapView addOverlay:poly];
        j++;
    }];
    self.allLocations = [NSMutableArray arrayWithArray:tempArray];
}
// 上传
- (IBAction)uploadAction:(UIButton *)sender {
    // 邮件解决
}
// 重新设置显示区域
- (IBAction)spanSetAction:(UIButton *)sender {
    if (self.nowCoordinateSpanType == SJCoordinateSpanTypeCustom) {
        self.nowCoordinateSpanType = SJCoordinateSpanTypeAuto;
    }
}
#pragma mark - BMKMapViewDelegate
- (void)mapStatusDidChanged:(BMKMapView *)mapView {
    if (mapView.region.span.latitudeDelta != 0.05 && self.nowCoordinateSpanType == SJCoordinateSpanTypeAuto) {
//        self.nowCoordinateSpanType = SJCoordinateSpanTypeCustom;
    }
}


#pragma mark - BMK Location delegate
-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    CLLocation *location = userLocation.location;
    // 设置地图的显示区域
    if (self.nowCoordinateSpanType == SJCoordinateSpanTypeAuto) {
        BMKCoordinateSpan span;
        span.latitudeDelta = 0.005;
        span.longitudeDelta = 0.005;
        BMKCoordinateRegion region;
        region.center = location.coordinate;
        region.span = span;
        [self.mapView setRegion:region animated:YES];
    }
    
    //添加当前点
    //每返回一个点,作为当前点添加标注,将地图的显示区域移动到定位到的位置
    QYAnnotation *nowAnno = [[QYAnnotation alloc] init];
    nowAnno.coordinate = location.coordinate;
    nowAnno.annotationType = SJAnnotationTypeNow;
    nowAnno.nowLocation = location;
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
        annoView.canShowCallout = YES;  // 显示 callout
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

// 返回绘制曲线视图
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

- (void)dealloc {
    [self.locationService stopUserLocationService];
    // 置空才能释放内存
    self.mapView.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
