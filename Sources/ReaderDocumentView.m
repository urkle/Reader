//
//  ReaderDocumentView.m
//  BoardRoom
//
//  Created by Edward Rudd on 9/21/11.
//  Copyright 2011 OutOfOrder.cc. All rights reserved.
//

#import "ReaderDocumentView.h"

#import "ReaderThumbCache.h"
#import "ReaderScrollView.h"

@interface ReaderDocumentView()
@property (nonatomic,retain) ReaderScrollView* scrollView;
@property (nonatomic,retain) NSMutableDictionary* contentViews;
@property (nonatomic,assign) CGSize lastAppearSize;
@property (nonatomic,retain) NSDate *lastHideTime;
@property (nonatomic,assign,getter = isVisible) BOOL visible;

- (void)loadDocument;
- (void)showDocument:(id)object;
- (void)showDocumentPage:(NSInteger)page;
- (void)updateScrollViewContentSize;
- (void)updateScrollViewContentViews;

@end

@implementation ReaderDocumentView

#pragma mark - Constants

#define PAGING_VIEWS 3

#pragma mark - Properties

@synthesize scrollView = _scrollView;
@synthesize contentViews = _contentViews;
@synthesize lastAppearSize = _lastAppearSize;
@synthesize lastHideTime = _lastHideTime;
@synthesize visible = _visible;

// Public properties
@synthesize tapAreaSize = _tapAreaSize;
@synthesize document = _document;
@synthesize delegate = _delegate;
@synthesize currentPage = _currentPage;
@synthesize pageBar = _pageBar;
@synthesize togglePageBar = _togglePageBar;

- (void)setDocument:(ReaderDocument *)document
{
	// Save the state of the current document
	[_document saveReaderDocument];
	[_document release];
	_document = [document retain];
	[self loadDocument];
	if (_pageBar) {
		_pageBar.document = document;
	}
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    [self showDocumentPage:currentPage];
}

- (void)setPageBar:(ReaderPagebarView *)pageBar
{
	if (_pageBar) {
		if (_pageBar.delegate == self) {
			_pageBar.delegate = nil;
		}
	}
	[_pageBar release];
	_pageBar = [pageBar retain];
	if (_pageBar.delegate == nil) {
		_pageBar.delegate = self;
	}
}

#pragma mark - Utility Methods

- (void)loadDocument
{
	// Rebuild cache
	[ReaderThumbCache createThumbCacheWithGUID:_document.guid];
	[_contentViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[_contentViews removeObjectForKey:key];
		ReaderContentView *contentView = obj;
		[contentView removeFromSuperview];
	}];
	_currentPage = 0;
	[self showDocument:nil];
}

- (void)showDocumentPage:(NSInteger)page
{
	if (page != _currentPage) // Only if different
	{
		NSInteger minValue; NSInteger maxValue;
		NSInteger maxPage = [_document.pageCount integerValue];
		NSInteger minPage = 1;

		if ((page < minPage) || (page > maxPage)) return;

		if (maxPage <= PAGING_VIEWS) // Few pages
		{
			minValue = minPage;
			maxValue = maxPage;
		}
		else // Handle more pages
		{
			minValue = (page - 1);
			maxValue = (page + 1);

			if (minValue < minPage)
				{minValue++; maxValue++;}
			else
				if (maxValue > maxPage)
				{minValue--; maxValue--;}
		}

		NSMutableIndexSet *newPageSet = [NSMutableIndexSet new];

		NSMutableDictionary *unusedViews = [_contentViews mutableCopy];

		CGRect viewRect = CGRectZero; viewRect.size = _scrollView.bounds.size;

		for (NSInteger number = minValue; number <= maxValue; number++)
		{
			NSNumber *key = [NSNumber numberWithInteger:number]; // # key

			ReaderContentView *contentView = [_contentViews objectForKey:key];

			if (contentView == nil) // Create a brand new document content view
			{
				NSURL *fileURL = _document.fileURL; NSString *phrase = _document.password; // Document properties

				contentView = [[ReaderContentView alloc] initWithFrame:viewRect fileURL:fileURL page:number password:phrase];

				[_scrollView addSubview:contentView]; [_contentViews setObject:contentView forKey:key];

				contentView.delegate = self; [contentView release]; [newPageSet addIndex:number];
			}
			else // Reposition the existing content view
			{
				contentView.frame = viewRect; [contentView zoomReset];

				[unusedViews removeObjectForKey:key];
			}

			viewRect.origin.x += viewRect.size.width;
		}

		[unusedViews enumerateKeysAndObjectsUsingBlock: // Remove unused views
		 ^(id key, id object, BOOL *stop)
		 {
			 [_contentViews removeObjectForKey:key];

			 ReaderContentView *contentView = object;

			 [contentView removeFromSuperview];
		 }
		 ];

		[unusedViews release], unusedViews = nil; // Release unused views

		CGFloat viewWidthX1 = viewRect.size.width;
		CGFloat viewWidthX2 = (viewWidthX1 * 2.0f);

		CGPoint contentOffset = CGPointZero;

		if (maxPage >= PAGING_VIEWS)
		{
			if (page == maxPage)
				contentOffset.x = viewWidthX2;
			else
				if (page != minPage)
					contentOffset.x = viewWidthX1;
		}
		else
			if (page == (PAGING_VIEWS - 1))
				contentOffset.x = viewWidthX1;

		if (CGPointEqualToPoint(_scrollView.contentOffset, contentOffset) == false)
		{
			_scrollView.contentOffset = contentOffset; // Update content offset
		}

		if ([_document.pageNumber integerValue] != page) // Only if different
		{
			_document.pageNumber = [NSNumber numberWithInteger:page]; // Update page number
		}

		NSURL *fileURL = _document.fileURL; NSString *phrase = _document.password; NSString *guid = _document.guid;

		if ([newPageSet containsIndex:page] == YES) // Preview visible page first
		{
			NSNumber *key = [NSNumber numberWithInteger:page]; // # key

			ReaderContentView *targetView = [_contentViews objectForKey:key];

			[targetView showPageThumb:fileURL page:page password:phrase guid:guid];

			[newPageSet removeIndex:page]; // Remove visible page from set
		}

		[newPageSet enumerateIndexesWithOptions:NSEnumerationReverse usingBlock: // Show previews
		 ^(NSUInteger number, BOOL *stop)
		 {
			 NSNumber *key = [NSNumber numberWithInteger:number]; // # key

			 ReaderContentView *targetView = [_contentViews objectForKey:key];

			 [targetView showPageThumb:fileURL page:number password:phrase guid:guid];
		 }
		 ];

		[newPageSet release], newPageSet = nil; // Release new page set

		if (_delegate && [_delegate respondsToSelector:@selector(readerDocumentView:didChangeToPage:)]) {
			[_delegate readerDocumentView:self didChangeToPage:page];
		}
		if (_pageBar) {
			[_pageBar updatePagebar];
		}
		_currentPage = page; // Track current page number
	}
}

- (void)showDocument:(id)object
{
	[self updateScrollViewContentSize]; // Set content size

	[self showDocumentPage:[_document.pageNumber integerValue]]; // Show

	_document.lastOpen = [NSDate date]; // Update last opened date

	_visible = YES; // iOS present modal bodge
}

- (void)updateScrollViewContentSize
{
	NSInteger count = [_document.pageCount integerValue];

	if (count > PAGING_VIEWS) count = PAGING_VIEWS; // Limit

	CGFloat contentHeight = _scrollView.bounds.size.height;

	CGFloat contentWidth = (_scrollView.bounds.size.width * count);

	_scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (void)updateScrollViewContentViews
{
	[self updateScrollViewContentSize]; // Update the content size

	NSMutableIndexSet *pageSet = [NSMutableIndexSet indexSet]; // Page set

	[_contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
	 ^(id key, id object, BOOL *stop)
	 {
		 ReaderContentView *contentView = object; [pageSet addIndex:contentView.tag];
	 }
	 ];

	__block CGRect viewRect = CGRectZero; viewRect.size = _scrollView.bounds.size;

	__block CGPoint contentOffset = CGPointZero; NSInteger page = [_document.pageNumber integerValue];

	[pageSet enumerateIndexesUsingBlock: // Enumerate page number set
	 ^(NSUInteger number, BOOL *stop)
	 {
		 NSNumber *key = [NSNumber numberWithInteger:number]; // # key

		 ReaderContentView *contentView = [_contentViews objectForKey:key];

		 contentView.frame = viewRect; if (page == number) contentOffset = viewRect.origin;

		 viewRect.origin.x += viewRect.size.width; // Next view frame position
	 }
	 ];

	if (CGPointEqualToPoint(_scrollView.contentOffset, contentOffset) == false)
	{
		_scrollView.contentOffset = contentOffset; // Update content offset
	}
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	__block NSInteger page = 0;

	CGFloat contentOffsetX = scrollView.contentOffset.x;

	[_contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
	 ^(id key, id object, BOOL *stop)
	 {
		 ReaderContentView *contentView = object;

		 if (contentView.frame.origin.x == contentOffsetX)
		 {
			 page = contentView.tag; *stop = YES;
		 }
	 }
	 ];

	if (page != 0) [self showDocumentPage:page]; // Show the page
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	[self showDocumentPage:_scrollView.tag]; // Show page

	_scrollView.tag = 0; // Clear page number tag
}

#pragma mark - ReaderContentViewDelegate methods

- (void)scrollViewTouchesBegan:(UIScrollView *)scrollView touches:(NSSet *)touches
{
	if (_delegate || (_pageBar && _togglePageBar)) {
		if (touches.count == 1) // Single touches only
		{
			UITouch *touch = [touches anyObject]; // Touch info

			CGPoint point = [touch locationInView:self]; // Touch location

			CGRect areaRect = CGRectInset(self.bounds, _tapAreaSize, _tapAreaSize);

			if (CGRectContainsPoint(areaRect, point) == false) return;
		}
		if (_delegate && [_delegate respondsToSelector:@selector(readerDocumentView:didTapForToolbar:)]) {
			[_delegate readerDocumentView:self didTapForToolbar:YES];
		}

		self.lastHideTime = [NSDate date];
	}
}

#pragma mark ReaderMainPagebarDelegate methods

- (void)pagebar:(ReaderPagebarView *)pagebar gotoPage:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self showDocumentPage:page]; // Show the page
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
	if ([touch.view isMemberOfClass:[ReaderScrollView class]]) return YES;

	return NO;
}

#pragma mark - UIGestureRecognizer action methods

- (void)decrementPageNumber
{
	if (_scrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [_document.pageNumber integerValue];
		NSInteger maxPage = [_document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != minPage))
		{
			CGPoint contentOffset = _scrollView.contentOffset;

			contentOffset.x -= _scrollView.bounds.size.width; // -= 1

			[_scrollView setContentOffset:contentOffset animated:YES];

			_scrollView.tag = (page - 1); // Decrement page number
		}
	}
}

- (void)incrementPageNumber
{
	if (_scrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [_document.pageNumber integerValue];
		NSInteger maxPage = [_document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != maxPage))
		{
			CGPoint contentOffset = _scrollView.contentOffset;

			contentOffset.x += _scrollView.bounds.size.width; // += 1

			[_scrollView setContentOffset:contentOffset animated:YES];

			_scrollView.tag = (page + 1); // Increment page number
		}
	}
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect areaRect = CGRectInset(viewRect, _tapAreaSize, 0.0f); // Area

		if (CGRectContainsPoint(areaRect, point)) // Single tap is inside the area
		{
			NSInteger page = [_document.pageNumber integerValue]; // Current page #

			NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			ReaderContentView *targetView = [_contentViews objectForKey:key];

			id target = [targetView singleTap:recognizer]; // Process tap

			if (target != nil) // Handle the returned target object
			{
				if ([target isKindOfClass:[NSURL class]]) // Open a URL
				{
					[[UIApplication sharedApplication] openURL:target];
				}
				else // Not a URL, so check for other possible object type
				{
					if ([target isKindOfClass:[NSNumber class]]) // Goto page
					{
						NSInteger value = [target integerValue]; // Number

						[self showDocumentPage:value]; // Show the page
					}
				}
			}
			else // Nothing active tapped in the target content view
			{
				if (_delegate || (_pageBar && _togglePageBar)) {
					if ([_lastHideTime timeIntervalSinceNow] < -0.75) {
						if (_delegate && [_delegate respondsToSelector:@selector(readerDocumentView:didTapForToolbar:)]) {
							[_delegate readerDocumentView:self didTapForToolbar:NO];
						}
					}
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = _tapAreaSize;
		nextPageRect.origin.x = (viewRect.size.width - _tapAreaSize);

		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = _tapAreaSize;

		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect zoomArea = CGRectInset(viewRect, _tapAreaSize, _tapAreaSize);

		if (CGRectContainsPoint(zoomArea, point)) // Double tap is in the zoom area
		{
			NSInteger page = [_document.pageNumber integerValue]; // Current page #

			NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			ReaderContentView *targetView = [_contentViews objectForKey:key];

			switch (recognizer.numberOfTouchesRequired) // Touches count
			{
				case 1: // One finger double tap: zoom ++
				{
					[targetView zoomIncrement]; break;
				}

				case 2: // Two finger double tap: zoom --
				{
					[targetView zoomDecrement]; break;
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = _tapAreaSize;
		nextPageRect.origin.x = (viewRect.size.width - _tapAreaSize);

		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = _tapAreaSize;

		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

#pragma mark - View handling

- (void)layoutSubviews
{
	if (CGSizeEqualToSize(_lastAppearSize, self.bounds.size) == false) {
		_lastAppearSize = self.bounds.size;
		[self updateScrollViewContentViews];
	}
}

#pragma mark - Memory Lifecycle

- (void)standardInit
{
	self.togglePageBar = YES;
	self.lastHideTime = [NSDate date];
	self.tapAreaSize = 48.0f;
	self.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];

	CGRect viewRect = self.bounds;

	_scrollView = [[ReaderScrollView alloc] initWithFrame:viewRect];
	// Should probably go inside the readerScrollView class
	_scrollView.scrollsToTop = NO;
	_scrollView.pagingEnabled = YES;
	_scrollView.delaysContentTouches = NO;
	_scrollView.showsVerticalScrollIndicator = NO;
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.contentMode = UIViewContentModeRedraw;
	_scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_scrollView.backgroundColor = [UIColor clearColor];
	_scrollView.userInteractionEnabled = YES;
	_scrollView.autoresizesSubviews = NO;

    _scrollView.delegate = self;
	[self addSubview:_scrollView];

	UITapGestureRecognizer *singleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTapOne.numberOfTouchesRequired = 1; singleTapOne.numberOfTapsRequired = 1; singleTapOne.delegate = self;

	UITapGestureRecognizer *doubleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapOne.numberOfTouchesRequired = 1; doubleTapOne.numberOfTapsRequired = 2; doubleTapOne.delegate = self;

	UITapGestureRecognizer *doubleTapTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapTwo.numberOfTouchesRequired = 2; doubleTapTwo.numberOfTapsRequired = 2; doubleTapTwo.delegate = self;

	[singleTapOne requireGestureRecognizerToFail:doubleTapOne]; // Single tap requires double tap to fail

	[self addGestureRecognizer:singleTapOne]; [singleTapOne release];
	[self addGestureRecognizer:doubleTapOne]; [doubleTapOne release];
	[self addGestureRecognizer:doubleTapTwo]; [doubleTapTwo release];

	_contentViews = [NSMutableDictionary new];

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(saveReaderDocument:) name:UIApplicationWillTerminateNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(saveReaderDocument:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self standardInit];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_scrollView release];
	[_lastHideTime release];
	[_contentViews release];
	[_document release];
	[_pageBar release];
	[super dealloc];
}

- (void)saveReaderDocument:(NSNotification *)notification
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[_document saveReaderDocument]; // Save any ReaderDocument object changes
}
@end
