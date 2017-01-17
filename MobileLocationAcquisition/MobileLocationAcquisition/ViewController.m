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

@property (nonatomic, assign) BOOL isRedisplay;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nowSpanBtn.layer.cornerRadius = 5.f;
    self.nowSpanBtn.clipsToBounds = YES;
    self.nowSpanBtn.selected = YES;
    
    self.allLocations = [NSMutableArray array];
    self.nowPathDrawType = SJPathDrawTypeNone;
    self.nowCoordinateSpanType = SJCoordinateSpanTypeAuto;
    self.isRedisplay = NO;
    
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
    [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (self.nowAnnotation != nil) {
            BMKCoordinateSpan span;
            span.latitudeDelta = 0.005;
            span.longitudeDelta = 0.005;
            BMKCoordinateRegion region;
            region.center = self.nowAnnotation.coordinate;
            region.span = span;
            [self.mapView setRegion:region animated:YES];
            [timer invalidate];
            timer = nil;
        }
    }];
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
        NSArray *DBArray = [DataBaseEngine getGPXDatas];
        if (DBArray.count > 0) {
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"是否继续上次未完成进度？" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                // 读取暂存
                if (DBArray.count > 0) {
                    if (self.allLocations > 0) {
                        [self.allLocations addObject:self.nowAnnotation.nowLocation];
                        [self displayTemporaryStorageData];
                        [self showAllAnnotationsIsWithCurrentLocation:YES];
                        self.nowPathDrawType = SJPathDrawTypeDraw;
                    }else {
                        for (NSDictionary *dict in DBArray) {
                            CLLocation *tempLocation = [[CLLocation alloc]initWithLatitude:[dict[@"lat"] doubleValue] longitude:[dict[@"lon"] doubleValue]];
                            [self.allLocations addObject:tempLocation];
                        }
                        if (self.allLocations.count > 0) {
                            [self.allLocations addObject:self.nowAnnotation.nowLocation];
                            [self displayTemporaryStorageData];
                        }
                        [self showAllAnnotationsIsWithCurrentLocation:YES];
                        self.nowPathDrawType = SJPathDrawTypeDraw;
                    }
                    
                }
            }];
            UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                // 清空所有信息
                [self redoAction:nil];
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
            }];
            [alertC addAction:okAction];
            [alertC addAction:deleteAction];
            [self presentViewController:alertC animated:YES completion:^{   }];
        }else {
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
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"确定执行结束？" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {  }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            // 添加一个结束点标注
            self.nowPathDrawType = SJPathDrawTypeNone;
            QYAnnotation *anno = [[QYAnnotation alloc] init];
            anno.coordinate = self.nowAnnotation.coordinate;
            anno.annotationType = SJAnnotationTypeStop;
            anno.title = @"结束";
            [self.mapView addAnnotation:anno];
            // 结束保存所有坐标
            [self saveGPXDatas:self.allLocations];
        }];
        [alertC addAction:okAction];
        [alertC addAction:deleteAction];
        [self presentViewController:alertC animated:YES completion:^{   }];
    }
}
// 重做
- (IBAction)redoAction:(UIButton *)sender {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"确定执行重做，执行后会删除本地所有信息？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {  }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        self.isRedisplay = NO;
        self.nowPathDrawType = SJPathDrawTypeNone;
        [self.allLocations removeAllObjects];
        // 移除数据库坐标
        [DataBaseEngine deleteAllGPXs];
        // 移除所有绘制
        [self.mapView removeOverlays:self.mapView.overlays];
        // 移除所有标注
        [self.mapView removeAnnotations:self.mapView.annotations];
    }];
    [alertC addAction:okAction];
    [alertC addAction:deleteAction];
    [self presentViewController:alertC animated:YES completion:^{   }];
}
// 回显
- (IBAction)redisplay:(UIButton *)sender {
    self.nowSpanBtn.selected = NO;
    self.nowCoordinateSpanType = SJCoordinateSpanTypeCustom;
    if (self.isRedisplay == YES) {
        if (self.allLocations.count > 0) {
            [self showAllAnnotationsIsWithCurrentLocation:NO];
        }
    }else {
        self.isRedisplay = YES;
        // 读取是否有暂存
        NSArray *DBArray = [DataBaseEngine getGPXDatas];
        if (DBArray.count > 0) {
            for (NSDictionary *dict in DBArray) {
                CLLocation *tempLocation = [[CLLocation alloc]initWithLatitude:[dict[@"lat"] doubleValue] longitude:[dict[@"lon"] doubleValue]];
                [self.allLocations addObject:tempLocation];
            }
            if (self.allLocations.count > 0) {
                [self displayTemporaryStorageData];
                [self showAllAnnotationsIsWithCurrentLocation:NO];
            }
        }
    }
}
// 上传
- (IBAction)uploadAction:(UIButton *)sender {
    // 邮件解决
}
// 重新设置显示区域
- (IBAction)spanSetAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.nowCoordinateSpanType == SJCoordinateSpanTypeCustom) {
        self.nowCoordinateSpanType = SJCoordinateSpanTypeAuto;
        BMKCoordinateSpan span;
        span.latitudeDelta = 0.005;
        span.longitudeDelta = 0.005;
        BMKCoordinateRegion region;
        region.center = self.nowAnnotation.coordinate;
        region.span = span;
        [self.mapView setRegion:region animated:YES];
    }else {
        self.nowCoordinateSpanType = SJCoordinateSpanTypeCustom;
    }
}

- (void)showAllAnnotationsIsWithCurrentLocation:(BOOL)isWith {
    NSMutableArray *orderArray = [NSMutableArray arrayWithArray:self.allLocations];
    if (isWith) {
        if (self.nowAnnotation != nil) {
            [orderArray addObject:self.nowAnnotation.nowLocation];
        }
    }
    NSMutableArray *latArray = [NSMutableArray array];
    NSMutableArray *lonArray = [NSMutableArray array];
    for (CLLocation *tempLoca in orderArray) {
        [latArray addObject:@(tempLoca.coordinate.latitude)];
        [lonArray addObject:@(tempLoca.coordinate.longitude)];
    }
    CGFloat maxLat = [[latArray valueForKeyPath:@"@max.floatValue"] floatValue];
    CGFloat minLat = [[latArray valueForKeyPath:@"@min.floatValue"] floatValue];
    
    CGFloat maxLon = [[lonArray valueForKeyPath:@"@max.floatValue"] floatValue];
    CGFloat minLon = [[lonArray valueForKeyPath:@"@min.floatValue"] floatValue];
    BMKCoordinateSpan span;
    span.latitudeDelta = maxLat - minLat + 0.002;
    span.longitudeDelta = maxLon - minLon + 0.002;
    CLLocationCoordinate2D center;
    center.latitude = (maxLat + minLat)/2;
    center.longitude = (maxLon + minLon)/2;
    BMKCoordinateRegion region;
    region.center = center;
    region.span = span;
    [self.mapView setRegion:region animated:YES];
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
