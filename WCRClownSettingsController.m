//
//  WCRClownSettingsController.m
//  小丑功能 设置页（9 项开关 + 免责门）
//

#import <UIKit/UIKit.h>
#import "WCRClownRuntime.h"

typedef NS_ENUM(NSInteger, WCRClownRow) {
    WCRClownRowMaster = 0,
    WCRClownRowText,
    WCRClownRowImage,
    WCRClownRowMessageTime,
    WCRClownRowChatTime,
    WCRClownRowSort,
    WCRClownRowYinYang,
    WCRClownRowTransfer,
    WCRClownRowPersist,
    WCRClownRowCount
};

static NSString *const kWCRClownDisclaimerAgreed = @"clownDisclaimerAgreed";

@interface WCRClownSettingsController : UITableViewController
@end

@implementation WCRClownSettingsController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"小丑功能";
    [self showDisclaimerIfNeeded];
}

#pragma mark - 免责门

- (void)showDisclaimerIfNeeded {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kWCRClownDisclaimerAgreed]) return;

    NSString *msg = @"本功能为自用娱乐功能，未开放若你看到请勿使用，\n"
                     "请勿用于任何非法用途，否则一切后果自行承担！";
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"小丑功能"
                                                               message:msg
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"不同意" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"我同意上述提示" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWCRClownDisclaimerAgreed];
    }]];
    [self presentViewController:ac animated:YES completion:nil];
}

#pragma mark - 数据源

- (NSArray<NSString *> *)titles {
    return @[@"启用小丑功能", @"修改文字", @"修改图片", @"修改消息时间",
             @"修改聊天时间", @"消息排序", @"颠倒阴阳", @"修改转账", @"退出保持"];
}

- (NSString *)defaultsKeyForRow:(WCRClownRow)row {
    switch (row) {
        case WCRClownRowMaster:      return kWCRClownFeatureEnabled;
        case WCRClownRowText:        return kWCRClownTextModifyEnabled;
        case WCRClownRowImage:       return kWCRClownImageModifyEnabled;
        case WCRClownRowMessageTime: return kWCRClownMessageTimeEnabled;
        case WCRClownRowChatTime:    return kWCRClownChatTimeEnabled;
        case WCRClownRowSort:        return kWCRClownSortEnabled;
        case WCRClownRowYinYang:     return kWCRClownYinYangSwapEnabled;
        case WCRClownRowTransfer:    return kWCRClownTransferEnabled;
        case WCRClownRowPersist:     return kWCRClownPersistOnExitChat;
    }
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    return s == 0 ? @"按功能" : @"按对应的内容点击小丑修改。\n「颠倒阴阳」只把消息左右对调，头像昵称仍是原发送者。";
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    return s == 0 ? @"所有修改仅在本次微信运行期间生效，重启自动失效。" : nil;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return s == 0 ? 1 : (WCRClownRowCount - 1);
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"c"] ?:
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
    WCRClownRow row = ip.section == 0 ? WCRClownRowMaster : (WCRClownRow)(ip.row + 1);
    cell.textLabel.text = [self titles][row];

    UISwitch *sw = [UISwitch new];
    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:[self defaultsKeyForRow:row]];
    sw.tag = row;
    [sw addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)toggle:(UISwitch *)sw {
    WCRClownRow row = (WCRClownRow)sw.tag;
    [WCRClownRuntime setOn:sw.on forKey:[self defaultsKeyForRow:row]];
    if (row == WCRClownRowMaster) [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip { [tv deselectRowAtIndexPath:ip animated:YES]; }

@end
