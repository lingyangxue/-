//
//  ClownCore.mm
//  WCClown
//

#import "ClownCore.h"

@implementation ClownCore
#pragma mark - Message Process


+ (void)processMessage:(id)message {


    if (![self enabled]) {
        return;
    }


    if (!message) {
        return;
    }


    /*
     对应：
     WCRefineShouldApplyClown
    */


    // 文字处理

    if ([self textModifyEnabled]) {


        @try {


            if ([message respondsToSelector:@selector(setM_nsContent:)]) {


                NSString *oldText =
                [message performSelector:@selector(m_nsContent)];


                NSString *newText =
                [self modifyText:oldText];


                if (newText &&
                    ![newText isEqualToString:oldText]) {


                    [message performSelector:
                     @selector(setM_nsContent:)
                     withObject:newText];

                }

            }


        } @catch(NSException *e) {


            NSLog(@"[WCClown] text error %@", e);

        }

    }





    /*
     图片处理

     对应：
     WCRefineSetClownImageOverride
     */


    if ([self imageModifyEnabled]) {


        @try {


            if ([message respondsToSelector:@selector(m_dtImg:)]) {


                NSData *img =
                [message performSelector:@selector(m_dtImg)];


                NSData *newImg =
                [self modifyImage:img];


                if (newImg) {


                    [message performSelector:
                     @selector(setM_dtImg:)
                     withObject:newImg];

                }

            }


        } @catch(NSException *e) {


            NSLog(@"[WCClown] image error %@",e);

        }

    }





    /*
     时间处理

     对应：
     WCRefineSetClownTimeOverride
     */


    if ([self timeModifyEnabled]) {


        @try {


            if ([message respondsToSelector:@selector(m_nsCreateTime:)]) {


                NSString *time =
                [message performSelector:
                 @selector(m_nsCreateTime)];


                NSString *newTime =
                [self modifyTime:time];


                if (newTime) {


                    [message performSelector:
                     @selector(setM_nsCreateTime:)
                     withObject:newTime];

                }

            }


        } @catch(NSException *e) {


            NSLog(@"[WCClown] time error %@",e);

        }

    }


}



@end
#pragma mark - Text Modify

+ (NSString *)modifyText:(NSString *)text {

    if (text == nil) {
        return text;
    }


    NSDictionary *map = [[self defaults] objectForKey:@"clown.text.map"];


    if (map && [map objectForKey:text]) {

        return [map objectForKey:text];

    }


    // 默认小丑标记
    if ([[self defaults] boolForKey:@"clown.add.emoji"]) {

        return [NSString stringWithFormat:@"🤡 %@", text];

    }


    return text;
}



#pragma mark - Image Modify

+ (NSData *)modifyImage:(NSData *)imageData {

    if (!imageData) {
        return imageData;
    }


    /*
     这里对应原 WCRefine：

     WCRefineSetClownImageOverride
     WCRefineShouldModifyClownImage

     后续可以接图片替换缓存
    */


    NSData *replace =
    [[self defaults] objectForKey:@"clown.image.data"];


    if (replace) {

        return replace;

    }


    return imageData;

}



#pragma mark - Time Modify

+ (NSString *)modifyTime:(NSString *)time {

    if (!time) {
        return time;
    }


    NSString *custom =
    [[self defaults] objectForKey:@"clown.custom.time"];


    if (custom.length > 0) {

        return custom;

    }


    return time;

}



#pragma mark - Chat Time

+ (NSString *)modifyChatTime:(NSString *)time {

    if (!time) {
        return time;
    }


    NSString *custom =
    [[self defaults] objectForKey:@"clown.chat.time.value"];


    if (custom.length > 0) {

        return custom;

    }


    return time;

}

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
