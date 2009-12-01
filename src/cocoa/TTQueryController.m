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
    SearchQuery *query = [[SearchQuery alloc] initWithTitle:@"Last week" predicate:[provider predicateWithSingleWeekFromToday:1]];
    [iSearchQueries addObject:query];
    [query release];
    
    query = [[SearchQuery alloc] initWithTitle:@"This week" predicate:[provider predicateWithSingleWeekFromToday:0]];
    [iSearchQueries addObject:query];
    [query release];
    NSPredicate *predicate = [provider predicateWithSingleDayFromToday:0];
    query = [[[SearchQuery alloc] initWithTitle:@"Today" predicate:predicate] autorelease];
    [iSearchQueries addObject:query];
    
    iGroupRowCell = [[NSTextFieldCell alloc] init];
    [iGroupRowCell setEditable:NO];
    [iGroupRowCell setLineBreakMode:NSLineBreakByTruncatingTail]; 
    [_outlineView reloadItem:nil];
}

#pragma mark -
#pragma mark NSOutlineView datasource and delegate methods

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return 1;
    else {
       return [iSearchQueries count] + 1; 
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return iSearchQueries;
    } else if (index < [iSearchQueries count]) {
        return [iSearchQueries objectAtIndex:index];
    } else {
        return @"New Search...";
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == nil || item == iSearchQueries) {
        return YES;
    }
/*    if ([item isKindOfClass:[SearchQuery class]]) {
        return YES;
    }*/
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    id result = nil;
    
    if ([item isKindOfClass:[SearchQuery class]]) {
        SearchQuery *query = item;
        result = query.title;
    } else if ([item isKindOfClass:[NSArray class]]) {
        result = @"Queries";
    } else {
        result = @"New Search ...";
    }
    return result;
}


/*
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // The "nil" tableColumn is an indicator for the "full width" row
    if (tableColumn == nil) {
        if ([item isKindOfClass:[SearchQuery class]]) {
            return iGroupRowCell;
        }
    }
    return nil;
}
*/
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return item == nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSLog(@"selection Clicked: %@", notification);
    NSIndexSet *selection = [_outlineView selectedRowIndexes];
    if ([selection count] == 0) {
        NSLog(@"Nothing selected");
    } else if ([selection count] == 1) {
        id selectedItem = [_outlineView itemAtRow:[selection firstIndex]];
        if ([selectedItem isKindOfClass:[SearchQuery class]]) {
            SearchQuery *searchItem = selectedItem;
            [_delegate filterQuerySelected:searchItem];
        } else if ([selectedItem isKindOfClass:[NSString class]]) {
            [_delegate newFilterSelected];
        }
        
    }
}
@end
