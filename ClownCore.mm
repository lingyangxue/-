#import "ClownCore.h"

@implementation ClownCore

+ (NSUserDefaults *)defaults {
    return [[NSUserDefaults alloc] initWithSuiteName:@"com.wcclown.settings"];
}


+ (BOOL)enabled {
    return [[self defaults] boolForKey:@"clown.enabled"];
}


+ (void)setEnabled:(BOOL)value {
    [[self defaults] setBool:value forKey:@"clown.enabled"];
    [[self defaults] synchronize];
}


+ (BOOL)textModifyEnabled {
    return [[self defaults] boolForKey:@"clown.text"];
}


+ (BOOL)imageModifyEnabled {
    return [[self defaults] boolForKey:@"clown.image"];
}


+ (BOOL)timeModifyEnabled {
    return [[self defaults] boolForKey:@"clown.time"];
}


+ (BOOL)chatTimeModifyEnabled {
    return [[self defaults] boolForKey:@"clown.chat.time"];
}


+ (BOOL)sortEnabled {
    return [[self defaults] boolForKey:@"clown.sort"];
}


+ (BOOL)yinYangEnabled {
    return [[self defaults] boolForKey:@"clown.yinyang"];
}


+ (NSString *)modifyText:(NSString *)text {

    if (!text)
        return text;

    NSString *prefix = @"🤡 ";

    if ([[self defaults] boolForKey:@"clown.add.emoji"]) {
        return [prefix stringByAppendingString:text];
    }

    return text;
}


+ (NSData *)modifyImage:(NSData *)imageData {

    NSData *replace =
    [[self defaults] objectForKey:@"clown.image.data"];

    if (replace)
        return replace;

    return imageData;
}


+ (NSString *)modifyTime:(NSString *)time {

    NSString *value =
    [[self defaults] objectForKey:@"clown.custom.time"];

    if (value)
        return value;

    return time;
}


+ (NSString *)modifyChatTime:(NSString *)time {

    NSString *value =
    [[self defaults] objectForKey:@"clown.chat.time.value"];

    if (value)
        return value;

    return time;
}


+ (void)processMessage:(id)message {

    if (![self enabled])
        return;

    NSLog(@"[WCClown] process message %@", message);

}


@end
