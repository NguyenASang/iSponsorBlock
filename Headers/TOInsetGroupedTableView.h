// An iOS 12 back-port of the grouped inset table view style in iOS 13.
// Author: Timothy Oliver
// Maintainer: NguyenASang

#import <UIKit/UIKit.h>

@interface TOInsetGroupedTableView : UITableView
@property (nonatomic, assign) BOOL isDarkMode;
- (instancetype)initWithFrame:(CGRect)frame isDarkMode:(BOOL)isDarkMode;
@end
