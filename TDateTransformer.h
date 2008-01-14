/*
 *  TDateTransformer.h
 *  Time Tracker
 *
 *  Created by Rainer Burgstaller on 29.11.07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */
#import "Foundation/NSDateFormatter.h"
#import "Foundation/NSValueTransformer.h"

@interface TDateTransformer: NSValueTransformer 
{
	NSDateFormatter *_dateFormatter;
}
@end
@implementation TDateTransformer
- (id) init  
{
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	/*
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	*/
	return self;
}

+ (Class)transformedValueClass 
{ 
	return [NSString class]; 
}

+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}

- (id)transformedValue:(id)value {
	return [_dateFormatter stringFromDate:value];
//    return (value == nil) ? nil : NSStringFromClass([value class]);
}
@end


@interface TTimeTransformer: NSValueTransformer 
{
	NSDateFormatter *_timeFormatter;
}
@end
@implementation TTimeTransformer
- (id) init  
{
	_timeFormatter = [[NSDateFormatter alloc] init];
	[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_timeFormatter setDateStyle:NSDateFormatterNoStyle];
	/*
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	*/
	return self;
}

+ (Class)transformedValueClass 
{ 
	return [NSString class]; 
}

+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}

- (id)transformedValue:(id)value {
	return [_timeFormatter stringFromDate:value];
//    return (value == nil) ? nil : NSStringFromClass([value class]);
}
@end