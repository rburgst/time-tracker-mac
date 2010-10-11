//
//  TWorkPeriod.h
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//forward declaration
@class TTask;

@interface TWorkPeriod : NSObject <NSCoding> {
	NSInteger _totalTime;
	NSDate *_startTime;
	NSDate *_endTime;
    NSDate *_date;
	NSAttributedString* _comment;
	TTask *_parent;
}

@property(readonly) NSInteger weekday;
@property(readonly) NSInteger daysSinceStart;
@property(readonly) NSInteger daysSinceEnd;
@property(readonly) NSInteger weeksSinceStart;
@property(readonly) NSInteger weeksSinceEnd;
@property(readonly) NSInteger monthsSinceStart;
@property(readonly) NSInteger monthsSinceEnd;

@property(readonly) NSInteger totalTime;

@property(retain, nonatomic) NSDate* startTime;
@property(retain, nonatomic) NSDate* endTime;
@property(retain, nonatomic) NSDate* date;
@property(retain, nonatomic) NSAttributedString* comment;
@property(readonly) NSString* strComment;
@property(retain, nonatomic) TTask* parentTask;

- (void) updateTotalTime;
// Set the end time to now
- (void) timerTick;

- (NSString*) serializeData: (NSString*) prefix separator:(NSString*) sep;

@end
