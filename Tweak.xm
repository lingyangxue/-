//
//  Tweak.xm
//  小丑功能 —— 挂钩部分（骨架）
//
//  ⚠️ 这里只做「什么时候调引擎」这一层。真实的微信类名/方法名各版本不一样，
//     按你的目标版本把 %hook 目标换成对应的消息 Cell / ViewModel / 会话控制器即可。
//     引擎本身（WCRClownRuntime）与微信版本无关，不用动。
//

#import <UIKit/UIKit.h>
#import "WCRClownRuntime.h"

// 长按菜单：给自己发出的消息追加「小丑」入口
%hook WCRMessageCell   // ← 换成你的目标版本里承载气泡的类

- (void)onLongPress:(id)sender {
    %orig;
    if (![WCRClownRuntime shouldShowClownMenuForCell:self]) return;

    id message = [self valueForKey:@"messageWrap"] ?: [self valueForKey:@"m_message"];
    UIMenuController *mc = [UIMenuController sharedMenuController];

    UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:@"小丑"
                                                  action:@selector(wcr_openClownMenu:)];
    NSMutableArray *items = [mc.menuItems mutableCopy] ?: [NSMutableArray array];
    [items addObject:item];
    mc.menuItems = items;
    [mc update];
}

- (void)wcr_openClownMenu:(id)sender {
    id message = [self valueForKey:@"messageWrap"] ?: [self valueForKey:@"m_message"];
    WCRClownRuntime *rt = [WCRClownRuntime shared];

    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"小丑"
                                                               message:@"选一项改"
                                                        preferredStyle:UIAlertControllerStyleActionSheet];

    if ([WCRClownRuntime messageCanEditText:message]) {
        [ac addAction:[UIAlertAction actionWithTitle:@"修改文字" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            UIAlertController *in = [UIAlertController alertControllerWithTitle:@"修改文字"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
            [in addTextFieldWithConfigurationHandler:nil];
            [in addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
                [rt setTextOverride:in.textFields.firstObject.text forMessage:message];
                [self.tableView reloadData];
            }]];
            [self.window.rootViewController presentViewController:in animated:YES completion:nil];
        }]];
    }

    if ([WCRClownRuntime messageCanReplaceImage:message]) {
        [ac addAction:[UIAlertAction actionWithTitle:@"修改图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            // 接你的相册选择器，拿到 NSData 后：
            // [rt setImageOverride:data forMessage:message];
        }]];
    }

    [ac addAction:[UIAlertAction actionWithTitle:@"修改时间" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSNumber *now = @([[NSDate date] timeIntervalSince1970]);
        [rt setTimeOverride:now forMessage:message];
    }]];

    if ([WCRClownRuntime messageCanSwapYinYang:message]) {
        [ac addAction:[UIAlertAction actionWithTitle:@"颠倒阴阳" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [rt setYinYangOverride:YES preserveIdentity:YES forMessage:message];
        }]];
    }

    [ac addAction:[UIAlertAction actionWithTitle:@"修改转账" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        // [rt setTransferAmountOverride:@"8888.00" forMessage:message];
    }]];

    [ac addAction:[UIAlertAction actionWithTitle:@"退出保持" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [WCRClownRuntime setOn:YES forKey:kWCRClownPersistOnExitChat];
    }]];

    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self.window.rootViewController presentViewController:ac animated:YES completion:nil];
}

%end

// 渲染前套用覆盖：消息 ViewModel 组装展示内容时调用
%hook WCRMessageViewModel   // ← 换成你的目标版本里的 ViewModel 类

- (void)setMessage:(id)message {
    %orig;
    [[WCRClownRuntime shared] applyOverridesToMessage:message];
}

%end

// 退出会话：非「退出保持」时清空该会话覆盖
%hook WCRBaseMsgContentViewController   // ← 换成聊天控制器类

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    if (![WCRClownRuntime isOn:kWCRClownPersistOnExitChat]) {
        NSString *session = [self valueForKey:@"m_nsRealChatUsr"] ?: [self valueForKey:@"m_nsUsrName"];
        [[WCRClownRuntime shared] clearOverridesForSession:session];
    }
}

%end
