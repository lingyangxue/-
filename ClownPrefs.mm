#import <UIKit/UIKit.h>
#import "ClownCore.h"

@interface ClownPrefs : UIViewController
@end

@implementation ClownPrefs

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"小丑";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UISwitch *masterSwitch = [[UISwitch alloc] init];
    masterSwitch.on = [ClownCore enabled];
    [masterSwitch addTarget:self
                     action:@selector(toggleMaster:)
           forControlEvents:UIControlEventValueChanged];

    UILabel *masterLabel = [[UILabel alloc] init];
    masterLabel.text = @"开启小丑";
    masterLabel.font = [UIFont systemFontOfSize:17.0];

    UIStackView *masterRow =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            masterLabel,
            masterSwitch
        ]];

    masterRow.axis = UILayoutConstraintAxisHorizontal;
    masterRow.distribution = UIStackViewDistributionEqualSpacing;
    masterRow.alignment = UIStackViewAlignmentCenter;


    UISwitch *textSwitch = [[UISwitch alloc] init];
    textSwitch.on = [ClownCore textModifyEnabled];

    [textSwitch addTarget:self
                   action:@selector(toggleText:)
         forControlEvents:UIControlEventValueChanged];

    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.text = @"文字修改";
    textLabel.font = [UIFont systemFontOfSize:17.0];

    UIStackView *textRow =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            textLabel,
            textSwitch
        ]];

    textRow.axis = UILayoutConstraintAxisHorizontal;
    textRow.distribution = UIStackViewDistributionEqualSpacing;
    textRow.alignment = UIStackViewAlignmentCenter;


    UIStackView *stack =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            masterRow,
            textRow
        ]];

    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 20.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:stack];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor
            constraintEqualToAnchor:guide.leadingAnchor
            constant:20.0],

        [stack.trailingAnchor
            constraintEqualToAnchor:guide.trailingAnchor
            constant:-20.0],

        [stack.topAnchor
            constraintEqualToAnchor:guide.topAnchor
            constant:20.0]
    ]];
}


- (void)toggleMaster:(UISwitch *)sender
{
    [ClownCore setEnabled:sender.isOn];
}


- (void)toggleText:(UISwitch *)sender
{
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc]
            initWithSuiteName:@"com.wcclown.settings"];

    [defaults setBool:sender.isOn
               forKey:@"clown.text"];

    [defaults synchronize];
}

@end