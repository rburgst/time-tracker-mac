//
//  TMetaProject.m
//  Time Tracker
//
//  Created by Rainer Burgstaller on 25.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TMetaProject.h"


@implementation TMetaProject

- (id)initWithCoder:(NSCoder *)coder
{
	assert(@"not supported");
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	assert(@"not supported");
}

- (NSInteger) calculateTime:(BOOL)closed
{
	NSInteger result = 0;
	NSEnumerator *enumProjects = [_projects objectEnumerator];
	TProject *project = nil;
	while ((project = [enumProjects nextObject]) != nil) {
		if (project.closed == closed) {
			result += [project totalTime];
		}
	}
	return result;
}

- (int) totalTime
{
	return [self calculateTime:NO];
}

- (NSInteger) closedTime 
{
	return [self calculateTime:YES];
}

- (void) updateTotalTime
{
	NSEnumerator *enumProjects = [_projects objectEnumerator];
	TProject *project = nil;
	while ((project = [enumProjects nextObject]) != nil) {
		[project updateTotalTime];
	}
}

- (NSArray *) tasks
{
	NSEnumerator *enumProjects = [_projects objectEnumerator];
	TProject *project = nil;
	NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
	while ((project = [enumProjects nextObject]) != nil) {
		[result addObjectsFromArray:[project tasks]];
	}
	return result;
}

- (NSString*) name
{
	return @"All Projects";
}

- (void) setProjects:(NSMutableArray*) projects
{
	if (_projects != nil) {
		[_projects release];
	}
	_projects = [projects retain];
}

- (TProject*) projectForTask:(TTask*)task returnIndex:(int*)taskIndex {
	NSEnumerator *enumerator = [_projects objectEnumerator];
	id aProject;
	*taskIndex = -1;
	
	while (aProject = [enumerator nextObject])
	{
		NSUInteger result = [[aProject tasks] indexOfObject:task];
		if (result != NSNotFound) {
			*taskIndex = result;
			return aProject;
		}
	}
	*taskIndex = -1;
	return nil;
}

- (id<IProject>) removeTask:(TTask*)task {
	int index = -1;
	TProject *project = [self projectForTask:task returnIndex:&index];
	[[project tasks] removeObject:task];
	return self;
}

- (int) filteredTime:(NSPredicate*) filter
{
	if (filter == nil) {
		return [self totalTime];
	}
	int result = 0;
	NSEnumerator *enumProjects = [_projects objectEnumerator];
	id project;
	while ((project = [enumProjects nextObject]) != nil) {
		result += [project filteredTime:filter];
	}
	return result;
}


- (NSArray *) matchingTasks:(NSPredicate*) filter //  : (bool) includeEmptyTasks
{
	if (filter == nil) {
		return [self tasks];
	}
	NSEnumerator *enumProjects = [_projects objectEnumerator];
	NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];

	id project;
	while ((project = [enumProjects nextObject]) != nil) {
		[result addObjectsFromArray: [project matchingTasks:filter]];
	}
	return result;
}

- (BOOL) doesTaskNameExist:(NSString*)name {
    NSEnumerator *enumTasks = [[self tasks] objectEnumerator];
    TTask *task;
    while ((task = [enumTasks nextObject]) != nil) {
        if ([name isEqualToString:[task name]]) {
            return YES;
        }
    }
    return NO;
}

- (void)moveTask:(TTask *)task toIndex:(NSInteger)index {
	assert(NO);
}
@end
