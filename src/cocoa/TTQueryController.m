//
//  TTQueryController.m
//
//  Created by Rainer Burgstaller on 21.11.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TTQueryController.h"
#import "SearchQuery.h"
#import "TTTimeProvider.h"

@implementation TTQueryController

-(id) init {    
    [super init];
    
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {        
    return [self init];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {

}

-(void) awakeFromNib {
    TTTimeProvider *provider = [TTTimeProvider instance];
    iSearchQueries = [[NSMutableArray alloc] init];

    SearchQuery *query = [[SearchQuery alloc] initWithTitle:@"None" predicate:nil];
    [iSearchQueries addObject:query];
    [query release];
    
    query = [[SearchQuery alloc] initWithTitle:@"Last week" predicate:[provider predicateWithSingleWeekFromToday:1]];
    [iSearchQueries addObject:query];
    [query release];
    
    query = [[SearchQuery alloc] initWithTitle:@"This week" predicate:[provider predicateWithSingleWeekFromToday:0]];
    [iSearchQueries addObject:query];
    [query release];
    
    query = [[SearchQuery alloc] initWithTitle:@"Yesterday" predicate:[provider predicateWithSingleDayFromToday:1]];
    [iSearchQueries addObject:query];
    [query release];
    
    NSPredicate *predicate = [provider predicateWithSingleDayFromToday:0];
    query = [[[SearchQuery alloc] initWithTitle:@"Today" predicate:predicate] autorelease];
    [iSearchQueries addObject:query];

    [_tableView reloadData];
}

#pragma mark -
#pragma mark NSTableView datasource and delegate methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
   return [iSearchQueries count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
    SearchQuery *query = [iSearchQueries objectAtIndex:row];
    return query.title;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSLog(@"selection Clicked: %@", notification);
    NSInteger selectionIndex = [_tableView selectedRow];
    if (selectionIndex >= 0) {
        SearchQuery *searchItem = [iSearchQueries objectAtIndex:selectionIndex];
        [_delegate filterQuerySelected:searchItem];        
    }
}
@end
