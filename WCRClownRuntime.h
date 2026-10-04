//
//  WCRClownRuntime.h
//  小丑功能 覆盖引擎（按逆向结果还原的独立实现）
//
//  作用：只在本机渲染层篡改「自己发出的消息」的显示内容。
//        全部数据存在内存字典里，不落盘、不发送、不影响对方。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 开关（NSUserDefaults 键，与逆向所得原键名保持一致）

extern NSString *const kWCRClownFeatureEnabled;          // 总开关
extern NSString *const kWCRClownTextModifyEnabled;       // 修改文字
extern NSString *const kWCRClownImageModifyEnabled;      // 修改图片
extern NSString *const kWCRClownMessageTimeEnabled;      // 修改消息时间
extern NSString *const kWCRClownChatTimeEnabled;         // 修改聊天时间
extern NSString *const kWCRClownSortEnabled;             // 消息排序
extern NSString *const kWCRClownYinYangSwapEnabled;      // 颠倒阴阳
extern NSString *const kWCRClownTransferEnabled;         // 修改转账
extern NSString *const kWCRClownPersistOnExitChat;       // 退出保持

#pragma mark - 单条消息的覆盖数据

@interface WCRClownOverride : NSObject
@property (nonatomic, copy,   nullable) NSString *text;        // 文字覆盖
@property (nonatomic, copy,   nullable) NSString *quotedText;  // 引用文字覆盖
@property (nonatomic, strong, nullable) NSNumber *time;        // 消息时间（unix, unsigned int）
@property (nonatomic, copy,   nullable) NSString *chatTimeKey; // 会话时间覆盖键
@property (nonatomic, strong, nullable) NSData   *imageData;   // 图片替换数据
@property (nonatomic, assign)           BOOL      yinYangSwapped; // 颠倒阴阳
@property (nonatomic, assign)           BOOL      preserveIdentity; // 阴阳时保留原身份
@property (nonatomic, copy,   nullable) NSString *transferAmount;   // 转账金额覆盖
- (BOOL)isEmpty;
@end

#pragma mark - 运行时

@interface WCRClownRuntime : NSObject

+ (instancetype)shared;

/// 本地内存中的覆盖表： messageKey -> WCRClownOverride
@property (nonatomic, readonly) NSMutableDictionary<NSString *, WCRClownOverride *> *overrides;

#pragma mark 开关读写（自动同步到 NSUserDefaults）
+ (BOOL)featureEnabled;
+ (void)setFeatureEnabled:(BOOL)on;
+ (BOOL)isOn:(NSString *)key;
+ (void)setOn:(BOOL)on forKey:(NSString *)key;

/// 按真实消息对象推导唯一键（会话 + 方向 + 消息标识）
+ (nullable NSString *)messageKeyForMessage:(id)message;

#pragma mark 写入覆盖
- (void)setTextOverride:(nullable NSString *)text    forMessage:(id)message;
- (void)setQuotedTextOverride:(nullable NSString *)t forMessage:(id)message;
- (void)setTimeOverride:(nullable NSNumber *)time    forMessage:(id)message;
- (void)setChatTimeOverride:(nullable NSString *)t   forSession:(NSString *)sessionKey;
- (void)setImageOverride:(nullable NSData *)data     forMessage:(id)message;
- (void)setYinYangOverride:(BOOL)swapped
          preserveIdentity:(BOOL)preserve
                forMessage:(id)message;
- (void)setTransferAmountOverride:(nullable NSString *)amount forMessage:(id)message;

#pragma mark 读取覆盖
- (nullable NSString *)textOverrideForMessage:(id)message;
- (nullable NSString *)quotedTextOverrideForMessage:(id)message;
- (nullable NSNumber *)timeOverrideForMessage:(id)message;
- (nullable NSString *)chatTimeOverrideForViewModel:(id)viewModel;
- (nullable NSData *)imageDataOverrideForMessage:(id)message;
- (BOOL)yinYangOverrideForMessage:(id)message preserveIdentity:(BOOL *)preserve;

#pragma mark 清理
- (void)clearOverridesForMessage:(id)message;
- (void)clearOverridesForSession:(NSString *)sessionKey;
- (void)clearAll;

#pragma mark 应用 / 判定
/// 把覆盖写回消息对象（文字写 m_nsContent、时间写 m_uiCreateTime、图片整体替换等）
- (void)applyOverridesToMessage:(id)message;

/// 该消息能否改（文本消息才可改；语音消息不可改；图片消息才可换图）
+ (BOOL)messageCanEditText:(id)message;
+ (BOOL)messageIsVoice:(id)message;
+ (BOOL)messageCanReplaceImage:(id)message;
+ (BOOL)messageCanSwapYinYang:(id)message;

/// 长按菜单里是否显示「小丑」入口：总开关开 + 是自己发的消息 + 至少有一项可改
+ (BOOL)shouldShowClownMenuForCell:(id)cell;

/// 子项是否生效（总开关 + 子开关）
+ (BOOL)shouldModifyText;
+ (BOOL)shouldModifyImage;
+ (BOOL)shouldModifyMessageTime;
+ (BOOL)shouldModifyChatTime;
+ (BOOL)shouldSortMessages;
+ (BOOL)shouldSwapYinYang;

@end

NS_ASSUME_NONNULL_END
