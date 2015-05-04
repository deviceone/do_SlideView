
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

#define SET_FRAME(CONTENT) x = CONTENT.frame.origin.x + increase;if(x < 0) x = pageWidth * 2;if(x > pageWidth * 2) x = 0.0f;[CONTENT setFrame:CGRectMake(x,CONTENT.frame.origin.y,CONTENT.frame.size.width,CONTENT.frame.size.height)]

#define MAX_VALUE [_dataArray GetCount]-1
#define MIN_VALUE 0


@interface do_SlideView_UIView ()<UIScrollViewDelegate>

@end


@implementation do_SlideView_UIView
{
    @private
    id<doIListData> _dataArray;
    BOOL _isLooping;
    NSMutableArray *_pages;
    int _currentPage;
    
    UIView *_leftView,*_middleView,*_rightView;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _isLooping = NO;
    _pages = [NSMutableArray array];
    _currentPage = 0;
    _leftView = [[UIView alloc] init];
    _middleView = [[UIView alloc] init];
    _rightView = [[UIView alloc] init];;
}

- (void)change_templates:(NSString *)newValue
{
    if (!newValue || [newValue isEqualToString:@""]) {
        return;
    }
    _pages = [NSMutableArray array];
    [_pages addObjectsFromArray:[newValue componentsSeparatedByString:@","]];
}

- (void)change_index:(NSString *)newValue
{
    if (!newValue || [newValue isEqualToString:@""]) {
        _currentPage = MIN_VALUE;
    }else{
        _currentPage = [newValue intValue];
        if (_currentPage > MAX_VALUE) {
            _currentPage = MAX_VALUE;
        }
    }
    
}

- (void)change_looping:(NSString *)newValue
{
    if (!newValue || [newValue isEqualToString:@""]) {
        _isLooping = NO;
    }else{
        _isLooping = [newValue boolValue];
    }
}


- (void)initialization{
    float y,width,height;
    y = 0;
    
    width = self.frame.size.width;
    height = self.frame.size.height;
    
    for (int j=0; j<3; j++) {
        CGRect r = CGRectMake(width*(j), y, width, height);
        
        if (j == 0) _leftView.frame = r;
        if (j == 1) _middleView.frame = r;
        if (j == 2) _rightView.frame = r;
    }
    
    [self addSubview:_leftView];
    [self addSubview:_middleView];
    [self addSubview:_rightView];

    [self setDelegate:self];
    [self setPagingEnabled:YES];
    [self setContentSize:CGSizeMake(width*3, height)];
    [self setShowsHorizontalScrollIndicator:NO];
}



#pragma mark -

#pragma mark UIScrollViewDelegate

//更新三个指针的指向，content1 -----> middle，content0 -----> left，content2 -----> right
- (void)allContentMoveRight:(CGFloat)pageWidth {
    UIView *tmpView = _rightView;

    _rightView = _middleView;
    _middleView = _leftView;
    _leftView = tmpView;
    
    float increase = pageWidth;
    CGFloat x = 0.0f;
    
    SET_FRAME(_rightView);
    SET_FRAME(_leftView);
    SET_FRAME(_middleView);
}

- (void)allContentMoveLeft:(CGFloat)pageWidth {
    UIView *tmpView = _leftView;

    _leftView = _middleView;
    _middleView = _rightView;
    _rightView = tmpView;
    
    float increase = -pageWidth;
    
    CGFloat x = 0.0f;

    SET_FRAME(_middleView);
    SET_FRAME(_rightView);
    SET_FRAME(_leftView);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)theself
{
    CGFloat pageWidth = self.frame.size.width;
    
    // 0 1 2  滑动距离必须大于半个页面
    int page = floor((theself.contentOffset.x - pageWidth/2) / pageWidth) + 1;
    
    if(page == 1) {
        if (_currentPage == 0) {
            _currentPage = 1;
        }
        return;
    }
    
    if (![self ifScroll:page]) {
        return;
    }
    
    [self genetatePage:page];
    NSLog(@"_currentPage = %i",_currentPage);

    if (page == 0) {
        [self allContentMoveRight:pageWidth];
    } else {
        [self allContentMoveLeft:pageWidth];
    }

    //建立新视图
    [self newCreatePage:page];

    CGPoint p = CGPointZero;
    p.x = pageWidth;
    [theself setContentOffset:p animated:NO];
}

- (void)genetatePage:(BOOL)ifLeft
{
    _currentPage += ifLeft?1:-1;
    if (_currentPage < MIN_VALUE) {
        _currentPage = MAX_VALUE;
    }else if(_currentPage > MAX_VALUE){
        _currentPage = MIN_VALUE;
    }
}

- (BOOL)ifScroll:(BOOL)ifLeft
{
    if ([_dataArray GetCount] < 3) {
        return false;
    }
    if (_isLooping) {
        return true;
    }else{
        return [self pageNoLoopingValidate:ifLeft];
    }
    return false;
}

- (BOOL)pageNoLoopingValidate:(BOOL)ifLeft
{
    NSInteger pageIncrease = ifLeft?1:-1;
    NSInteger p = _currentPage+pageIncrease;

    if (p <= MIN_VALUE || p >= MAX_VALUE) {
        return false;
    }
    return true;
}


- (void) bindItems: (NSArray*) parms
{
    doJsonNode * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine= [parms objectAtIndex:1];
    NSString* _address = [_dictParas GetOneText:@"data": nil];
    if (_address == nil || _address.length <= 0)
        [NSException raise:@"doSlideView" format:@"未指定相关的SlideView data参数！",nil];
    id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scriptEngine : _address];
    if (bindingModule == nil) [NSException raise:@"doListView" format:@"data参数无效！",nil];
    if([bindingModule conformsToProtocol:@protocol(doIListData)])
    {
        if(_dataArray!= bindingModule)
            _dataArray = bindingModule;
    }
}


- (void)refreshItems: (NSArray*) parms
{
    [self resetView:[NSArray arrayWithObjects:@(0),@(1),@(2), nil]];
}

- (void)resetView:(NSArray *)a
{
    for (int i = 0;i<a.count;i++) {
        int tmp = [[a objectAtIndex:i] intValue];
        UIView *view = [self getPage:tmp];
        if (view) {
            if (tmp == 0) {
                [_leftView addSubview:view];
            }else if (tmp == 1){
                [_middleView addSubview:view];
            }else if(tmp == 2){
                [_rightView addSubview:view];
            }
        }
    }
}

- (void)newCreatePage:(BOOL)ifRight
{
    UIView *v ;
    int num = ifRight?1:-1;
    num += _currentPage;

    if(ifRight){
        if (_currentPage == MAX_VALUE) {
            num = 0;
        }
        v = [self getPage:num];
        [_rightView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_rightView addSubview:v];
    }else{
        if (_currentPage == MIN_VALUE) {
            num = MAX_VALUE;
        }
        v = [self getPage:num];
        [_leftView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_leftView addSubview:v];
    }
}

- (UIView *)getPage:(int)num
{
    int num0 = num;
    if (!_isLooping) {
        if (num < MIN_VALUE || num > MAX_VALUE) {
            return nil;
        }
    }

    doJsonValue *jsonValue = [_dataArray GetData:num0];
    doJsonNode *dataNode = [jsonValue GetNode];
    
    int num1 = [[dataNode.dictValues objectForKey:[[dataNode.dictValues allKeys] firstObject]] GetInteger:0];
    
    if (num1 < MIN_VALUE || num1 > MAX_VALUE) {
        return nil;
    }

    NSString* fileName = [_pages objectAtIndex:num1];
    doSourceFile *source = [[[_model.CurrentPage CurrentApp] SourceFS] GetSourceByFileName:fileName];
    id<doIPage> pageModel = _model.CurrentPage;
    doUIContainer *container = [[doUIContainer alloc] init:pageModel];
    [container LoadFromFile:source:nil:nil];
    doUIModule* module = container.RootView;
    [container LoadDefalutScriptFile:fileName];
    UIView *view = (UIView*)(((doUIModule*)module).CurrentUIModuleView);
    id<doIUIModuleView> modelView =((doUIModule*) module).CurrentUIModuleView;
    [modelView OnRedraw];
    [module SetModelData:jsonValue];

    return view;
}

//销毁所有的全局对象
- (void) OnDispose
{
    _model = nil;
    //自定义的全局属性
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _pages = nil;
    [(doModule*)_dataArray Dispose];
}
//实现布局`
- (void) OnRedraw
{
    //实现布局相关的修改
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    
    [self initialization];

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
