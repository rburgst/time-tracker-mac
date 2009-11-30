
#import "CaseInsensitivePredicateTemplate.h"

@implementation CaseInsensitivePredicateTemplate

- (NSPredicate *)predicateWithSubpredicates:(NSArray *)subpredicates
{
    
    NSArray *views = [self templateViews];
    NSComparisonPredicate *predicate = nil;    
    // make sure the selected date starts at midnight
    NSView *rightView = [views objectAtIndex:2];
    if ([rightView isKindOfClass:[NSDatePicker class]]) {
        NSDatePicker *picker = (NSDatePicker*)rightView;
        NSDate *date = [picker dateValue];
        NSLog(@"Date: %@", date);
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
        NSDateComponents *date00 = [cal components:unitFlags fromDate:date];
        date = [cal dateFromComponents:date00];
        [picker setDateValue:date];
        predicate = (NSComparisonPredicate *)[super predicateWithSubpredicates:subpredicates];
    } else {
        NSPopUpButton *popup = (NSPopUpButton*) rightView;

        return [NSComparisonPredicate predicateWithFormat:@"weekday == %d", [popup selectedTag]];
    }


    // construct an identical predicate, but add the NSCaseInsensitivePredicateOption flag
    return [NSComparisonPredicate predicateWithLeftExpression:
				[predicate leftExpression]
				rightExpression:[predicate rightExpression]
				modifier:[predicate comparisonPredicateModifier]
				type:[predicate predicateOperatorType]
				options:[predicate options] | NSCaseInsensitivePredicateOption];
}

@end

