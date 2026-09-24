#import <UIKit/UIKit.h>

// ========================
// 配置区域：改成你想替换的内容
// ========================
static NSString * const kOriginalText  = @"在吗";   // 原始文字
static NSString * const kReplacementText = @"不在";  // 替换后的文字

// 图片替换：设置 YES 开启，NO 关闭（默认先关闭，避免全局替换）
static BOOL const kEnableImageReplace = NO; 

%ctor {
    // 延迟 5 秒弹窗，验证是否注入成功
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"注入成功" 
                                                                       message:@"WeChatMod 已加载，去聊天里发送“在吗”试试" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// ========================
// 1. 文字替换 Hook（覆盖 UILabel 和 YYLabel）
// ========================
%hook UILabel

- (void)setText:(NSString *)text {
    if (text.length > 0 && [text isEqualToString:kOriginalText]) {
        text = kReplacementText;
    }
    %orig(text);
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSString *plainText = attributedText.string;
    if (plainText.length > 0 && [plainText isEqualToString:kOriginalText]) {
        NSAttributedString *newAttr = [[NSAttributedString alloc] initWithString:kReplacementText];
        %orig(newAttr);
        return;
    }
    %orig(attributedText);
}

%end

// 微信新版广泛使用 YYLabel，补上这个 Hook
%hook YYLabel

- (void)setText:(NSString *)text {
    if (text.length > 0 && [text isEqualToString:kOriginalText]) {
        text = kReplacementText;
    }
    %orig(text);
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSString *plainText = attributedText.string;
    if (plainText.length > 0 && [plainText isEqualToString:kOriginalText]) {
        NSAttributedString *newAttr = [[NSAttributedString alloc] initWithString:kReplacementText];
        %orig(newAttr);
        return;
    }
    %orig(attributedText);
}

%end

// ========================
// 2. 图片替换 Hook（仅在开启时生效）
// ========================
%hook UIImageView

- (void)setImage:(UIImage *)image {
    if (kEnableImageReplace) {
        // 严苛的判定条件：只替换特定尺寸的图片，避免头像等全被换掉
        // 这里作为示例，替换 100x100 到 200x200 之间的图片
        CGFloat w = image.size.width;
        CGFloat h = image.size.height;
        if (image && w > 100 && w < 200 && h > 100 && h < 200) {
            // 你可以在包里放一张替换图片，命名为 replace@2x.png
            // UIImage *replacement = [UIImage imageNamed:@"replace"];
            // if (replacement) {
            //     %orig(replacement);
            //     return;
            // }
        }
    }
    %orig(image);
}

%end
