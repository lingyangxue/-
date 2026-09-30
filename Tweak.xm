#import <UIKit/UIKit.h>
#import "ClownCore.h"

%hook CMessageMgr

- (void)AddMsg:(id)msg MsgWrap:(id)wrap {
    
    %orig;

    if ([ClownCore enabled]) {
        [ClownCore processMessage:wrap];
    }
}

%end


%hook CMessageWrap

- (NSString *)m_nsContent {

    NSString *content = %orig;

    if ([ClownCore textModifyEnabled]) {
        content = [ClownCore modifyText:content];
    }

    return content;
}

%end


%hook MMChatHistoryViewController

- (void)viewDidLoad {

    %orig;

    if ([ClownCore enabled]) {
        NSLog(@"WCClown Loaded");
    }
}

%end


%ctor {

    NSLog(@"[WCClown] Inject Success");

}
