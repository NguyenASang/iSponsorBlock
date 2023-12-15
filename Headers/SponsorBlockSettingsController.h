#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <rootless.h>
#import "TOInsetGroupedTableView.h"

@protocol HBColorPickerDelegate <NSObject>
@optional -(void)colorPicker:(id)colorPicker didSelectColor:(UIColor *)color;
@end

@interface UITableViewCell ()
- (void)_setSeparatorEffect:(id)arg1;
@end

@interface UIView ()
- (UIViewController *)_viewControllerForAncestor;
@end

@interface UITableViewCell ()
- (UITextField *)editableTextField;
- (id)_indexPath;
@end

@interface UISegment : UIView
@end

@interface HBColorPickerConfiguration
@property (nonatomic, assign) BOOL supportsAlpha;
@end

@interface HBColorPickerViewController : UIViewController
@property (strong, nonatomic) NSObject <HBColorPickerDelegate> *delegate;
@property (strong, nonatomic) HBColorPickerConfiguration *configuration;
@end

@interface HBColorWell : UIControl
@property (nonatomic, assign) BOOL isDragInteractionEnabled;
@property (nonatomic, assign) BOOL isDropInteractionEnabled;
@property (strong, nonatomic) UIColor *color;
@end

@interface SponsorBlockTableCell : UITableViewCell <HBColorPickerDelegate>
@property (strong, nonatomic) NSString *category;
@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) HBColorWell *colorWell;
@end

@interface SponsorBlockSettingsController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, assign) BOOL toggleDarkMode;
@property (nonatomic, strong) NSString *tweakTitle;
@property (strong, nonatomic) TOInsetGroupedTableView *tableView;
@property (strong, nonatomic) NSArray *sectionTitles;
@property (strong, nonatomic) NSMutableDictionary *settings;
@property (strong, nonatomic) NSString *settingsPath;
- (void)enabledSwitchToggled:(UISwitch *)sender;
- (void)switchToggled:(UISwitch *)sender;
- (void)categorySegmentSelected:(UISegmentedControl *)segmentedControl;
@end
