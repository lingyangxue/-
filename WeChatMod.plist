#import <UIKit/UIKit.h>

// 改这里：想替换的文字
static NSString * const kOriginal = @"原始文本";
static NSString * const kReplacement = @"替换后的文本";

%hook UILabel

- (void)setText:(NSString *)text {
    if (text.length > 0 && [text isEqualToString:kOriginal]) {
        text = kReplacement;
    }
    %orig(text);
}

%end
