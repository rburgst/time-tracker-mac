//
//  TTaskNameTransformer.m
//  Time Tracker
//
//  Created by Rainer Burgstaller on 30.05.10.
//  Copyright 2010 N/A. All rights reserved.
//

#import "TTaskNameTransformer.h"
#import "ITask.h"
#import "TTask.h"
#import "TProject.h"

@implementation TTaskNameTransformer

@synthesize showProjectName = _showProjectName;

- (id)transformedValue:(id)value {
	id<ITask> task = value;
	if (_showProjectName && [task isKindOfClass:[TTask class]]) {
		return [NSString stringWithFormat:@"%@ (%@)", task.name, ((TTask*)task).parentProject.name];
	}
    return task.name;
}

+ (Class) transformedValueClass 
{ 
	return [NSString class]; 
}

+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}

@end
