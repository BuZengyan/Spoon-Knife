/*
Copyright (C) 2014 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:

 Implements LocalAuthenticaion framework demo
 
*/


#import "AAPLLocalAuthenticationTestsViewController.h"

//#import <LocalAuthentication/LocalAuthentication.h>


@import LocalAuthentication;


@interface AAPLLocalAuthenticationTestsViewController ()

@end

@implementation AAPLLocalAuthenticationTestsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // prepare the actions whch ca be tested in this class
    self.tests = @[
               [[AAPLTest alloc] initWithName:NSLocalizedString(@"TOUCH_ID_PREFLIGHT", nil) details:@"Using canEvaluatePolicy:" selector:@selector(canEvaluatePolicy)],
               [[AAPLTest alloc] initWithName:NSLocalizedString(@"TOUCH_ID", nil) details:@"Using evaluatePolicy:" selector:@selector(evaluatePolicy)]
               ];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.textView scrollRangeToVisible:NSMakeRange([_textView.text length], 0)];
}

-(void)viewDidLayoutSubviews
{
    // just set the proper size for the table view based on its content
    CGFloat height = MIN(self.view.bounds.size.height, self.tableView.contentSize.height);
    self.dynamicViewHeight.constant = height;
    [self.view layoutIfNeeded];
}

#pragma mark - Tests

- (void)canEvaluatePolicy
{
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *msg;
    NSError *error;
    BOOL success;
    
    // test if we can evaluate the policy, this test will tell us if Touch ID is available and enrolled
    success = [context canEvaluatePolicy: LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    if (success) {
        msg =[NSString stringWithFormat:NSLocalizedString(@"TOUCH_ID_IS_AVAILABLE", nil)];
    } else {
        msg =[NSString stringWithFormat:NSLocalizedString(@"TOUCH_ID_IS_NOT_AVAILABLE", nil)];
    }
    [super printResult:self.textView message:msg];
    self.textView.backgroundColor = [UIColor redColor];
    
}

- (void)evaluatePolicy
{
    LAContext *context = [[LAContext alloc] init];
    __block  NSString *msg;
    
    // show the authentication UI with our reason string
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:NSLocalizedString(@"UNLOCK_ACCESS_TO_LOCKED_FATURE", nil) reply:
     ^(BOOL success, NSError *authenticationError) {
         if (success) {
             msg =[NSString stringWithFormat:NSLocalizedString(@"EVALUATE_POLICY_SUCCESS", nil)];
         } else {
             msg = [NSString stringWithFormat:NSLocalizedString(@"EVALUATE_POLICY_WITH_ERROR", nil), authenticationError.localizedDescription];
         }
         [self printResult:self.textView message:msg];
     }];
    
}

/******************************  简单解析  ************************************/

// LocalAuthentication.framework
//
// #import <LocalAuthentication/LocalAuthentication.h>

// 注意事项：做iOS 8以下版本适配时，务必进行API验证，避免调用相关API引起崩溃。
// 使用类：LAContext 指纹验证操作对象
// 代码：

- (void)authenticateUser
{
    //初始化上下文对象
    LAContext* context = [[LAContext alloc] init];
    
    //错误对象 除了那些，我们必须定义两个变量：一个是NSError类型的，一个是String类型的，这样便于指出展示Touch ID对话框的原因，让我们增加这几行代码： 注意：错误变量声明是可选的，因为如果没有错误它将会返回nil，提醒一下，在Swift中nil不同于Objective-C中的nil，它意味着没有值。还有就是result字符串在编译器将会从分配的值推断它时，我会忽略它的类型。reasonString可以自定义，因此可以随意设置你喜欢的信息。
    
    NSError* error = nil;
    NSString* result = @"Authentication is needed to access your notes.";
    
    //首先使用canEvaluatePolicy 判断设备支持状态
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
    {
        //支持指纹验证
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:result reply:^(BOOL success, NSError *error) {
            if (success)
            {
                //验证成功，主线程处理UI
            }
            else
            {
                [self errorMessage:error];
            }
        }];
     }
     else
     {
          //不支持指纹识别，LOG出错误详情
          switch (error.code)
         {
               case LAErrorTouchIDNotEnrolled:
                {
                    NSLog(@"TouchID is not enrolled");
                    break;
                }
                case LAErrorPasscodeNotSet:
                {
                    NSLog(@"A passcode has not been set");
                    break;
                }
                default:
                {
                    NSLog(@"TouchID not available");
                    break;
                }
          }
                NSLog(@"%@",error.localizedDescription);
    }
}


- (void)errorMessage:(NSError *)error
{
    NSLog(@"%@",error.localizedDescription);
    switch (error.code)
    {
        case LAErrorSystemCancel:
        {
            NSLog(@"Authentication was cancelled by the system");
            //切换到其他APP，系统取消验证Touch ID
            break;
        }
        case LAErrorUserCancel:
        {
            NSLog(@"Authentication was cancelled by the user");
            //用户取消验证Touch ID
            break;
        }
        case LAErrorUserFallback:
        {
            //  NSLog(@"User selected to enter custom pass<a href="http://www.it165.net/edu/ebg/" target="_blank" class="keylink">word</a>");
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                //用户选择输入密码，切换主线程处理
            }];
            break;
        }
        default:
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                //其他情况，切换主线程处理
            }];
            break;
        }
    }
}

/*
typedef NS_ENUM(NSInteger, LAError)
{
    //授权失败
    LAErrorAuthenticationFailed = kLAErrorAuthenticationFailed,
    //用户取消Touch ID授权
    LAErrorUserCancel           = kLAErrorUserCancel,
    //用户选择输入密码
    LAErrorUserFallback         = kLAErrorUserFallback,
    //系统取消授权(例如其他APP切入)
    LAErrorSystemCancel         = kLAErrorSystemCancel,
    //系统未设置密码
    LAErrorPasscodeNotSet       = kLAErrorPasscodeNotSet,
    //设备Touch ID不可用，例如未打开
    LAErrorTouchIDNotAvailable  = kLAErrorTouchIDNotAvailable,
    //设备Touch ID不可用，用户未录入
    LAErrorTouchIDNotEnrolled   = kLAErrorTouchIDNotEnrolled
} NS_ENUM_AVAILABLE(10_10, 8_0);
 */
                              
//  操作流程：首先判断系统版本，iOS 8及以上版本执行-(void)authenticateUser方法，方法自动判断设备是否支持和开启Touch ID。
                              
                              
@end
