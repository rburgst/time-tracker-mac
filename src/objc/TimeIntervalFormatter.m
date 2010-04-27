//
//  TimeIntervalFormatter.m
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TimeIntervalFormatter.h"


@implementation TimeIntervalFormatter

@synthesize decimalMode = _decimalMode;

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

+ (NSString*) secondsToDecimalHours: (int) seconds 
{
    float hours = ((float) seconds) / 3600.0f;
    return [NSString stringWithFormat:@"%.2fh", hours];
}

- (NSString*) transformSeconds:(int) seconds {
    if (_decimalMode) {
        return [TimeIntervalFormatter secondsToDecimalHours: seconds];
    } else {
        return [TimeIntervalFormatter secondsToString: seconds];
    }    
}

- (id)transformedValue:(id)value {
    return [self transformSeconds: [value intValue]];
}

+ (Class) transformedValueClass 
{ 
	return [NSString class]; 
}

+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}

@end
