//
//  DatePredicateTemplate.m
//  Time Tracker
//
//  Created by Rainer Burgstaller on 27.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DatePredicateTemplate.h"


@implementation DatePredicateTemplate

@synthesize _templateViews;

- (NSArray*) templateViews {
    if (_templateViews != nil) {
        return _templateViews;
    }
//    NSArray *result = [super templateViews];
    NSPopUpButton *label = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(37.0, 3.0, 60.0, 19.0)];
    [label addItemWithTitle:@"Date is"];
    [label sizeToFit];

    NSPopUpButton *qualifier = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(37.0, 3.0, 60.0, 19.0)];
    [qualifier addItemWithTitle:@"at most"];
    [qualifier addItemWithTitle:@"at least"];
    [qualifier sizeToFit];
    
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(120.0, 3.0, 40.0, 19.0)];
    [field setIntValue:1];
    NSPopUpButton *popup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(205.0, 3.0, 70.0, 19.0)];
//    [popup addItemWithTitle:@"hours ago"];
    [popup addItemWithTitle:@"days ago"];
    [popup addItemWithTitle:@"weeks ago"];
    [popup addItemWithTitle:@"months ago"];
    [popup addItemWithTitle:@"years ago"];
    [popup sizeToFit];
    NSArray *result = [NSArray arrayWithObjects:label, qualifier, field, popup, nil];
    [label release];
    [qualifier release];
    [field release];
    [popup release];
    self._templateViews = result;
    return result;
}

- (NSPredicate*) predicateWithSubpredicates:(NSArray *)subpredicates {
    NSArray* views = [self templateViews];
    NSPopUpButton *timeInterval = (NSPopUpButton*) [views objectAtIndex:3];
    NSPopUpButton *qualifier = (NSPopUpButton*) [views objectAtIndex:1];
    NSTextField *field = (NSTextField*) [views objectAtIndex:2];
    int timeDeltaAgo = [field intValue];
    int intervalIndex = [timeInterval indexOfSelectedItem];
    NSInteger comparisonType = [qualifier indexOfSelectedItem] == 0 ? 
        NSGreaterThanOrEqualToPredicateOperatorType : NSLessThanOrEqualToPredicateOperatorType;
    long day = 1;
    long week = 7 * day;
    long month = 30 * day;
    long year = 365 * day;
    long intervals[] = {
        day, week, month, year
    };
    long selectedInterval = intervals[intervalIndex];
    long totalDelta = selectedInterval * timeDeltaAgo;
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:-totalDelta];
    NSDate *startDate = [cal dateByAddingComponents:components toDate:now options:0];
    [components release];

    NSPredicate *result = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"startTime"]
                                                             rightExpression:[NSExpression expressionForConstantValue:startDate]
                                                                    modifier:NSDirectPredicateModifier
                                                                        type:comparisonType
                                                                     options:0];
    
    return result;
}

-(void) dealloc {
    self._templateViews = nil;
    [super dealloc];
}
@end
