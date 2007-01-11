//
//  TWorkPeriod.h
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TWorkPeriod : NSObject <NSCoding> {
	int _totalTime;
	NSDate *_startTime;
	NSDate *_endTime;
}

- (void) setStartTime: (NSDate *) startTime;
- (void) setEndTime: (NSDate *) endTime;

- (void) updateTotalTime;

- (int) totalTime;
- (void) updateTotalTime;

- (NSDate *) startTime;
- (NSDate *) endTime;

@end
