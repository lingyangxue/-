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


    UIViewController *root = nil;


    if (@available(iOS 13.0, *)) {


        for (UIScene *scene in
             [UIApplication sharedApplication].connectedScenes) {


            if ([scene isKindOfClass:[UIWindowScene class]]) {


                UIWindowScene *windowScene =
                (UIWindowScene *)scene;


                for (UIWindow *window in windowScene.windows) {


                    if (window.isKeyWindow) {


                        root =
                        window.rootViewController;


                        break;

                    }
                }
            }


            if (root) {
                break;
            }
        }


    } else {


        root =
        [UIApplication sharedApplication]
        .keyWindow.rootViewController;


    }



    if (root) {


        [root presentViewController:alert
                           animated:YES
                         completion:nil];

    }


}


@end
