/*
 *  ITask.h
 *  Time Tracker
 *
 *  Created by Rainer Burgstaller on 26.11.07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */
 
 #import "TWorkPeriod.h"

@protocol ITask<NSObject>

- (int) totalTime;
- (void) updateTotalTime;
- (NSArray *) workPeriods;
- (NSString*) name;
- (id<ITask>) removeWorkPeriod:(TWorkPeriod*)period;
- (int) filteredTime:(NSPredicate*) filter;
@end