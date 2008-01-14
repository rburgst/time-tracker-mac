/* MainController */

#import <Cocoa/Cocoa.h>
#import <Appkit/NSArrayController.h>
#import "TProject.h"
#import "TTask.h"
#import "TWorkPeriod.h"
#import "TMetaProject.h"
#import "IProject.h"
#import "ITask.h"
#import "TMetaTask.h"
#import "TDateTransformer.h"
#import "TimeIntervalFormatter.h"

#define FILTER_MODE_NONE 0
#define FILTER_MODE_DAY 1
#define FILTER_MODE_WEEK 2
#define FILTER_MODE_MONTH 3

@interface MainController : NSObject
{
	NSColor *_normalCol;
	NSColor *_highlightCol;

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

	NSImage *dayToolImage;
	NSImage *weekToolImage;
	NSImage *monthToolImage;
	NSImage *dayToolImageUnsel;
	NSImage *weekToolImageUnsel;
	NSImage *monthToolImageUnsel;
	NSImage *pickDateToolImage;
	
	
	IBOutlet NSTextField *tfActiveProject;
	IBOutlet NSTextField *tfActiveTask;
    IBOutlet NSTableView *tvProjects;
    IBOutlet NSTableView *tvTasks;
    IBOutlet NSTableView *tvWorkPeriods;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSPanel *panelEditWorkPeriod;
    IBOutlet NSPanel *panelIdleNotification;
	IBOutlet NSPanel *panelPickFilterDate;
    
	IBOutlet NSDatePicker *dtpEditWorkPeriodStartTime;
	IBOutlet NSDatePicker *dtpEditWorkPeriodEndTime;
	IBOutlet NSDatePicker *dtpFilterDate;
	IBOutlet NSTextView *dtpEditWorkPeriodComment;
	
	IBOutlet NSMenuItem *startMenuItem;
	IBOutlet NSArrayController *workPeriodController;
	IBOutlet NSArrayController *changeProjectController;
	// the start of the filtered interval
	IBOutlet NSDate *_filterStartDate;
	// the end of the filtered interval
	IBOutlet NSDate *_filterEndDate;
	IBOutlet NSPredicate *_currentPredicate;
	IBOutlet NSPopUpButton *_taskPopupButton;
	IBOutlet NSPopUpButton *_projectPopupButton;
	
	NSToolbarItem *startstopToolbarItem;
	NSToolbarItem *_dayToolbarItem;
	NSToolbarItem *_weekToolbarItem;	
	NSToolbarItem *_monthToolbarItem;
	NSMutableArray *_projects;
	IBOutlet TMetaProject *_metaProject;
	TMetaTask *_metaTask;
	NSMutableDictionary *_projects_lastTask;
	id<IProject> _selProject;
	id<ITask> _selTask;
	TWorkPeriod *_curWorkPeriod;
	TTimeTransformer *_timeValueFormatter;
	TDateTransformer *_dateValueFormatter;
	TimeIntervalFormatter *_intervalValueFormatter;
	id<IProject> _curProject;
	id<ITask> _curTask;
	NSDateFormatter *_dateFormatter;
	NSToolbarItem *_tbPickDateItem;
	
	NSDate *_lastNonIdleTime;
	NSDate *_selectedfilterDate;
	int timeSinceSave;
	int _filterMode;
}

// actions
- (IBAction)clickedAddProject:(id)sender;
- (IBAction)clickedAddTask:(id)sender;
- (IBAction)clickedStartStopTimer:(id)sender;
- (IBAction)clickedDelete:(id)sender;
- (IBAction)clickedChangeWorkPeriod:(id)sender;
- (IBAction)clickedCountIdleTimeYes:(id)sender;
- (IBAction)clickedCountIdleTimeNo:(id)sender;
- (IBAction)okClicked:(id) sender;
- (IBAction)cancelClicked:(id) sender;
- (IBAction)clickedFilterDateOk:(id) sender;
- (IBAction)clickedFilterDateCancel:(id) sender;
- (IBAction)changedProjectInEditWpDialog:(id) sender;

- (void) provideTasksForEditWpDialog:(TProject*)project;
- (void) provideProjectsForEditWpDialog:(TProject*) selectedProject;
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
- (void) reloadWorkPeriods;

-(NSDate*) determineFilterStartDate;
-(NSDate*) determineFilterEndDate;

- (BOOL) validateUserInterfaceItem:(id)anItem;
- (TTask*) taskForWorkTimeIndex: (int) rowIndex timeIndex:(int*)resultIndex;
@end
