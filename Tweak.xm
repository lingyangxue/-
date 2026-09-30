#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "ClownCore.h"

%hook CMessageMgr

- (void)AddMsg:(id)msg MsgWrap:(id)wrap
{
    %orig;

    if ([ClownCore enabled]) {
        [ClownCore processMessage:wrap];
    }
}

%end


%hook CMessageWrap

- (NSString *)m_nsContent
{
    NSString *content = %orig;

    if ([ClownCore textModifyEnabled]) {
        content = [ClownCore modifyText:content];
    }

    return content;
}

%end


__attribute__((constructor))
static void WCClownInit(void)
{
    NSLog(@"[WCClown] dylib injected");
}