//
//  SearchQuery.h
//  Time Tracker
//
//  Created by Rainer Burgstaller on 21.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/NSPredicate.h>


@interface SearchQuery : NSObject {
    NSPredicate *_predicate;
    NSString *_title;
}

@property(retain,nonatomic) NSPredicate* predicate;
@property(retain,nonatomic) NSString* title;

-(id) initWithTitle:(NSString*)title predicate:(NSPredicate*)predicate;
@end
