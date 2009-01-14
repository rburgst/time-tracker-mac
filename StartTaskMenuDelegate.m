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
    // now fill with new ones
    NSEnumerator *enumItems = [[_controller lruTasks] objectEnumerator];
    TTask *task;
    while ((task = [enumItems nextObject]) != nil) {
        TProject *project = [task parentProject];
        NSString *title = [NSString stringWithFormat:@"%@ : %@", [project name], [task name]];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(menuItemClicked:) keyEquivalent:@""];
        [item setRepresentedObject:task];
        [item setTarget:self];
        [menu addItem:item];
        [item release];
    }                               
}

- (int)numberOfItemsInMenu:(NSMenu*)menu
{
    return [[_controller lruTasks] count];
}

@end
