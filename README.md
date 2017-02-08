# SystemAuthorizationManager

在开发中，我们可能会遇到这样的情况，用户自己关闭了所有的操作权限，以后要使用我们的App,总是得不到想要的结果。这个时候，对用户操作权限的获取，并进行必要的提示就必不可少了。

  
![84B2A9705B046412E1D8F9591830C8FB.png](http://upload-images.jianshu.io/upload_images/325120-1ea360b50ed50ebd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/680)
#苹果对用户权限逻辑的修改
 在iOS10中，如果你的App想要访问用户的相机、相册、麦克风、通讯录等等权限，都需要进行相关的配置，不然会直接crash（闪退）。
需要在info.plist中添加App需要的一些设备权限。

```
    <key>NSCalendarsUsageDescription</key>
    <string>访问日历</string>
    <key>NSCameraUsageDescription</key>
    <string>访问相机</string>
    <key>NSContactsUsageDescription</key>
    <string>访问联系人</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>我们需要通过您的地理位置信息获取您周边的相关数据,提供精准服务</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>我们需要通过您的地理位置信息获取您周边的相关数据,提供精准服务</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>访问麦克风</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>访问相册</string>

```

那么在这种情况下，就需要对用户权限的获取状态和逻辑进行修改。下边是我对整个App用户请求权限的封装。代码还是很简单的。

 # 用户权限状态的几种枚举类型

```
AuthorizationStatusNotDetermined      // 用户从未进行过授权等处理，首次访问相应内容会提示用户进行授权
 AuthorizationStatusAuthorized = 0,    // 用户已授权，允许访问
 AuthorizationStatusDenied,            // 用户拒绝访问
 AuthorizationStatusRestricted,        // 应用没有相关权限，且当前用户无法改变这个权限，比如:家长控制

```
常见的几种可以获取系统权限的对象

  ```

typedef NS_ENUM(NSInteger, KSystemPermissions) {
    
    KAVMediaTypeVideo = 0,  // 相机
    KALAssetsLibrary,       //相册
    KCLLocationManager,     //地理位置信息
    KAVAudioSession,        //音频
    KABAddressBook          //手机通讯录
};

```

大致的思路就是根据 传入的需要获取权限的对象， 弹出响应的提示语，让用户根据需要决定是否去设置中开启相应的权限。
 由于代码比较简单，这里就大致提一下，具体可以将Demo 下载下来。

我写的Demo地址： [SystemAuthorizationManager](https://github.com/summerHearts/SystemAuthorizationManager)。稍后会使用pods的形式，集成到工程中。

```
//
//  SystemPermissionsManager.h
//  SystemPermissionsManager
//
//  Created by Kenvin on 2016/11/24.
//  Copyright © 2016年 上海方创金融股份信息服务有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum KSystemPermissionsType {
    KAVMediaTypeVideo = 0,  // 相机
    KALAssetsLibrary,       //相册
    KCLLocationManager,     //地理位置信息
    KAVAudioSession,        //音频
    KABAddressBook          //手机通讯录
} KSystemPermissions;

@interface SystemPermissionsManager : NSObject

+ (instancetype)sharedManager ;

/**
 *  根据场景选择合适的提示系统权限类型
 *
 *  @param systemPermissions 系统权限类型
 *
 *  @return 是否具有权限
 */
- (BOOL)requestAuthorization:(KSystemPermissions)systemPermissions;
@end

```
```
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
                                   
                               } confirmButtonWithTitle:@"去设置" confrimBlock:^{
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
                              confrimBlock:^{
                                  
                              }];
        }
        
    });
}

@end

#pragma clang diagnostic pop

```


#如何使用，方法如下

```
    [[SystemPermissionsManager sharedManager] requestAuthorization:KALAssetsLibrary];

```
