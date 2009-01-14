//
//  TTask.h
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/NSPredicate.h>
#import "TWorkPeriod.h"
#import "ITask.h"

@class TProject;

@interface TTask : NSObject <NSCoding, ITask> {
	NSString *_name;
	int _totalTime;
	NSMutableArray *_workPeriods;
	TProject* _parent;
    int _taskId;
}

- (NSString *) name;
- (void) setName: (NSString *) name;
- (void) setParentProject: (TProject*) project;

- (void) addWorkPeriod: (TWorkPeriod *) workPeriod;
- (NSMutableArray *) workPeriods;
- (NSMutableArray *) matchingWorkPeriods:(NSPredicate*) filter;

- (int) totalTime;
- (int) filteredTime:(NSPredicate*) filter;
- (void) updateTotalTime;
- (NSString*) serializeData:(NSString*) prefix separator:(NSString*) sep;
- (id<ITask>) removeWorkPeriod:(TWorkPeriod*)period;
- (TProject*) parentProject;
- (void) setTaskId:(int) id;
@end
