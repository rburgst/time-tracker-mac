/* MainController */

#import <Cocoa/Cocoa.h>
#import "TProject.h"
#import "TTask.h"
#import "TWorkPeriod.h"

@interface MainController : NSObject
{
	NSUserDefaults *defaults;
	NSTimer *timer;
	NSStatusItem *statusItem;
	
	NSImage *playItemImage;
	NSImage *playItemHighlightImage;
	
	NSImage *stopItemImage;
	NSImage *stopItemHighlightImage;

	NSImage *playToolImage;
	NSImage *stopToolImage;
	NSImage *addTaskToolImage;
	NSImage *addProjectToolImage;

	IBOutlet NSTextField *tfActiveProject;
	IBOutlet NSTextField *tfActiveTask;
    IBOutlet NSTableView *tvProjects;
    IBOutlet NSTableView *tvTasks;
    IBOutlet NSTableView *tvWorkPeriods;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSPanel *panelEditWorkPeriod;
    IBOutlet NSPanel *panelIdleNotification;
    
	IBOutlet NSDatePicker *dtpEditWorkPeriodStartTime;
	IBOutlet NSDatePicker *dtpEditWorkPeriodEndTime;
	
	IBOutlet NSMenuItem *startMenuItem;
	
	NSToolbarItem *startstopToolbarItem;
	
	NSMutableArray *_projects;
	NSMutableDictionary *_projects_lastTask;
	TProject *_selProject;
	TTask *_selTask;
	TWorkPeriod *_curWorkPeriod;
	TProject *_curProject;
	TTask *_curTask;
	NSDateFormatter *_dateFormatter;
	
	NSDate *_lastNonIdleTime;
	int timeSinceSave;
}

// actions
- (IBAction)clickedAddProject:(id)sender;
- (IBAction)clickedAddTask:(id)sender;
- (IBAction)clickedStartStopTimer:(id)sender;
- (IBAction)clickedDelete:(id)sender;
- (IBAction)clickedChangeWorkPeriod:(id)sender;
- (IBAction)clickedCountIdleTimeYes:(id)sender;
- (IBAction)clickedCountIdleTimeNo:(id)sender;

- (void) timerFunc: (NSTimer *) timer;
- (void) stopTimer:(NSDate*)endTime;
- (void) stopTimer;
- (void) startTimer;
- (void) createTask;
- (void) createProject;
- (int)idleTime;
- (void) saveData;

- (void) updateStartStopState;
- (void) updateProminentDisplay;

- (BOOL) validateUserInterfaceItem:(id)anItem;

@end
