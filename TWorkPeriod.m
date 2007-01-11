//
//  TWorkPeriod.m
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TWorkPeriod.h"


@implementation TWorkPeriod

- (id) init
{
	_startTime = nil;
	_endTime = nil;
	return self;
}

- (void) setStartTime: (NSDate *) startTime
{
	[startTime retain];
	[_startTime release];
	_startTime = startTime;
	[self updateTotalTime];
}

- (void) setEndTime: (NSDate *) endTime
{
	[endTime retain];
	[_endTime release];
	_endTime = endTime;
	[self updateTotalTime];
}

- (void) updateTotalTime
{
	if (_endTime == nil || _startTime == nil) {
		_totalTime = 0;
		return;
	}
	double timeInterval = [_endTime timeIntervalSinceDate: _startTime];
	_totalTime = (int) timeInterval;
}

- (int) totalTime
{
	return _totalTime;
}

- (NSDate *) startTime
{
	return _startTime;
}

- (NSDate *) endTime
{
	return _endTime;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    //[super encodeWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        [coder encodeObject:_startTime forKey:@"WPStartTime"];
        [coder encodeObject:_endTime forKey:@"WPEndTime"];
    } else {
        [coder encodeObject:_startTime];
		[coder encodeObject:_endTime];
    }
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    //self = [super initWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
        _startTime = [[coder decodeObjectForKey:@"WPStartTime"] retain];
        _endTime = [[coder decodeObjectForKey:@"WPEndTime"] retain];
    } else {
        // Must decode keys in same order as encodeWithCoder:
        _startTime = [[coder decodeObject] retain];
        _endTime = [[coder decodeObject] retain];
    }
	[self updateTotalTime];
    return self;
}

@end
