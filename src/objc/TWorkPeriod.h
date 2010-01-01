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
	int _totalTime;
	NSDate *_startTime;
	NSDate *_endTime;
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
@property(retain, nonatomic) NSDate* startTime;
@property(retain, nonatomic) NSDate* endTime;

- (void) setStartTime: (NSDate *) startTime;
- (void) setEndTime: (NSDate *) endTime;
- (void) setComment:(NSAttributedString*) aComment;
- (void) setParentTask:(TTask*) task;

- (void) updateTotalTime;

- (int) totalTime;
- (void) updateTotalTime;

- (NSDate *) startTime;
- (NSDate *) endTime;
- (NSAttributedString *) comment;
- (NSString*) serializeData: (NSString*) prefix separator:(NSString*) sep;
- (TTask*) parentTask;
@end
