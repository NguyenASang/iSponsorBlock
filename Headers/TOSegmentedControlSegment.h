// An iOS 12 back-port of the segment style in iOS 13.
// Author: Timothy Oliver
// Maintainer: NguyenASang

#import <Foundation/Foundation.h>

@class UIView;
@class UIImage;
@class UIImageView;
@class UILabel;
@class TOSegmentedControl;

NS_ASSUME_NONNULL_BEGIN

/**
 A private model object that holds all of the
 information and state for a single item in the
 segmented control.
 */
@interface TOSegmentedControlSegment : NSObject

/** When item is a label, the text to display */
@property (nonatomic, copy, nullable) NSString *title;

/** When item is an image, the image to display */
@property (nonatomic, strong, nullable) UIImage *image;

/** Whether the item can be tapped to toggle direction */
@property (nonatomic, assign) BOOL isReversible;

/** Whether the item is currently reveresed or not */
@property (nonatomic, assign) BOOL isReversed;

/** Whether this item is enabled or disabled. */
@property (nonatomic, assign) BOOL isDisabled;

/** Whether the item is selected or not. */
@property (nonatomic, assign) BOOL isSelected;

/** A container view that wraps the item and arrow views */
@property (nonatomic, strong) UIView *containerView;

/** The view (either image or label) for this item */
@property (nonatomic, readonly) UIView *itemView;

/** If the item is a string, the subsequent label view (nil if an image) */
@property (nonatomic, nullable, readonly) UILabel *label;

/** If the item is an image, the subsequent image view (nil if a string) */
@property (nonatomic, nullable, readonly) UIImageView *imageView;

/// Create an array of objects given an array of strings and images
+ (NSArray *)segmentsWithObjects:(NSArray *)objects forSegmentedControl:(TOSegmentedControl *)segmentedControl;

/// Re-synchronize the item view when the segmented control style changes
- (void)refreshItemView;

@end

NS_ASSUME_NONNULL_END
