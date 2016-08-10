//
//  TaskEditorController.h
//
//  Created by Rainer Burgstaller on 02.07.10.
//  Copyright 2010 N/A. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import <BWToolkitFramework/BWToolkitFramework.h>
#import "TTask.h"

@interface TaskEditorController : NSWindowController {
	TTask *_task;
	NSString* _taskName;
	BOOL _completed;
}

@property(nonatomic,retain) TTask* task;
@property(nonatomic,retain) NSString* taskName;
@property BOOL completed;

- (IBAction)openSheet:(id)sender forWindow:(NSWindow*) parentWindow withTask:(TTask*)task;
- (IBAction)closeSheet:(id)sender;
- (IBAction)applyAndClose:(id) sender;

@end
