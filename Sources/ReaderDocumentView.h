//
//  ReaderDocumentView.h
//  BoardRoom
//
//  Created by Edward Rudd on 9/21/11.
//  Copyright 2011 OutOfOrder.cc. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "ReaderDocument.h"
#include "ReaderContentView.h"


@protocol ReaderDocumentViewDelegate;

@interface ReaderDocumentView : UIView <UIScrollViewDelegate,UIGestureRecognizerDelegate,ReaderContentViewDelegate> {

}

// The actual document to render.  Will restore to the stored "last viewed" page
@property (nonatomic, retain) ReaderDocument *document;
// The size of the "tap area" .. default is 48
@property (nonatomic, assign) float tapAreaSize;
// The current page that the PDF viewer is displaying.  OR assign to change pages
@property (nonatomic,assign) NSInteger currentPage;
// The delegate to pass of certain events too
@property (nonatomic,assign) id<ReaderDocumentViewDelegate> delegate;

@end

@protocol ReaderDocumentViewDelegate <NSObject>

@optional
- (void)readerDocumentView:(ReaderDocumentView *)documentView didTapForToolbar:(BOOL)hidden;
- (void)readerDocumentView:(ReaderDocumentView *)documentView didChangeToPage:(NSInteger)page;
@end

