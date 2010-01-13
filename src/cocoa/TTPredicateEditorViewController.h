//
//  TTPredicateEditorViewController.h
//
//  Created by Rainer Burgstaller on 21.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// forward declarations
@class SearchQuery;

@protocol TTPredicateEditorDelegate

-(void) predicateSelected:(NSPredicate*)predicate;

@end

@interface TTPredicateEditorViewController : NSViewController <NSUserInterfaceValidations> {
    IBOutlet NSPredicateEditor *_editor;
    IBOutlet id<TTPredicateEditorDelegate> _delegate;
    IBOutlet NSView *siblingView;
    NSInteger _previousRowCount;
    NSView *_container;
    BOOL _predicateValid;
}

@property(retain,nonatomic) id<TTPredicateEditorDelegate> delegate;
@property BOOL predicateValid;

-(IBAction) predicateEditorChanged:(id)sender;
-(IBAction) pressedSubmitPredicate:(id)sender;
-(IBAction) pressedSavePredicate:(id)sender;
-(IBAction) filterQuerySelected:(SearchQuery*)query;

@end
