//
//  TTPredicateEditorViewController.m
//
//  Created by Rainer Burgstaller on 21.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TTPredicateEditorViewController.h"
#import <BWToolkitFramework/BWSplitView.h>
@implementation TTPredicateEditorViewController

@synthesize delegate = _delegate;

-(void)editorFrameDidChange:(NSNotification*)notification {
    BWSplitView *split = (BWSplitView*) _container.superview;
    BOOL collapsed = [split collapsibleSubviewCollapsed];
    if (collapsed) {
        return;
    }
//    NSRect editorFrame = _editor.frame;
    NSInteger editorHeight = [_editor numberOfRows] * [_editor rowHeight];
    
    NSLog(@"Have notification height: %d",editorHeight);
    NSRect frame = _container.frame;
    frame.size.height = editorHeight + 2;
    [_container setFrame:frame];
}

-(void) awakeFromNib {    
    [_editor addRow:self];
    [_editor addRow:self];
//    [_editor setPostsFrameChangedNotifications:YES];
/*    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(editorFrameDidChange:) 
                                                 name:NSViewFrameDidChangeNotification 
                                               object:_editor];
*/
    _container = [[[_editor enclosingScrollView] superview] retain]; 
    // cause a layout
    [self editorFrameDidChange:nil];
}

// -------------------------------------------------------------------------------
//	createNewSearchForPredicate:predicate:withTitle
//
// -------------------------------------------------------------------------------
- (void)createNewSearchForPredicate:(NSPredicate*)predicate withTitle:(NSString*)title
{
    if (predicate != nil)
	{
/*          
		// always search for items in the Address Book
		NSPredicate* addrBookPredicate = [NSPredicate predicateWithFormat:@"(kMDItemKind = 'Address Book Person Data')"];
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:addrBookPredicate, predicate, nil]];
*/
        [_delegate predicateSelected:predicate];
    }
}

// -------------------------------------------------------------------------------
//	predicateEditorChanged:sender
//
//  This method gets called whenever the predicate editor changes.
//	It is the action of our predicate editor and the single plate for all our updates.
//	
//	We need to do potentially three things:
//		1) Fire off a search if the user hits enter.
//		2) Add some rows if the user deleted all of them, so the user isn't left without any rows.
//		3) Resize the window if the number of rows changed (the user hit + or -).
// -------------------------------------------------------------------------------
-(IBAction) predicateEditorChanged:(id)sender {
    // check NSApp currentEvent for the return key
    NSEvent* event = [NSApp currentEvent];
    if ([event type] == NSKeyDown)
	{
		NSString* characters = [event characters];
		if ([characters length] > 0 && [characters characterAtIndex:0] == 0x0D)
		{
			// get the predicat, which is the object value of our view
			NSPredicate* predicate = [_editor objectValue];
			
			if (predicate)
			{
				static NSInteger searchIndex = 0;
				NSString* title = NSLocalizedString(@"Search #%ld", @"Search title");
				[self createNewSearchForPredicate:predicate withTitle:[NSString stringWithFormat:title, (long)++searchIndex]];
			}
		}
    }
    
    
    // if the user deleted the first row, then add it again - no sense leaving the user with no rows
    if ([_editor numberOfRows] == 0)
		[_editor addRow:self];
    
    [self editorFrameDidChange:nil];
    return;
    
    
    
    
    /* Get the new number of rows, which tells us the change in height.  Note that we can't just get the view frame, because it's currently animating - this method is called before the animation is finished. */
    NSInteger newRowCount = [_editor numberOfRows];
    
    /* If there's no change in row count, there's no need to resize anything */
    if (newRowCount == _previousRowCount) return;
    
    /* The autoresizing masks, by default, allows the outline view to grow and keeps the predicate editor fixed.  We need to temporarily grow the predicate editor, and keep the outline view fixed, so we have to change the autoresizing masks.  Save off the old ones; we'll restore them after changing the window frame. */
/*    NSScrollView *outlineScrollView = [resultsOutlineView enclosingScrollView];
    NSUInteger oldOutlineViewMask = [outlineScrollView autoresizingMask];
  */  
    NSScrollView *predicateEditorScrollView = [_editor enclosingScrollView];
    NSUInteger oldPredicateEditorViewMask = [predicateEditorScrollView autoresizingMask];
    
//    [outlineScrollView setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    [predicateEditorScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    /* Determine whether we're growing or shrinking... */
    BOOL growing = (newRowCount > _previousRowCount);
    
    /* And figure out by how much.  Sizes must contain nonnegative values, which is why we avoid negative floats here. */
    CGFloat heightDifference = fabs(([_editor rowHeight]+2) * (newRowCount - _previousRowCount));
    
    /* Convert the size to window coordinates.  This is very important!  If we didn't do this, we would break under scale factors other than 1.  We don't care about the horizontal dimension, so leave that as 0. */
    NSSize sizeChange = [_editor convertSize:NSMakeSize(0, heightDifference) toView:nil];
    NSView *superV = [predicateEditorScrollView superview];
    NSRect superFrame = [superV frame];
    superFrame.size.height += growing ? sizeChange.height : -sizeChange.height;
    superFrame.origin.y -= growing ? sizeChange.height : -sizeChange.height;
    [superV setFrame:superFrame];
    /* Change the window frame size.  If we're growing, the height goes up and the origin goes down (corresponding to growing down).  If we're shrinking, the height goes down and the origin goes up. */
/*    NSRect windowFrame = [window frame];
    windowFrame.size.height += growing ? sizeChange.height : -sizeChange.height;
    windowFrame.origin.y -= growing ? sizeChange.height : -sizeChange.height;
    [window setFrame:windowFrame display:YES animate:YES];
    
    /* restore the autoresizing mask */
  //  [outlineScrollView setAutoresizingMask:oldOutlineViewMask];
  
    [predicateEditorScrollView setAutoresizingMask:oldPredicateEditorViewMask];
    
    /* record our new row count */
    _previousRowCount = newRowCount;    
}

-(IBAction) pressedSubmitPredicate:(id)sender {
    [self createNewSearchForPredicate:[_editor predicate] withTitle:@"New Search"];
}

-(void) dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_editor];
    [_container release];
    [super dealloc];
}
@end
