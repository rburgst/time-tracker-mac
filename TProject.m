//
//  TProject.m
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TProject.h"


@implementation TProject

- (id) init
{
	[self setName: @"Untitled"];
	_tasks = [NSMutableArray new];
	_totalTime = 0;
	return self;
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

- (NSMutableArray *) tasks
{
	return _tasks;
}

- (void) addTask: (TTask *) task
{
	[_tasks addObject: task];
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
        _name = [[coder decodeObjectForKey:@"TName"] retain];
        _tasks = [[NSMutableArray arrayWithArray: [coder decodeObjectForKey:@"PTasks"]] retain];
    } else {
        // Must decode keys in same order as encodeWithCoder:
        _name = [[coder decodeObject] retain];
        _tasks = [[NSMutableArray arrayWithArray: [coder decodeObject]] retain];
    }
	[self updateTotalTime];
    return self;
}

@end
