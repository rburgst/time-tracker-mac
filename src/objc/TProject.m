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

- (id) init
{
	[self setName: @"New Project"];
	_tasks = [NSMutableArray new];
	_totalTime = 0;
	return self;
}

- (NSString *) name
{
	if (_name == nil) {
		return [@"no name" autorelease];
	}
	return _name;
}

- (void) setName: (NSString *) name
{
	[name retain];
	[_name release];
	_name = name;
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

- (int) totalTime
{
	return _totalTime;
}

- (void) updateTotalTime
{
	_totalTime = 0;
	int i;
	for (i = 0; i < [_tasks count]; i++) {
		_totalTime += [[_tasks objectAtIndex: i] totalTime];
	}
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

- (int) filteredTime:(NSPredicate*) filter
{
	if (filter == nil) {
		return [self totalTime];
	}
	int result = 0;
	NSEnumerator *enumTasks = [_tasks objectEnumerator];
	id task;
	while ((task = [enumTasks nextObject]) != nil) {
		result += [task filteredTime:filter];
	}
	return result;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    //[super encodeWithCoder:coder];
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
    //self = [super initWithCoder:coder];
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
@end
