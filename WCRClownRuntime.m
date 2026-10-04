//
//  WCRClownRuntime.m
//  小丑功能 覆盖引擎实现
//
//  说明：这里的「消息对象」一律用 id + respondsToSelector: 访问，
//        避免依赖某一版微信的类名；接自己目标版本时按需替换取值方式。
//

#import "WCRClownRuntime.h"

NSString *const kWCRClownFeatureEnabled     = @"clownFeatureEnabled";
NSString *const kWCRClownTextModifyEnabled  = @"clownTextModifyEnabled";
NSString *const kWCRClownImageModifyEnabled = @"clownImageModifyEnabled";
NSString *const kWCRClownMessageTimeEnabled = @"clownMessageTimeModifyEnabled";
NSString *const kWCRClownChatTimeEnabled    = @"clownChatTimeModifyEnabled";
NSString *const kWCRClownSortEnabled        = @"clownMessageSortEnabled";
NSString *const kWCRClownYinYangSwapEnabled = @"clownYinYangSwapEnabled";
NSString *const kWCRClownTransferEnabled    = @"transferAmountModifyEnabled";
NSString *const kWCRClownPersistOnExitChat  = @"transferAmountPersistOnExitChat";

@implementation WCRClownOverride
- (BOOL)isEmpty {
    return self.text.length == 0 && self.quotedText.length == 0 && !self.time
        && self.imageData.length == 0 && !self.yinYangSwapped && !self.transferAmount.length;
}
@end

#pragma mark - 小工具

static id WCRCall(id obj, NSString *sel) {
    SEL s = NSSelectorFromString(sel);
    if (obj && [obj respondsToSelector:s]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [obj performSelector:s];
#pragma clang diagnostic pop
    }
    return nil;
}

static void WCRCallVoid(id obj, NSString *sel, id arg) {
    SEL s = NSSelectorFromString(sel);
    if (obj && [obj respondsToSelector:s]) {
        IMP imp = [obj methodForSelector:s];
        ((void (*)(id, SEL, id))imp)(obj, s, arg);
    }
}

static BOOL WCRBool(id obj, NSString *sel) {
    return [WCRCall(obj, sel) boolValue];
}

@implementation WCRClownRuntime

+ (instancetype)shared {
    static WCRClownRuntime *g;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ g = [WCRClownRuntime new]; });
    return g;
}

- (instancetype)init {
    if ((self = [super init])) { _overrides = [NSMutableDictionary dictionary]; }
    return self;
}

#pragma mark - 开关

+ (BOOL)isOn:(NSString *)key {
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    return v ? [v boolValue] : NO;
}

+ (void)setOn:(BOOL)on forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)featureEnabled                { return [self isOn:kWCRClownFeatureEnabled]; }
+ (void)setFeatureEnabled:(BOOL)on    { [self setOn:on forKey:kWCRClownFeatureEnabled]; }

+ (BOOL)shouldModifyText        { return [self featureEnabled] && [self isOn:kWCRClownTextModifyEnabled]; }
+ (BOOL)shouldModifyImage       { return [self featureEnabled] && [self isOn:kWCRClownImageModifyEnabled]; }
+ (BOOL)shouldModifyMessageTime { return [self featureEnabled] && [self isOn:kWCRClownMessageTimeEnabled]; }
+ (BOOL)shouldModifyChatTime    { return [self featureEnabled] && [self isOn:kWCRClownChatTimeEnabled]; }
+ (BOOL)shouldSortMessages      { return [self featureEnabled] && [self isOn:kWCRClownSortEnabled]; }
+ (BOOL)shouldSwapYinYang       { return [self featureEnabled] && [self isOn:kWCRClownYinYangSwapEnabled]; }

#pragma mark - 消息键

+ (nullable NSString *)messageKeyForMessage:(id)message {
    if (!message) return nil;

    NSString *from   = WCRCall(message, @"m_nsFromUsr");
    NSString *to     = WCRCall(message, @"m_nsToUsr");
    NSString *real   = WCRCall(message, @"m_nsRealChatUsr");
    NSNumber *type   = WCRCall(message, @"m_uiMessageType");
    NSNumber *when   = WCRCall(message, @"createTime");

    if (!from.length && !to.length) return nil;

    // 发送方向归一：谁发的不重要，重要的是「会话 + 这条消息」
    NSString *session = real.length ? real
                       : ([from isEqualToString:to] ? from : [NSString stringWithFormat:@"%@|%@", from, to]);

    return [NSString stringWithFormat:@"%@#%@#%@#%@",
            session ?: @"?",
            from ?: @"?",
            type ?: @0,
            when ?: @0];
}

- (WCRClownOverride *)overrideForMessage:(id)message create:(BOOL)create {
    NSString *key = [WCRClownRuntime messageKeyForMessage:message];
    if (!key.length) return nil;
    WCRClownOverride *ov = self.overrides[key];
    if (!ov && create) { ov = [WCRClownOverride new]; self.overrides[key] = ov; }
    return ov;
}

#pragma mark - 写入覆盖

- (void)setTextOverride:(NSString *)text forMessage:(id)message {
    WCRClownOverride *ov = [self overrideForMessage:message create:YES];
    ov.text = text.length ? text : nil;
    // 立刻回写一次，UI 马上能看到
    [self applyOverridesToMessage:message];
}

- (void)setQuotedTextOverride:(NSString *)t forMessage:(id)message {
    [self overrideForMessage:message create:YES].quotedText = t.length ? t : nil;
}

- (void)setTimeOverride:(NSNumber *)time forMessage:(id)message {
    [self overrideForMessage:message create:YES].time = time;
    [self applyOverridesToMessage:message];
}

- (void)setChatTimeOverride:(NSString *)t forSession:(NSString *)sessionKey {
    if (!sessionKey.length) return;
    // 会话时间单独一张表： key = "chatTime#" + session
    WCRClownOverride *ov = self.overrides[[@"chatTime#" stringByAppendingString:sessionKey]];
    if (!ov) { ov = [WCRClownOverride new]; self.overrides[[@"chatTime#" stringByAppendingString:sessionKey]] = ov; }
    ov.chatTimeKey = t;
}

- (void)setImageOverride:(NSData *)data forMessage:(id)message {
    [self overrideForMessage:message create:YES].imageData = data.length ? data : nil;
}

- (void)setYinYangOverride:(BOOL)swapped preserveIdentity:(BOOL)preserve forMessage:(id)message {
    WCRClownOverride *ov = [self overrideForMessage:message create:YES];
    ov.yinYangSwapped   = swapped;
    ov.preserveIdentity = preserve;
}

- (void)setTransferAmountOverride:(NSString *)amount forMessage:(id)message {
    [self overrideForMessage:message create:YES].transferAmount = amount.length ? amount : nil;
}

#pragma mark - 读取覆盖

- (NSString *)textOverrideForMessage:(id)message        { return [self overrideForMessage:message create:NO].text; }
- (NSString *)quotedTextOverrideForMessage:(id)message  { return [self overrideForMessage:message create:NO].quotedText; }
- (NSNumber *)timeOverrideForMessage:(id)message        { return [self overrideForMessage:message create:NO].time; }
- (NSData  *)imageDataOverrideForMessage:(id)message    { return [self overrideForMessage:message create:NO].imageData; }

- (NSString *)chatTimeOverrideForViewModel:(id)viewModel {
    NSString *session = WCRCall(viewModel, @"m_nsRealChatUsr") ?: WCRCall(viewModel, @"sessionKey");
    if (!session.length) return nil;
    return self.overrides[[@"chatTime#" stringByAppendingString:session]].chatTimeKey;
}

- (BOOL)yinYangOverrideForMessage:(id)message preserveIdentity:(BOOL *)preserve {
    WCRClownOverride *ov = [self overrideForMessage:message create:NO];
    if (preserve) *preserve = ov.preserveIdentity;
    return ov.yinYangSwapped;
}

#pragma mark - 清理

- (void)clearOverridesForMessage:(id)message {
    NSString *key = [WCRClownRuntime messageKeyForMessage:message];
    if (key.length) [self.overrides removeObjectForKey:key];
}

- (void)clearOverridesForSession:(NSString *)sessionKey {
    if (!sessionKey.length) return;
    NSString *prefix = [sessionKey stringByAppendingString:@"#"];
    for (NSString *k in self.overrides.allKeys.copy) {
        if ([k hasPrefix:prefix] || [k isEqualToString:[@"chatTime#" stringByAppendingString:sessionKey]]) {
            [self.overrides removeObjectForKey:k];
        }
    }
}

- (void)clearAll { [self.overrides removeAllObjects]; }

#pragma mark - 应用

- (void)applyOverridesToMessage:(id)message {
    if (![WCRClownRuntime featureEnabled]) return;
    WCRClownOverride *ov = [self overrideForMessage:message create:NO];
    if (!ov || ov.isEmpty) return;

    // 时间：直接改消息对象的时间字段
    if (ov.time && [WCRClownRuntime shouldModifyMessageTime]) {
        id content = WCRCall(message, @"m_nsContent") ?: message;
        WCRCallVoid(content, @"setM_uiCreateTime:", ov.time);
    }

    // 文字：写进消息内容对象，并把引用文字一并替换
    if (ov.text.length && [WCRClownRuntime shouldModifyText]) {
        WCRCallVoid(message, @"setM_nsContent:", ov.text);
        id content = WCRCall(message, @"m_nsContent");
        if (content && ov.quotedText.length) {
            WCRCallVoid(content, @"setReferDisplayText:", ov.quotedText);
        }
    }
}

#pragma mark - 可编辑性判定

+ (BOOL)messageIsVoice:(id)message {
    return WCRBool(message, @"IsVoiceMsg");
}

+ (BOOL)messageCanEditText:(id)message {
    if (!message) return NO;
    if ([self messageIsVoice:message]) return NO;              // 语音不许改字
    if (WCRBool(message, @"IsTextMsg")) return YES;            // 纯文本
    NSNumber *type = WCRCall(message, @"m_uiMessageType");
    return (type.integerValue == 1);                           // 1 = 文本类型
}

+ (BOOL)messageCanReplaceImage:(id)message {
    id img = WCRCall(message, @"m_nsImgData") ?: WCRCall(message, @"GetImgData");
    return img != nil;
}

+ (BOOL)messageCanSwapYinYang:(id)message {
    return [self messageKeyForMessage:message].length > 0;
}

+ (BOOL)shouldShowClownMenuForCell:(id)cell {
    if (![self featureEnabled]) return NO;
    id message = WCRCall(cell, @"messageWrap") ?: WCRCall(cell, @"m_message") ?: WCRCall(cell, @"viewModel");
    if (!message) return NO;
    return [self messageCanEditText:message]
        || [self messageCanReplaceImage:message]
        || [self messageCanSwapYinYang:message];
}

@end
