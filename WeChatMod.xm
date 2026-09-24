#import <UIKit/UIKit.h>

// 内存字典，保存修改前后的映射关系：@{"原文字": "想改成的新文字"}
static NSMutableDictionary *kModifiedTexts = nil;

%ctor {
    kModifiedTexts = [NSMutableDictionary new];
    
    // 注入成功提示
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"注入成功" 
                                                                       message:@"【双击】聊天里的文字气泡即可修改（仅自己可见）" 
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
    NSString *plainText = attributedText.string;
    if (plainText.length > 0 && kModifiedTexts[plainText]) {
        NSString *newText = kModifiedTexts[plainText];
        NSMutableAttributedString *newAttr = [attributedText mutableCopy];
        [newAttr replaceCharactersInRange:NSMakeRange(0, newAttr.length) withString:newText];
        %orig(newAttr);
        return;
    }
    %orig(attributedText);
}

// 2. 给Label绑定【双击】手势
- (void)didMoveToWindow {
    %orig;
    if (self.window && self.gestureRecognizers.count == 0) {
        NSString *superClassName = NSStringFromClass([self.superview class]);
        // 只给聊天界面的气泡加手势，防止给按钮文字加
        if ([superClassName containsString:@"Chat"] || 
            [superClassName containsString:@"Message"] || 
            [superClassName containsString:@"Cell"] || 
            [superClassName containsString:@"Table"]) {
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapEdit:)];
            tap.numberOfTapsRequired = 2; // 双击
            [self addGestureRecognizer:tap];
        }
    }
}

// 3. 双击事件触发弹窗
- (void)handleDoubleTapEdit:(UITapGestureRecognizer *)gesture {
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
            kModifiedTexts[originalText] = newText; // 记录修改
            self.text = newText; // 立即刷新当前UI
            [self.superview setNeedsLayout];
            [self.superview layoutIfNeeded];
        }
    }]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

%end

// 同样给 YYLabel 加上双击
%hook YYLabel

- (void)setText:(NSString *)text {
    if (text.length > 0 && kModifiedTexts[text]) {
        text = kModifiedTexts[text];
    }
    %orig(text);
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSString *plainText = attributedText.string;
    if (plainText.length > 0 && kModifiedTexts[plainText]) {
        NSString *newText = kModifiedTexts[plainText];
        NSMutableAttributedString *newAttr = [attributedText mutableCopy];
        [newAttr replaceCharactersInRange:NSMakeRange(0, newAttr.length) withString:newText];
        %orig(newAttr);
        return;
    }
    %orig(attributedText);
}

- (void)didMoveToWindow {
    %orig;
    if (self.window && self.gestureRecognizers.count == 0) {
        NSString *superClassName = NSStringFromClass([self.superview class]);
        if ([superClassName containsString:@"Chat"] || 
            [superClassName containsString:@"Message"] || 
            [superClassName containsString:@"Cell"] || 
            [superClassName containsString:@"Table"]) {
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapEdit:)];
            tap.numberOfTapsRequired = 2;
            [self addGestureRecognizer:tap];
        }
    }
}

- (void)handleDoubleTapEdit:(UITapGestureRecognizer *)gesture {
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
            kModifiedTexts[originalText] = newText;
            self.text = newText;
            [self.superview setNeedsLayout];
            [self.superview layoutIfNeeded];
        }
    }]];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

%end
