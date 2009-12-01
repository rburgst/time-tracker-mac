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

- (NSArray*) templateViews {
    if (_templateViews != nil) {
        return _templateViews;
    }
    NSMutableArray *result = [NSMutableArray arrayWithArray:[super templateViews]];
    NSPopUpButton *search = [result objectAtIndex:0];
//    [search selectItemAtIndex:0];
    
    NSButton *applyBtn = [[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 18.0)];
    applyBtn.title = @"Apply";
    [applyBtn setBezelStyle:NSRoundRectBezelStyle];
  //  applyBtn.font = search.font;
    [applyBtn.cell setControlSize:NSMiniControlSize];
    [applyBtn sizeToFit];
    [result addObject:applyBtn];
    [applyBtn release];
    
    NSButton *saveBtn = [[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 18.0)];
    saveBtn.title = @"Save";
    saveBtn.bezelStyle = NSRoundRectBezelStyle;
//    saveBtn.font = search.font;
    [saveBtn.cell setControlSize:NSMiniControlSize];
    [saveBtn sizeToFit];
    [result addObject:saveBtn];
    [saveBtn release];
    self._templateViews = result;
    return result;
}

-(void) dealloc {
    self._templateViews = nil;
    [super dealloc];
}
@end
