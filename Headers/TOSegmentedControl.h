// An iOS 12 back-port of the segmented control style in iOS 13.
// Author: Timothy Oliver
// Maintainer: NguyenASang

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TOSegmentedControlSegment.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A UI control that presents several
 options to the user in a horizontal, segmented layout.

 Only one segment may be selected at a time and, if desired,
 may be designated as 'reversible' with an arrow icon indicating
 its direction.
 */

NS_SWIFT_NAME(SegmentedControl)
IB_DESIGNABLE @interface TOSegmentedControl : UIControl

/** Dark mode */
@property (nonatomic, assign) BOOL isDarkMode;

/** The items currently assigned to this segmented control. (Can be a combination of strings and images) */
@property (nonatomic, copy, nullable) NSArray *items;

/** The number of segments this segmented control has. */
@property (nonatomic, readonly) NSInteger numberOfSegments;

/** The index of the currently segment. (May be manually set) */
@property (nonatomic, assign) NSInteger selectedSegmentIndex;

/** Whether the selected segment is also reveresed. */
@property (nonatomic, assign) BOOL selectedSegmentReversed;

/** Automatically handle the width of segments */
@property (nonatomic, assign) BOOL apportionsSegmentWidthsByContent;

/** The index values of all of the segments that are reversible. */
@property (nonatomic, strong) NSArray<NSNumber *> *reversibleSegmentIndexes;

/** The amount of rounding in the corners (Default is 9.0f) */
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

/** Set the background color of the track in the segmented control (Default is light grey) */
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *backgroundColor;

/** Set the color of the thumb view. (Default is white) */
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *thumbColor;

/** Set the color of the separator lines between each item. (Default is dark grey) */
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *separatorColor;

/** The color of the text labels / images (Default is black) */
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *itemColor;

/** The color of the selected labels / images (Default is black) */
@property (nonatomic, strong, null_resettable) IBInspectable UIColor *selectedItemColor;

/** The font of the text items (Default is system default at 10 points) */
@property (nonatomic, strong, null_resettable) IBInspectable UIFont *textFont;

/** The font of the text item when it's been selected (Default is bold system default 10) */
@property (nonatomic, strong, null_resettable) IBInspectable UIFont *selectedTextFont;

/** The amount of insetting the thumb view is from the edge of the track (Default is 2.0f) */
@property (nonatomic, assign) IBInspectable CGFloat thumbInset;

/** The opacity of the shadow surrounding the thumb view*/
@property (nonatomic, assign) IBInspectable CGFloat thumbShadowOpacity;

/** The vertical offset of the shadow */
@property (nonatomic, assign) IBInspectable CGFloat thumbShadowOffset;

/** The radius of the shadow */
@property (nonatomic, assign) IBInspectable CGFloat thumbShadowRadius;

/**
 Creates a new segmented control with the provided items.

 @param items An array of either images, or strings to display
*/
- (instancetype)initWithItems:(NSArray *)items isDarkMode:(BOOL)isDarkMode NS_SWIFT_NAME(init(items:isDarkMode:));

/**
 Sets which segment is currently selected, and optionally play an animation during the transition.

 @param selectedSegmentIndex The index of the segment to select.
 @param animated Whether the transition to the newly selected index is animated or not.
*/
- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex animated:(BOOL)animated NS_SWIFT_NAME(setSelectedSegmentIndex(_:animated:));

@end

NS_ASSUME_NONNULL_END

FOUNDATION_EXPORT double TOSegmentedControlFrameworkVersionNumber;
FOUNDATION_EXPORT const unsigned char TOSegmentedControlFrameworkVersionString[];
