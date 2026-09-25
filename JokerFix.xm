//
//  JokerFix.xm — 微信 8.0.75 发图修改插件
//
//  设计要点：不 hook 任何微信类名（8.0.75 改了类名也照常工作），
//  只 hook UIKit 的稳定 C 函数 UIImageJPEGRepresentation /
//  UIImagePNGRepresentation，并用 dladdr 过滤调用者必须是 WeChat 主程序。
//
//  功能（全部可用 plist 配置开关）：
//   1. Enabled      —— 总开关
//   2. ReplaceImage —— 替换图绝对路径（设置后，发出的图一律变成这张图）
//   3. Scale        —— 等比缩放系数，0 或 1 = 不改尺寸
//   4. Quality      —— JPEG 压缩质量 0~1，负数 = 用微信原参数
//   5. StripMeta    —— 重绘去 EXIF/GPS 等元数据（默认开）
//
//  配置文件：/var/mobile/Library/Preferences/com.jokerfix.plist
//  修改后不需要重启微信，插件监听 com.jokerfix.prefschanged 通知即时生效。
//

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <math.h>

static BOOL       gEnabled     = YES;
static NSString  *gReplacePath = @"/var/mobile/Library/Preferences/JokerFix_replace.jpg";
static CGFloat    gScale       = 0.0;    // 0 = 不改
static CGFloat    gQuality     = -1.0;   // <0 = 用原参数
static BOOL       gStripMeta   = YES;

#define PREFS_DOMAIN "com.jokerfix"

static void loadPrefs(void) {
    CFStringRef dom = CFSTR(PREFS_DOMAIN);
    CFPreferencesAppSynchronize(dom);
    id v;
    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Enabled"), dom))))
        gEnabled = [v boolValue];
    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("ReplaceImage"), dom))))
        gReplacePath = [v isKindOfClass:NSString.class] ? v : nil;
    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Scale"), dom))))
        gScale = [v floatValue];
    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Quality"), dom))))
        gQuality = [v floatValue];
    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("StripMeta"), dom))))
        gStripMeta = [v boolValue];
}

static void prefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *d, CFDictionaryRef u) {
    loadPrefs();
}

// 调用者必须是 WeChat 主二进制（libsubstrate / UIKit / 其他 dylib 一律放行）
static BOOL callerIsWeChat(void) {
    void *ret = __builtin_return_address(0);
    if (!ret) return NO;
    Dl_info info;
    if (dladdr(ret, &info) && info.dli_fname) {
        NSString *path = @(info.dli_fname);
        return ([path containsString:@"/WeChat.app/"] ||
                [path containsString:@"MicroMessenger"]);
    }
    return NO;
}

// 重绘：去元数据 + 可选缩放
static UIImage *redraw(UIImage *img, CGFloat scale) {
    CGSize s = img.size;
    if (scale > 0 && fabs(scale - 1.0) > 0.001) {
        s = CGSizeMake(MAX(1.0, s.width * scale), MAX(1.0, s.height * scale));
    }
    UIGraphicsBeginImageContextWithOptions(s, NO, img.scale);
    [img drawInRect:CGRectMake(0.0, 0.0, s.width, s.height)];
    UIImage *outImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outImg ?: img;
}

static UIImage *applyModify(UIImage *img) {
    if (!img) return img;
    UIImage *out = img;

    // 1) 任意替换：换成指定图片
    if (gReplacePath.length &&
        [[NSFileManager defaultManager] fileExistsAtPath:gReplacePath]) {
        UIImage *rep = [UIImage imageWithContentsOfFile:gReplacePath];
        if (rep) out = rep;
    }

    // 2) 缩放 / 去 EXIF
    if ((gScale > 0 && fabs(gScale - 1.0) > 0.001) || gStripMeta) {
        out = redraw(out, gScale);
    }
    return out;
}

static NSData *(*orig_JPEG)(UIImage *, CGFloat);
static NSData *(*orig_PNG)(UIImage *);

static NSData *hook_JPEG(UIImage *img, CGFloat quality) {
    if (!gEnabled || !callerIsWeChat()) return orig_JPEG(img, quality);
    UIImage *m = applyModify(img);
    if (gQuality >= 0.0) quality = gQuality;
    return orig_JPEG(m, quality);
}

static NSData *hook_PNG(UIImage *img) {
    if (!gEnabled || !callerIsWeChat()) return orig_PNG(img);
    return orig_PNG(applyModify(img));
}

%ctor {
    @autoreleasepool {
        loadPrefs();
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            NULL, prefsChanged, CFSTR(PREFS_DOMAIN ".prefschanged"), NULL,
            CFNotificationSuspensionBehaviorCoalesce);

        MSHookFunction((void *)UIImageJPEGRepresentation,
                       (void *)hook_JPEG, (void **)&orig_JPEG);
        MSHookFunction((void *)UIImagePNGRepresentation,
                       (void *)hook_PNG, (void **)&orig_PNG);
    }
}
