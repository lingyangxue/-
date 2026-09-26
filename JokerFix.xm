//
//  JokerFix.xm — 微信 8.0.75 发图修改插件 v0.4
//
//  设计要点：不 hook 任何微信类名，只 hook UIKit 的稳定 C 函数
//  UIImageJPEGRepresentation / UIImagePNGRepresentation，
//  并用 dladdr 过滤调用者必须是 WeChat 主程序。
//
//  v0.4：
//   - 修复 callerIsWeChat 取错返回地址的问题
//   - 重绘改用 CGContext，避免后台线程调用 UIKit 闪退
//   - 启动通知改用 NSNotificationCenter
//   - 用 dlsym 取符号，避免直接引用导致加载失败
//   - 兼容 rootless /var/jb 路径
//   - 增加异常保护
//
//  配置文件：/var/mobile/Library/Preferences/com.jokerfix.plist
//  键：Enabled / ReplaceImage / Scale / Quality / StripMeta
//

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <math.h>

static BOOL       gEnabled     = YES;
static NSString  *gReplacePath = nil;
static CGFloat    gScale       = 0.0;    // 0 = 不改
static CGFloat    gQuality     = -1.0;   // <0 = 用原参数
static BOOL       gStripMeta   = YES;

#define PREFS_DOMAIN "com.jokerfix"

static NSString *defaultReplacePath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *rootless = @"/var/jb/var/mobile/Library/Preferences/JokerFix_replace.jpg";
    if ([fm fileExistsAtPath:rootless]) return rootless;
    return @"/var/mobile/Library/Preferences/JokerFix_replace.jpg";
}

static void loadPrefs(void) {
    CFStringRef dom = CFSTR(PREFS_DOMAIN);
    CFPreferencesAppSynchronize(dom);

    id v;

    gEnabled = YES;
    gScale = 0.0;
    gQuality = -1.0;
    gStripMeta = YES;
    gReplacePath = defaultReplacePath();

    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Enabled"), dom))))
        gEnabled = [v boolValue];

    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("ReplaceImage"), dom)))) {
        if ([v isKindOfClass:NSString.class] && [v length] > 0)
            gReplacePath = v;
    }

    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Scale"), dom))))
        gScale = [v floatValue];

    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("Quality"), dom))))
        gQuality = [v floatValue];

    if ((v = CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("StripMeta"), dom))))
        gStripMeta = [v boolValue];
}

static void prefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n,
                         const void *d, CFDictionaryRef u) {
    (void)c; (void)o; (void)n; (void)d; (void)u;
    loadPrefs();
}

// 调用者必须是 WeChat 主二进制
static BOOL callerIsWeChat(void *returnAddress) {
    if (!returnAddress) return NO;

    Dl_info info;
    if (dladdr(returnAddress, &info) && info.dli_fname) {
        NSString *path = @(info.dli_fname);
        return ([path containsString:@"/WeChat.app/"] ||
                [path containsString:@"MicroMessenger"]);
    }
    return NO;
}

// 纯 CGContext 重绘：去元数据 + 可选缩放，后台线程安全
static UIImage *redraw(UIImage *img, CGFloat scale) {
    if (!img) return img;

    CGImageRef cg = img.CGImage;
    if (!cg) return img;

    size_t w = CGImageGetWidth(cg);
    size_t h = CGImageGetHeight(cg);
    if (w == 0 || h == 0) return img;

    if (scale > 0 && fabs(scale - 1.0) > 0.001) {
        w = MAX(1, (size_t)(w * scale));
        h = MAX(1, (size_t)(h * scale));
    }

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    if (!cs) return img;

    CGContextRef ctx = CGBitmapContextCreate(NULL, w, h, 8, 0, cs,
                                             kCGImageAlphaPremultipliedLast |
                                             kCGBitmapByteOrderDefault);
    CGColorSpaceRelease(cs);
    if (!ctx) return img;

    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);

    // CGBitmapContext 原点在左下角，翻转一下，避免上下颠倒
    CGContextTranslateCTM(ctx, 0, h);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), cg);

    CGImageRef newCg = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    if (!newCg) return img;

    UIImage *out = [UIImage imageWithCGImage:newCg
                                       scale:img.scale
                                 orientation:UIImageOrientationUp];
    CGImageRelease(newCg);
    return out ?: img;
}

static UIImage *applyModify(UIImage *img) {
    if (!img) return img;

    @try {
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
    } @catch (NSException *e) {
        return img;
    }
}

static NSData *(*orig_JPEG)(UIImage *, CGFloat);
static NSData *(*orig_PNG)(UIImage *);

static NSData *hook_JPEG(UIImage *img, CGFloat quality) {
    if (!orig_JPEG) return nil;

    void *ret = __builtin_return_address(0);
    if (!gEnabled || !callerIsWeChat(ret))
        return orig_JPEG(img, quality);

    UIImage *m = applyModify(img);
    if (gQuality >= 0.0) quality = gQuality;
    return orig_JPEG(m, quality);
}

static NSData *hook_PNG(UIImage *img) {
    if (!orig_PNG) return nil;

    void *ret = __builtin_return_address(0);
    if (!gEnabled || !callerIsWeChat(ret))
        return orig_PNG(img);

    return orig_PNG(applyModify(img));
}

static void installHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *jpegSym = dlsym(RTLD_DEFAULT, "UIImageJPEGRepresentation");
        void *pngSym  = dlsym(RTLD_DEFAULT, "UIImagePNGRepresentation");

        if (jpegSym) {
            MSHookFunction(jpegSym, (void *)hook_JPEG, (void **)&orig_JPEG);
        }
        if (pngSym) {
            MSHookFunction(pngSym, (void *)hook_PNG, (void **)&orig_PNG);
        }
    });
}

%ctor {
    @autoreleasepool {
        loadPrefs();

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            NULL, prefsChanged, CFSTR(PREFS_DOMAIN ".prefschanged"), NULL,
            CFNotificationSuspensionBehaviorCoalesce);

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification * _Nonnull note) {
            (void)note;
            installHooks();
        }];
    }
}
