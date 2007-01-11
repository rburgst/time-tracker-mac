//
//  TimeIntervalFormatter.m
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TimeIntervalFormatter.h"


@implementation TimeIntervalFormatter

+ (NSString *) secondsToString: (int) seconds
{
	int hours = seconds / 3600;
	int minutes = (seconds % 3600) / 60;
	int secs = seconds % 60;
	return [NSString stringWithFormat: @"%@%d:%@%d:%@%d",
		(hours < 10 ? @"0" : @""), hours,
		(minutes < 10 ? @"0" : @""), minutes,
		(secs < 10 ? @"0" : @""), secs];
}

@end
