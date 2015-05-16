//
//  PSMTabBarCell.m
//  PSMTabBarControl
//
//  Created by John Pannell on 10/13/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"
#import "PSMTabStyle.h"
#import "PSMProgressIndicator.h"
#import "PSMTabDragAssistant.h"
#import "FutureMethods.h"

static NSTimeInterval kHighlightAnimationDuration = 0.5;

@implementation PSMTabBarCell  {
    // sizing
    NSRect              _frame;
    NSSize              _stringSize;
    int                 _currentStep;
    BOOL                _isPlaceholder;

    // state
    int                 _tabState;
    NSTrackingRectTag   _closeButtonTrackingTag;    // left side tracking, if dragging
    NSTrackingRectTag   _cellTrackingTag;           // right side tracking, if dragging
    BOOL                _closeButtonOver;
    BOOL                _closeButtonPressed;
    PSMProgressIndicator *_indicator;
    BOOL                _isInOverflowMenu;
    BOOL                _hasCloseButton;
    BOOL                _hasIcon;
    int                 _count;

    //iTerm add-on
    NSColor             *_tabColor;
    NSString            *_modifierString;

    BOOL _isLast;
    NSTimeInterval _highlightChangeTime;
}

@synthesize isLast = _isLast;

#pragma mark -
#pragma mark Creation/Destruction
- (id)initWithControlView:(PSMTabBarControl *)controlView {
    if ((self = [super init])) {
        [self setControlView:controlView];
        _indicator = [[PSMProgressIndicator alloc] initWithFrame:NSMakeRect(0.0,0.0,kPSMTabBarIndicatorWidth,kPSMTabBarIndicatorWidth)];
        _indicator.delegate = controlView;
        [_indicator setAutoresizingMask:NSViewMinYMargin];
        _indicator.light = controlView.style.useLightControls;
        _hasCloseButton = YES;
        _modifierString = [@"" copy];
    }
    return self;
}

- (id)initPlaceholderWithFrame:(NSRect)frame expanded:(BOOL)value inControlView:(PSMTabBarControl *)controlView
{
    self = [super init];
    if (self) {
        [self setControlView:controlView];
        _isPlaceholder = YES;
        if (!value) {
            if ([controlView orientation] == PSMTabBarHorizontalOrientation) {
                frame.size.width = 0.0;
            } else {
                frame.size.height = 0.0;
            }
        }
        [self setFrame:frame];
        _closeButtonTrackingTag = 0;
        _cellTrackingTag = 0;
        _closeButtonOver = NO;
        _closeButtonPressed = NO;
        _indicator = nil;
        _hasCloseButton = YES;
        _count = 0;
        _tabColor = nil;
        _modifierString = [@"" copy];
        if (value) {
            [self setCurrentStep:(kPSMTabDragAnimationSteps - 1)];
        } else {
            [self setCurrentStep:0];
        }
    }
    return self;
}

- (void)dealloc
{
    [_modifierString release];
    [_indicator release];
    if (_tabColor)
        [_tabColor release];
    [super dealloc];
}

// we don't want this to be the first responder in the chain
- (BOOL)acceptsFirstResponder
{
  return NO;
}

#pragma mark -
#pragma mark Accessors

- (BOOL)closeButtonVisible {
    return !_isCloseButtonSuppressed || [self highlightAmount] > 0;
}

- (NSView<PSMTabBarControlProtocol> *)psmTabControlView {
    return (NSView<PSMTabBarControlProtocol> *)[self controlView];
}

- (NSTrackingRectTag)closeButtonTrackingTag
{
    return _closeButtonTrackingTag;
}

- (void)setCloseButtonTrackingTag:(NSTrackingRectTag)tag
{
    _closeButtonTrackingTag = tag;
}

- (NSTrackingRectTag)cellTrackingTag
{
    return _cellTrackingTag;
}

- (void)setCellTrackingTag:(NSTrackingRectTag)tag
{
    _cellTrackingTag = tag;
}

- (float)width
{
    return _frame.size.width;
}

- (NSRect)frame
{
    return _frame;
}

- (void)setFrame:(NSRect)rect
{
    _frame = rect;
}

- (void)setStringValue:(NSString *)aString
{
    [super setStringValue:aString];
    _stringSize = [[self attributedStringValue] size];
    // need to redisplay now - binding observation was too quick.
    [[self psmTabControlView] update:[[self psmTabControlView] automaticallyAnimates]];
}

- (NSSize)stringSize
{
    return _stringSize;
}

- (NSAttributedString *)attributedStringValue {
    id<PSMTabBarControlProtocol> control = [self psmTabControlView];
    id <PSMTabStyle> tabStyle = [control style];
    return [tabStyle attributedStringValueForTabCell:self];
}

- (int)tabState
{
    return _tabState;
}

- (void)setTabState:(int)state
{
    _tabState = state;
}

- (PSMProgressIndicator *)indicator
{
    return _indicator;
}

- (BOOL)isInOverflowMenu
{
    return _isInOverflowMenu;
}

- (void)setIsInOverflowMenu:(BOOL)value
{
    _isInOverflowMenu = value;
}

- (BOOL)closeButtonPressed
{
    return _closeButtonPressed;
}

- (void)setCloseButtonPressed:(BOOL)value
{
    _closeButtonPressed = value;
}

- (BOOL)closeButtonOver
{
    return _closeButtonOver;
}

- (void)setCloseButtonOver:(BOOL)value
{
    _closeButtonOver = value;
}

- (BOOL)hasCloseButton
{
    return _hasCloseButton;
}

- (void)setHasCloseButton:(BOOL)set
{
    _hasCloseButton = set;
}

- (BOOL)hasIcon
{
    return _hasIcon;
}

- (void)setHasIcon:(BOOL)value
{
    _hasIcon = value;
    [[self psmTabControlView] update:[[self psmTabControlView] automaticallyAnimates]]; // binding notice is too fast
}

- (int)count
{
    return _count;
}

- (void)setCount:(int)value
{
    _count = value;
    [[self psmTabControlView] update:[[self psmTabControlView] automaticallyAnimates]]; // binding notice is too fast
}

- (BOOL)isPlaceholder
{
    return _isPlaceholder;
}

- (void)setIsPlaceholder:(BOOL)value
{
    _isPlaceholder = value;
}

- (int)currentStep
{
    return _currentStep;
}

- (void)setCurrentStep:(int)value
{
    if(value < 0)
        value = 0;

    if(value > (kPSMTabDragAnimationSteps - 1))
        value = (kPSMTabDragAnimationSteps - 1);

    _currentStep = value;
}

- (NSString*)modifierString
{
    return _modifierString;
}

- (void)setModifierString:(NSString*)value
{
    [_modifierString autorelease];
    _modifierString = [value copy];
}

#pragma mark -
#pragma mark Bindings

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // the progress indicator, label, icon, or count has changed - redraw the control view
    [[self psmTabControlView] update:[[self psmTabControlView] automaticallyAnimates]];
}

#pragma mark -
#pragma mark Component Attributes

- (NSRect)indicatorRectForFrame:(NSRect)cellFrame
{
    return [[[self psmTabControlView] style] indicatorRectForTabCell:self];
}

- (NSRect)closeButtonRectForFrame:(NSRect)cellFrame
{
    return [[[self psmTabControlView] style] closeButtonRectForTabCell:self];
}

- (float)minimumWidthOfCell
{
    return [[[self psmTabControlView] style] minimumWidthOfTabCell:self];
}

- (float)desiredWidthOfCell
{
    return [[[self psmTabControlView] style] desiredWidthOfTabCell:self];
}

#pragma mark -
#pragma mark Drawing

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (_isPlaceholder){
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
        NSRectFillUsingOperation(cellFrame, NSCompositeSourceAtop);
        return;
    }

    [[[self psmTabControlView] style] drawTabCell:self highlightAmount:[self highlightAmount]];
}

- (CGFloat)highlightAmount {
    NSTimeInterval timeSinceChange = [NSDate timeIntervalSinceReferenceDate] - _highlightChangeTime;
    CGFloat amount = self.highlighted ? 1 : 0;
    if (timeSinceChange < kHighlightAnimationDuration) {
        CGFloat alpha = timeSinceChange / kHighlightAnimationDuration;
        return amount * alpha + (1 - amount) * (1 - alpha);
    } else {
        return amount;
    }
}

#pragma mark -
#pragma mark Tracking

- (void)mouseEntered:(NSEvent *)theEvent
{
    // check for which tag
    if ([theEvent trackingNumber] == _closeButtonTrackingTag) {
        _closeButtonOver = YES;
    }
    if ([theEvent trackingNumber] == _cellTrackingTag) {
        [self setHighlighted:YES];
        [[self psmTabControlView] setNeedsDisplay:NO];
    }

    //tell the control we only need to redraw the affected tab
    [[self psmTabControlView] setNeedsDisplayInRect:NSInsetRect([self frame], -2, -2)];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    // check for which tag
    if ([theEvent trackingNumber] == _closeButtonTrackingTag) {
        _closeButtonOver = NO;
    }

    if ([theEvent trackingNumber] == _cellTrackingTag) {
        [self setHighlighted:NO];
        [[self psmTabControlView] setNeedsDisplay:NO];
    }

    //tell the control we only need to redraw the affected tab
    [[self psmTabControlView] setNeedsDisplayInRect:NSInsetRect([self frame], -2, -2)];
}

#pragma mark -
#pragma mark Drag Support

- (NSImage *)dragImage
{
    NSRect cellFrame =
        [[[self psmTabControlView] style] dragRectForTabCell:self
                                                 orientation:[[self psmTabControlView] orientation]];

    [[self psmTabControlView] lockFocus];
    NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:cellFrame] autorelease];
    [[self psmTabControlView] unlockFocus];
    NSImage *image = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
    [image addRepresentation:rep];
    NSImage *returnImage = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
    [returnImage lockFocus];
    [image drawAtPoint:NSZeroPoint
              fromRect:NSZeroRect
             operation:NSCompositeSourceOver
              fraction:1.0];
    [returnImage unlockFocus];
    if (![[self indicator] isHidden]){
        NSImage *piImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"pi"]];
        [returnImage lockFocus];
        NSPoint indicatorPoint = NSMakePoint([self frame].size.width - MARGIN_X - kPSMTabBarIndicatorWidth, MARGIN_Y);
        [piImage drawAtPoint:indicatorPoint
                    fromRect:NSZeroRect
                   operation:NSCompositeSourceOver
                    fraction:1.0];
        [returnImage unlockFocus];
        [piImage release];
    }
    return returnImage;
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeRect:_frame forKey:@"frame"];
        [aCoder encodeSize:_stringSize forKey:@"stringSize"];
        [aCoder encodeInt:_currentStep forKey:@"currentStep"];
        [aCoder encodeBool:_isPlaceholder forKey:@"isPlaceholder"];
        [aCoder encodeInt:_tabState forKey:@"tabState"];
        [aCoder encodeInt:_closeButtonTrackingTag forKey:@"closeButtonTrackingTag"];
        [aCoder encodeInt:_cellTrackingTag forKey:@"cellTrackingTag"];
        [aCoder encodeBool:_closeButtonOver forKey:@"closeButtonOver"];
        [aCoder encodeBool:_closeButtonPressed forKey:@"closeButtonPressed"];
        [aCoder encodeObject:_indicator forKey:@"indicator"];
        [aCoder encodeBool:_isInOverflowMenu forKey:@"isInOverflowMenu"];
        [aCoder encodeBool:_hasCloseButton forKey:@"hasCloseButton"];
        [aCoder encodeBool:_isCloseButtonSuppressed forKey:@"isCloseButtonSuppressed"];
        [aCoder encodeBool:_hasIcon forKey:@"hasIcon"];
        [aCoder encodeInt:_count forKey:@"count"];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        if ([aDecoder allowsKeyedCoding]) {
            _frame = [aDecoder decodeRectForKey:@"frame"];
            NSLog(@"decoding cell");
            _stringSize = [aDecoder decodeSizeForKey:@"stringSize"];
            _currentStep = [aDecoder decodeIntForKey:@"currentStep"];
            _isPlaceholder = [aDecoder decodeBoolForKey:@"isPlaceholder"];
            _tabState = [aDecoder decodeIntForKey:@"tabState"];
            _closeButtonTrackingTag = [aDecoder decodeIntForKey:@"closeButtonTrackingTag"];
            _cellTrackingTag = [aDecoder decodeIntForKey:@"cellTrackingTag"];
            _closeButtonOver = [aDecoder decodeBoolForKey:@"closeButtonOver"];
            _closeButtonPressed = [aDecoder decodeBoolForKey:@"closeButtonPressed"];
            _indicator = [[aDecoder decodeObjectForKey:@"indicator"] retain];
            _isInOverflowMenu = [aDecoder decodeBoolForKey:@"isInOverflowMenu"];
            _hasCloseButton = [aDecoder decodeBoolForKey:@"hasCloseButton"];
            _isCloseButtonSuppressed = [aDecoder decodeBoolForKey:@"isCloseButtonSuppressed"];
            _hasIcon = [aDecoder decodeBoolForKey:@"hasIcon"];
            _count = [aDecoder decodeIntForKey:@"count"];
        }
    }
    return self;
}

#pragma mark -
#pragma mark Accessibility

- (BOOL)accessibilityIsIgnored {
    return NO;
}

- (NSArray*)accessibilityAttributeNames
{
    static NSArray *attributes = nil;
    if (!attributes) {
        NSSet *set = [NSSet setWithArray:[super accessibilityAttributeNames]];
        set = [set setByAddingObjectsFromArray:[NSArray arrayWithObjects:
                                                   NSAccessibilityTitleAttribute,
                                                   NSAccessibilityValueAttribute,
                                                   nil]];
        attributes = [[set allObjects] retain];
    }
    return attributes;
}


- (id)accessibilityAttributeValue:(NSString *)attribute {
    id attributeValue = nil;

    if ([attribute isEqualToString: NSAccessibilityRoleAttribute]) {
        attributeValue = NSAccessibilityRadioButtonRole;
    } else if ([attribute isEqualToString: NSAccessibilityHelpAttribute]) {
        id<PSMTabBarControlDelegate> controlViewDelegate = [[self psmTabControlView] delegate];
        if ([controlViewDelegate respondsToSelector:@selector(accessibilityStringForTabView:objectCount:)]) {
            attributeValue = [NSString stringWithFormat:@"%@, %i %@",
                              [self stringValue], [self count],
                              [controlViewDelegate accessibilityStringForTabView:[[self psmTabControlView] tabView] objectCount:[self count]]];
        } else {
            attributeValue = [self stringValue];
        }
    } else if ([attribute isEqualToString:NSAccessibilityPositionAttribute] ||
               [attribute isEqualToString:NSAccessibilitySizeAttribute]) {
        NSRect rect = [self frame];
        rect = [[self controlView] convertRect:rect toView:nil];
        rect = [[[self controlView] window] convertRectToScreen:rect];
        if ([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
            attributeValue = [NSValue valueWithPoint:rect.origin];
        } else {
            attributeValue = [NSValue valueWithSize:rect.size];
        }
    } else if ([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
        attributeValue = [self stringValue];
    } else if ([attribute isEqualToString: NSAccessibilityValueAttribute]) {
        attributeValue = [NSNumber numberWithBool:([self tabState] == 2)];
    } else {
        attributeValue = [super accessibilityAttributeValue:attribute];
    }

    return attributeValue;
}

- (NSArray *)accessibilityActionNames
{
    static NSArray *actions;

    if (!actions) {
        actions = [[NSArray alloc] initWithObjects:NSAccessibilityPressAction, nil];
    }
    return actions;
}

- (NSString *)accessibilityActionDescription:(NSString *)action
{
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
    return NSAccessibilityActionDescription(action);
#else
    return nil;
#endif
}

- (void)accessibilityPerformAction:(NSString *)action {
    if ([action isEqualToString:NSAccessibilityPressAction]) {
        // this tab was selected
        [[self psmTabControlView] performSelector:@selector(tabClick:)
                                       withObject:self];
    }
}

- (id)accessibilityHitTest:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement:(NSPoint)point {
    return NSAccessibilityUnignoredAncestor(self);
}

#pragma mark - iTerm Add-on

- (NSColor*)tabColor
{
    return _tabColor;
}

- (void)setTabColor:(NSColor *)aColor
{
    if (_tabColor != aColor) {
        if (_tabColor) {
            [_tabColor release];
        }
        _tabColor = aColor ? [aColor retain] : nil;
    }
}

- (void)updateForStyle {
    _indicator.light = [self psmTabControlView].style.useLightControls;
}

- (void)updateHighlight {
    if (self.isHighlighted) {
        NSPoint mouseLocationInScreenCoords = [NSEvent mouseLocation];
        NSRect rectInScreenCoords;
        rectInScreenCoords.origin = mouseLocationInScreenCoords;
        rectInScreenCoords.size = NSZeroSize;
        NSPoint mouseLocationInWindowCoords = [self.controlView.window convertRectFromScreen:rectInScreenCoords].origin;
        NSPoint mouseLocationInViewCoords = [self.controlView convertPoint:mouseLocationInWindowCoords
                                                                  fromView:nil];
        if (!NSPointInRect(mouseLocationInViewCoords, self.frame)) {
            self.highlighted = NO;
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    BOOL wasHighlighted = self.isHighlighted;
    [super setHighlighted:highlighted];
    if (highlighted != wasHighlighted) {
        _highlightChangeTime = [NSDate timeIntervalSinceReferenceDate];
        [self.controlView retain];
        [NSTimer scheduledTimerWithTimeInterval:1/60.0
                                         target:self
                                       selector:@selector(redrawHighlight:)
                                       userInfo:nil
                                        repeats:YES];
    }
}

- (void)redrawHighlight:(NSTimer *)timer {
    [self.controlView setNeedsDisplayInRect:self.frame];
    if ([NSDate timeIntervalSinceReferenceDate] - _highlightChangeTime > kHighlightAnimationDuration) {
        [self.controlView release];
        [timer invalidate];
    }
}

@end
