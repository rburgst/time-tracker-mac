//
//  TProject.h
//  Time Tracker
//
//  Created by Ivan Dramaliev on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TTask.h"

@interface TProject : NSObject <NSCoding> {
	NSString *_name;
	NSMutableArray *_tasks;
	int _totalTime;
}

- (NSString *) name;
- (void) setName: (NSString *) name;

- (NSMutableArray *) tasks;
- (void) addTask: (TTask *) task;

- (int) totalTime;
- (void) updateTotalTime;

@end
