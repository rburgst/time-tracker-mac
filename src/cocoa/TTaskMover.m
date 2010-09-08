//
//  TTaskMover.m
//  Time Tracker
//
//  Created by Rainer Burgstaller on 08.09.10.
//  Copyright 2010 N/A. All rights reserved.
//

#import "TTaskMover.h"
#import "TTask.h"
#import "TProject.h"


@implementation TTaskMover

@synthesize mainController = _mainController;

-(BOOL) moveObjectFrom:(NSInteger)fromIndex to:(NSInteger)toIndex objects:(NSArray*)objects {
	// we must have more than one task otherwise there is nothing to move
	assert([objects count] > 1);
	// first grab the associated project
	TTask *task = [objects objectAtIndex:1];
	TProject* project = task.parentProject;
	// correct indices (ignore the "All tasks")
	NSInteger correctedFrom = fromIndex - 1;
	NSInteger correctedTo = toIndex - 1;
	TTask *origTask = [project.tasks objectAtIndex:correctedFrom];
	[project moveTask:origTask toIndex:correctedTo];
	[self.mainController reloadTasks];
	return YES;
}
@end
