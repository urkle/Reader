//
//	ReaderPagebarView.h
//	Reader v2.4.0
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright ¬© 2011 Julius Oklamcak. All rights reserved.
//
//	This work is being made available under a Creative Commons Attribution license:
//		¬´http://creativecommons.org/licenses/by/3.0/¬ª
//	You are free to use this work and any derivatives of this work in personal and/or
//	commercial products and projects as long as the above copyright is maintained and
//	the original author is attributed.
//

#import <UIKit/UIKit.h>

#import "ReaderThumbView.h"

@class ReaderPagebarView;
@class ReaderTrackControlView;
@class ReaderPagebarThumbView;
@class ReaderDocument;

@protocol ReaderPagebarViewDelegate <NSObject>

@required // Delegate protocols

- (void)pagebar:(ReaderPagebarView *)pagebar gotoPage:(NSInteger)page;

@optional

- (void)pagebarDidReceiveDoubleTap:(ReaderPagebarView *)pagebar;

@end

@interface ReaderPagebarView : UIView
{
@private // Instance variables

	ReaderDocument *document;

	ReaderTrackControlView *trackControl;

	NSMutableDictionary *miniThumbViews;

	ReaderPagebarThumbView *pageThumbView;

	UILabel *pageNumberLabel;

	UIView *pageNumberView;

	NSTimer *enableTimer;
	NSTimer *trackTimer;
    NSTimer *fadePageNumberTimer;
}

@property (nonatomic, assign, readwrite) id <ReaderPagebarViewDelegate> delegate;
@property (nonatomic, retain) ReaderDocument *document;
@property (nonatomic, assign) BOOL fadePageNumber;

- (id)initWithFrame:(CGRect)frame document:(ReaderDocument *)object;

- (void)updatePagebar;

@end

#pragma mark -

//
//	ReaderTrackControl class interface
//

@interface ReaderTrackControlView : UIControl
{
@private // Instance variables

	CGFloat _value;
}

@property (nonatomic, assign, readonly) CGFloat value;

@end

#pragma mark -

//
//	ReaderPagebarThumb class interface
//

@interface ReaderPagebarThumbView : ReaderThumbView
{
@private // Instance variables
}

- (id)initWithFrame:(CGRect)frame small:(BOOL)small;

@end
