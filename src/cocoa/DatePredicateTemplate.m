//
//  DatePredicateTemplate.m
//  Time Tracker
//
//  Created by Rainer Burgstaller on 27.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DatePredicateTemplate.h"
#import "TTTimeProvider.h"
#import <Foundation/NSException.h>

/* This template is used for filters of the form
 * start/end date is at least/most XXX days/weeks/months ago.
 */

@implementation DatePredicateTemplate

@synthesize _templateViews;

#pragma mark row template implementation

/// Determines whether the given predicate is handled by us
- (double)matchForPredicate:(NSPredicate *)predicate {
    if ([predicate isKindOfClass:[NSComparisonPredicate class]] == NO) {
        return 0.0;
    }
    NSString *predString = [predicate predicateFormat];
    // This is out of date and can be removed.
    if ([predString hasPrefix:@"daysSince"] 
        || [predString hasPrefix:@"weeksSince"]
        || [predString hasPrefix:@"monthsSince"]) {
        return 1.0;
    }
    // typically we use variables for start date and end date comparisons
    if ([predString rangeOfString:@"$"].location != NSNotFound) {
        return 1.0;
    }
    return 0.0;
}

- (NSPredicate*) predicateWithSubpredicates:(NSArray *)subpredicates {
    NSArray* views = [self templateViews];
    NSPopUpButton *timeInterval = (NSPopUpButton*) [views objectAtIndex:3];
    NSPopUpButton *qualifier = (NSPopUpButton*) [views objectAtIndex:1];
    NSTextField *field = (NSTextField*) [views objectAtIndex:2];
    int timeDeltaAgo = [field intValue];
    int intervalIndex = [timeInterval indexOfSelectedItem];
    NSInteger comparisonType = 0;
    TTTimeProvider *provider = [TTTimeProvider instance];
    
    switch ([qualifier indexOfSelectedItem]) {
        case 0:
            comparisonType = NSGreaterThanOrEqualToPredicateOperatorType;
            break;
        case 1:
            comparisonType = NSLessThanOrEqualToPredicateOperatorType;
            break;
        case 2:
            switch (intervalIndex) {
                case 0:
                    return [provider predicateWithSingleDayFromToday:timeDeltaAgo];
                case 1:
                    return [provider predicateWithSingleWeekFromToday:timeDeltaAgo];
                case 2:
                    return [provider predicateWithSingleMonthFromToday:timeDeltaAgo];

                default:
                    break;
            }
            break;
        default:
            break;
    }
    
    switch (intervalIndex) {
        case 0: // DAY
            return [[TTTimeProvider instance] predicateWithStartDateFromToday:timeDeltaAgo comparisonType:comparisonType];            

        case 1: // week
            if (comparisonType == NSLessThanOrEqualToPredicateOperatorType) {
                return [[TTTimeProvider instance] predicateWithWeekEndDateFromToday:timeDeltaAgo comparisonType:comparisonType];                
            } else {
                return [[TTTimeProvider instance] predicateWithWeekStartDateFromToday:timeDeltaAgo comparisonType:comparisonType];                
            }
            

        case 2: // month
            if (comparisonType == NSLessThanOrEqualToPredicateOperatorType) {
                return [[TTTimeProvider instance] predicateWithMonthEndDateFromToday:timeDeltaAgo comparisonType:comparisonType];                
            } else {
                return [[TTTimeProvider instance] predicateWithMonthStartDateFromToday:timeDeltaAgo comparisonType:comparisonType];                
            }

        default:
            break;
            
    }
    NSAssert(NO, @"Should never get here");
    return nil;
}

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
    [qualifier addItemWithTitle:@"exactly"];
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

-(BOOL) parseVariable:(NSString*)variable outType:(int*)type outValue:(int*)value outStart:(BOOL*)start {
    if ([variable hasPrefix:@"days"]) {
        *type = 1;
    } else if ([variable hasPrefix:@"weeks"]) {
        *type = 2;
    } else if ([variable hasPrefix:@"months"]) {
        *type = 3;
    }
    if ([variable rangeOfString:@"Start"].location != NSNotFound) {
        *start = YES;
    } else {
        *start = NO;
    }
    int startOfNumber = [variable rangeOfString:@"_"].location + 1;
    NSString *numString = [variable substringFromIndex:startOfNumber];
    *value = [numString intValue];
    return YES;
}

- (void)setPredicate:(NSPredicate *)predicate {
    NSArray *views = [self templateViews];
    NSPopUpButton *durationFilter = [views objectAtIndex:3];
    NSPopUpButton *comparator = [views objectAtIndex:1];
    NSTextField *numberField = [views objectAtIndex:2];
    NSComparisonPredicate *compPred = (NSComparisonPredicate*)predicate;
    NSExpression *lhs = [compPred leftExpression];
    NSExpression *rhs = [compPred rightExpression];
    if ([[lhs keyPath] isEqualToString:@"daysSinceStart"]) {
        [durationFilter selectItemAtIndex:0];
        [numberField setStringValue:[rhs constantValue]];
    } else if ([[lhs keyPath] isEqualToString:@"weeksSinceStart"]) {
        [durationFilter selectItemAtIndex:1];
        [numberField setStringValue:[rhs constantValue]];
    } else if ([[lhs keyPath] isEqualToString:@"monthsSinceStart"]) {
        [durationFilter selectItemAtIndex:2];
        [numberField setStringValue:[rhs constantValue]];
    } else if ([rhs expressionType] == NSVariableExpressionType) {
        NSString *var = [rhs variable];
        int type = 0;
        int value = 0;
        BOOL start = NO;
        if ([self parseVariable:var outType:&type outValue:&value outStart:&start]) {
            [durationFilter selectItemAtIndex:type-1];
            [numberField setStringValue:[NSString stringWithFormat:@"%d", value]];
        }
    } else if (compPred.predicateOperatorType == NSBetweenPredicateOperatorType) {
        [comparator selectItemAtIndex:2];
        int type = 0;
        int value = 0;
        BOOL start = NO;
        NSString *var = [rhs description];
        NSRange found = [var rangeOfString:@","];
        NSString *variable = [var substringWithRange:NSMakeRange(2, found.location - 2)];
        NSLog(@"found variable: %@", variable);
        if ([self parseVariable:variable outType:&type outValue:&value outStart:&start]) {
            [durationFilter selectItemAtIndex:type-1];
            [numberField setStringValue:[NSString stringWithFormat:@"%d", value]];
            return;
        }
    }
    switch ([compPred predicateOperatorType]) {
        case NSLessThanOrEqualToComparison:
            [comparator selectItemAtIndex:0];
            break;
        case NSGreaterThanOrEqualToComparison: 
            [comparator selectItemAtIndex:1];
            break;
        case NSEqualToPredicateOperatorType:
            [comparator selectItemAtIndex:2];
            break;
            
        default:
            NSLog(@"Unexpected comparator: @%", predicate);
            break;
    }
    
}

// this does not seem to be used
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
    NSLog(@"Validate %@", anItem);
    return NO;
}

-(void) dealloc {
    self._templateViews = nil;
    [super dealloc];
}
@end
