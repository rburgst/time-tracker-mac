/*
 *  IProject.h
 *  Time Tracker
 *
 *  Created by Rainer Burgstaller on 26.11.07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

@protocol IProject<NSObject, NSCoding>

- (NSInteger) totalTime;
- (void) updateTotalTime;
- (NSArray *) tasks;
- (NSString*) name;
- (id<IProject>) removeTask:(TTask*)task;
- (int) filteredTime:(NSPredicate*) filter;
- (BOOL) doesTaskNameExist:(NSString*)name;
- (void)moveTask:(TTask *)task toIndex:(NSInteger)index;
- (NSMutableArray *) matchingTasks:(NSPredicate*) filter;

@property(readonly) NSInteger closedTime;
@end