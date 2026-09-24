#import <UIKit/UIKit.h>

// 内存字典，保存修改前后的映射关系：@{"原文字": "想改成的新文字"}
static NSMutableDictionary *kModifiedTexts = nil;

%ctor {
    kModifiedTexts = [NSMutableDictionary new];
    
    // 注入成功提示（延迟5秒）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"注入成功" 
                                                                       message:@"长按聊天里的文字气泡即可修改（仅自己可见）" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

%hook UILabel

// 1. 拦截文本渲染：如果字典里有记录，就替换成修改后的文本
- (void)setText:(NSString *)text {
    if (text.length > 0 && kModifiedTexts[text]) {
        text = kModifiedTexts[text];
    }
    %orig(text);
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (attributedText.string.length > 0 && kModifiedTexts[attributedText.string]) {
        NSString *newText = kModifiedTexts[attributedText.string];
        NSAttributedString *newAttr = [[NSAttributedString alloc] initWithString:newText attributes:attributedText.attributes];
        %orig(newAttr);
        return;
    }
    %orig(attributedText);
}

// 2. 给Label绑定长按手势（限制只在聊天界面的Cell上触发，避免全局冲突）
- (void)didMoveToWindow {
    %orig;
    if (self.window && self.gestureRecognizers.count == 0) {
        // 简单判断父视图类名，避免把按钮、菜单等文字也加上长按
        NSString *superClassName = NSStringFromClass([self.superview class]);
        if ([superClassName containsString:@"Chat"] || 
            [superClassName containsString:@"Message"] || 
            [superClassName containsString:@"Cell"] || 
            [superClassName containsString:@"Table"]) {
            
            UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressEdit:)];
            [self addGestureRecognizer:lp];
        }
    }
}

// 3. 长按事件触发弹窗
- (void)handleLongPressEdit:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSString *originalText = self.text;
        if (originalText.length == 0) return;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改消息（仅自己可见）" 
                                                                       message:@"输入你想看到的文字，不会发给对方" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = originalText;
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *newText = alert.textFields.firstObject.text;
            if (newText.length > 0 && ![newText isEqualToString:originalText]) {
                // 记录修改映射
                kModifiedTexts[originalText] = newText;
                
                // 强制刷新当前显示的UI
                self.text = newText; 
                [self.superview setNeedsLayout];
                [self.superview layoutIfNeeded];
            }
        }]];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

%end
