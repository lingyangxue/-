//
//  ClownCore.h
//  WCClown
//

#import <Foundation/Foundation.h>

@interface ClownCore : NSObject

// 总开关
+ (BOOL)enabled;
+ (void)setEnabled:(BOOL)value;


// 文字修改
+ (BOOL)textModifyEnabled;
+ (NSString *)modifyText:(NSString *)text;


// 图片修改
+ (BOOL)imageModifyEnabled;
+ (NSData *)modifyImage:(NSData *)imageData;


// 时间修改
+ (BOOL)timeModifyEnabled;
+ (NSString *)modifyTime:(NSString *)time;


// 聊天时间
+ (BOOL)chatTimeModifyEnabled;
+ (NSString *)modifyChatTime:(NSString *)time;


// 消息排序
+ (BOOL)sortEnabled;


// 阴阳互换
+ (BOOL)yinYangEnabled;


// 消息处理
+ (void)processMessage:(id)message;

@end
