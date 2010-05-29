//
//  TMetaTask.h
//  Time Tracker
//
//  Created by Rainer Burgstaller on 26.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ITask.h"
#import "TWorkPeriod.h"
#import "TTask.h"


@interface TMetaTask : NSObject<ITask> {
	NSArray *_tasks;
}

- (NSString *) name;
- (NSMutableArray *) workPeriods;

- (NSInteger) totalTime;
- (void) updateTotalTime;
- (void) setTasks:(NSArray*)tasks;
- (id<ITask>) removeWorkPeriod:(TWorkPeriod*)period;
- (int) filteredTime:(NSPredicate*) filter;
- (NSEnumerator*)objectEnumerator;
@end
