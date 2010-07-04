//
//  TTask.m
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TTask.h"
#import "TProject.h"

static int _maxTaskId = 1;

#define CODERKEY_CLOSED @"Tclosed"
#define CODERKEY_WORKPERIODS @"TWorkPeriods"
#define CODERKEY_TASK_ID @"TID"
#define CODERKEY_TASKNAME @"TName"

// note in order to make the compiler generate the private setter, the
// category must not have a name, FFS Apple!!
@interface TTask ()
	@property(readwrite) NSInteger totalTime;
@end



@implementation TTask

@synthesize closed = _closed;
@synthesize filterPredicate = _filterPredicate;
@synthesize totalTime = _totalTime;
@synthesize name = _name;
@synthesize parentProject = _parent;
@synthesize taskId = _taskId;

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

- (void) addWorkPeriod: (TWorkPeriod *) workPeriod
{
	[_workPeriods addObject: workPeriod];
	workPeriod.parentTask = self;
}

-(NSString*) description {
	return [NSString stringWithFormat:@"<TTask: %@, parent %@>", _name, self.parentProject.name];
}

- (NSMutableArray *) workPeriods
{
	return _workPeriods;
}

- (void) updateTotalTime
{
	int result = 0;
	int i;
	for (i = 0; i < [_workPeriods count]; i++) {
		result += [[_workPeriods objectAtIndex: i] totalTime];
	}
	self.totalTime = result; 
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
        [coder encodeObject:_name forKey:CODERKEY_TASKNAME];
        [coder encodeInt:_taskId forKey:CODERKEY_TASK_ID];
        [coder encodeObject:_workPeriods forKey:CODERKEY_WORKPERIODS];
        [coder encodeBool:_closed forKey:CODERKEY_CLOSED];
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
        _name = [[coder decodeObjectForKey:CODERKEY_TASKNAME] retain];
        _workPeriods = [[NSMutableArray arrayWithArray: [coder decodeObjectForKey:CODERKEY_WORKPERIODS]] retain];
        int taskId = [coder decodeIntForKey:CODERKEY_TASK_ID];
        if (taskId <= 0) {
            taskId = _maxTaskId + 1;
        }
        self.closed = [coder decodeBoolForKey:CODERKEY_CLOSED];
        
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

- (void) setTaskId:(int)id 
{
    _taskId = id;
    _maxTaskId = MAX(_taskId, _maxTaskId);
}

- (void) setFilterPredicate:(NSPredicate *) predicate {
	if (_filterPredicate == predicate) {
		return;
	}
	[self willChangeValueForKey:@"filteredDuration"];
	[_filterPredicate release];
	_filterPredicate = [predicate retain];
	[self didChangeValueForKey:@"filteredDuration"];
}

-(NSInteger) filteredDuration {
	if (_filterPredicate == nil) {
		return self.totalTime;
	}
	return [self filteredTime:_filterPredicate];
}

- (void) updateTotalBySeconds:(int)diffInSeconds sender:(id)theSender {
	if (_filterPredicate == nil || [_filterPredicate evaluateWithObject:theSender]) {
		[self willChangeValueForKey:@"filteredDuration"];
		self.totalTime = self.totalTime + diffInSeconds;
		// TODO notify parent project
		[self didChangeValueForKey:@"filteredDuration"];
	}
}

- (NSComparisonResult)compare:(id<ITask>)aTask {
	return [self.name compare:aTask.name];
}
@end
