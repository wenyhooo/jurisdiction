//
//  ViewController.m
//  SystemAuthorizationManager
//
//  Created by Kenvin on 17/1/16.
//  Copyright © 2017年 上海方创金融信息服务股份有限公司. All rights reserved.
//

#import "ViewController.h"
#import "SystemPermissionsManager.h"

@interface ViewController ()
@property(nonatomic, strong) NSDictionary *getDic;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [[SystemPermissionsManager sharedManager] requestAuthorization:KCTCellularData];
    [self sessionAndGet];    [self sessionAndGet];    [self sessionAndGet];    [self sessionAndGet];    [self sessionAndGet];
}

- (void)sessionAndGet {
    //网址
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com/"];
    //建立加载数据任务
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
//        dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
//        NSLog(@"%@",dic);
    }];
    //启动任务
    [dataTask resume];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[SystemPermissionsManager sharedManager] requestAuthorization:KCTCellularData];
        [[SystemPermissionsManager sharedManager] requestAuthorization:KABAddressBook];
        [[SystemPermissionsManager sharedManager] requestAuthorization:KAVAudioSession];
        [[SystemPermissionsManager sharedManager] requestAuthorization:KALAssetsLibrary];
        [[SystemPermissionsManager sharedManager] requestAuthorization:KAVMediaTypeVideo];

}

@end
