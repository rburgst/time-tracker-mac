//
//  TTask.h
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TWorkPeriod.h"

@interface TTask : NSObject <NSCoding> {
	NSString *_name;
	int _totalTime;
	NSMutableArray *_workPeriods;
}

- (NSString *) name;
- (void) setName: (NSString *) name;

- (void) addWorkPeriod: (TWorkPeriod *) workPeriod;
- (NSMutableArray *) workPeriods;

- (int) totalTime;
- (void) updateTotalTime;


@end
