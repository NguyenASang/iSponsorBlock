// An iOS 12 back-port of the segmented control style in iOS 13.
// Author: Timothy Oliver
// Maintainer: NguyenASang

#include <RemoteLog.h>
#import "Headers/TOSegmentedControl.h"
#import "Headers/TOSegmentedControlSegment.h"

// ----------------------------------------------------------------
// Static Function

static NSMutableDictionary *calculateSegmentWidth(NSMutableDictionary *segments, CGFloat segmentedControlWidth) {
    CGFloat currentWidth = 0;
    for (NSString *key in [segments allKeys]) {
        currentWidth += [segments[key] floatValue];
    }

    NSUInteger i = 0;
    NSArray *keys = [segments allKeys];
    while (currentWidth < segmentedControlWidth) {
        CGFloat widthOfCurrentSegment = [segments[keys[i]] floatValue] + 1.0f;
        segments[keys[i]] = @(widthOfCurrentSegment);
        currentWidth++;
        i++;

        if (i > [keys count] - 1) i = 0;
    }

    return segments;
}

// ----------------------------------------------------------------
// Static Members

// A cache to hold images generated for this view that may be shared.
static NSMapTable *_imageTable = nil;

// Statically referenced key names for the images stored in the map table.
static NSString * const kTOSegmentedControlSeparatorImage = @"separatorImage";

// When tapped the amount the focused elements will shrink / fade
static CGFloat const kTOSegmentedControlSelectedTextAlpha = 0.3f;
static CGFloat const kTOSegmentedControlDisabledAlpha = 0.4f;
static CGFloat const kTOSegmentedControlSelectedScale = 0.95f;

// ----------------------------------------------------------------
// Private Members

@interface TOSegmentedControl ()

/** The private list of item objects, storing state and view data */
@property (nonatomic, strong) NSMutableArray<TOSegmentedControlSegment *> *segments;

/** Keep track when the user taps explicitily on the thumb view */
@property (nonatomic, assign) BOOL isDraggingThumbView;

/** Track if the user drags the thumb off the original segment. This disables reversing. */
@property (nonatomic, assign) BOOL didDragOffOriginalSegment;

/** Before we commit to a new selected index, this is the index the user has dragged over */
@property (nonatomic, assign) NSInteger focusedIndex;

/** The background rounded "track" view */
@property (nonatomic, strong) UIView *trackView;

/** The view that shows which view is highlighted */
@property (nonatomic, strong) UIView *thumbView;

/** The separator views between each of the items */
@property (nonatomic, strong) NSMutableArray<UIView *> *separatorViews;

/** A weakly retained image table that holds cached images for us. */
@property (nonatomic, readonly) NSMapTable *imageTable;

/** A rounded line used as the separator line. */
@property (nonatomic, readonly) UIImage *separatorImage;

/** Convenience property for testing if there are no segments */
@property (nonatomic, readonly) BOOL hasNoSegments;

/** Store width of segments */
@property (nonatomic, strong) NSMutableDictionary *widthOfItems;

@end

@implementation TOSegmentedControl

#pragma mark - Class Init -

- (instancetype)initWithItems:(NSArray *)items isDarkMode:(BOOL)isDarkMode {
    self.isDarkMode = isDarkMode;
    if (self = [super initWithFrame:(CGRect){{0.0f, 0.0f}, {300.0f, 32.0f}}]) {
        [self commonInit];
        self.items = [self sanitizedItemArrayWithItems:items];
    }
    return self;
}

- (void)commonInit {
    // Create content view
    self.trackView = [[UIView alloc] initWithFrame:self.bounds];
    self.trackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.trackView.layer.masksToBounds = YES;
    self.trackView.userInteractionEnabled = NO;
    [self addSubview:self.trackView];

    // Create thumb view
    self.thumbView = [[UIView alloc] initWithFrame:CGRectMake(2.0f, 2.0f, 100.0f, 28.0f)];
    self.thumbView.layer.shadowColor = [UIColor blackColor].CGColor;
    [self.trackView addSubview:self.thumbView];

    // Create list for managing each item
    self.segments = [NSMutableArray array];

    // Create containers for views
    self.separatorViews = [NSMutableArray array];

    // Set default resettable values
    self.backgroundColor = self.isDarkMode ? [UIColor colorWithRed:0.898f green:0.898f blue:1.0f alpha:0.12f] : [UIColor colorWithRed:0.0f green:0.0f blue:0.08f alpha:0.06666f];
    self.thumbColor = self.isDarkMode ? [UIColor colorWithRed:0.357f green:0.357f blue:0.376f alpha:1.0f] : [UIColor whiteColor];
    self.separatorColor = self.isDarkMode ? [UIColor colorWithRed:0.918f green:0.918f blue:1.0f alpha:0.16f] : [UIColor colorWithRed:0.0f green:0.0f blue:0.08f alpha:0.1f];
    self.itemColor = self.isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
    self.selectedItemColor = self.isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
    self.textFont = [UIFont systemFontOfSize:13.0f weight:UIFontWeightMedium];
    self.selectedTextFont = [UIFont systemFontOfSize:13.0f weight:UIFontWeightSemibold];

    // Set default values
    self.selectedSegmentIndex = -1;
    self.cornerRadius = 8.0f;
    self.thumbInset = 2.0f;
    self.thumbShadowRadius = 3.0f;
    self.thumbShadowOffset = 2.0f;
    self.thumbShadowOpacity = 0.13f;

    // Set focused index to -1 to indicate nothing is focused
    self.focusedIndex = -1;

    // Configure view interaction
    // When the user taps down in the view
    [self addTarget:self
             action:@selector(didTapDown:withEvent:)
   forControlEvents:UIControlEventTouchDown];

    // When the user drags, either inside or out of the view
    [self addTarget:self
             action:@selector(didDragTap:withEvent:)
   forControlEvents:UIControlEventTouchDragInside|UIControlEventTouchDragOutside];

    // When the user's finger leaves the bounds of the view
    [self addTarget:self
             action:@selector(didExitTapBounds:withEvent:)
   forControlEvents:UIControlEventTouchDragExit];

    // When the user's finger re-enters the bounds
    [self addTarget:self
             action:@selector(didEnterTapBounds:withEvent:)
   forControlEvents:UIControlEventTouchDragEnter];

    // When the user taps up, either inside or out
    [self addTarget:self
             action:@selector(didEndTap:withEvent:)
   forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
}

#pragma mark - Item Management -

- (NSMutableArray *)sanitizedItemArrayWithItems:(NSArray *)items {
    // Filter the items to extract only strings and images
    NSMutableArray *sanitizedItems = [NSMutableArray array];
    for (id item in items) {
        if (![item isKindOfClass:[UIImage class]] && ![item isKindOfClass:[NSString class]]) {
            continue;
        }
        [sanitizedItems addObject:item];
    }

    return sanitizedItems;
}

- (void)updateSeparatorViewCount {
    // Work out how many separators we need (One less than segments)
    NSInteger numberOfSeparators = self.segments.count - 1;

    // Cap the number at 0 if there were no segments
    numberOfSeparators = MAX(0, numberOfSeparators);

    // Add as many separators as needed
    while (self.separatorViews.count < numberOfSeparators) {
        UIImageView *separator = [[UIImageView alloc] initWithImage:self.separatorImage];
        separator.tintColor = self.separatorColor;
        [self.trackView insertSubview:separator atIndex:0];
        [self.separatorViews addObject:separator];
    }

    // Substract as many separators as needed
    while (self.separatorViews.count > numberOfSeparators) {
        UIView *separator = self.separatorViews.lastObject;
        [self.separatorViews removeLastObject];
        [separator removeFromSuperview];
    }
}

#pragma mark Deleting Items

- (void)removeAllSegments {
    // Remove all item objects
    for (TOSegmentedControlSegment * segment in self.segments) {
        [segment.containerView removeFromSuperview];
    }
    self.segments = [NSMutableArray array];

    // Remove all separators
    for (UIView *separator in self.separatorViews) {
        [separator removeFromSuperview];
    }
    [self.separatorViews removeAllObjects];

    // Delete the items array
    _items = nil;
}

#pragma mark - View Layout -

- (void)layoutThumbView {
    // Hide the thumb view if no segments are selected
    if (self.selectedSegmentIndex < 0 || !self.enabled) {
        self.thumbView.hidden = YES;
        return;
    }

    // Lay-out the thumb view
    CGRect frame = [self frameForSegmentAtIndex:self.selectedSegmentIndex];
    self.thumbView.frame = frame;
    self.thumbView.hidden = NO;

    // Match the shadow path to the new size of the thumb view
    CGPathRef oldShadowPath = self.thumbView.layer.shadowPath;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero, frame.size}
                                                          cornerRadius:self.cornerRadius - self.thumbInset];

    // If the segmented control is animating its shape, to prevent the
    // shadow from visibly snapping, perform a resize animation on it
    CABasicAnimation *boundsAnimation = [self.layer animationForKey:@"bounds.size"];
    if (oldShadowPath != NULL && boundsAnimation) {
        CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
        shadowAnimation.fromValue = (__bridge id)oldShadowPath;
        shadowAnimation.toValue = (id)shadowPath.CGPath;
        shadowAnimation.duration = boundsAnimation.duration;
        shadowAnimation.timingFunction = boundsAnimation.timingFunction;
        [self.thumbView.layer addAnimation:shadowAnimation forKey:@"shadowPath"];
    }
    self.thumbView.layer.shadowPath = shadowPath.CGPath;
}

- (void)layoutItemViews {
    // Lay out the item views
    NSInteger i = 0;
    for (TOSegmentedControlSegment *item in self.segments) {
        UIView *itemView = item.itemView;
        [itemView sizeToFit];
        [self.trackView addSubview:item.containerView];

        // Get the container frame that the item will be aligned with
        CGRect thumbFrame = [self frameForSegmentAtIndex:i];
        item.containerView.frame = thumbFrame;

        // Work out the appropriate size of the item
        CGRect itemFrame = itemView.frame;

        // Cap its size to be within the segmented frame
        itemFrame.size.height = MIN(thumbFrame.size.height, itemFrame.size.height);
        itemFrame.size.width = MIN(thumbFrame.size.width, itemFrame.size.width);

        // Center the item in the container
        itemFrame.origin.x = (CGRectGetWidth(thumbFrame) - itemFrame.size.width) * 0.5f;
        itemFrame.origin.y = (CGRectGetHeight(thumbFrame) - itemFrame.size.height) * 0.5f;

        // Set the item frame
        itemView.frame = CGRectIntegral(itemFrame);

        // Make sure they are all unselected
        [self setItemAtIndex:i selected:NO];

        // If the item is disabled, make it faded
        if (!self.enabled || item.isDisabled) {
            itemView.alpha = kTOSegmentedControlDisabledAlpha;
        }

        i++;
    }

    // Exit out if there is nothing selected
    if (self.selectedSegmentIndex < 0) { return; }

    // Set the selected state for the current selected index
    [self setItemAtIndex:self.selectedSegmentIndex selected:YES];
}

- (void)layoutSeparatorViews {
    CGSize size = self.trackView.frame.size;
    CGFloat segmentWidth = 0;
    CGFloat xOffset = (_thumbInset + segmentWidth) - 1.0f;
    NSInteger i = 0;
    for (UIView *separatorView in self.separatorViews) {
        CGRect frame = separatorView.frame;
        segmentWidth = segmentWidth + [self widthOfSegmentAtIndex:i];
        frame.origin.x = xOffset + segmentWidth;
        frame.size.width = 1.0f;
        frame.size.height = (size.height - (self.cornerRadius) * 2.0f) + 2.0f;
        frame.origin.y = (size.height - frame.size.height) * 0.5f;
        separatorView.frame = CGRectIntegral(frame);
        i++;
    }

   // Update the alpha of the separator views
   [self refreshSeparatorViewsForSelectedIndex:self.selectedSegmentIndex];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // Lay-out the thumb view
    [self layoutThumbView];

    // Lay-out the item views
    [self layoutItemViews];

    // Lay-out the separator views
    [self layoutSeparatorViews];
}

- (CGFloat)widthOfSegmentAtIndex:(NSInteger)index {
    if (!self.apportionsSegmentWidthsByContent) {
        return floorf((self.bounds.size.width - (_thumbInset * 2.0f)) / self.numberOfSegments);
    }

    if (!self.widthOfItems) {
        // Sort items in descending order
        NSArray *sortedItems = [self.items sortedArrayUsingComparator:^NSComparisonResult(NSString *currentItem, NSString *nextItem) {
            return [@([nextItem length]) compare:@([currentItem length])];
        }];

        // Get text width
        UIFont *font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightMedium];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];

        self.widthOfItems = [[NSMutableDictionary alloc] init];
        for (NSString *item in sortedItems) {
            CGFloat width = floorf([[[NSAttributedString alloc] initWithString:item attributes:attributes] size].width);
            [self.widthOfItems setObject:@(width) forKey:item];
        }

        self.widthOfItems = calculateSegmentWidth(self.widthOfItems, self.bounds.size.width - (_thumbInset * 2.0f));
    }

    return [self.widthOfItems[self.items[index]] floatValue];
}

- (CGRect)frameForSegmentAtIndex:(NSInteger)index {
    CGRect frame = CGRectZero;

    if (!self.apportionsSegmentWidthsByContent) {
        frame.origin.x = _thumbInset + ([self widthOfSegmentAtIndex:index] * index) + ((_thumbInset * 2.0f) * index);
    } else {
        frame.origin.x = _thumbInset;
        for (NSInteger i = 0; i < index; i++) {
            frame.origin.x = frame.origin.x + [self.widthOfItems[self.items[i]] floatValue];
        }
    }

    CGSize size = self.trackView.frame.size;
    frame.origin.y = _thumbInset;
    frame.size.width = [self widthOfSegmentAtIndex:index];
    frame.size.height = size.height - (_thumbInset * 2.0f);

    // Cap the position of the frame so it won't overshoot
    frame.origin.x = MAX(_thumbInset, frame.origin.x);
    frame.origin.x = MIN(size.width - ([self widthOfSegmentAtIndex:index] + _thumbInset), frame.origin.x);

    return CGRectIntegral(frame);
}

- (NSInteger)segmentIndexForPoint:(CGPoint)point {
    if (!self.apportionsSegmentWidthsByContent) {
        CGFloat segmentWidth = floorf(self.frame.size.width / self.numberOfSegments);
        NSInteger segment = floorf(point.x / segmentWidth);
        segment = MAX(segment, 0);
        segment = MIN(segment, self.numberOfSegments - 1);
        return segment;
    }

    CGFloat widthSum = 0;
    for (NSString *item in self.items) {
        widthSum = widthSum + [self.widthOfItems[item] floatValue];
        if (point.x < widthSum) return [self.items indexOfObject:item];
    }

    // This line will never execute
    return -1;
}

- (void)setThumbViewShrunken:(BOOL)shrunken {
    CGFloat scale = shrunken ? kTOSegmentedControlSelectedScale : 1.0f;
    self.thumbView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
}

- (void)setItemViewAtIndex:(NSInteger)segmentIndex shrunken:(BOOL)shrunken {
    TOSegmentedControlSegment *segment = self.segments[segmentIndex];
    UIView *itemView = segment.itemView;

    if (shrunken == NO) {
        itemView.transform = CGAffineTransformIdentity;
    } else {
        CGFloat scale = kTOSegmentedControlSelectedScale;
        itemView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale);
    }
}

- (void)setItemAtIndex:(NSInteger)index selected:(BOOL)selected {
    // Tell the segment to select itself in order to show the reversible arrow
    TOSegmentedControlSegment *segment = self.segments[index];

    // The rest of this code deals with swapping the font
    // of the label. Cancel out if we're an image.
    UILabel *label = segment.label;
    if (label == nil) return;

    // Set the font
    UIFont *font = selected ? self.selectedTextFont : self.textFont;
    label.font = font;

    // Set the text color
    label.textColor = selected ? self.selectedItemColor : self.itemColor;
}

- (void)setItemAtIndex:(NSInteger)index faded:(BOOL)faded {
    UIView *itemView = self.segments[index].itemView;
    itemView.alpha = faded ? kTOSegmentedControlSelectedTextAlpha : 1.0f;
}

- (void)refreshSeparatorViewsForSelectedIndex:(NSInteger)index {
    [self refreshSeparatorViewsForSelectedIndexes:[NSSet setWithObject:@(index)]];
}

- (void)refreshSeparatorViewsForSelectedIndexes:(NSSet<NSNumber *> *)indexes {
    // Hide the separators on either side of the selected segment
    NSInteger i = 0;
    for (UIView *separatorView in self.separatorViews) {
        // if the view is disabled, the thumb view will be hidden
        if (!self.enabled) {
            separatorView.alpha = 1.0f;
            continue;
        }

        // Hide the index (right side) and the previous index (left side) if it's in the set
        BOOL containsIndex = ([indexes containsObject:@(i)] || [indexes containsObject:@(i + 1)]);
        separatorView.alpha = containsIndex ? 0.0f : 1.0f;
        i++;
    }
}

#pragma mark - Touch Interaction -

- (void)didTapDown:(UIControl *)control withEvent:(UIEvent *)event {
    // Exit out if the control is disabled
    if (!self.enabled || self.hasNoSegments) { return; }

    // Determine which segment the user tapped
    CGPoint tapPoint = [event.allTouches.anyObject locationInView:self];
    NSInteger tappedIndex = [self segmentIndexForPoint:tapPoint];

    // If the control or item is disabled, pass
    if (self.segments[tappedIndex].isDisabled) {
        return;
    }

    // Work out if we tapped on the thumb view, or on an un-selected segment
    self.isDraggingThumbView = (tappedIndex == self.selectedSegmentIndex);

    // Track if we drag off this segment
    self.didDragOffOriginalSegment = NO;

    // Track the currently selected item as the focused one
    self.focusedIndex = tappedIndex;

    // Work out which animation effects to apply
    if (!self.isDraggingThumbView) {
        [UIView animateWithDuration:0.35f animations:^{
            [self setItemAtIndex:tappedIndex faded:YES];
        }];

        [self setSelectedSegmentIndex:tappedIndex animated:YES];
        return;
    }

    id animationBlock = ^{
        [self setThumbViewShrunken:YES];
        [self setItemViewAtIndex:self.selectedSegmentIndex shrunken:YES];
    };

    // Animate the transition
    [UIView animateWithDuration:0.3f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.1f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock
                     completion:nil];
}

- (void)didDragTap:(UIControl *)control withEvent:(UIEvent *)event {
    // Exit out if the control is disabled
    if (!self.enabled || self.hasNoSegments) { return; }

    CGPoint tapPoint = [event.allTouches.anyObject locationInView:self];
    NSInteger tappedIndex = [self segmentIndexForPoint:tapPoint];

    if (tappedIndex == self.focusedIndex) {
      return;
    }

    // If the control or item is disabled, pass
    if (self.segments[tappedIndex].isDisabled) {
        return;
    }

    // Track that we dragged off the first segments
    self.didDragOffOriginalSegment = YES;

    // Handle transitioning when not dragging the thumb view
    if (!self.isDraggingThumbView) {
        // If we dragged out of the bounds, disregard
        if (self.focusedIndex < 0) { return; }

        id animationBlock = ^{
            // Deselect the current item
            [self setItemAtIndex:self.focusedIndex faded:NO];

            // Fade the text if it is NOT the thumb track one
            if (tappedIndex != self.selectedSegmentIndex) {
                [self setItemAtIndex:tappedIndex faded:YES];
            }
        };

        // Perform a faster change over animation
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:animationBlock
                         completion:nil];

        // Update the focused item
        self.focusedIndex = tappedIndex;
        return;
    }

    // Get the new frame of the segment
    CGRect frame = [self frameForSegmentAtIndex:tappedIndex];

    // Work out the center point from the frame
    CGPoint center = (CGPoint){CGRectGetMidX(frame), CGRectGetMidY(frame)};

    // Create the animation block
    id animationBlock = ^{
        self.thumbView.frame = frame;
        self.thumbView.center = center;

        // Deselect the focused item
        [self setItemAtIndex:self.focusedIndex selected:NO];
        [self setItemViewAtIndex:self.focusedIndex shrunken:NO];

        // Select the new one
        [self setItemAtIndex:tappedIndex selected:YES];
        [self setItemViewAtIndex:tappedIndex shrunken:YES];

        // Update the separators
        [self refreshSeparatorViewsForSelectedIndex:tappedIndex];
    };

    // Perform the animation
    [UIView animateWithDuration:0.45
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:1.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock
                     completion:nil];

    // Update the focused item
    self.focusedIndex = tappedIndex;
}

- (void)didExitTapBounds:(UIControl *)control withEvent:(UIEvent *)event {
    // Exit out if the control is disabled
    if (!self.enabled || self.hasNoSegments) { return; }

    // No effects needed when tracking the thumb view
    if (self.isDraggingThumbView) { return; }

    // Un-fade the focused item
    [UIView animateWithDuration:0.45f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ [self setItemAtIndex:self.focusedIndex faded:NO]; }
                     completion:nil];

    // Disable the focused index
    self.focusedIndex = -1;
}

- (void)didEnterTapBounds:(UIControl *)control withEvent:(UIEvent *)event {
    // Exit out if the control is disabled
    if (!self.enabled || self.hasNoSegments) { return; }

    // No effects needed when tracking the thumb view
    if (self.isDraggingThumbView) { return; }

    CGPoint tapPoint = [event.allTouches.anyObject locationInView:self];
    self.focusedIndex = [self segmentIndexForPoint:tapPoint];

    // Un-fade the focused item
    [UIView animateWithDuration:0.45f
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ [self setItemAtIndex:self.focusedIndex faded:YES]; }
                     completion:nil];
}

- (void)didEndTap:(UIControl *)control withEvent:(UIEvent *)event {
    // Exit out if the control is disabled
    if (!self.enabled || self.hasNoSegments) return;

    // Capture the touch object in order to track its state
    UITouch *touch = event.allTouches.anyObject;

    // Check if the tap was cancelled (In which case we shouldn't commit non-drag events)
    BOOL isCancelled = (touch.phase == UITouchPhaseCancelled);

    // Work out the final place where we released
    CGPoint tapPoint = [touch locationInView:self];
    NSInteger tappedIndex = [self segmentIndexForPoint:tapPoint];

    TOSegmentedControlSegment *segment = self.segments[tappedIndex];

    // If we WEREN'T dragging the thumb view, work out where we need to move to
    if (!self.isDraggingThumbView) {
        if (segment.isDisabled) return;

        // If we weren't cancelled, animate to the new index
        if (!isCancelled) {
            [self setSelectedSegmentIndex:tappedIndex animated:YES];
        } else {
            // Else, reset the currently highlighted item
            [self didExitTapBounds:self withEvent:event];
        }

        // Reset the focused index flag
        self.focusedIndex = -1;

        return;
    }

    // Update the state and alert the delegate
    if (self.selectedSegmentIndex != tappedIndex) {
        _selectedSegmentIndex = tappedIndex;
        [self sendIndexChangedEventActions];
    }

    // Work out which animation effects to apply
    id animationBlock = ^{
        [self setThumbViewShrunken:NO];
        [self setItemViewAtIndex:self.selectedSegmentIndex shrunken:NO];
    };

    // Animate the transition
    [UIView animateWithDuration:0.3f
                         delay:0.0f
        usingSpringWithDamping:1.0f
         initialSpringVelocity:0.1f
                       options:UIViewAnimationOptionBeginFromCurrentState
                    animations:animationBlock
                    completion:nil];

    // Reset the focused index flag
    self.focusedIndex = -1;
}

- (void)sendIndexChangedEventActions {
    // Trigger the action event for any targets that were
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark - Accessors -

// -----------------------------------------------
// Selected Item Index

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex animated:(BOOL)animated {
    if (self.selectedSegmentIndex == selectedSegmentIndex) return;

    // Set the new value
    _selectedSegmentIndex = selectedSegmentIndex;

    // Cap the value
    _selectedSegmentIndex = MAX(selectedSegmentIndex, -1);
    _selectedSegmentIndex = MIN(selectedSegmentIndex, self.numberOfSegments - 1);

    // Send the update alert
    if (_selectedSegmentIndex >= 0) {
        [self sendIndexChangedEventActions];
    }

    if (!animated) {
        // Trigger a view layout
        [self setNeedsLayout];
        return;
    }

    // Create an animation block that will update the position of the
    // thumb view and restore all of the item views
    id animationBlock = ^{
        // Un-fade all of the item views
        for (NSInteger i = 0; i < self.segments.count; i++) {
            // De-select everything
            [self setItemAtIndex:i faded:NO];
            [self setItemAtIndex:i selected:NO];

            // Select the currently selected index
            [self setItemAtIndex:self.selectedSegmentIndex selected:YES];

            // Move the thumb view
            self.thumbView.frame = [self frameForSegmentAtIndex:self.selectedSegmentIndex];

            // Update the separators
            [self refreshSeparatorViewsForSelectedIndex:self.selectedSegmentIndex];
        }
    };

    // Commit the animation
    [UIView animateWithDuration:0.45f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:2.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:animationBlock
                     completion:nil];
}

// -----------------------------------------------
// Items

- (void)setItems:(NSArray *)items {
    if (items == _items) { return; }

    // Remove all current items
    [self removeAllSegments];

    // Set the new array
    _items = [self sanitizedItemArrayWithItems:items];

    // Create the list of item objects  to track their state
    _segments = [TOSegmentedControlSegment segmentsWithObjects:_items
                                           forSegmentedControl:self].mutableCopy;

    // Update the number of separators
    [self updateSeparatorViewCount];

    // Trigger a layout update
    [self setNeedsLayout];

    // Set the initial selected index
    self.selectedSegmentIndex = (_items.count > 0) ? 0 : -1;
}

// -----------------------------------------------
// Corner Radius

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.trackView.layer.cornerRadius = cornerRadius;
    self.thumbView.layer.cornerRadius = (self.cornerRadius - _thumbInset) + 1.0f;
}

- (CGFloat)cornerRadius {
    return self.trackView.layer.cornerRadius;
}

// -----------------------------------------------
// Thumb Color

- (void)setThumbColor:(UIColor *)thumbColor {
    self.thumbView.backgroundColor = thumbColor;
}

- (UIColor *)thumbColor {
    return self.thumbView.backgroundColor;
}

// -----------------------------------------------
// Background Color

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[UIColor clearColor]];
    _trackView.backgroundColor = backgroundColor;
}

- (UIColor *)backgroundColor {
    return self.trackView.backgroundColor;
}

// -----------------------------------------------
// Separator Color

- (void)setSeparatorColor:(UIColor *)separatorColor {
    _separatorColor = separatorColor;
    for (UIView *separatorView in self.separatorViews) {
        separatorView.tintColor = _separatorColor;
    }
}

// -----------------------------------------------
// Item Color

- (void)setItemColor:(UIColor *)itemColor {
    _itemColor = itemColor;
    // Set each item to the color
    for (TOSegmentedControlSegment *item in self.segments) {
        [item refreshItemView];
    }
}

//-------------------------------------------------
// Selected Item Color

- (void)setSelectedItemColor:(UIColor *)selectedItemColor {
    _selectedItemColor = selectedItemColor;
    // Set each item to the color
    for (TOSegmentedControlSegment *item in self.segments) {
        [item refreshItemView];
    }
}

// -----------------------------------------------
// Text Font

- (void)setTextFont:(UIFont *)textFont {
    _textFont = textFont;
    // Set each item to adopt the new font
    for (TOSegmentedControlSegment *item in self.segments) {
        [item refreshItemView];
    }
}

// -----------------------------------------------
// Selected Text Font

- (void)setSelectedTextFont:(UIFont *)selectedTextFont {
    _selectedTextFont = selectedTextFont;
    // Set each item to adopt the new font
    for (TOSegmentedControlSegment *item in self.segments) {
        [item refreshItemView];
    }
}

// -----------------------------------------------
// Thumb Inset

- (void)setThumbInset:(CGFloat)thumbInset {
    _thumbInset = thumbInset;
    self.thumbView.layer.cornerRadius = (self.cornerRadius - _thumbInset) + 1.0f;
}

// -----------------------------------------------
// Shadow Properties

- (void)setThumbShadowOffset:(CGFloat)thumbShadowOffset {
    self.thumbView.layer.shadowOffset = (CGSize){0.0f, thumbShadowOffset};
}

- (CGFloat)thumbShadowOffset {
    return self.thumbView.layer.shadowOffset.height;
}

- (void)setThumbShadowOpacity:(CGFloat)thumbShadowOpacity {
    self.thumbView.layer.shadowOpacity = thumbShadowOpacity;
}

- (CGFloat)thumbShadowOpacity {
    return self.thumbView.layer.shadowOpacity;
}

- (void)setThumbShadowRadius:(CGFloat)thumbShadowRadius {
    self.thumbView.layer.shadowRadius = thumbShadowRadius;
}

- (CGFloat)thumbShadowRadius {
    return self.thumbView.layer.shadowRadius;
}

// -----------------------------------------------
// Number of segments

- (NSInteger)numberOfSegments {
    return self.segments.count;
}

- (BOOL)hasNoSegments {
    return self.segments.count <= 0;
}

#pragma mark - Image Creation and Management -

- (UIImage *)separatorImage {
    UIImage *separatorImage = [self.imageTable objectForKey:kTOSegmentedControlSeparatorImage];
    if (separatorImage != nil) return separatorImage;

    UIGraphicsBeginImageContextWithOptions((CGSize){1.0f, 3.0f}, NO, 0.0f);
    {
        UIBezierPath* separatorPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 1, 3) cornerRadius:0.5];
        [UIColor.blackColor setFill];
        [separatorPath fill];
        separatorImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();

    // Format image to be resizable and tint-able.
    separatorImage = [separatorImage resizableImageWithCapInsets:(UIEdgeInsets){1.0f, 0.0f, 1.0f, 0.0f} resizingMode:UIImageResizingModeTile];
    separatorImage = [separatorImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    return separatorImage;
}

- (NSMapTable *)imageTable {
    // The map table is a global instance that allows all instances of
    // segmented controls to efficiently share the same images.

    // The images themselves are weakly referenced, so they will be cleaned
    // up from memory when all segmented controls using them are deallocated.

    if (_imageTable) { return _imageTable; }
    _imageTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                        valueOptions:NSPointerFunctionsWeakMemory];
    return _imageTable;
}

@end
