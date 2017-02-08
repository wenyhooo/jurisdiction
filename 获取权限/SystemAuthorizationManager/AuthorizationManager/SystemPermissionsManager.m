//
//  SystemPermissionsManager.m
//  SystemPermissionsManager
//
//  Created by Kenvin on 2016/11/24.
//  Copyright © 2016年 上海方创金融股份信息服务有限公司. All rights reserved.
//


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "SystemPermissionsManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <Photos/Photos.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <ContactsUI/ContactsUI.h>
#import <CoreTelephony/CTCellularData.h>

#import "BlockAlertView.h"

static NSString *const APPNAME = @"";  //填写自己APP NAME

static SystemPermissionsManager *systemPermissionsManager = nil;

@interface SystemPermissionsManager ()<CLLocationManagerDelegate,UIAlertViewDelegate>

@property(nonatomic,strong) CLLocationManager *locationManager;


@end

@implementation SystemPermissionsManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        systemPermissionsManager = [[SystemPermissionsManager alloc] init];
    });
    return systemPermissionsManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        systemPermissionsManager = [super allocWithZone:zone];
    });
    return systemPermissionsManager;
}

- (id)init {
    self = [super init];
    if (self) {
        //如果不需要定位的话，请删除与定位相关的代码即可。
        [self setup];
    }
    return self;
}

- (void)setup {
    //定位
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.distanceFilter = 1.0;
    if([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationManager requestAlwaysAuthorization]; // 永久授权
    }
    
    
    if ([CLLocationManager locationServicesEnabled]) {
        if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 8.0) {
            [_locationManager requestAlwaysAuthorization];
        }
        CLAuthorizationStatus status = CLLocationManager.authorizationStatus;
        if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
            
        }else{
            
        }
    }else{
        
    }
    
}


-(id)copyWithZone:(struct _NSZone *)zone{
    return systemPermissionsManager;
}

- (BOOL)requestAuthorization:(KSystemPermissions)systemPermissions{
    switch (systemPermissions) {
        case KAVMediaTypeVideo:{
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
                NSString *mediaType = AVMediaTypeVideo;
                AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
                if(authStatus == ALAuthorizationStatusDenied){
                    
                    NSString *tips = [NSString stringWithFormat:@"请在iPhone的”设置-隐私-相机“选项中，允许%@访问你的手机相机",APPNAME];
                    [self executeAlterTips:tips isSupport:YES];
                    return NO;
                }else if(authStatus == ALAuthorizationStatusRestricted ){
                    [self executeAlterTips:nil isSupport:NO];
                    return NO;
                }else if(authStatus == ALAuthorizationStatusNotDetermined ){
                    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                        if (granted) {
                            
                        }else{
                            
                        }
                    }];
                }
            }
        }
            break;
        case KALAssetsLibrary:{
            
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
                    ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
                    if ( authStatus ==ALAuthorizationStatusDenied){
                        //无权限
                        NSString *tips = [NSString stringWithFormat:@"请在iPhone的”设置-隐私-相册“选项中，允许%@访问你的手机相册",APPNAME];
                        [self executeAlterTips:tips isSupport:YES];
                        return NO;
                    }else if (authStatus == ALAuthorizationStatusRestricted){
                        [self executeAlterTips:nil isSupport:NO];
                        return NO;
                    }
                }else{
                    
                    PHAuthorizationStatus  authorizationStatus = [PHPhotoLibrary   authorizationStatus];
                    if (authorizationStatus == PHAuthorizationStatusRestricted) {
                        [self executeAlterTips:nil isSupport:NO];
                        return NO;
                    }else if(authorizationStatus == PHAuthorizationStatusDenied){
                        
                        NSString *tips = [NSString stringWithFormat:@"请在iPhone的”设置-隐私-相册“选项中，允许%@访问你的手机相册",APPNAME];
                        [self executeAlterTips:tips isSupport:YES];
                        return NO;
                    }else if (authorizationStatus == PHAuthorizationStatusNotDetermined){
                        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                            
                        }];
                    }
                    
                }
                
            }
            
        }
            break;
        case KCLLocationManager:{
            CLAuthorizationStatus authStatus = CLLocationManager.authorizationStatus;
            if ( authStatus == kCLAuthorizationStatusDenied) {
                NSString *tips = [NSString stringWithFormat:@"请在iPhone的”设置-隐私-定位“选项中，允许%@访问你的定位",APPNAME];
                [self executeAlterTips:tips isSupport:YES];
                return NO;
            }else if(authStatus == kCLAuthorizationStatusRestricted ){
                [self executeAlterTips:nil isSupport:NO];
                return NO;
            }
        }
            break;
        case KAVAudioSession:{
            if (![self canRecord]) {
                NSString *tips = [NSString stringWithFormat:@"请在iPhone的”设置-隐私-麦克风“选项中，允许%@访问你的麦克风",APPNAME];
                [self executeAlterTips:tips isSupport:YES];
                return NO;
            }
        }
            break;
        case KABAddressBook:{
            ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
            NSString *tips = [NSString stringWithFormat:@"请在iPhone的”设置-隐私-联系人“选项中，允许%@访问你的手机通讯录",APPNAME];
            
            if ( authStatus ==kABAuthorizationStatusDenied){
                //无权限
                [self executeAlterTips:tips isSupport:YES];
                return NO;
            }else if (authStatus == kABAuthorizationStatusRestricted ){
                [self executeAlterTips:nil isSupport:NO];
                return NO;
            }else if(authStatus == kABAuthorizationStatusNotDetermined){
                __block ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
                
                if (addressBook == NULL) {
                    
                    [self executeAlterTips:nil isSupport:NO];
                    return NO;
                }
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                    
                    if (granted) {
                        
                    }else{
                        
                    }
                    
                    if (addressBook) {
                        CFRelease(addressBook);
                        addressBook = NULL;
                    }
                });
                
            }
        }
            break;
        case KCTCellularData:{
            CTCellularData *cellularData = [[CTCellularData alloc]init];
//            CTCellularDataRestrictedState state = cellularData.restrictedState;
            cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state)
            {
                NSLog(@"网络权限状态11=%lu",(unsigned long)cellularData.restrictedState);
                if (state == kCTCellularDataRestricted || state == kCTCellularDataRestrictedStateUnknown){
                    NSLog(@"网络权限状态222=%lu",(unsigned long)state);
                    NSString *tips = [NSString stringWithFormat:@"请在iPhone的”设置-隐私-网络“选项中，允许%@访问你的shabi网络",APPNAME];
                    [self executeAlterTips:tips isSupport:YES];
                    
                }
            };
        }
            break;
        default:
            break;
    }
    
    return YES;
}


- (BOOL)canRecord{
    
    __block BOOL bCanRecord = YES;
    if ([[UIDevice currentDevice] systemVersion].floatValue > 7.0){
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                } else {
                    bCanRecord = NO;
                }
            }];
        }
    }
    
    return bCanRecord;
}


- (void)executeAlterTips:(NSString *)alterTips isSupport:(BOOL)isSupport{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *alterContent = @"";
        if (isSupport) {
            alterContent = alterTips;
            [BlockAlertView alertWithTitle:alterContent
                                   message:@""
                     cancelButtonWithTitle:@"取消"
                               cancelBlock:^{
                                   
                               } confirmButtonWithTitle:@"去设置" confirmBlock:^{
                                   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                                                      options:@{@"url":@""}
                                                            completionHandler:^(BOOL success) {
                                                                
                                                            }];
                               }];
        }else{
            alterContent = @"权限受限";
            [BlockAlertView alertWithTitle:alterContent
                                   message:@""
                     cancelButtonWithTitle:nil
                               cancelBlock:^{
                                   
                               } confirmButtonWithTitle:@"确定"
                              confirmBlock:^{
                                  
                              }];
        }
        
    });
}

@end

#pragma clang diagnostic pop
