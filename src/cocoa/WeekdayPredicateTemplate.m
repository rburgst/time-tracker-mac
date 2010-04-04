//
//  WeekdayPredicateTemplate.m
//
//  Created by Rainer Burgstaller on 27.02.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WeekdayPredicateTemplate.h"

@implementation WeekdayPredicateTemplate
- (double)matchForPredicate:(NSPredicate *)predicate {
    if (![predicate isKindOfClass:[NSComparisonPredicate class]]) {
        return 0.0;
    }
    NSComparisonPredicate *compPred = (NSComparisonPredicate*)predicate;
    NSExpression *leftExp = [compPred leftExpression];
    if (leftExp.expressionType == NSKeyPathExpressionType) {
        if ([leftExp.keyPath isEqualToString:@"weekday"]) {
            return 1.0;
        }
    }
    double result = [super matchForPredicate:predicate];
    return result;
}    

- (NSPredicate *)predicateWithSubpredicates:(NSArray *)subpredicates
{
    NSPopUpButton *popup = (NSPopUpButton*) [[self templateViews] objectAtIndex:2];
    return [NSComparisonPredicate predicateWithFormat:@"weekday == %d", [popup selectedTag]];
}    


- (void)setPredicate:(NSPredicate *)predicate {
    NSComparisonPredicate *compPred = (NSComparisonPredicate*)predicate;
    NSArray *views = [self templateViews];
    NSPopUpButton *last = [views objectAtIndex:2];
    NSExpression *rightExp = [compPred rightExpression];
    NSNumber *num = [rightExp constantValue];
    [last selectItemWithTag:num.intValue];
}

@end
