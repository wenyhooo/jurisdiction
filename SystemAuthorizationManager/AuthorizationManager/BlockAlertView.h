//
//  BlockAlertView.h
//  SystemPermissionsManager
//
//  Created by Kenvin on 2016/11/24.
//  Copyright © 2016年 上海方创金融股份信息服务有限公司. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import <UIKit/UIKit.h>

@interface  BlockAlertView: UIAlertView<UIAlertViewDelegate>

+ (void)alertWithTitle:(NSString *)title
               message:(NSString *)message
               cancelButtonWithTitle:(NSString *)cancelTitle
               cancelBlock:(void (^)())cancelblock
               confirmButtonWithTitle:(NSString *)confirmTitle
               confirmBlock:(void (^)())confirmBlock;

@end


#pragma clang diagnostic pop
