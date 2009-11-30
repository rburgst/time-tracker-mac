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
    [super init];
    self.title = title;
    self.predicate = predicate;
    return self;
}

- (void)dealloc {
    self.title = nil;
    self.predicate = nil;
    
    [super dealloc];
}


@end
