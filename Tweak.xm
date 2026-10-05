//
//  Tweak.xm
//  小丑功能 —— 挂钩层(v2 修复版)
//
//  ▍为什么上一版编不过
//    上一版直接对 WCRMessageCell / WCRMessageViewModel 这类「只有 @class 前向声明」
//    的私有类发消息( [self valueForKey:…] / self.tableView / self.window )。
//    在 ARC 下,编译器不知道这些类到底有没有这些方法 → 每条都是 error(×10)。
//
//  ▍这一版怎么修的
//    1. 本文件不声明、也不 import 任何微信私有类;
//       所有对 hook 对象的访问一律先转成 id 再动态派发(valueForKey / IMP),
//       对 id 发未知消息在 ARC 下只是 warning,不再报错。
//    2. 自己出的 UI 全部挂在 UIApplication 的 keyWindow 上,不再依赖 cell.window。
//    3. 类名(下面三处 %hook)是占位符,按你的目标微信版本换成真实类名。
//       引擎 WCRClownRuntime 与版本无关,不用动。
//

#import <UIKit/UIKit.h>
#import <objc/message.h>
#import "WCRClownRuntime.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - 动态工具(不依赖任何私有类声明)

static id WCRGetVal(id obj, NSString *key) {
    if (!obj || !key.length) return nil;
    @try {
        return [obj valueForKey:key];
    } @catch (NSException *e) {
        (void)e;
        return nil;
    }
}

static id WCRGetFirst(id obj, NSArray<NSString *> *keys) {
    for (NSString *k in keys) {
        id v = WCRGetVal(obj, k);
        if (v) return v;
    }
    return nil;
}

static void WCRPerformVoid(id obj, SEL sel) {
    if (obj && [obj respondsToSelector:sel]) {
        IMP imp = [obj methodForSelector:sel];
        if (imp) ((void (*)(id, SEL))imp)(obj, sel);
    }
}

/// 取当前可用来弹 UI 的控制器
static UIViewController *WCRTopViewController(void) {
    UIWindow *key = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) { key = w; break; }
    }
    if (!key) key = [UIApplication sharedApplication].windows.firstObject;
    UIViewController *vc = key.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static void WCRPresentAlert(UIAlertController *ac, id sourceView) {
    UIViewController *vc = WCRTopViewController();
    if (!vc || !ac) return;
    if (ac.popoverPresentationController) {          // iPad 不设锚点会崩
        UIView *src = (UIView *)sourceView;
        ac.popoverPresentationController.sourceView = src ?: vc.view;
        ac.popoverPresentationController.sourceRect = src ? src.bounds : vc.view.bounds;
    }
    [vc presentViewController:ac animated:YES completion:nil];
}

/// 改完刷新列表:cell 的 tableView 不一定是属性,挨个试
static void WCRRefresh(id cell) {
    WCRPerformVoid(WCRGetVal(cell, @"tableView"), @selector(reloadData));
    WCRPerformVoid(WCRGetVal(WCRGetVal(cell, @"viewController"), @"tableView"), @selector(reloadData));
    WCRPerformVoid(WCRGetVal(cell, @"superview"), @selector(setNeedsLayout));
}

#pragma mark - 挂钩 ①:消息气泡(长按出「小丑」入口)

%hook WCRMessageCell   // ← 换成你目标版本里承载气泡的 Cell 类

- (void)onLongPress:(id)sender {
    %orig;
    if (![WCRClownRuntime shouldShowClownMenuForCell:self]) return;

    UIMenuController *mc = [UIMenuController sharedMenuController];
    UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:@"小丑"
                                                 action:@selector(wcr_openClownMenu:)];
    NSMutableArray *items = [mc.menuItems mutableCopy] ?: [NSMutableArray array];
    NSArray<UIMenuItem *> *snapshot = [items copy];
    for (UIMenuItem *it in snapshot) {
        if ([it.title isEqualToString:@"小丑"]) [items removeObject:it];
    }
    [items addObject:item];
    mc.menuItems = items;
    [mc update];
}

// 自定义菜单项要能被响应,必须在这里放行
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(wcr_openClownMenu:)) {
        return [WCRClownRuntime shouldShowClownMenuForCell:self];
    }
    return %orig;
}

- (void)wcr_openClownMenu:(id)sender {
    id cell    = (id)self;
    __weak id wcell = cell;
    id message = WCRGetFirst(cell, @[@"messageWrap", @"m_message", @"viewModel"]);
    if (!message) return;

    WCRClownRuntime *rt = [WCRClownRuntime shared];
    UIAlertController *ac = [UIAlertController
                             alertControllerWithTitle:@"小丑"
                                              message:@"只改本机显示,不发送、不影响对方"
                                       preferredStyle:UIAlertControllerStyleActionSheet];

    // —— 修改文字
    if ([WCRClownRuntime messageCanEditText:message]) {
        [ac addAction:[UIAlertAction actionWithTitle:@"修改文字"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *a) {
            UIAlertController *box = [UIAlertController alertControllerWithTitle:@"修改文字"
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleAlert];
            [box addTextFieldWithConfigurationHandler:nil];
            [box addAction:[UIAlertAction actionWithTitle:@"确定"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *ok) {
                [rt setTextOverride:box.textFields.firstObject.text forMessage:message];
                WCRRefresh(wcell);
            }]];
            WCRPresentAlert(box, wcell);
        }]];
    }

    // —— 修改图片
    if ([WCRClownRuntime messageCanReplaceImage:message]) {
        [ac addAction:[UIAlertAction actionWithTitle:@"修改图片"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *a) {
            // 这里接相册选择器,拿到 NSData 后:
            //   [rt setImageOverride:data forMessage:message];
            //   WCRRefresh(wcell);
            // 参考 PHPickerViewController(iOS 14+)或 UIImagePickerController。
        }]];
    }

    // —— 修改消息时间
    [ac addAction:[UIAlertAction actionWithTitle:@"修改消息时间"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *a) {
        [rt setTimeOverride:@([[NSDate date] timeIntervalSince1970]) forMessage:message];
        WCRRefresh(wcell);
    }]];

    // —— 颠倒阴阳
    if ([WCRClownRuntime messageCanSwapYinYang:message]) {
        [ac addAction:[UIAlertAction actionWithTitle:@"颠倒阴阳"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *a) {
            [rt setYinYangOverride:YES preserveIdentity:YES forMessage:message];
            WCRRefresh(wcell);
        }]];
    }

    // —— 修改转账金额
    [ac addAction:[UIAlertAction actionWithTitle:@"修改转账金额"
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction *a) {
        UIAlertController *box = [UIAlertController alertControllerWithTitle:@"转账金额"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
        [box addTextFieldWithConfigurationHandler:^(UITextField *tf) {
            tf.keyboardType = UIKeyboardTypeDecimalPad;
            tf.placeholder = @"如 8888.00";
        }];
        [box addAction:[UIAlertAction actionWithTitle:@"确定"
                                                style:UIAlertActionStyleDefault
                                              handler:^(UIAlertAction *ok) {
            [rt setTransferAmountOverride:box.textFields.firstObject.text forMessage:message];
            WCRRefresh(wcell);
        }]];
        WCRPresentAlert(box, wcell);
    }]];

    // —— 退出保持
    [ac addAction:[UIAlertAction actionWithTitle:@"退出保持"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *a) {
        [WCRClownRuntime setOn:YES forKey:kWCRClownPersistOnExitChat];
    }]];

    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    WCRPresentAlert(ac, wcell);
}

%end

#pragma mark - 挂钩 ②:ViewModel 组装展示内容时套用覆盖

%hook WCRMessageViewModel   // ← 换成你目标版本里的 ViewModel 类

- (void)setMessage:(id)message {
    %orig;
    [[WCRClownRuntime shared] applyOverridesToMessage:message];
}

%end

#pragma mark - 挂钩 ③:退出会话时清掉本次覆盖(除非开了「退出保持」)

%hook WCRBaseMsgContentViewController   // ← 换成聊天控制器类

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    if ([WCRClownRuntime isOn:kWCRClownPersistOnExitChat]) return;
    id vc = (id)self;
    NSString *session = WCRGetFirst(vc, @[@"m_nsRealChatUsr", @"m_nsUsrName", @"m_nsChatName"]);
    if (session.length) [[WCRClownRuntime shared] clearOverridesForSession:session];
}

%end
