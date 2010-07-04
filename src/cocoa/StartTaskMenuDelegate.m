#import "StartTaskMenuDelegate.h"

#import "MainController.h"
#import "TProject.h"
#import "TTask.h"

@implementation StartTaskMenuDelegate
-(id) initWithController:(MainController*) controller;
{
    _controller = controller;
    return self;
}

- (IBAction) menuItemClicked:(id)menuItem
{
    NSMenuItem *item = (NSMenuItem*)menuItem;
    NSLog(@"Select menu ITem %@", [item title]);
    TTask *task = (TTask*) [item representedObject];
    if (task != nil) {
        TProject *project = [task parentProject];
        
        // if there is another timer already running, stop it before
        // starting a new recording.
        if (_controller.timerRunning) {
            [_controller stopTimer];
        }
        [_controller selectTask:task project:project];
        [_controller startTimer];
        [_controller reloadWorkPeriods];
    }
}

- (void)menuNeedsUpdate:(NSMenu*)menu
{
    // empty the old items
    while ([menu numberOfItems] > 0) {
        [menu removeItemAtIndex:0];
    }

    if (_controller.timerRunning) {
        // show stop symbol
        NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"Edit current timer" action:@selector(clickedEditCurrentWorkperiod:) keyEquivalent:@""];
        [editItem setTarget:_controller];
        [menu addItem:editItem];
        [editItem release];
        NSMenuItem *stopItem = [[NSMenuItem alloc] initWithTitle:@"Stop current timer" action:@selector(clickedStartStopTimer:) keyEquivalent:@""];
        [stopItem setTarget:_controller];
        [menu addItem:stopItem];
        [stopItem release];
        
    }
    // now fill with new ones

    BOOL shouldShowMenu = NO;
    NSArray *lruTasks = [_controller lruTasks];
    NSInteger numLruTasks = [lruTasks count];
    id<ITask>selTask = [_controller selectedTask];
    TTask *task = nil;
    if ([selTask isKindOfClass:[TTask class]]) {
        // the task can be selected, it is not a meta task
        shouldShowMenu = YES;
        task = (TTask*) selTask;
    }
    if (numLruTasks > 0) {
        shouldShowMenu = YES;
    }

    if (shouldShowMenu) {
        NSMenuItem *startItem = [[NSMenuItem alloc] initWithTitle:@"Start:" action:nil keyEquivalent:@""];
        [menu addItem:startItem];
        [startItem release];
    }
    
    if (task != nil) {
        TProject *project = [task parentProject];
        NSString *title = [NSString stringWithFormat:@"→ %@ : %@", [project name], [task name]];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(menuItemClicked:) keyEquivalent:@""];
        [item setRepresentedObject:task];
        [item setTarget:self];
        [menu addItem:item];
        [item release];        
    }
    
    NSEnumerator *enumItems = [[_controller lruTasks] objectEnumerator];    

    while ((task = [enumItems nextObject]) != nil) {
        TProject *project = [task parentProject];
        NSString *title = [NSString stringWithFormat:@"• %@ : %@", [project name], [task name]];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(menuItemClicked:) keyEquivalent:@""];
        [item setRepresentedObject:task];
        [item setTarget:self];
        [menu addItem:item];
        [item release];
    }                               
}

- (NSInteger)numberOfItemsInMenu:(NSMenu*)menu
{
    return [[_controller lruTasks] count];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem {
	if ([((NSObject*)anItem) isKindOfClass:[NSMenuItem class]]) {
		NSObject *repObj = [((NSMenuItem*)anItem) representedObject];
		if ([repObj isKindOfClass:[TTask class]]) {
			return !((TTask*)repObj).closed;
		}
	}
	return YES;
}

@end
