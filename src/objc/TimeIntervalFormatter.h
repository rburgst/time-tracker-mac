//
//  TimeIntervalFormatter.h
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TimeIntervalFormatter : NSValueTransformer 
{
    BOOL _decimalMode;
}

+ (NSString *) secondsToString: (int) seconds;

+ (NSString*) secondsToDecimalHours: (int) seconds; 

+ (Class) transformedValueClass;

+ (BOOL)allowsReverseTransformation;

- (id)transformedValue:(id) value;

- (NSString*) transformSeconds:(int) seconds;

@property BOOL decimalMode;

@end
