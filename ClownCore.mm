//
//  ClownCore.mm
//  WCClown
//

#import "ClownCore.h"

@implementation ClownCore


#pragma mark - Settings

+ (NSUserDefaults *)defaults {
    return [[NSUserDefaults alloc] initWithSuiteName:@"com.wcclown.settings"];
}


+ (BOOL)enabled {

    return [[[self defaults] objectForKey:@"clown.enabled"] boolValue];

}


+ (void)setEnabled:(BOOL)value {

    [[self defaults] setBool:value forKey:@"clown.enabled"];
    [[self defaults] synchronize];

}



#pragma mark - Text

+ (BOOL)textModifyEnabled {

    return [[[self defaults] objectForKey:@"clown.text"] boolValue];

}



#pragma mark - Image

+ (BOOL)imageModifyEnabled {

    return [[[self defaults] objectForKey:@"clown.image"] boolValue];

}



#pragma mark - Time

+ (BOOL)timeModifyEnabled {

    return [[[self defaults] objectForKey:@"clown.time"] boolValue];

}



+ (BOOL)chatTimeModifyEnabled {

    return [[[self defaults] objectForKey:@"clown.chat.time"] boolValue];

}



#pragma mark - Other

+ (BOOL)sortEnabled {

    return [[[self defaults] objectForKey:@"clown.sort"] boolValue];

}



+ (BOOL)yinYangEnabled {

    return [[[self defaults] objectForKey:@"clown.yinyang"] boolValue];

}


@end
