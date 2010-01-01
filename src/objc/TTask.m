//
//  TTask.m
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TTask.h"

static int _maxTaskId = 1;


@implementation TTask

- (id) init
{
    if (self = [super init]) {
        [self setName: @"New Task"];
        _totalTime = 0;
        [self setTaskId:_maxTaskId + 1];
        _workPeriods = [NSMutableArray new];
        return self;
    }
    return nil;
}

- (NSString *) name
{
	return _name;
}

- (void) setName: (NSString *) name
{
	[name retain];
	[_name release];
	_name = name;
}

- (void) addWorkPeriod: (TWorkPeriod *) workPeriod
{
	[_workPeriods addObject: workPeriod];
	[workPeriod setParentTask:self];
}

- (NSMutableArray *) workPeriods
{
	return _workPeriods;
}

- (void) updateTotalTime
{
	_totalTime = 0;
	int i;
	for (i = 0; i < [_workPeriods count]; i++) {
		_totalTime += [[_workPeriods objectAtIndex: i] totalTime];
	}
}

- (int) totalTime
{
	return _totalTime;
}

- (NSArray *) matchingWorkPeriods:(NSPredicate*) filter
{
    return [_workPeriods filteredArrayUsingPredicate:filter];
/*	NSMutableArray* result = [[[NSMutableArray alloc] init] autorelease];
	NSEnumerator *enumerator = [_workPeriods objectEnumerator];
	id anObject;
 
	while (anObject = [enumerator nextObject])
	{
		if ([filter evaluateWithObject:anObject]) {
			[result addObject:anObject];
		}
	}
	return result;
*/	
}

- (int) filteredTime:(NSPredicate*) filter
{
	if (filter == nil) {
		return [self totalTime];
	}
	NSEnumerator *enumPeriods = [[self matchingWorkPeriods:filter] objectEnumerator];
	id anObject;
	int result = 0;
 
	while (anObject = [enumPeriods nextObject])
	{
		result += [anObject totalTime];
	}
	return result;

}

- (void)encodeWithCoder:(NSCoder *)coder
{
    //[super encodeWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        [coder encodeObject:_name forKey:@"TName"];
        [coder encodeInt:_taskId forKey:@"TID"];
        [coder encodeObject:_workPeriods forKey:@"TWorkPeriods"];
    } else {
        [coder encodeObject:_name];
		[coder encodeObject:_workPeriods];
    }
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    //self = [super initWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
        _name = [[coder decodeObjectForKey:@"TName"] retain];
        _workPeriods = [[NSMutableArray arrayWithArray: [coder decodeObjectForKey:@"TWorkPeriods"]] retain];
        int taskId = [coder decodeIntForKey:@"TID"];
        if (taskId <= 0) {
            taskId = _maxTaskId + 1;
        }
        [self setTaskId:taskId];
    } else {
        // Must decode keys in same order as encodeWithCoder:
        _name = [[coder decodeObject] retain];
        _workPeriods = [[NSMutableArray arrayWithArray: [coder decodeObject]] retain];
    }
	// update back links
	NSEnumerator *enumerator = [_workPeriods objectEnumerator];
	id anObject;
	while (anObject = [enumerator nextObject])
	{
		[anObject setParentTask:self];
	}

	[self updateTotalTime];
    return self;
}

- (NSString*)serializeData:(NSString*) prefix separator:(NSString*)sep
{
	NSMutableString* result = [NSMutableString string];
	NSEnumerator *enumerator = [_workPeriods objectEnumerator];
	id anObject;
	NSString *addPrefix = [NSString stringWithFormat:@"%@%@\"%@\"", prefix, sep, _name];
 
	while (anObject = [enumerator nextObject])
	{
		[result appendString:[anObject serializeData:addPrefix separator:sep]];
	}
	return result;
}

- (id<ITask>) removeWorkPeriod:(TWorkPeriod*)period {
	[[self workPeriods] removeObject:period];
	[period setParentTask:nil];
	return self;
}

- (void) setParentProject:(TProject*) project
{
	[_parent release];
	_parent = nil;
	_parent = [project retain];
}

- (TProject*) parentProject
{
	return _parent;
}

- (int) taskId 
{
    return _taskId;
}

- (void) setTaskId:(int)id 
{
    _taskId = id;
    _maxTaskId = MAX(_taskId, _maxTaskId);
}
@end
