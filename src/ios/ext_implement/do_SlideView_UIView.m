//
//  do_SlideView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_SlideView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doJsonNode.h"
#import "doJsonValue.h"
#import "doIPage.h"
#import "doUIContainer.h"
#import "doISourceFS.h"

@implementation do_SlideView_UIView
{
    @private
    NSMutableDictionary* _pages;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _pages = [[NSMutableDictionary alloc]init];
}
//销毁所有的全局对象
- (void) OnDispose
{
    for(int i = 0;i<_pages.count;i++)
    {
        doUIModule* module = [_pages allValues][i];
        [module Dispose];
    }
    for(int i =0;i<[self subviews].count;i++)
    {
        [self.subviews[i] removeFromSuperview];
    }
    [_pages removeAllObjects];
    _model = nil;
    //自定义的全局属性
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */

#pragma mark -
#pragma mark - 同步异步方法的实现
/*
    1.参数节点
        doJsonNode *_dictParas = [parms objectAtIndex:0];
        在节点中，获取对应的参数
        NSString *title = [_dictParas GetOneText:@"title" :@"" ];
        说明：第一个参数为对象名，第二为默认值
 
    2.脚本运行时的引擎
        id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
 
 同步：
    3.同步回调对象(有回调需要添加如下代码)
        doInvokeResult *_invokeResult = [parms objectAtIndex:2];
        回调信息
        如：（回调一个字符串信息）
        [_invokeResult SetResultText:((doUIModule *)_model).UniqueKey];
 异步：
    3.获取回调函数名(异步方法都有回调)
        NSString *_callbackName = [parms objectAtIndex:2];
        在合适的地方进行下面的代码，完成回调
        新建一个回调对象
        doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
        填入对应的信息
        如：（回调一个字符串）
        [_invokeResult SetResultText: @"异步方法完成"];
        [_scritEngine Callback:_callbackName :_invokeResult];
 */
//同步
 - (void)addViews:(NSArray *)parms
 {
     doJsonNode *_dictParas = [parms objectAtIndex:0];
     //构建_invokeResult的内容
     NSArray * pages = [_dictParas GetOneNodeArray:@"data"];
     for(int i = 0;i <pages.count;i++){
         doJsonNode* page = pages[i];
         NSString* pageID = [page GetOneText:@"id" :@""];
         NSString* pagePath = [page GetOneText:@"path" :@""];
         [_pages setObject:pagePath forKey:pageID];
     }
     //自己的代码实现
 }
 - (void)removeView:(NSArray *)parms
 {
     doJsonNode *_dictParas = [parms objectAtIndex:0];
     //构建_invokeResult的内容
     NSString* pageID = [_dictParas GetOneText : @"id" : @""];
     id pageValue = _pages[pageID];
     if (pageValue!=nil) {
         if([pageValue isKindOfClass:[NSString class]])
             [_pages removeObjectForKey:pageID];
         else if([pageValue isKindOfClass:[doUIModule class]])
         {
             UIView* view =(UIView*)(((doUIModule*)pageValue).CurrentUIModuleView);
             [view removeFromSuperview];
             [_pages removeObjectForKey:pageID];
             [((doUIModule*)pageValue) Dispose];
         }
     }
     //自己的代码实现
 }
 - (void)showView:(NSArray *)parms
 {
     doJsonNode *_dictParas = [parms objectAtIndex:0];
     //构建_invokeResult的内容
     NSString* pageID = [_dictParas GetOneText : @"id" : @""];
     NSString* animationType = [_dictParas GetOneText : @"animationType" : @""];
     int animationTime = [_dictParas GetOneInteger: @"animationTime" : 300];
     id pageValue = _pages[pageID];
     if (pageValue!=nil) {
         UIView* view = nil;
         if([pageValue isKindOfClass:[NSString class]])
         {
             NSString* fileName = (NSString*) pageValue;
             doSourceFile *source = [[[_model.CurrentPage CurrentApp] SourceFS] GetSourceByFileName:fileName];
             id<doIPage> pageModel = _model.CurrentPage;
             doUIContainer *container = [[doUIContainer alloc] init:pageModel];
             [container LoadFromFile:source:nil:nil];
             doUIModule* module = container.RootView;
             [container LoadDefalutScriptFile:fileName];
             view = (UIView*)(((doUIModule*)module).CurrentUIModuleView);
             id<doIUIModuleView> modelView =((doUIModule*) module).CurrentUIModuleView;
             [modelView OnRedraw];
             _pages[pageID] = module;
         }
         else if([pageValue isKindOfClass:[doUIModule class]])
         {
             view =(UIView*)(((doUIModule*)pageValue).CurrentUIModuleView);
             if(view==[self subviews][0])//已经显示了当前页就不需要再刷新
                 return;
         }
         
         for(int i =0;i<[self subviews].count;i++)
         {
             UIView* subview = self.subviews[i];
             [subview.layer removeAllAnimations];
             [subview removeFromSuperview];
         }

         CATransition *animation = [doUIModuleHelper GetAnmation:animationType :animationTime/1000.0];
         if (animationTime != 0&&animationType.length>0) {
             [self.layer addAnimation:animation forKey:animationType.lowercaseString];
              }
         [self addSubview:view];
         [self bringSubviewToFront:view];
         doInvokeResult* _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
         [_model.EventCenter FireEvent:@"viewChanged" :_invokeResult];
     }
 }

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (doJsonNode *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (doJsonNode *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
