//
//  TProject.m
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TProject.h"
#import "ITask.h"

@implementation TProject

@synthesize name = _name;
@synthesize closed = _closed;

#pragma mark -
#pragma mark object lifecycle

- (id) init
{
	self.name = @"New Project";
	_tasks = [NSMutableArray new];
	_totalTime = 0;
	return self;
}

- (void) dealloc 
{
	[_tasks release];
	_tasks = nil;
	[super dealloc];
}
#pragma mark -
#pragma mark persistence

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        [coder encodeObject:_name forKey:@"PName"];
        [coder encodeObject:_tasks forKey:@"PTasks"];
    } else {
        [coder encodeObject:_name];
		[coder encodeObject:_tasks];
    }
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
        _name = [[coder decodeObjectForKey:@"PName"] retain];
        _tasks = [[NSMutableArray arrayWithArray: [coder decodeObjectForKey:@"PTasks"]] retain];
    } else {
        // Must decode keys in same order as encodeWithCoder:
        _name = [[coder decodeObject] retain];
        _tasks = [[NSMutableArray arrayWithArray: [coder decodeObject]] retain];
    }
	[self updateTotalTime];
	
		// update back links
	NSEnumerator *enumerator = [_tasks objectEnumerator];
	id anObject;
	while (anObject = [enumerator nextObject])
	{
		[anObject setParentProject:self];
	}

    return self;
}

#pragma mark -
#pragma mark CSV export
- (NSString*)serializeData:(NSString*)separatorChar
{
	NSMutableString* result = [NSMutableString string];
	NSEnumerator *enumerator = [_tasks objectEnumerator];
	id anObject;
	NSString *prefix = [NSString stringWithFormat:@"\"%@\"", _name];
	while (anObject = [enumerator nextObject])
	{
		[result appendString:[anObject serializeData:prefix separator:separatorChar]];
	}
	return [[result retain] autorelease];
}

#pragma mark -
#pragma mark model API

- (id<IProject>) removeTask:(TTask*)task {
	[[self tasks] removeObject:task];
	[task setParentProject:nil];
	return self;
}

- (void)moveTask:(TTask *)task toIndex:(NSInteger)index
{
	NSInteger oldIndex = [_tasks indexOfObject:task];
	if (oldIndex == NSNotFound)
	{
		NSLog(@"TProject moveTask:toIndex: task was not found in the tasks lists");
		return;
	}
	
	[_tasks insertObject:task atIndex:index];
	if (oldIndex >= index) oldIndex++;
	[_tasks removeObjectAtIndex:oldIndex];
}


/**
 * Checks whether a given task name already exists. 
 * @param name  the task name to search for
 * @return YES if the task name already exists.
 */
- (BOOL) doesTaskNameExist:(NSString*)name {
    NSEnumerator *enumTasks = [_tasks objectEnumerator];
    TTask *task;
    while ((task = [enumTasks nextObject]) != nil) {
        if ([name isEqualToString:[task name]]) {
            return YES;
        }
    }
    return NO;
}

- (void) deDuplicateTaskNames {
    // check projects for duplicate names
    NSEnumerator *projectEnum = [_tasks objectEnumerator];
    int i = 0;
    int j = 0;
    int uniqueMaker = 1;
    TTask *task;
    while ((task = [projectEnum nextObject]) != nil) {
        for (j = 0; j < i; j++) {
            TTask *checkTask = [_tasks objectAtIndex:j];
            if ([[checkTask name] isEqualToString:[task name]]) {
                // duplicate name detected
                [checkTask setName:[NSString stringWithFormat:@"%@ %d",[checkTask name], uniqueMaker++]];
            }
        }
        i++;
    }
}

/**
 * Checks all existing task names for name collisions and proposes
 * a name that wont collide.
 * @param baseName  the default name for a potential new task
 * @return a unique task name
 */
- (NSString*) findUniqueTaskNameBasedOn:(NSString*) baseName {
    NSString *curTaskName = baseName;
    NSInteger uniqueMaker = 1;
    for (TTask* task in _tasks) {
        while ([task.name isEqualToString:curTaskName]) {
            uniqueMaker++;
            curTaskName = [NSString stringWithFormat:@"%@ %d", baseName, uniqueMaker];
        }
    }
    return curTaskName;
}

/** 
 * Evaluates all time records in this project which match the filter and their
 * tasks are not closed.
 * @param filter	the filter predicate which to match WorkPeriods
 * @param closed	only evaluate project have the matching closed state
 */
- (int) filteredTime:(NSPredicate*) filter closed:(BOOL) closed
{
	if (filter == nil) {
		return [self totalTime];
	}
	int result = 0;
	NSEnumerator *enumTasks = [_tasks objectEnumerator];
	id<ITask> task;
	while ((task = [enumTasks nextObject]) != nil) {
		if (closed == _closed) {
			result += [task filteredTime:filter];
		}
	}
	return result;
}

/** 
 * Evaluates all time records in this project which match the filter and their
 * tasks are not closed. This will only collect times for not closed Tasks.
 * @param filter	the filter predicate which to match WorkPeriods
 */
- (int) filteredTime:(NSPredicate*) filter
{
	return [self filteredTime:filter closed:NO];
}

- (NSMutableArray *) tasks
{
	return _tasks;
}

- (void) addTask: (TTask *) task
{
	[_tasks addObject: task];
	[task setParentProject:self];
}

- (NSInteger) totalTime
{
	return _totalTime;
}

- (void) updateTotalTime
{
	_totalTime = 0;
	int i;
	for (i = 0; i < [_tasks count]; i++) {
		TTask *task = [_tasks objectAtIndex: i];
		if (!task.closed) {
			_totalTime += [task totalTime];
		}
	}
}

- (NSInteger) closedTime
{
	NSInteger result = 0;
	int i;
	for (i = 0; i < [_tasks count]; i++) {
		TTask *task = [_tasks objectAtIndex: i];
		if (task.closed) {
			result += [task totalTime];
		}
	}
	return result;
}

- (NSMutableArray *) matchingTasks:(NSPredicate*) filter
{
	NSMutableArray *result = [NSMutableArray array];
	// this needs to be performance tuned but it does the job for now
	NSEnumerator *enumTasks = [_tasks objectEnumerator];
	id task;
	while ((task = [enumTasks nextObject]) != nil) {
		if ([[task matchingWorkPeriods:filter] count] > 0) {
			[result addObject:task];
		}
	}
	return result;
}
@end
