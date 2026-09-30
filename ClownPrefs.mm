#import <UIKit/UIKit.h>
#import "ClownCore.h"


@interface ClownPrefs : NSObject
@end


@implementation ClownPrefs


+ (void)showMenu {


    UIAlertController *alert =
    [UIAlertController
     alertControllerWithTitle:@"🤡 WCClown"
     message:@"小丑功能设置"
     preferredStyle:UIAlertControllerStyleAlert];



    UIAlertAction *enable =
    [UIAlertAction
     actionWithTitle:@"开启小丑"
     style:UIAlertActionStyleDefault
     handler:^(UIAlertAction *action){


        [ClownCore setEnabled:YES];


    }];



    UIAlertAction *disable =
    [UIAlertAction
     actionWithTitle:@"关闭小丑"
     style:UIAlertActionStyleDestructive
     handler:^(UIAlertAction *action){


        [ClownCore setEnabled:NO];


    }];



    [alert addAction:enable];
    [alert addAction:disable];


    UIViewController *root =
    [UIApplication sharedApplication]
    .keyWindow.rootViewController;


    [root presentViewController:alert
                       animated:YES
                     completion:nil];

}


@end
