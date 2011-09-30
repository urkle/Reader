//
//	ReaderMainPagebar.m
//	Reader v2.4.0
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright © 2011 Julius Oklamcak. All rights reserved.
//
//	This work is being made available under a Creative Commons Attribution license:
//		«http://creativecommons.org/licenses/by/3.0/»
//	You are free to use this work and any derivatives of this work in personal and/or
//	commercial products and projects as long as the above copyright is maintained and
//	the original author is attributed.
//

#import "ReaderMainPagebar.h"
#import "ReaderThumbCache.h"
#import "ReaderDocument.h"

#import <QuartzCore/QuartzCore.h>

@interface ReaderPagebarView(Private)
- (void)updatePagebarViews;
@end

@implementation ReaderMainPagebar

#pragma mark Properties

@synthesize pagebar = _pagebar;
@dynamic document;

- (ReaderDocument *)document
{
	return _pagebar.document;
}

- (void)setDocument:(ReaderDocument *)document
{
	_pagebar.document = document;
}

#pragma mark ReaderMainPagebar class methods

+ (Class)layerClass
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [CAGradientLayer class];
}

#pragma mark ReaderMainPagebar instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [self initWithFrame:frame document:nil];
}

- (void)standardInit
{
	self.autoresizesSubviews = YES;
	self.userInteractionEnabled = YES;
	self.contentMode = UIViewContentModeRedraw;
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	self.backgroundColor = [UIColor clearColor];
	
	NSAssert(self.bounds.size.height >= 44, @"Height must be a minimum of 48");

	CAGradientLayer *layer = (CAGradientLayer *)self.layer;
	CGColorRef liteColor = [UIColor colorWithWhite:0.82f alpha:0.8f].CGColor;
	CGColorRef darkColor = [UIColor colorWithWhite:0.32f alpha:0.8f].CGColor;
	layer.colors = [NSArray arrayWithObjects:(id)liteColor, (id)darkColor, nil];
	
	CGRect shadowRect = self.bounds;
	shadowRect.size.height = 4.0f;
	shadowRect.origin.y -= shadowRect.size.height;

	_shadowView = [[ReaderPagebarShadow alloc] initWithFrame:shadowRect];
	[self addSubview:_shadowView];

    _pagebar = [[ReaderPagebarView alloc] initWithFrame: self.bounds];
    _pagebar.fadePageNumber = NO;
    [self addSubview:_pagebar];
}

- (id)initWithFrame:(CGRect)frame document:(ReaderDocument *)object
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self = [super initWithFrame:frame]))
	{
		[self standardInit];

		self.document = object; // Retain the document object for our use
	}

	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self standardInit];
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[_pagebar release], _pagebar = nil;

	[super dealloc];
}

- (void)updatePagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[_pagebar updatePagebar];
}

- (void)hidePagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.hidden == NO) // Only if visible
	{
		[UIView animateWithDuration:0.25 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.alpha = 0.0f;
			}
			completion:^(BOOL finished)
			{
				self.hidden = YES;
			}
		];
	}
}

- (void)showPagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.hidden == YES) // Only if hidden
	{
		[_pagebar updatePagebarViews]; // Update views first

		[UIView animateWithDuration:0.25 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.hidden = NO;
				self.alpha = 1.0f;
			}
			completion:NULL
		];
	}
}

@end

#pragma mark -

//
//	ReaderPagebarShadow class implementation
//

@implementation ReaderPagebarShadow

//#pragma mark Properties

//@synthesize ;

#pragma mark ReaderPagebarShadow class methods

+ (Class)layerClass
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [CAGradientLayer class];
}

#pragma mark ReaderPagebarShadow instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor clearColor];

		CAGradientLayer *layer = (CAGradientLayer *)self.layer;
		CGColorRef blackColor = [UIColor colorWithWhite:0.42f alpha:1.0f].CGColor;
		CGColorRef clearColor = [UIColor colorWithWhite:0.42f alpha:0.0f].CGColor;
		layer.colors = [NSArray arrayWithObjects:(id)clearColor, (id)blackColor, nil];
	}

	return self;
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[super dealloc];
}

@end
