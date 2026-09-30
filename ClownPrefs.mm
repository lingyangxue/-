#import <UIKit/UIKit.h>
#import "ClownCore.h"

@interface ClownPrefs : NSObject
@end


@implementation ClownPrefs


+ (UIViewController *)topController {

    UIWindow *window = nil;

    for (UIScene *scene in
         [UIApplication sharedApplication].connectedScenes) {

        if ([scene isKindOfClass:[UIWindowScene class]]) {

            UIWindowScene *ws = (UIWindowScene *)scene;

            for (UIWindow *w in ws.windows) {

                if (w.isKeyWindow) {
                    window = w;
                    break;
                }
            }
        }

        if (window) {
            break;
        }
    }


    UIViewController *root = window.rootViewController;


    while (root.presentedViewController) {
        root = root.presentedViewController;
    }


    return root;
}



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


    UIViewController *root = [self topController];


    if (root) {

        [root presentViewController:alert
                           animated:YES
                         completion:nil];

    }

}


@end
