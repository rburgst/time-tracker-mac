//
//  TTask.h
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/NSPredicate.h>
#import "TWorkPeriod.h"
#import "ITask.h"

@class TProject;

@interface TTask : NSObject <NSCoding, ITask> {
	NSString *_name;
	NSInteger _totalTime;
	NSMutableArray *_workPeriods;
	TProject* _parent;
    int _taskId;
    BOOL _closed;
	NSPredicate *_filterPredicate;
}

- (void) setParentProject: (TProject*) project;

- (void) addWorkPeriod: (TWorkPeriod *) workPeriod;
- (NSMutableArray *) workPeriods;
- (NSArray *) matchingWorkPeriods:(NSPredicate*) filter;

- (int) filteredTime:(NSPredicate*) filter;

- (void) updateTotalTime;
- (NSString*) serializeData:(NSString*) prefix separator:(NSString*) sep;
- (id<ITask>) removeWorkPeriod:(TWorkPeriod*)period;
- (void) updateTotalBySeconds:(int)diffInSeconds sender:(id)theSender;

@property BOOL closed;
@property(readonly) NSInteger totalTime;
@property(readonly) NSInteger filteredDuration;

@property(retain, nonatomic) NSPredicate* filterPredicate;
@property(retain, nonatomic) NSString* name;
@property(retain, nonatomic) TProject* parentProject;
@property int taskId;


@end
