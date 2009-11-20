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



@interface TTimeTransformer: NSValueTransformer 
{
	NSDateFormatter *_timeFormatter;
}
@end
