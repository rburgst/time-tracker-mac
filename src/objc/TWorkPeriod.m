//
//  TWorkPeriod.m
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "TWorkPeriod.h"
#import "TTTimeProvider.h"
#import "TTask.h"

#define ENCODER_KEY_START_TIME @"WPStartTime"
#define ENCODER_KEY_END_TIME @"WPEndTime"
#define ENCODER_KEY_COMMENT @"AttributedComment"

// note in order to make the compiler generate the private setter, the
// category must not have a name, FFS Apple!!
@interface TWorkPeriod ()
	@property(readwrite) NSInteger totalTime;
@end

@implementation TWorkPeriod

@synthesize date = _date;
@synthesize totalTime = _totalTime;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize comment = _comment;
@synthesize parentTask = _parent;

- (id) init
{
	_startTime = nil;
	_endTime = nil;
	_comment = [[NSAttributedString alloc] init];
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    //self = [super initWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
        [self setStartTime:[coder decodeObjectForKey:ENCODER_KEY_START_TIME]];
        [self setEndTime:[coder decodeObjectForKey:ENCODER_KEY_END_TIME]];
        id attribComment = [coder decodeObjectForKey:ENCODER_KEY_COMMENT];
		
        if ([attribComment isKindOfClass:[NSString class]]) {
			attribComment = [[[NSAttributedString alloc] initWithString:attribComment] autorelease];
        }
        if (attribComment == nil) {
			attribComment = [[[NSAttributedString alloc] initWithString:[coder decodeObjectForKey:@"Comment"]] autorelease];
        }
        [self setComment:attribComment];
    } else {
        // Must decode keys in same order as encodeWithCoder:
        [self setStartTime:[coder decodeObject]];
        [self setEndTime:[coder decodeObject]];
		// comment not supported here for data file compability reasons.
    }
	[self updateTotalTime];
    return self;
}


- (void) setStartTime: (NSDate *) startTime
{
    if (startTime != _startTime) {
        [_startTime release];
        _startTime = nil;
        _startTime = [startTime retain];
		// reset the start date otherwise our filter is all wrong
		self.date = nil;
        [self updateTotalTime];        
    }
}

- (void) setEndTime: (NSDate *) endTime
{
    if (endTime != _endTime) {
		// determine difference
		NSTimeInterval diffInSeconds = [endTime timeIntervalSinceDate:_startTime];
		NSInteger totalDiff = diffInSeconds - _totalTime;
        [_endTime release];
        _endTime = nil;
        _endTime = [endTime retain];
		if (_totalTime > 0 && totalDiff < 5.0) {
			self.totalTime = _totalTime + totalDiff;
			[_parent updateTotalBySeconds:diffInSeconds sender:self];
		} else {
			[self updateTotalTime];
		}
    }
}

// set the end time to now
- (void) timerTick {
	self.endTime = [NSDate date];
}


- (void) updateTotalTime
{
	if (_endTime == nil || _startTime == nil) {
		self.totalTime = 0;
		return;
	}
	NSTimeInterval timeInterval = [_endTime timeIntervalSinceDate: _startTime];
	self.totalTime = timeInterval;
}


- (NSString *) strComment
{
    if (_comment != nil) {
        return [_comment string];
    } 
    return @"";
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    //[super encodeWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        [coder encodeObject:_startTime forKey:ENCODER_KEY_START_TIME];
        [coder encodeObject:_endTime forKey:ENCODER_KEY_END_TIME];
		[coder encodeObject:_comment forKey:ENCODER_KEY_COMMENT];
		
    } else {
        [coder encodeObject:_startTime];
		[coder encodeObject:_endTime];
		// comment not supported here for data file compability reasons.
    }
    return;
}


- (NSString*)serializeData:(NSString*) prefix separator:(NSString*)sep
{
    int hours = _totalTime / 3600;
    int minutes = _totalTime % 3600 / 60;
    int seconds = _totalTime - hours * 3600 - minutes * 60;// % 60;
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d %H:%M:%S" allowNaturalLanguage:NO]  autorelease];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d" allowNaturalLanguage:NO]  autorelease];
	NSString* result = [NSString stringWithFormat:@"%@%@\"%@\"%@\"%@\"%@\"%@\"%@\"%02d:%02d:%02d\"%@\"%@\"\n", prefix, sep, 
                        [dateFormatter stringFromDate:_startTime], sep,
                        [formatter stringFromDate:_startTime], sep, [formatter stringFromDate:_endTime], sep,
                        hours, minutes, seconds, sep, [self strComment]];
	return result;
}

-(NSInteger) weekday {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSWeekdayCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:_startTime];
    NSInteger result = [comp weekday];
    return result;
}


-(NSInteger) daysSinceDate:(NSDate*)date {
    TTTimeProvider *provider = [TTTimeProvider instance];
    NSDate* today = provider.todayStartTime;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit
                                                                   fromDate:date toDate:today options:0];
    return components.day;    
}

-(NSInteger) weeksSinceDate:(NSDate*)date {
    TTTimeProvider *provider = [TTTimeProvider instance];
    NSDate* today = provider.todayStartTime;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekCalendarUnit
                                                                       fromDate:date toDate:today options:0];
    return components.week;
}

-(NSInteger) monthsSinceDate:(NSDate*)date {
    TTTimeProvider *provider = [TTTimeProvider instance];
    NSDate* today = provider.todayStartTime;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit
                                                                   fromDate:date toDate:today options:0];
    return components.month;
}

-(NSInteger) daysSinceStart {
    return [self daysSinceDate:self.startTime];
}

-(NSInteger) daysSinceEnd {
    return [self daysSinceDate:self.endTime];
}

-(NSInteger) weeksSinceStart {
    return [self weeksSinceDate:self.startTime];
}

-(NSInteger) weeksSinceEnd {
    return [self weeksSinceDate:self.endTime];
}

-(NSInteger) monthsSinceStart {
    return [self monthsSinceDate:self.startTime];
}

-(NSInteger) monthsSinceEnd {
    return [self monthsSinceDate:self.endTime];
}

-(NSNumber*)startedDaysAgo:(NSNumber*)days fromDate:(NSDate*)referenceDate {
    return [NSNumber numberWithInt:1];
}

-(NSDate*)date {
    if (_date == nil) {
        self.date = [[TTTimeProvider instance] dateWithMidnight:self.startTime];
    }
    return _date;
}
@end
