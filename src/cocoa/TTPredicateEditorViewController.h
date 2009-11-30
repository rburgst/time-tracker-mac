//
//  TTPredicateEditorViewController.h
//
//  Created by Rainer Burgstaller on 21.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol TTPredicateEditorDelegate

-(void) predicateSelected:(NSPredicate*)predicate;

@end

@interface TTPredicateEditorViewController : NSViewController {
    IBOutlet NSPredicateEditor *_editor;
    IBOutlet id<TTPredicateEditorDelegate> _delegate;
    IBOutlet NSView *siblingView;
    NSInteger _previousRowCount;
    NSView *_container;
}

@property(retain,nonatomic) id<TTPredicateEditorDelegate> delegate;

-(IBAction) predicateEditorChanged:(id)sender;
-(IBAction) pressedSubmitPredicate:(id)sender;
@end
