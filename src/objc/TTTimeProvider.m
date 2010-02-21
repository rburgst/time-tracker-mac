//
//  TTTimeProvider.m
//  Time Tracker
//
//  Created by Aaron VonderHaar on 9/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TTTimeProvider.h"

static id staticInstance;

@implementation TTTimeProvider

+(TTTimeProvider*)instance {
    if (staticInstance == nil) {
        id instance = [[TTTimeProvider alloc] init];
        staticInstance = instance;
    }
    return staticInstance;
}

- (void)setNow:(NSDate *)aNow
{
  [masterNow release];
  masterNow = [aNow retain];
}

- (NSDate *)now
{
  if (masterNow != nil)
  {
    return masterNow;
  }
  else
  {
    return [NSDate date];
  }
}

- (void)dealloc
{
  [masterNow release];
  [super dealloc];
}

#pragma mark day functions
-(NSDate*) dateWithMidnight:(NSDate*)dateWithTime {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents *date00 = [cal components:unitFlags fromDate:dateWithTime];
    return [cal dateFromComponents:date00];
}

-(NSDate*) dateWithDaysFromToday:(NSInteger)days {
    NSDate *now = [self dateWithMidnight:[self now]];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:-days];
    NSDate *startDate = [cal dateByAddingComponents:components toDate:now options:0];
    [components release];
    return startDate;
}

-(NSDate*) dateWithDaysFromTodayNum:(NSNumber*)days {
    return [self dateWithDaysFromToday:[days integerValue]];
}

- (NSDate *)todayStartTime
{
	return [self dateWithDaysFromToday:0];
}

- (NSDate *)todayEndTime
{
    // tomorrow morning
    return [self dateWithDaysFromToday:-1];
}

- (NSDate *)yesterdayStartTime
{
	return [self dateWithDaysFromToday:1];
}

- (NSDate *)yesterdayEndTime
{
	return [self dateWithDaysFromToday:0];
}

- (NSDate *)dayStartDateWithDaysFromToday:(NSInteger)days {
    return [self dateWithDaysFromToday:days];
}

- (NSDate *)dayEndDateWithDaysFromToday:(NSInteger)days {
    return [self dateWithDaysFromToday:days-1];
}

#pragma mark week functions

- (NSDate *)weekStartDateWithWeeksFromToday:(NSInteger)weeks {
    NSDate *now = [self now];
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	NSDateComponents *rangeStartComps = [gregorian 
                                         components:NSYearCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit
                                         fromDate:now];
	[rangeStartComps setWeekday:[gregorian firstWeekday]];
	NSDate *rangeStart = [gregorian dateFromComponents:rangeStartComps];
	rangeStart = [rangeStart addTimeInterval:-(weeks * 3600 * 24 * 7)];
	return rangeStart;
}

- (NSDate *)weekEndDateWithWeeksFromToday:(NSInteger)weeks {
    return [self weekStartDateWithWeeksFromToday:weeks - 1];
}

- (NSDate *)thisWeekStartTime
{
    return [self weekStartDateWithWeeksFromToday:0];
}

- (NSDate *)thisWeekEndTime
{
    // next weeks start time is this weeks end time :)
    return [self weekStartDateWithWeeksFromToday:-1];
}

- (NSDate *)lastWeekStartTime
{
    return [self weekStartDateWithWeeksFromToday:1];
}

- (NSDate *)lastWeekEndTime
{
    return [self weekStartDateWithWeeksFromToday:0];
}

- (NSDate *)weekBeforeLastStartTime
{
    return [self weekStartDateWithWeeksFromToday:2];
}

- (NSDate *)weekBeforeLastEndTime
{
    return [self weekStartDateWithWeeksFromToday:1];
}

#pragma mark month functions

- (NSDate *)monthStartDateWithMonthsFromToday:(NSInteger) months {
    NSDate *now = [self now];
	NSCalendar *gregorian = [NSCalendar currentCalendar];
	NSDateComponents *rangeStartComps = [gregorian 
                                         components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                         fromDate:now];
	[rangeStartComps setDay:1];
	[rangeStartComps setMonth:[rangeStartComps month] - months];
	NSDate *rangeStart = [gregorian dateFromComponents:rangeStartComps];
	return rangeStart;    
}

- (NSDate*) monthEndDateWithMonthsFromToday:(NSInteger) months {
    return [self monthStartDateWithMonthsFromToday:months - 1];
}

- (NSDate *)thisMonthStartTime
{
    return [self monthStartDateWithMonthsFromToday:0];
}

- (NSDate *)thisMonthEndTime
{
    return [self monthStartDateWithMonthsFromToday:-1];
}

- (NSDate *)lastMonthStartTime
{
	return [self monthStartDateWithMonthsFromToday:1];
}

- (NSDate *)lastMonthEndTime
{
	return [self monthStartDateWithMonthsFromToday:0];
}

#pragma mark predicate day functions

- (NSPredicate*) predicateWithStartDateFromToday:(NSInteger)days  comparisonType:(NSInteger)comparisonType {
    NSString *startVariable = [NSString stringWithFormat:@"daysAgoStart_%d", days];
    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"startTime"] 
                                                             rightExpression:[NSExpression expressionForVariable:startVariable] 
                                                                    modifier:NSDirectPredicateModifier 
                                                                        type:comparisonType 
                                                                     options:0];
    return result;
}

- (NSPredicate*) predicateWithEndDateFromToday:(NSInteger)days  comparisonType:(NSInteger)comparisonType {
    NSString *endVariable = [NSString stringWithFormat:@"daysAgoEnd_%d", days];
    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"endTime"]
                                                             rightExpression:[NSExpression expressionForVariable:endVariable]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:comparisonType
                                                                     options:0];
    return result;
}

- (NSPredicate*) predicateWithSingleDayFromToday:(NSInteger)days {
    NSString *startVariable = [NSString stringWithFormat:@"daysAgoStart_%d", days];
    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"date"] 
                                                             rightExpression:[NSExpression expressionForVariable:startVariable] 
                                                                    modifier:NSDirectPredicateModifier 
                                                                        type:NSEqualToPredicateOperatorType 
                                                                     options:0];
    return result;
}

#pragma mark predicate week functions

- (NSPredicate*) predicateWithWeekStartDateFromToday:(NSInteger)weeks comparisonType:(NSInteger)compType {
    NSString *startVariable = [NSString stringWithFormat:@"weeksAgoStart_%d", weeks];

    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"date"]
                                                             rightExpression:[NSExpression expressionForVariable:startVariable]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:compType
                                                                     options:0];
    return result;
}

- (NSPredicate*) predicateWithWeekEndDateFromToday:(NSInteger)weeks comparisonType:(NSInteger)compType {
/*    NSDate *endDate = [self weekEndDateWithWeeksFromToday:weeks];
    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"endTime"]
                                                             rightExpression:[NSExpression expressionForConstantValue:endDate]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:compType
                                                                     options:0];
    return result;*/
    NSString *startVariable = [NSString stringWithFormat:@"weeksAgoEnd_%d", weeks];
    
    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"date"]
                                                             rightExpression:[NSExpression expressionForVariable:startVariable]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:compType
                                                                     options:0];
    return result;
    
}

- (NSPredicate*) predicateWithSingleWeekFromToday:(NSInteger)weeks {
    NSString *start = [NSString stringWithFormat:@"weeksAgoStart_%d", weeks];
    NSString *end = [NSString stringWithFormat:@"weeksAgoEnd_%d",weeks];
    
    NSPredicate *equalsPred = [NSPredicate predicateWithFormat:@"date BETWEEN %@", 
                               [NSArray arrayWithObjects:[NSExpression expressionForVariable:start], 
                                    [NSExpression expressionForVariable:end], nil]];
    return equalsPred;
/*    NSPredicate *startPredicate = [self predicateWithWeekStartDateFromToday:weeks comparisonType:NSGreaterThanOrEqualToComparison];
    NSPredicate *endPredicate = [self predicateWithWeekEndDateFromToday:weeks comparisonType:NSLessThanOrEqualToComparison];
    return [NSCompoundPredicate andPredicateWithSubpredicates:
            [NSArray arrayWithObjects:startPredicate, endPredicate, nil]];
  */  
}

#pragma mark predicate month functions

- (NSPredicate*) predicateWithMonthStartDateFromToday:(NSInteger)months comparisonType:(NSInteger)compType {
    NSDate *startDate = [self monthStartDateWithMonthsFromToday:months];
    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"startTime"]
                                                             rightExpression:[NSExpression expressionForConstantValue:startDate]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:compType
                                                                     options:0];
    return result;
}

- (NSPredicate*) predicateWithMonthEndDateFromToday:(NSInteger)months comparisonType:(NSInteger)compType {
    NSDate *endDate = [self monthEndDateWithMonthsFromToday:months];
    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"endTime"]
                                                             rightExpression:[NSExpression expressionForConstantValue:endDate]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:compType
                                                                     options:0];
    return result;
}

- (NSPredicate*) predicateWithSingleMonthFromToday:(NSInteger)months {
    NSPredicate *startPredicate = [self predicateWithMonthStartDateFromToday:months comparisonType:NSGreaterThanOrEqualToComparison];
    NSPredicate *endPredicate = [self predicateWithMonthEndDateFromToday:months comparisonType:NSLessThanOrEqualToComparison];
    return [NSCompoundPredicate andPredicateWithSubpredicates:
            [NSArray arrayWithObjects:startPredicate, endPredicate, nil]];
    
}

@end
