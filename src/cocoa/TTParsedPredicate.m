//
//  TTParsedPredicate.m
//  Time Tracker
//
//  Created by Rainer Burgstaller on 17.02.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TTParsedPredicate.h"

#import "TTTimeProvider.h"

#define AGOTYPE_DAYS 1
#define AGOTYPE_WEEKS 2
#define AGOTYPE_MONTHS 3


@implementation TTParsedPredicate

@synthesize template = _template;

+(NSPredicate*) producePredicateFromTemplate:(NSPredicate*) template {
    // search for all variables with daysAgo
    NSLog(@"input predicate %@", template);
    NSString *templateString = [template predicateFormat];
    NSMutableString *resultString = [NSMutableString stringWithString:templateString];
    
    NSScanner *scanner = [NSScanner scannerWithString:templateString];
    NSString *result;
    NSDictionary *varDic = [NSMutableDictionary dictionaryWithCapacity:5];
    while (![scanner isAtEnd]) {
        if (![scanner scanUpToString:@"$" intoString:&result]) {
            break;
        }
        if ([scanner isAtEnd]) {
            // havent found the target
            break;
        }
        // now decide which one we have
        NSString *keyTemplate = nil;
        NSInteger agoType = -1;
        BOOL start = NO;
        if ([scanner scanString:@"$daysAgoStart_" intoString:&result]) {
            keyTemplate = @"daysAgoStart_";
            agoType = AGOTYPE_DAYS;
            start = YES;
        } else if ([scanner scanString:@"$daysAgoEnd_" intoString:&result]) {
            keyTemplate = @"daysAgoEnd_";
            agoType = AGOTYPE_DAYS;
            start = NO;
        } else if ([scanner scanString:@"$weeksAgo_" intoString:&result]) {
            keyTemplate = @"weeksAgo_";
            agoType = AGOTYPE_WEEKS;
            start = YES;
        } else if ([scanner scanString:@"$weeksAgoStart_" intoString:&result]) {
            keyTemplate = @"weeksAgoStart_";
            agoType = AGOTYPE_WEEKS;
            start = YES;
        } else if ([scanner scanString:@"$weeksAgoEnd_" intoString:&result]) {
            keyTemplate = @"weeksAgoEnd_";
            agoType = AGOTYPE_WEEKS;
            start = NO;
        } else if ([scanner scanString:@"$monthsAgo_" intoString:&result]) {
            keyTemplate = @"monthsAgo_";
            agoType = AGOTYPE_MONTHS;
            start = YES;
        } else if ([scanner scanString:@"$monthsAgoStart_" intoString:&result]) {
            keyTemplate = @"monthsAgoStart_";
            agoType = AGOTYPE_MONTHS;
            start = YES;
        } else if ([scanner scanString:@"$monthsAgoEnd_" intoString:&result]) {
            keyTemplate = @"monthsAgoEnd_";
            agoType = AGOTYPE_MONTHS;
            start = NO;
        }
        if (keyTemplate != nil) {
            int value = 0;
            BOOL success = [scanner scanInt:&value];
            if (!success) {
                NSLog(@"Scanner failed parsing int at %d", [scanner scanLocation]);
            }
            NSString *key = [NSString stringWithFormat:@"%@%d", keyTemplate, value];
            TTTimeProvider *provider = [TTTimeProvider instance];
            NSDate *daysAgoDate = nil;
            switch (agoType) {
                case AGOTYPE_DAYS:
                    daysAgoDate = (start == YES) ? 
                    [provider dayStartDateWithDaysFromToday:value]
                    : [provider dayEndDateWithDaysFromToday:value];
                    break;
                case AGOTYPE_WEEKS:
                    daysAgoDate = (start == YES) ?
                    [provider weekStartDateWithWeeksFromToday:value] : 
                    [provider weekEndDateWithWeeksFromToday:value];
	                    break;
                case AGOTYPE_MONTHS:
                    daysAgoDate = (start == YES) ?
                    [provider monthStartDateWithMonthsFromToday:value] : 
                    [provider monthEndDateWithMonthsFromToday:value];
                    break;
                default:
                    break;
            }
            NSString *keyWithDollar = [NSString stringWithFormat:@"$%@", key];
            NSExpression *exp = [NSExpression expressionForConstantValue:daysAgoDate];
            [resultString replaceOccurrencesOfString:keyWithDollar 
                                          withString:[exp description] 
                                             options:NSLiteralSearch 
                                               range:NSMakeRange(0, [resultString length])];
            
            [varDic setValue:daysAgoDate forKey:key];            
        }
    }
    [varDic setValue:[[TTTimeProvider instance] todayStartTime] forKey:@"TODAY"];
    [varDic setValue:[[TTTimeProvider instance] todayEndTime] forKey:@"TOMORROW"];
    NSPredicate *resultTemplate = [NSPredicate predicateWithFormat:resultString];
    NSPredicate *resultPred = [resultTemplate predicateWithSubstitutionVariables:varDic];
    NSLog(@"result predicate %@", resultPred);
    
    return resultPred;
}

@end
