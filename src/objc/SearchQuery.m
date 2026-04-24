//
//  SearchQuery.m
//  Time Tracker
//
//  Created by Rainer Burgstaller on 21.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SearchQuery.h"


@implementation SearchQuery

@synthesize title = _title;
@synthesize predicate = _predicate;

-(id) initWithTitle:(NSString*)title predicate:(NSPredicate*)predicate {
    if (!(self = [super init])) return nil;
    self.title = title;
    self.predicate = predicate;
    return self;
}




@end
