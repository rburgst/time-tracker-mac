//
//  TTTimeProvider.h
//  Time Tracker
//
//  Created by Aaron VonderHaar on 9/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TTTimeProvider : NSObject {
  
    NSDate *masterNow;
}

+(TTTimeProvider*) instance;

/* setNow can be used in testing to set a pre-determined now value.  setNow:nil to clear it. */
- (void)setNow:(NSDate *)aNow;
/* now will return the current time, or the last value passed to setNow if setNow has been called. */
- (NSDate *)now;

- (NSDate *)todayStartTime;
- (NSDate *)todayEndTime;

- (NSDate *)yesterdayStartTime;
- (NSDate *)yesterdayEndTime;

- (NSDate *)dayStartDateWithDaysFromToday:(NSInteger)days;
- (NSDate *)dayEndDateWithDaysFromToday:(NSInteger)days;
    
- (NSDate *)thisWeekStartTime;
- (NSDate *)thisWeekEndTime;

- (NSDate *)lastWeekStartTime;
- (NSDate *)lastWeekEndTime;

- (NSDate *)weekBeforeLastStartTime;
- (NSDate *)weekBeforeLastEndTime;

- (NSDate *)thisMonthStartTime;
- (NSDate *)thisMonthEndTime;

- (NSDate *)lastMonthStartTime;
- (NSDate *)lastMonthEndTime;

/* Generic methods */
- (NSDate *)monthStartDateWithMonthsFromToday:(NSInteger) months;
- (NSDate*) monthEndDateWithMonthsFromToday:(NSInteger) months;

- (NSDate *)weekStartDateWithWeeksFromToday:(NSInteger)weeks;
- (NSDate *)weekEndDateWithWeeksFromToday:(NSInteger)weeks;

- (NSDate*) dateWithDaysFromToday:(NSInteger)days;
- (NSDate*) dateWithMidnight:(NSDate*)dateWithTime;

/* Predicate methods */
- (NSPredicate*) predicateWithSingleDayFromToday:(NSInteger)days;
- (NSPredicate*) predicateWithStartDateFromToday:(NSInteger)days  comparisonType:(NSInteger)comparisonType;
- (NSPredicate*) predicateWithEndDateFromToday:(NSInteger)days  comparisonType:(NSInteger)comparisonType;

- (NSPredicate*) predicateWithSingleWeekFromToday:(NSInteger)weeks;
- (NSPredicate*) predicateWithWeekEndDateFromToday:(NSInteger)weeks comparisonType:(NSInteger)compType;
- (NSPredicate*) predicateWithWeekStartDateFromToday:(NSInteger)weeks comparisonType:(NSInteger)compType;

- (NSPredicate*) predicateWithSingleMonthFromToday:(NSInteger)months;
- (NSPredicate*) predicateWithMonthStartDateFromToday:(NSInteger)months comparisonType:(NSInteger)compType;
- (NSPredicate*) predicateWithMonthEndDateFromToday:(NSInteger)months comparisonType:(NSInteger)compType;

@end
