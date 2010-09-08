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
#import "TTQueryController.h"
#import "TTPredicateEditorViewController.h"
#import "TTaskNameTransformer.h"

#define FILTER_MODE_NONE 0
#define FILTER_MODE_DAY 1
#define FILTER_MODE_WEEK 2
#define FILTER_MODE_MONTH 3
#define FILTER_MODE_PREDICATE 4

#define DEFAULT_LRU_SIZE 5

// forward declarations
@class StartTaskMenuDelegate;
@class TaskEditorController;

@interface MainController : NSObject<TTQueryDelegate, TTPredicateEditorDelegate>
{
	NSColor *_normalCol;
	NSColor *_highlightCol;
    NSColor *_highlightBgCol;
    NSColor *_greyCol;

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
    IBOutlet NSTableView *tvCustomers;
    IBOutlet NSTableView *tvFilters;
    
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSPanel *panelEditWorkPeriod;
    IBOutlet NSPanel *panelIdleNotification;
	IBOutlet NSPanel *panelPickFilterDate;
	TaskEditorController* _taskEditorController;
    
	IBOutlet NSDatePicker *dtpEditWorkPeriodStartTime;
	IBOutlet NSDatePicker *dtpEditWorkPeriodEndTime;
	IBOutlet NSDatePicker *dtpFilterDate;
	IBOutlet NSTextView *dtpEditWorkPeriodComment;
	
	IBOutlet NSMenuItem *startMenuItem;
	IBOutlet NSArrayController *workPeriodController;
	IBOutlet NSArrayController *taskController;
	
//	IBOutlet NSArrayController *changeProjectController;
	// the start of the filtered interval
	IBOutlet NSDate *_filterStartDate;
	// the end of the filtered interval
	IBOutlet NSDate *_filterEndDate;
	IBOutlet NSPredicate *_currentPredicate;
    IBOutlet NSPredicate *_extraFilterPredicate;
	IBOutlet NSPopUpButton *_taskPopupButton;
	IBOutlet NSPopUpButton *_projectPopupButton;
	IBOutlet NSSearchField *_searchBox;
    IBOutlet NSView *_saveCsvAuxView;
    IBOutlet TTPredicateEditorViewController *_predicateController;
	
	IBOutlet NSToolbarItem *startstopToolbarItem;
	NSMutableArray *_projects;
	IBOutlet TMetaProject *_metaProject;
	TMetaTask *_metaTask;
	id<IProject> _selProject;
	id<ITask> _selTask;
	NSArray *_filteredTasks;
	NSArray *_currentTasks;
    NSMutableArray *_lruTasks;
	TWorkPeriod *_curWorkPeriod;
	TTimeTransformer *_timeValueFormatter;
	TDateTransformer *_dateValueFormatter;
	TimeIntervalFormatter *_intervalValueFormatter;
	TTaskNameTransformer* _taskNameTransformer;
	id<IProject> _curProject;
	id<ITask> _curTask;
	NSDateFormatter *_dateFormatter;
	NSToolbarItem *_tbPickDateItem;
	
	NSDate *_lastNonIdleTime;
	NSDate *_selectedfilterDate;
	int timeSinceSave;
	int _filterMode;

    // Preferences
  	IBOutlet BOOL _autosaveCsv;
   	IBOutlet NSString *_autosaveCsvFilename;
   	IBOutlet NSString *_csvSeparatorChar;
    IBOutlet NSString *_updateURL;
    int _maxLruSize;
    NSMenu *_startMenu;
    BOOL _showTimeInMenuBar;
    int _idleTimeoutSeconds;
    BOOL _enableStandbyDetection;
    TWorkPeriod *_currentEditingWP;
    BOOL _decimalHours;
	StartTaskMenuDelegate* _startTaskMenuDelegate;
}

// actions
- (IBAction)clickedAddProject:(id)sender;
- (IBAction)clickedAddTask:(id)sender;
- (IBAction)clickedStartStopTimer:(id)sender;
- (IBAction)clickedDelete:(id)sender;
- (IBAction)clickedChangeWorkPeriod:(id)sender;
- (IBAction)clickedEditCurrentWorkperiod:(id)sender;
- (IBAction)clickedCountIdleTimeYes:(id)sender;
- (IBAction)clickedCountIdleTimeNo:(id)sender;
- (IBAction)clickedAddTimePeriod:(id)sender;
- (IBAction)clickedDeleteWorkPeriod:(id)sender;

- (IBAction)okClicked:(id) sender;
- (IBAction)cancelClicked:(id) sender;
- (IBAction)changedProjectInEditWpDialog:(id) sender;
- (IBAction)filterComments: (id)sender;
- (IBAction)actionExport:(id)sender;


- (void) provideTasksForEditWpDialog:(TProject*)project;
- (void) provideProjectsForEditWpDialog:(TProject*) selectedProject;

- (TTask*) findTaskById:(int)taskId;
- (NSArray*) lruTasks;
- (void) selectTask:(TTask*) task project:(TProject*)project;
- (void)reloadWorkPeriods;

- (void) timerFunc: (NSTimer *) timer;
- (void) stopTimer:(NSDate*)endTime;
- (void) stopTimer;
- (void) startTimer;
- (TTask*) createTask;
- (TProject*) createProject;
- (int)  idleTime;
- (void) saveData;
- (void) loadData;

- (void) updateStartStopState;
- (void) updateProminentDisplay;
- (void) reloadWorkPeriods;
- (NSString *) pathForDataFile;
- (bool) dataFileExists;
- (void) validateToolbarFilterItems;
- (void) applyFilter;
- (void) updateTaskFilterCache;

-(NSDate*) determineFilterStartDate;
-(NSDate*) determineFilterEndDate;

- (BOOL) validateUserInterfaceItem:(id)anItem;
- (TTask*) taskForWorkTimeIndex: (int) rowIndex timeIndex:(int*)resultIndex;


// properties
-(BOOL) autosaveCsv;
-(void) setAutosaveCsv:(BOOL)autosave;

-(NSString*) autosaveCsvFilename;
-(void) setAutosaveCsvFilename:(NSString*)filename;

-(NSString*) csvSeparatorChar;
-(void) setCsvSeparatorChar:(NSString*) separator;

-(int)  maxLruSize;
-(void) setMaxLruSize:(int)size;

-(void) setShowTimeInMenuBar:(BOOL)show;
-(BOOL) showTimeInMenuBar;

-(void) setIdleTimeoutSeconds:(int)seconds;
-(int)  idleTimeoutSeconds;

-(void) setEnableStandbyDetection:(BOOL)enable;
-(BOOL) enableStandbyDetection;


@property(readonly) BOOL timerRunning;
@property(retain, nonatomic) NSPredicate* extraFilterPredicate;
@property(retain, nonatomic) NSString *updateURL;
@property BOOL decimalHours;
@property(retain, nonatomic) id<ITask> selectedTask;
@property(retain, nonatomic) id<IProject> selectedProject;
@property(retain, nonatomic) NSArray* currentTasks;
@property(retain, nonatomic) TaskEditorController* taskEditorController;

@end

