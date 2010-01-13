//
//  WorkPeriodMainPredicateTemplate.m
//  Time Tracker
//
//  Created by Rainer Burgstaller on 29.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "WorkPeriodMainPredicateTemplate.h"


@implementation WorkPeriodMainPredicateTemplate

@synthesize _templateViews;

- (double)matchForPredicate:(NSPredicate *)predicate {
    if ([predicate isKindOfClass:[NSCompoundPredicate class]] == YES) {
        return 1.0;
    }
    return 0.0;
}

-(void) dealloc {
    self._templateViews = nil;
    [super dealloc];
}
@end
