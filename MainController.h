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
	NSMenuItem *startStopMenuItem;
	
	NSImage *playItemImage;
	NSImage *playItemHighlightImage;
	
	NSImage *stopItemImage;
	NSImage *stopItemHighlightImage;

	NSImage *playToolImage;
	NSImage *stopToolImage;
	NSImage *addTaskToolImage;
	NSImage *addProjectToolImage;

	
    IBOutlet NSTableView *tvProjects;
    IBOutlet NSTableView *tvTasks;
    IBOutlet NSTableView *tvWorkPeriods;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSPanel *panelEditWorkPeriod;
    IBOutlet NSPanel *panelIdleNotification;
    
	IBOutlet NSDatePicker *dtpEditWorkPeriodStartTime;
	IBOutlet NSDatePicker *dtpEditWorkPeriodEndTime;
	
	NSToolbarItem *startstopToolbarItem;
	NSToolbarItem *addProjectToolbarItem;
	NSToolbarItem *addTaskToolbarItem;
	
	NSMutableArray *_projects;
	TProject *_selProject;
	TTask *_selTask;
	TWorkPeriod *_curWorkPeriod;
	TProject *_curProject;
	TTask *_curTask;
	
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
- (void) stopTimer;
- (int)idleTime;
- (void) saveData;

@end
