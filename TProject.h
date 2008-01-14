//
//  TProject.h
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TTask.h"
#import "IProject.h"

@interface TProject : NSObject <NSCoding, IProject> {
	NSString *_name;
	NSMutableArray *_tasks;
	int _totalTime;
}

- (NSString *) name;
- (void) setName: (NSString *) name;

- (NSMutableArray *) tasks;
- (void) addTask: (TTask *) task;

- (NSMutableArray *) matchingTasks:(NSPredicate*) filter;
- (int) filteredTime:(NSPredicate*) filter;

- (int) totalTime;
- (void) updateTotalTime;
- (NSString*) serializeData;
- (id<IProject>) removeTask:(TTask*)task;
@end
