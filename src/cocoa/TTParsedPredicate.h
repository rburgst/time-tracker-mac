//
//  NSParsedPredicate.h
//  Time Tracker
//
//  Created by Rainer Burgstaller on 17.02.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TTParsedPredicate : NSPredicate {
    NSPredicate *_template;
}

@property(retain,nonatomic) NSPredicate* template;


+(NSPredicate*) producePredicateFromTemplate:(NSPredicate*) template;
@end
