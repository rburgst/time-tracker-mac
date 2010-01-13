//
//  TTQueryController.h
//
//  Created by Rainer Burgstaller on 21.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SearchQuery;

@protocol TTQueryDelegate 

-(void) filterQuerySelected:(SearchQuery*)query;
-(void) newFilterSelected;

@end

@interface TTQueryController : NSObject<NSCoding> {
    NSMutableArray *iSearchQueries;    

    IBOutlet NSTableView* _tableView;
    IBOutlet id<TTQueryDelegate> _delegate;
}

@end
