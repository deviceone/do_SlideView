//
//  do_SlideView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_SlideView_IView <NSObject>

@required
//属性方法
- (void)change_templates:(NSString *)newValue;
- (void)change_index:(NSString *)newValue;
- (void)change_looping:(NSString *)newValue;

@end