//
//  do_SlideView_Model.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_SlideView_UIModel.h"
#import "doProperty.h"

@implementation do_SlideView_UIModel

#pragma mark - 注册属性（--属性定义--）
-(void)OnInit
{
    [super OnInit];    
    //注册属性
    //属性声明
    [self RegistProperty:[[doProperty alloc]init:@"templates" :String :@"" :YES]];
    [self RegistProperty:[[doProperty alloc]init:@"index" :String :@"" :YES]];
    [self RegistProperty:[[doProperty alloc]init:@"looping" :String :@"" :YES]];
}

@end