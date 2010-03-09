
#import "CaseInsensitivePredicateTemplate.h"
#import "TTTimeProvider.h"

/* This template is used for filters of the form
 * start/end time is DATE
 */

@implementation CaseInsensitivePredicateTemplate

- (double)matchForPredicate:(NSPredicate *)predicate {
    if (![predicate isKindOfClass:[NSComparisonPredicate class]]) {
        return 0.0;
    }
    NSComparisonPredicate *compPred = (NSComparisonPredicate*)predicate;
    NSExpression *leftExp = [compPred leftExpression];
    if (leftExp.expressionType == NSKeyPathExpressionType) {
        if ([leftExp.keyPath isEqualToString:@"weekday"]) {
            return 0.0;
        }
    }
    double result = [super matchForPredicate:predicate];
    return result;
}    

- (NSPredicate *)predicateWithSubpredicates:(NSArray *)subpredicates
{
    NSArray *views = [self templateViews];
    NSComparisonPredicate *predicate = nil;    
    // make sure the selected date starts at midnight
    NSView *rightView = [views objectAtIndex:2];
    if ([rightView isKindOfClass:[NSDatePicker class]]) {
        NSDatePicker *picker = (NSDatePicker*)rightView;
        NSDate *date = [picker dateValue];
        [picker setDateValue:[[TTTimeProvider instance] dateWithMidnight:date]];
        predicate = (NSComparisonPredicate *)[super predicateWithSubpredicates:subpredicates];
    }

    // construct an identical predicate, but add the NSCaseInsensitivePredicateOption flag
    return [NSComparisonPredicate 
                predicateWithLeftExpression:[predicate leftExpression]
                            rightExpression:[predicate rightExpression]
                                   modifier:[predicate comparisonPredicateModifier]
                                       type:[predicate predicateOperatorType]
                                    options:[predicate options] | NSCaseInsensitivePredicateOption];
}
@end

