/*
 *  IProject.h
 *  Time Tracker
 *
 *  Created by Rainer Burgstaller on 26.11.07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

@protocol IProject<NSObject>

- (int) totalTime;
- (void) updateTotalTime;
- (NSArray *) tasks;
- (NSString*) name;
- (id<IProject>) removeTask:(TTask*)task;
- (int) filteredTime:(NSPredicate*) filter;
- (BOOL) doesTaskNameExist:(NSString*)name;
- (NSMutableArray *) matchingTasks:(NSPredicate*) filter;
@end