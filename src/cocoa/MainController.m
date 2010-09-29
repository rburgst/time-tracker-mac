#include <IOKit/IOKitLib.h>
#import <AppKit/NSTableColumn.h>
#include <assert.h>

#import "MainController.h"
#import "TTask.h"
#import "IProject.h"
#import "TProject.h"
#import "TimeIntervalFormatter.h"
#import "TTTimeProvider.h"
#import "TWorkPeriod.h"
#import "TMetaProject.h"
#import "TDateTransformer.h"
#import "StartTaskMenuDelegate.h"
#import "TTPredicateEditorViewController.h"
#import "SearchQuery.h"
#import "TTParsedPredicate.h"
#import <Sparkle/Sparkle.h>
#import "TaskEditorController.h"


@interface MainController (PrivateMethods)
	- (void)initializeTableViews;
	- (NSArray*) determineCurrentTasks;
@end


@implementation MainController


@synthesize extraFilterPredicate = _extraFilterPredicate;
@synthesize updateURL = _updateURL;
@synthesize decimalHours = _decimalHours;
@synthesize selectedTask = _selTask;
@synthesize selectedProject = _selProject;
@synthesize taskEditorController = _taskEditorController;

// this flag toggles whether we show tasks in the "All Projects View"
// that have no matching time entries (1 means that these will NOT be shown)
// 0 means that empty tasks will also be shown.
#define ONLY_NON_NULL_TASKS_FOR_OVERVIEW 1
//#define USE_EXTENDED_TOOLBAR


#define PBOARD_TYPE_PROJECT_ROWS @"TIME_TRACKER_PROJECT_ROWS"
#define PBOARD_TYPE_TASK_ROWS @"TIME_TRACKER_TASK_ROWS"

// property keys for user defaults
#define PREFKEY_DECIMAL_HOURS @"decimalHours"

#define URL_APPCAST_OLD_STABLE @"http://time-tracker-mac.googlecode.com/svn/appcast/timetracker-stable.xml"
#define URL_APPCAST_OLD_BETA @"http://time-tracker-mac.googlecode.com/svn/appcast/timetracker-beta.xml"
#define URL_APPCAST_OLD_TEST @"http://time-tracker-mac.googlecode.com/svn/appcast/timetracker-test.xml"

#define URL_APPCAST_STABLE @"http://time-tracker-mac.googlecode.com/hg/appcast/timetracker-stable.xml"
#define URL_APPCAST_BETA @"http://time-tracker-mac.googlecode.com/hg/appcast/timetracker-beta.xml"
#define URL_APPCAST_TEST @"http://time-tracker-mac.googlecode.com/hg/appcast/timetracker-test.xml"

- (id) init
{
    if ((self = [super init]) == nil) {
        return nil;
    }
    _maxLruSize = DEFAULT_LRU_SIZE;
	_projects = [NSMutableArray new];
	_selProject = nil;
	_selTask = nil;
	_curTask = nil;
	_curProject = nil;
	_curWorkPeriod = nil;
    _idleTimeoutSeconds = 5*60;    // DEFAULT 5 minutes
    _enableStandbyDetection = YES;
    _showTimeInMenuBar = NO;
	timer = nil;
	timeSinceSave = 0;
    _autosaveCsv = YES;
    _lruTasks = [[NSMutableArray alloc] initWithCapacity:_maxLruSize+1];
    [self setAutosaveCsvFilename:[@"~/times.csv" stringByExpandingTildeInPath]];
    _csvSeparatorChar = [@";" retain];
	_metaProject = [[TMetaProject alloc] init];
	_metaTask = [[TMetaTask alloc] init];
    
	[_metaProject setProjects: _projects];
	[_metaTask setTasks: [_metaProject tasks]];
	
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	_dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	_timeValueFormatter = [[TTimeTransformer alloc] init];
	_dateValueFormatter = [[TDateTransformer alloc] init];
	_intervalValueFormatter = [[TimeIntervalFormatter alloc] init];
	_taskNameTransformer = [[TTaskNameTransformer alloc] init];
	[NSValueTransformer setValueTransformer:_timeValueFormatter forName:@"TimeToStringFormatter"];
	[NSValueTransformer setValueTransformer:_dateValueFormatter forName:@"DateToStringFormatter"];
	[NSValueTransformer setValueTransformer:_intervalValueFormatter forName:@"TimeIntervalToStringFormatter"];
	[NSValueTransformer setValueTransformer:_taskNameTransformer forName:@"TTaskNameTransformer"];
	_selectedfilterDate = nil;
    _startMenu = [[NSMenu alloc] initWithTitle:@"TimeTracker"];
    _startTaskMenuDelegate = [[StartTaskMenuDelegate alloc] initWithController:self];
    [_startMenu setDelegate:_startTaskMenuDelegate];
//	[_startMenu setTarget:self];
    [self loadData];

    NSLog(@"Have MetaProject: %@, retainCount %d",_metaProject, [_metaProject retainCount]);
	return self;
}

- (NSPredicate*) filterPredicate
{
    NSPredicate *generalPredicate = nil;
	if (_currentPredicate == nil && _filterMode != FILTER_MODE_NONE) {
		[self determineFilterStartDate];
		[self determineFilterEndDate];

		NSString *commentFilter = [_searchBox stringValue];
		if ([[_searchBox stringValue] length] > 0) {
			if (_filterMode == FILTER_MODE_NONE || _filterMode == FILTER_MODE_PREDICATE) {
				generalPredicate = [NSPredicate predicateWithFormat: 
					@"comment.string contains[cd] %@", 
					commentFilter];
           } else {
				generalPredicate = [NSPredicate predicateWithFormat: 
					@"startTime >= %@ AND endTime <= %@ AND comment.string contains[cd] %@", 
					_filterStartDate, _filterEndDate, commentFilter];
			}
		} else if (_filterMode != FILTER_MODE_NONE && _filterMode != FILTER_MODE_PREDICATE) {
			generalPredicate = [NSPredicate predicateWithFormat: @"startTime >= %@ AND endTime <= %@", 
				_filterStartDate, _filterEndDate];	
		} // otherwise the filterpredicate will stay nil

        NSPredicate *finalPredicateTemplate = nil;
        if (_extraFilterPredicate == nil && generalPredicate == nil) {
            // nothing to filter
            return nil;
        } else if (_extraFilterPredicate == nil) {
            finalPredicateTemplate = [generalPredicate retain];
        } else if (generalPredicate == nil) {
            finalPredicateTemplate = [_extraFilterPredicate retain];
        } else {
            finalPredicateTemplate = [[NSCompoundPredicate 
                            andPredicateWithSubpredicates:
                                [NSArray arrayWithObjects:generalPredicate, _extraFilterPredicate, nil]] retain];
        }
        // now fill in the variables
        _currentPredicate = [[TTParsedPredicate producePredicateFromTemplate:finalPredicateTemplate] retain];
		NSString *name = self.selectedTask.name;
		NSLog(@"filterPredicate: selTask %@", name);
	}
	return _currentPredicate;
}


- (void) invalidateFilterPredicate
{
	[_currentPredicate release];
	_currentPredicate = nil;
}

- (void) applyFilterToCurrentTasks {
	// in order to apply the filter to the tasks we need to set the predicate on each one
	for (id<ITask>task in self.currentTasks) {
		task.filterPredicate = self.filterPredicate;
	}
}

- (void) applyFilter
{
    NSPredicate *pred = self.filterPredicate;
	[self updateTaskFilterCache];

	//[tvTasks reloadData];
	[tvProjects reloadData];
	
	[workPeriodController setFilterPredicate:pred];
		
}

- (void) setFilterMode:(int)filterMode
{
	_filterMode = filterMode;
	[self invalidateFilterPredicate];
}

- (void) validateToolbarFilterItems
{
}

- (int) selectedTaskRow 
{
	return [tvTasks selectedRow] - 1;
}

- (int)selectedProjectRow
{
	return [tvProjects selectedRow] - 1;
}

- (int)selectedWorkPeriodRow
{
	
	return [workPeriodController selectionIndex];
}


- (IBAction)clickedStartStopTimer:(id)sender
{
	if (timer == nil) {
        if (_selTask != nil && [_selTask isKindOfClass:[TTask class]]
            && _selProject != _metaProject) {
            [self startTimer];
        } else {
            NSBeep();
        }
	} else {
		[self stopTimer];
	}
}


- (BOOL)validateMenuItem:(NSMenuItem *) anItem {
	return YES;
}

- (void)addTaskToLruCache:(TTask*) task
{
    [_lruTasks removeObject:task];
    [_lruTasks insertObject:task atIndex:0];
    while ([_lruTasks count] > _maxLruSize) {
        [_lruTasks removeLastObject];
    }
}

- (void)selectTask:(TTask*)task project:(TProject*) project
{
	NSLog(@"Select task: %@, project %@ (%@)", task, project, [project name]);
    // calling the setter will automatically perform the key value observing
    self.selectedTask = task;
    // TODO use setters here too.
    self.selectedProject = project;
    [self addTaskToLruCache:task];
	
	// select the project in table view
	NSInteger projIndex = 0;
	if ([_selProject isKindOfClass:[TProject class]]) {
		projIndex = [_projects indexOfObject:_selProject] + 1;
	}
	NSIndexSet *projIndexes = [NSIndexSet indexSetWithIndex:projIndex];
	[tvProjects selectRowIndexes:projIndexes byExtendingSelection:NO];
	// update the tasks that are shown
	
	[self updateTaskFilterCache];
	
	NSInteger taskIndex = [self.currentTasks indexOfObject:task];
	[taskController setSelectionIndex:taskIndex];
	NSIndexSet *taskIndexes = [NSIndexSet indexSetWithIndex:taskIndex];
	[tvTasks selectRowIndexes:taskIndexes byExtendingSelection:NO];
}

- (void)startTimer
{
	assert([_selTask isKindOfClass:[TTask class]]);
	// assert timer == nil
	if (timer != nil) return;
	
	if (_selTask.closed) {
		NSBeep();
		NSLog(@"Trying to record a closed task");
		return;
	}
	
	// if there is no project selected, create a new one
	if (_selProject == nil)
		[self createProject];

	// if there is no task selected, create a new one
	if (_selTask == nil)
		[self createTask];
	
	_curProject = _selProject;
	_curTask = _selTask;
	
	timer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector (timerFunc:)
					userInfo: nil repeats: YES];
	
	[self updateStartStopState];
	
	_curWorkPeriod = [TWorkPeriod new];
	[_curWorkPeriod setStartTime: [NSDate date]];
	[_curWorkPeriod setEndTime: [NSDate date]];
	
	[(TTask*)_curTask addWorkPeriod: _curWorkPeriod];
	//[tvWorkPeriods reloadData];	
	// make sure the controller knows about the new object
	[workPeriodController rearrangeObjects];
    
    [self selectTask:(TTask*)_curTask project:(TProject*)_curProject];
	
	[self updateProminentDisplay];
	
	// assert timer != nil
	// assert _curProject != nil
	// assert _curTask != nil
}

- (void)stopTimer
{
	[self stopTimer:[NSDate date]];
}

- (void)stopTimer:(NSDate*)endTime
{
	// assert timer != nil
	if (timer == nil) return;
	
	[timer invalidate];
	timer = nil;
	
	[_curWorkPeriod setEndTime:endTime];
	[_curTask updateTotalTime];
	[_curProject updateTotalTime];
	_curWorkPeriod = nil;
	_curProject = nil;
	_curTask = nil;
	
	[self saveData];
	
	[self updateStartStopState];
	
	[tvProjects reloadData];
	
	[self updateProminentDisplay];
	
	//[defaults setObject: [NSNumber numberWithInt: totalTime] forKey: @"TotalTime"];
	
	// assert timer == nil
	// assert _curProject == nil
	// assert _curTask == nil
}

- (IBAction)filterComments: (id)sender
{
	[self invalidateFilterPredicate];
	[self applyFilter];
}

-(NSString*) migrateUpdateURL:(NSString*)oldURL {
	if ([oldURL isEqualToString:URL_APPCAST_OLD_STABLE]) {
		return URL_APPCAST_STABLE;
	}
	if ([oldURL isEqualToString:URL_APPCAST_OLD_BETA]) {
		return URL_APPCAST_BETA;
	}
	if ([oldURL isEqualToString:URL_APPCAST_OLD_TEST]) {
		return URL_APPCAST_TEST;
	}
	return oldURL;
}

-(void) createDefaultProjectAndTask {
    TProject *project = [self createProject];
    self.selectedProject = project;
    TTask *task = [self createTask];
    [self selectTask:task project:project];
}

-(void) loadData
{
    NSData *theData = nil;
    NSMutableArray *projects = nil;
    NSData *indexData = nil;
	    
    if ([self dataFileExists]) {
		NSString * path = [self pathForDataFile]; 
		NSDictionary * rootObject; 
		rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path]; 
		theData = [rootObject valueForKey:@"ProjectTimes"];
		if (theData != nil) {
			projects = (NSMutableArray *)[[NSMutableArray arrayWithArray: [NSKeyedUnarchiver unarchiveObjectWithData:theData]] retain];
		}
        NSString* autosave = [rootObject valueForKey:@"autosave"];
        if ([@"NO" isEqualToString:autosave]) {
            _autosaveCsv = NO;
        } else {
            _autosaveCsv = YES;
        }
        NSString* showTime = [rootObject valueForKey:@"showTimeInMenuBar"];
        if ([@"NO" isEqualToString:showTime]) {
            _showTimeInMenuBar = NO;
        } else {
            _showTimeInMenuBar = YES;
        }
        NSNumber* decimalHoursPref = [rootObject valueForKey:PREFKEY_DECIMAL_HOURS];
        if (decimalHoursPref != nil) {
            self.decimalHours = [decimalHoursPref boolValue];            
        }
        
        NSString *autosaveFilename = [rootObject valueForKey:@"autosaveCsvFilename"];
        if (autosaveFilename != nil) {
            [self setAutosaveCsvFilename:autosaveFilename];
        }
        NSString *csvSeparator = [rootObject valueForKey:@"separator"];
        if (csvSeparator != nil) {
            [self setCsvSeparatorChar:csvSeparator];
        }
        NSString* strLruCount = [rootObject valueForKey:@"lruEntryCount"];
        if (strLruCount != nil) {
            int value = [strLruCount intValue];
            if (value > 2 && value < 99) {
                _maxLruSize = value;
            }
        }
        NSString* strIdleTimeout = [rootObject valueForKey:@"idleTimeout"];
        if (strIdleTimeout != nil) {
            int value = [strIdleTimeout intValue];
            [self setIdleTimeoutSeconds:value];
        }
        NSString* strStandbyDetection = [rootObject valueForKey:@"standbyDetection"];
        if ([@"NO" isEqualToString:strStandbyDetection]) {
            _enableStandbyDetection = NO;
        } else {
            _enableStandbyDetection = YES;
        }
        NSString* update = [self migrateUpdateURL:[rootObject valueForKey:@"updateURL"]];
        if (update != nil) {
            self.updateURL = update;            
        } else {
            self.updateURL = URL_APPCAST_STABLE;
        }
        // restore the lruCache
        indexData = [rootObject valueForKey:@"lruIndexes"];
	} else {
		// use the old unarchiver
		defaults = [NSUserDefaults standardUserDefaults];
        
		theData=[[NSUserDefaults standardUserDefaults] dataForKey:@"ProjectTimes"];
		if (theData != nil) {
			projects = (NSMutableArray *)[[NSMutableArray arrayWithArray: [NSUnarchiver unarchiveObjectWithData:theData]] retain];
		}
       self.updateURL = URL_APPCAST_STABLE;
	}
    
	if (projects != nil) {
		[_projects release];
		// projects is already retained
		_projects = projects;
		[_metaProject setProjects:_projects];
		[_metaTask setTasks:[_metaProject tasks]];
	}
    // restore lru cache
    if (indexData != nil) {
        int count = [indexData length] / sizeof(int);
        const int *ptrData = (const int*) [indexData bytes];
        int i = 0;
        for (i = 0; i < count && i < _maxLruSize; i++) {
            int taskId = NSSwapBigIntToHost(*ptrData);
            ptrData++;
            TTask *task = [self findTaskById:taskId];
            if (task != nil) {
                [_lruTasks addObject:task];
            } else {
                NSLog(@"task is nil for id: %d",taskId);
            }
        }
    }        
    
    // check projects for duplicate names
    int i = 0;
    int j = 0;
    int uniqueMaker = 1;
    for (TProject *project in _projects) {
        for (j = 0; j < i; j++) {
            TProject *checkProject = [_projects objectAtIndex:j];
            if ([[checkProject name] isEqualToString:[project name]]) {
                // duplicate name detected
                [checkProject setName:[NSString stringWithFormat:@"%@ %d",[checkProject name], uniqueMaker++]];
            }
        }
        // now also check for duplicate task names and fix them
        [project deDuplicateTaskNames];
        i++;
    }
    
    if ([_projects count] == 0) {
        [self createDefaultProjectAndTask];        
    }
}


- (void)awakeFromNib
{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	
    //[statusItem ]
	[statusItem setTarget: self];
	[statusItem setAction: @selector (clickedStartStopTimer:)];
    [statusItem setLength:NSVariableStatusItemLength];
	statusItem.menu = _startMenu;

	NSBundle *bundle = [NSBundle mainBundle];

	playItemImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"playitem" ofType:@"png"]];
	playItemHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"playitem_hl" ofType:@"png"]];
	stopItemImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"stopitem" ofType:@"png"]];
	stopItemHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"stopitem_hl" ofType:@"png"]];

	playToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"playtool" ofType:@"png"]];
	stopToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"stoptool" ofType:@"png"]];
	addTaskToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"addtasktool" ofType:@"png"]];
	addProjectToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"addprojecttool" ofType:@"png"]];
	
	dayToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"daytool" ofType:@"png"]];
	weekToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"weektool" ofType:@"png"]];
	monthToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"monthtool" ofType:@"png"]];
	dayToolImageUnsel = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"dayofftool" ofType:@"png"]];
	weekToolImageUnsel = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"weekofftool" ofType:@"png"]];
	monthToolImageUnsel = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"monthofftool" ofType:@"png"]];
	pickDateToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"pickdatetool" ofType:@"png"]];
	[statusItem setToolTip:@"Time Tracker"];
	[statusItem setHighlightMode:NO];

	[self updateStartStopState];
	[self updateProminentDisplay];
	
    [self initializeTableViews];
	
	NSMutableArray *descriptors = [NSMutableArray array];
	[descriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:YES] autorelease]];
	[descriptors addObject:[[[NSSortDescriptor alloc] initWithKey:@"parentTask.name" ascending:YES] autorelease]];
	[workPeriodController setSortDescriptors:descriptors];
	[tvProjects reloadData];
}

- (void)initializeTableViews
{
	[tvWorkPeriods setTarget: self];
	[tvWorkPeriods setDoubleAction: @selector(doubleClickWorkPeriod:)];
    
	[tvProjects reloadData];
    
    //	[tvProjects setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
	[tvProjects registerForDraggedTypes:[NSArray arrayWithObjects:PBOARD_TYPE_PROJECT_ROWS, nil]];
	[tvTasks registerForDraggedTypes:[NSArray arrayWithObjects:PBOARD_TYPE_TASK_ROWS, nil]];
	[tvTasks setDoubleAction:@selector(doubleClickTask:)];
}

- (TWorkPeriod*) workPeriodAtIndex:(int) index
{
	TWorkPeriod *wp = nil;
	
	int result = [self selectedWorkPeriodRow];
	TTask *task = [self taskForWorkTimeIndex:index timeIndex:&result];
	wp = [[task workPeriods] objectAtIndex:result];
	return wp;
}

- (TWorkPeriod*) selectedWorkPeriod 
{
	return [[workPeriodController arrangedObjects] objectAtIndex:[tvWorkPeriods selectedRow]];
}

- (IBAction)okClicked:(id) sender
{
	[NSApp endSheet:panelEditWorkPeriod returnCode:NSOKButton];
}

- (IBAction)cancelClicked:(id) sender
{
	[NSApp endSheet:panelEditWorkPeriod returnCode:NSCancelButton];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (sheet == panelPickFilterDate) {
		if (returnCode == NSOKButton) {			
			[_tbPickDateItem setLabel:[_dateFormatter stringFromDate:_selectedfilterDate]];
		} else {
			[self setFilterMode: FILTER_MODE_NONE];
			[_tbPickDateItem setLabel:@"Pick Date"];
		}
		[self invalidateFilterPredicate];
		[self applyFilter];
	} else {
		if (returnCode == NSOKButton) {
			[self clickedChangeWorkPeriod:contextInfo];
		}
	}
	// hide the window
	[sheet orderOut:nil];
}


- (void)notificationDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[self invalidateFilterPredicate];
	[self applyFilter];
	// hide the window
	[sheet orderOut:nil];
	statusItem.menu = _startMenu;
}

- (void) openEditWorkPeriodPanel:(TWorkPeriod*) wp {
    [dtpEditWorkPeriodStartTime setDateValue: [wp startTime]];
	[dtpEditWorkPeriodEndTime setDateValue: [wp endTime]];
	[dtpEditWorkPeriodComment setString: [[wp comment] string]];
    //	[changeProjectController setSelectionIndex:[_projects indexOfObject:[[wp parentTask] parentProject]]];
	[self provideProjectsForEditWpDialog:[[wp parentTask] parentProject]];
	[self provideTasksForEditWpDialog:[[wp parentTask] parentProject]];
	[_taskPopupButton selectItemWithTitle:[[wp parentTask] name]];
    
    /*	[panelEditWorkPeriod makeKeyAndOrderFront: self];
     [NSApp runModalForWindow: panelEditWorkPeriod];
     */
	[NSApp beginSheet:panelEditWorkPeriod modalForWindow:mainWindow modalDelegate:self 
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:wp];
    
}
- (void) doubleClickWorkPeriod: (id) sender
{
	// assert _selProject != nil
	// assert _selTask != nil
	TWorkPeriod *wp = [self selectedWorkPeriod];
    [self openEditWorkPeriodPanel:wp];
}

- (void) doubleClickTask: (id) sender {
	id<ITask> task = self.selectedTask;
	if ([task isKindOfClass:[TMetaTask class]]) {
		NSBeep();
		return;
	}
	[self.taskEditorController openSheet:self forWindow:mainWindow withTask:(TTask*)task];
}

-(TaskEditorController*) taskEditorController {
	if (_taskEditorController == nil) {
		_taskEditorController = [[TaskEditorController alloc] initWithWindowNibName:@"TaskEditor"];
	}
	return _taskEditorController;
}
									   
- (void) moveWorkPeriodToNewTask:(TWorkPeriod*) wp task:(TTask*) newParent
{
	// first remove the workperiod from the old parent
	TTask *oldParent = [wp parentTask];
    if (oldParent != newParent) {
        [oldParent removeWorkPeriod:wp];
        [newParent addWorkPeriod:wp];        
    }
}

- (IBAction)clickedEditCurrentWorkperiod:(id) sender {
    [self openEditWorkPeriodPanel:_curWorkPeriod];
}

- (IBAction)clickedChangeWorkPeriod:(id)sender
{
	// assert _selProject != nil
	// assert _selTask != nil
	TWorkPeriod *wp = nil;
    
    if ([sender isKindOfClass:[TWorkPeriod class]]) {
        wp = (TWorkPeriod*) sender;
    } else {
        wp = [self selectedWorkPeriod];        
    }
	[wp setStartTime: [dtpEditWorkPeriodStartTime dateValue]];
	[wp setEndTime: [dtpEditWorkPeriodEndTime dateValue]];
	[wp setComment: [[[NSAttributedString alloc] initWithString:[dtpEditWorkPeriodComment string]] autorelease]];
	
	BOOL doRefilter = NO;
	// move the workperiod to a different task / project
	if ([_taskPopupButton indexOfSelectedItem] > 0) {
        int projectIndex = [_projectPopupButton indexOfSelectedItem];
		TProject *selectedProject = [_projects objectAtIndex:projectIndex];
        int taskIndex = [_taskPopupButton indexOfSelectedItem] - 1;
		TTask *selectedTask = [[selectedProject tasks] objectAtIndex:taskIndex];
		[self moveWorkPeriodToNewTask:wp task:selectedTask];
		// in this case we need to update all the task filters, etc.
		// since the work period has moved from one project to another and we need to 
		// make sure that the task display in the upper right corner refreshes.
		doRefilter = YES;
	}
	
	[_selTask updateTotalTime];
	[_selProject updateTotalTime];
	[tvProjects reloadData];
	[self reloadWorkPeriods];
	// reload the tasks as well
	if (doRefilter) {
		[self updateTaskFilterCache];
	} else {
		// only make sure that the totals are updated.
		[self reloadTasks];
	}
	[NSApp stopModal];
	[panelEditWorkPeriod orderOut: self];
}

- (void) showIdleNotification
{
	// reset the flag
	_showIdleNotification = NO;
	// prevent someone from starting a new task while the popup is visible.
	statusItem.menu = nil;
	NSLog(@"Showing idle notification for mainWindow %@", mainWindow);
    [NSApp beginSheet:panelIdleNotification modalForWindow:mainWindow modalDelegate:self 
       didEndSelector:@selector(notificationDidEnd:returnCode:contextInfo:) contextInfo:nil];
/*
		[NSApp activateIgnoringOtherApps: YES];
		[NSApp runModalForWindow: panelIdleNotification];
		[panelIdleNotification orderOut: self];*/
}

- (void) timerFunc: (NSTimer *) atimer
{	
	if ([panelIdleNotification isVisible]) {
		return;
	}
	// assert timer != nil
	// assert timer == atimer
	if (timer != atimer) return;
	
	// determine if the computer was on standby
	NSDate *lastEndTime = [_curWorkPeriod endTime];
	NSDate *curTime = [NSDate date];
	if (_enableStandbyDetection && [curTime timeIntervalSinceDate:lastEndTime] > 5) {
        if ([mainWindow attachedSheet] != nil) {
            // dont show idle notification just now, wait until the sheet did end
            _showIdleNotification = YES;
        } else {
            [timer setFireDate: [NSDate distantFuture]];
            // time jumped by 60 seconds, probably the computer was on standby
            [_lastNonIdleTime release];
            _lastNonIdleTime = [lastEndTime retain];
            [self showIdleNotification];
            return;
        }
	}
	[_curWorkPeriod setEndTime: curTime];
	[_curTask updateTotalTime];
	[_curProject updateTotalTime];
	[tvProjects reloadData];
	//[tvTasks reloadData];
	//[tvWorkPeriods reloadData];
	int idleTime = [self idleTime];
	if (idleTime == 0) {
		[_lastNonIdleTime release];
		_lastNonIdleTime = [[NSDate date] retain];
	}
	
	if (idleTime > _idleTimeoutSeconds || _showIdleNotification) {
		// if there is a sheet already open, if yes, then simply 
		// remember that we should show the popup and move on
		if ([mainWindow attachedSheet] != nil) {
			// there is currently a sheet open (probably the user is editing a recording)
			// so remember that we should pop up the notification later.
			_showIdleNotification = YES;
		} else {
			[timer setFireDate: [NSDate distantFuture]];
			[self showIdleNotification];
		}
	}
	
	[self updateProminentDisplay];
	
	if (timeSinceSave > 5 * 60) {
		[self saveData];
	} else {
		timeSinceSave++;
	}
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    if (notification.object == [NSApp mainWindow]) {
        [[notification object] setExcludedFromWindowsMenu:YES];        
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
//	if ([notification object] == mainWindow)
//		[NSApp terminate: self];
	if ([notification object] == panelEditWorkPeriod)
		[NSApp stopModal];
}

- (NSString *) pathForDataFile : (bool) createIfNecessary
{ 
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
	NSString *folder = @"~/Library/Application Support/TimeTracker/"; 
	folder = [folder stringByExpandingTildeInPath]; 
	if ([fileManager fileExistsAtPath: folder] == NO) { 
		[fileManager createDirectoryAtPath: folder attributes: nil]; 
	} 
	NSString *fileName = @"data.plist"; 
	return [folder stringByAppendingPathComponent: fileName]; 
} 

- (NSString *) pathForDataFile
{
	return [self pathForDataFile: YES];
}

- (bool) dataFileExists
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *dataFile = [self pathForDataFile:NO];
	return [fm fileExistsAtPath:dataFile];
}

- (NSString*)serializeWorkPeriod:(TWorkPeriod*)wp
{
    TTask *task = [wp parentTask];
    TProject *project = [task parentProject];
    NSString *prefix = [NSString stringWithFormat:@"\"%@\"%@\"%@\"%@", [project name], _csvSeparatorChar, [task name], _csvSeparatorChar];
    return [wp serializeData:prefix separator:_csvSeparatorChar];
}

- (NSString*)serializeCurrentFilter
{
	NSMutableString *result = [NSMutableString 
                    stringWithFormat:@"\"Project\"%@\"Task\"%@\"Date\"%@\"Start\"%@\"End\"%@\"Duration\"%@\"Comment\"\n", 
                         _csvSeparatorChar, _csvSeparatorChar, _csvSeparatorChar, _csvSeparatorChar, _csvSeparatorChar, _csvSeparatorChar];
	NSEnumerator *enumerator = [[workPeriodController arrangedObjects] objectEnumerator];
	id anObject;
    
	while (anObject = [enumerator nextObject])
	{
		[result appendString:[self serializeWorkPeriod:anObject]];
	}
	return result;
    
}
- (NSString*)serializeData 
{
	NSMutableString *result = [NSMutableString 
                               stringWithFormat:@"\"Project\"%@\"Task\"%@\"Date\"%@\"Start\"%@\"End\"%@\"Duration\"%@\"Comment\"\n", 
                               _csvSeparatorChar, _csvSeparatorChar, _csvSeparatorChar, _csvSeparatorChar, _csvSeparatorChar, _csvSeparatorChar];
	NSEnumerator *enumerator = [_projects objectEnumerator];
	id anObject;
 
	while (anObject = [enumerator nextObject])
	{
		[result appendString:[anObject serializeData:[self csvSeparatorChar]]];
	}
	return result;
}

- (void)saveData
{
	NSData *theData=[NSKeyedArchiver archivedDataWithRootObject:_projects];
	NSString * path = [self pathForDataFile]; 
	NSMutableDictionary * rootObject; 
	rootObject = [NSMutableDictionary dictionary]; 

    int count = [_lruTasks count];
    NSMutableData *lruData = [[NSMutableData alloc] initWithCapacity:count * sizeof(int)];
    [lruData setLength:count * sizeof(int)];
    int* ptrData = (int*) [lruData mutableBytes];

    NSEnumerator *enumLruTasks = [_lruTasks objectEnumerator];
    TTask *task = nil;
    while ((task = [enumLruTasks nextObject]) != nil) {
        *ptrData = NSSwapHostIntToBig([task taskId]);
        ptrData++;
    }
    [rootObject setValue:lruData forKey:@"lruIndexes"];
    [lruData release];
    lruData = nil;
    
    
	[rootObject setObject:theData forKey:@"ProjectTimes"];
    [rootObject setValue:_autosaveCsvFilename forKey:@"autosaveCsvFilename"];
    [rootObject setValue:_csvSeparatorChar forKey:@"separator"];
    [rootObject setValue:_updateURL forKey:@"updateURL"];
    [rootObject setValue:[NSString stringWithFormat:@"%d", _maxLruSize] forKey:@"lruEntryCount"];
    [rootObject setValue:[NSString stringWithFormat:@"%d", _idleTimeoutSeconds] forKey:@"idleTimeout"];
    if (_autosaveCsv) {
        [rootObject setValue:@"YES" forKey:@"autosave"];
    } else {
        [rootObject setValue:@"NO" forKey:@"autosave"];        
    }
    if (_showTimeInMenuBar) {
        [rootObject setValue:@"YES" forKey:@"showTimeInMenuBar"];
    } else {
        [rootObject setValue:@"NO" forKey:@"showTimeInMenuBar"];        
    }
    if (_enableStandbyDetection) {
        [rootObject setValue:@"YES" forKey:@"standbyDetection"];
    } else {
        [rootObject setValue:@"NO" forKey:@"standbyDetection"];        
    }
    [rootObject setValue:[NSNumber numberWithBool:_decimalHours] forKey:PREFKEY_DECIMAL_HOURS];
    
	[NSKeyedArchiver archiveRootObject: rootObject toFile: path];
	
	timeSinceSave = 0;
	
    if (_autosaveCsv && _autosaveCsvFilename != nil) {
        NSString *data = [self serializeData];
        [data writeToFile:_autosaveCsvFilename 
               atomically:YES 
                 encoding:NSISOLatin1StringEncoding 
                    error:NULL];
    }
}


#pragma mark document methods (will be moved to document class eventually)

- (void)moveProject:(TProject *)proj toIndex:(int)index
{
	NSInteger oldIndex = [_projects indexOfObject:proj];
	if (oldIndex == NSNotFound)
	{
		NSLog(@"TTDocumentV1 moveProject:toIndex: project was not found in the projects lists");
		return;
	}
	
	[_projects insertObject:proj atIndex:index];
	if (oldIndex >= index) oldIndex++;
	[_projects removeObjectAtIndex:oldIndex];
}

#pragma mark ----

- (IBAction)actionExport:(id)sender
{
    NSSavePanel *sp;
    int savePanelResult;
    
    sp = [NSSavePanel savePanel];

    NSPopUpButton *rangeButton = (NSPopUpButton*) [[_saveCsvAuxView subviews] objectAtIndex:1];
    // the user has some filtering going on, so lets use the filtered output by default
    if (_selProject == _metaProject && _filteredTasks != nil) {
        [rangeButton selectItemWithTag:1];
    } else {
        [rangeButton selectItemWithTag:0];        
    }
    
    [sp setAccessoryView:_saveCsvAuxView];
    [sp setTitle:@"Export"];
    [sp setNameFieldLabel:@"Export to:"];
    [sp setPrompt:@"Export"];
    
    [sp setRequiredFileType:@"csv"];
    
    savePanelResult = [sp runModalForDirectory:nil file:@"Time Tracker Data.csv"];
    
    if (savePanelResult == NSOKButton) {
        NSMenuItem *selectedRange = [rangeButton selectedItem];
        
        NSString *data = nil;
        
        if (selectedRange.tag == 0) {
            data = [self serializeData];
        } else {
            data = [self serializeCurrentFilter];
        }
		NSError *error;
        [data writeToFile:[sp filename] 
               atomically:YES
                 encoding:NSUTF8StringEncoding 
                    error:&error];
		//NSLog(@"Export error: %@", error);
//        [data release];
    }
}



- (TTask*) taskForWorkTimeIndex: (int) rowIndex timeIndex:(int*)resultIndex {
	NSEnumerator *enumerator = [[_selProject tasks] objectEnumerator];
	id aTask;
	*resultIndex = rowIndex;
	
	while (aTask = [enumerator nextObject])
	{
		int count = [[aTask workPeriods] count];
		if (count > *resultIndex) {
			break;
		}
		*resultIndex -= count;
	}
	return aTask;
}

- (IBAction)clickedAddProject:(id)sender
{
	[self createProject];

	int index = [_projects count];
	[tvProjects editColumn:[tvProjects columnWithIdentifier:@"ProjectName"] row:index withEvent:nil select:YES];
}

- (TProject*)createProject
{
	TProject *proj = [TProject new];
	[_projects addObject: proj];
    [proj release];
	[tvProjects reloadData];
	int index = [_projects count];
	[tvProjects selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[mainWindow makeFirstResponder:tvProjects];
    return proj;
}

- (IBAction)clickedAddTask:(id)sender
{
	[self createTask];

	int index = [[_selProject tasks] count];
	[tvTasks editColumn:[tvTasks columnWithIdentifier:@"TaskName"] row:index withEvent:nil select:YES];
}

-(NSDate*) determineFilterEndDate
{
    if (_filterMode == FILTER_MODE_PREDICATE) {
        return nil;
    }
	NSDateComponents *comps = [[[NSDateComponents alloc] init] autorelease];
	switch (_filterMode) {
		case FILTER_MODE_DAY:			
			[comps setDay:1];
			break;
		case FILTER_MODE_WEEK:
			[comps setWeek:1];
			break;
		case FILTER_MODE_MONTH:
			[comps setMonth:1];
			break;
	}
	_filterEndDate = [[[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:_filterStartDate options:0] retain];
	//NSLog(@"startTime >= %@ AND endTime <= %@", _filterStartDate, _filterEndDate);
	//NSLog(@"objects %@", [workPeriodController content]);
	return _filterEndDate;
}

-(NSDate*) determineFilterStartDate 
{
    
	if (_filterMode == FILTER_MODE_PREDICATE || _selectedfilterDate == nil) {
		return nil;
	}
	[_filterStartDate release];
	_filterStartDate = nil;
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDateComponents *comps = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:_selectedfilterDate];
	_filterStartDate = [[cal dateFromComponents:comps] retain];
	return _filterStartDate;
}


- (IBAction)clickedAddTimePeriod:(id)sender
{
    if (_selTask == nil) {
        NSBeep();
        return;
    }
    TWorkPeriod *period = [TWorkPeriod new];
	[period setStartTime: [NSDate date]];
	[period setEndTime: [NSDate date]];
	
	[(TTask*)_selTask addWorkPeriod: period];
    
    [self openEditWorkPeriodPanel:period];
}

-(void) filterQuerySelected:(SearchQuery*)query {
    // pass it on to the predicate controller since even though we have a binding
    // to the PredicateEditor the controller is not notified about a new predicate
    // especially when setting the predicate to NIL
    [_predicateController filterQuerySelected:query];
    self.extraFilterPredicate = query.predicate;
}

-(void) setExtraFilterPredicate:(NSPredicate *)predicate {
    if (_extraFilterPredicate != predicate) {
        [_extraFilterPredicate release];
        _extraFilterPredicate = [predicate retain];
        if (predicate != nil) {
            _filterMode = FILTER_MODE_PREDICATE;
        } else {
            _filterMode = FILTER_MODE_NONE;
        }

        [self invalidateFilterPredicate];
        [self applyFilter];
    }    
}
-(void)predicateSelected:(NSPredicate *)predicate {
   /* if (_extraFilterPredicate != predicate) {
        [_extraFilterPredicate release];
        _extraFilterPredicate = [predicate retain];
        [self invalidateFilterPredicate];
        [self applyFilter];
    }*/
}

- (TTask*)createTask
{
	// assert _selProject != nil
	if (_selProject == nil) return nil;
	
	TTask *task = [TTask new];
    TProject* project = (TProject*) self.selectedProject;

    NSString *taskName = [project findUniqueTaskNameBasedOn:task.name];
    task.name = taskName;
	[project addTask: task];
    [task release];
    
    [self selectTask:task project:project];
    return task;
/*	[tvTasks reloadData];
	
	self.currentTasks = [self determineCurrentTasks];
	//[taskController setContent:self.currentTasks];
	int index = [[_selProject tasks] count];
	[tvTasks selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[mainWindow makeFirstResponder:tvTasks];
  */  
}

- (void)selectAndUpdateMetaTask {
	[_metaTask setTasks:[_selProject tasks]];
	
	self.selectedTask = _metaTask;
    
    // now refresh the UI and make sure that the record is selected
	[taskController setSelectionIndex:0];
	NSIndexSet *taskIndexes = [NSIndexSet indexSetWithIndex:0];
	[tvTasks selectRowIndexes:taskIndexes byExtendingSelection:NO];

}

- (void)reloadWorkPeriods
{
	[workPeriodController setContent:[_selTask workPeriods]];
}

- (void) reloadTasks 
{
	self.currentTasks = [self determineCurrentTasks];
}

/** 
 * This method will update the cached tasks to be displayed when a filter
 * is selected. 
 */
- (void) updateTaskFilterCache {
	[_filteredTasks release];
	_filteredTasks = nil;
	
	if (_filterMode != FILTER_MODE_NONE) {
		_filteredTasks = [[_selProject matchingTasks:[self filterPredicate]] retain];
	} 
	self.currentTasks = [self determineCurrentTasks];
	[self applyFilterToCurrentTasks];
}
                
- (BOOL) doesProjectNameExist:(NSString*)name {
    NSEnumerator *enumProjects = [_projects objectEnumerator];
    TProject *project;
    while ((project = [enumProjects nextObject]) != nil) {
        if ([name isEqualToString:[project name]]) {
            return YES;
        }
    }
    return NO;
}

- (void) provideProjectsForEditWpDialog:(TProject*) selectedProject
{
	[_projectPopupButton removeAllItems];
	NSEnumerator *enumProjects = [_projects objectEnumerator];
    TProject *project = nil;
	
    while ((project = [enumProjects nextObject]) != nil) {
        NSString *projectName = [project name];
        NSLog(@"Providing project #%@#", projectName);
		[_projectPopupButton addItemWithTitle:projectName];
	}
	[_projectPopupButton selectItemWithTitle:selectedProject.name];
}

- (void) provideTasksForEditWpDialog:(TProject*)project 
{
	[_taskPopupButton removeAllItems];
	NSEnumerator *enumTasks = [[project tasks] objectEnumerator];
	TTask *task = nil;
	[_taskPopupButton addItemWithTitle:
		NSLocalizedString(@"Select", 
						  @"the SELECT label in the edit workperiod dialog which will allow the user to assign the current recording to another task ")];
	while ((task = [enumTasks nextObject]) != nil) {
		[_taskPopupButton addItemWithTitle:[task name]];
	}
}

- (IBAction)changedProjectInEditWpDialog:(id) sender
{
	TProject *selectedProject = [_projects objectAtIndex:[_projectPopupButton indexOfSelectedItem]];
	[self provideTasksForEditWpDialog:selectedProject];
}

- (IBAction) clickedDeleteWorkPeriod:(id)sender {
	NSInteger selIndex = [tvWorkPeriods selectedRow];
	if (selIndex < 0) {
		NSBeep();
		return;
	}
    int iResponse = 
        NSRunAlertPanel(@"Delete selection", 
                    @"Are you sure to delete the selected item(s)?",
                    @"YES", @"NO", /*ThirdButtonHere:*/nil
                    /*, args for a printf-style msg go here */);
	switch(iResponse) {
        case NSAlertDefaultReturn:    /* user pressed OK */
            break;
        case NSAlertAlternateReturn:  /* user pressed Cancel */
            return;
        case NSAlertErrorReturn:      /* an error occurred */
            return;
	}

    
    TWorkPeriod *selPeriod = [self selectedWorkPeriod];
    if (selPeriod == _curWorkPeriod) {
        [self stopTimer];
    }
    TTask* parentTask = [selPeriod parentTask];			
    [parentTask removeWorkPeriod:selPeriod];
    [_selTask updateTotalTime];
    [_selProject updateTotalTime];
	// reload the workperiods and tasks
	[self reloadWorkPeriods];
	[self reloadTasks];
    [tvProjects reloadData];
		
    [self reloadWorkPeriods];
}

- (IBAction)clickedDelete:(id)sender
{
	if ([mainWindow firstResponder] == tvWorkPeriods) {
        [self clickedDeleteWorkPeriod:nil];
        return;
	}
    
	int iResponse = 
        NSRunAlertPanel(@"Delete selection", 
                        @"Are you sure to delete the selected item(s)?",
                        @"YES", @"NO", /*ThirdButtonHere:*/nil
                        /*, args for a printf-style msg go here */);
	switch(iResponse) {
    case NSAlertDefaultReturn:    /* user pressed OK */
		break;
    case NSAlertAlternateReturn:  /* user pressed Cancel */
		return;
	case NSAlertErrorReturn:      /* an error occurred */
		return;
	}
	if ([mainWindow firstResponder] == tvTasks) {
		if ([_selProject isKindOfClass: [TProject class]]) {
			if ([_selTask isKindOfClass:[TMetaTask class]]) {
				return;
			}
			TProject *project = (TProject*) _selProject;
			// assert _selTask != nil
			// assert _selProject != nil
			if (self.selectedTask == _curTask) {
				[self stopTimer];
			}
			TTask *delTask = (TTask*)_selTask;
			[tvTasks deselectAll: self];
			[[project tasks] removeObject: delTask];
			[project updateTotalTime];
			[tvTasks reloadData];
			[tvProjects reloadData];
		}
	}
	if ([mainWindow firstResponder] == tvProjects) {
		if ([_selProject isKindOfClass:[TMetaProject class]]) {
			return;
		}
		// assert _selProject != nil
		if ([_selProject isEqual:_curProject] || [_selTask isEqual: _curProject]) {
			[self stopTimer];
		}
		TProject *delProject = (TProject*)_selProject;
		[tvProjects deselectAll: self];
		[_projects removeObject: delProject];
		[tvProjects reloadData];
	}
}

- (int)idleTime 
{
  mach_port_t masterPort;
  io_iterator_t iter;
  io_registry_entry_t curObj;
  int res = 0;

  IOMasterPort(MACH_PORT_NULL, &masterPort);
  
  IOServiceGetMatchingServices(masterPort,
                 IOServiceMatching("IOHIDSystem"),
                 &iter);
  if (iter == 0) {
    return 0;
  }
  
  curObj = IOIteratorNext(iter);

  if (curObj == 0) {
    return 0;
  }

  CFMutableDictionaryRef properties = 0;
  CFTypeRef obj;

  if (IORegistryEntryCreateCFProperties(curObj, &properties,
                   kCFAllocatorDefault, 0) ==
      KERN_SUCCESS && properties != NULL) {

    obj = CFDictionaryGetValue(properties, CFSTR("HIDIdleTime"));
    CFRetain(obj);
  } else {
    obj = NULL;
  }

  if (obj) {
    uint64_t tHandle;

    CFTypeID type = CFGetTypeID(obj);

    if (type == CFDataGetTypeID()) {
      CFDataGetBytes((CFDataRef) obj,
           CFRangeMake(0, sizeof(tHandle)),
           (UInt8*) &tHandle);
    }  else if (type == CFNumberGetTypeID()) {
      CFNumberGetValue((CFNumberRef)obj,
             kCFNumberSInt64Type,
             &tHandle);
    } else {
      CFRelease(obj);
      return 0;
    }

    CFRelease(obj);

    // essentially divides by 10^9
    tHandle >>= 30;
	res = tHandle;
  } else {
	}

  /* Release our resources */
  IOObjectRelease(curObj);
  IOObjectRelease(iter);
  CFRelease((CFTypeRef)properties);

  return res;
}

- (IBAction)clickedCountIdleTimeYes:(id)sender
{
	// update the current end time in order not to let the
	// standby timer go off
	[_curWorkPeriod setEndTime: [NSDate date]];

	// assert timer != nil
	[timer setFireDate: [NSDate dateWithTimeIntervalSinceNow: 1]];
    [NSApp endSheet:panelIdleNotification returnCode:NSOKButton];
}

- (BOOL) validateUserInterfaceItem:(id)anItem
{
	if ([anItem action] == @selector(clickedStartStopTimer:)) {
		if (timer != nil) return YES;
		if (_selTask != nil && [_selTask isKindOfClass:[TTask class]]
				&& _selProject != _metaProject && !_selTask.closed) {
			return YES;
		}
		return NO;
	} else if ([anItem action] == @selector(clickedAddProject:)) {
		return YES;
	} else if ([anItem action] == @selector(clickedAddTask:)) {
		if (_selProject != nil && [_selProject isKindOfClass:[TProject class]]) {
			return YES;
		}
		return NO;
	} else if ([anItem action] == @selector(clickedAddTimePeriod:)) {
		if (_selTask != nil && [_selTask isKindOfClass:[TTask class]]
            && _selProject != _metaProject && !_selTask.closed) {
			return YES;
		}
        return NO;
    } else if ([anItem action] == @selector(clickedDeleteWorkPeriod:)) {
		return [tvWorkPeriods selectedRow] >= 0;
	}
	return YES;
}

- (BOOL)timerRunning {
    return timer != nil;
}

- (void)updateStartStopState
{
	if (timer == nil) {
		// Timer is stopped: show the Start button
		if (startstopToolbarItem != nil) {
			[startstopToolbarItem setLabel:@"Start"];
			[startstopToolbarItem setPaletteLabel:@"Start"];
			[startstopToolbarItem setToolTip:@"Start timer"];
			[startstopToolbarItem setImage: playToolImage];
		}
		
		// assert statusItem != nil
		[statusItem setImage:playItemImage];
		[statusItem setAlternateImage:playItemHighlightImage];
		
		// assert startMenuItem != nil
		[startMenuItem setTitle:@"Start Timer"];
	} else {
		if (startstopToolbarItem != nil) {
			[startstopToolbarItem setLabel:@"Stop"];
			[startstopToolbarItem setPaletteLabel:@"Stop"];
			[startstopToolbarItem setToolTip:@"Stop timer"];
			[startstopToolbarItem setImage: stopToolImage];
		}
		
		// assert statusItem != nil
		[statusItem setImage:stopItemImage];
		[statusItem setAlternateImage:stopItemHighlightImage];
		
		// assert startMenuItem != nil
		[startMenuItem setTitle:@"Stop Timer"];
	}
	
}

- (NSString*) stringForSelectedProjectTask 
{
    NSString *project = @"NONE";
    NSString *task = @"NONE";
    
    if (_selProject != nil && [_selProject isKindOfClass:[TProject class]]) {
        project = [_selProject name];
    }
    if (_selTask != nil && [_selTask isKindOfClass:[TTask class]]) {
        task = [_selTask name];
    }
    NSString *result = [NSString stringWithFormat:@"%@:%@", project, task];
    return result;
}

- (NSString*) stringForCurrentProjectTask 
{
    NSString *project = @"NONE";
    NSString *task = @"NONE";
    
    if (_curProject != nil) {
        project = [_curProject name];
    }
    if (_curTask != nil) {
        task = [_curTask name];
    }
    NSString *result = [NSString stringWithFormat:@"%@:%@", project, task];
    return result;
}

- (void)updateProminentDisplay
{
    int seconds = 0;
    if (_showTimeInMenuBar && _curWorkPeriod != nil) {
        seconds = [_curWorkPeriod totalTime];
    }
    if (timer == nil) {
        // start a new task
        if (_selTask != nil && [_selTask isKindOfClass:[TTask class]]
                && _selProject != _metaProject) {
            [statusItem setToolTip:[NSString stringWithFormat:@"TimeTracker Start: %@", [self stringForSelectedProjectTask]]];
        } else {
            [statusItem setToolTip:@"TimeTracker"];
        }
    } else {
        [statusItem setToolTip:[NSString stringWithFormat:@"TimeTracker Stop: %@", [self stringForCurrentProjectTask]]];
    }        
    if (_showTimeInMenuBar) {
        if (seconds > 0) {
            [statusItem setTitle:[TimeIntervalFormatter secondsToString:seconds]];
        } else {
            [statusItem setTitle:@""];
        }
    }
    
	if (_curTask != nil) {
		NSString *s = [[_curTask name] stringByAppendingString:@" - "];
		s = [s stringByAppendingString:[TimeIntervalFormatter secondsToString:[_curTask totalTime]]];
		[tfActiveTask setStringValue:s];
		[tfActiveTask setTextColor:[NSColor blackColor]];
	} else if (_selTask != nil) {
		NSString *s = [[_selTask name] stringByAppendingString:@" - "];
		s = [s stringByAppendingString:[TimeIntervalFormatter secondsToString:[_selTask totalTime]]];
		[tfActiveTask setStringValue:s];
		[tfActiveTask setTextColor:[NSColor lightGrayColor]];
	} else {
		[tfActiveTask setStringValue:@"New Task - 00:00:00"];
		[tfActiveTask setTextColor:[NSColor lightGrayColor]];
	}

	if (_curProject != nil) {
		NSString *s = [[_curProject name] stringByAppendingString:@" - "];
		s = [s stringByAppendingString:[TimeIntervalFormatter secondsToString:[_curProject totalTime]]];
		[tfActiveProject setStringValue:s];
		[tfActiveProject setTextColor:[NSColor blackColor]];
	} else if (_selProject != nil) {
		NSString *s = [[_selProject name] stringByAppendingString:@" - "];
		s = [s stringByAppendingString:[TimeIntervalFormatter secondsToString:[_selProject totalTime]]];
		[tfActiveProject setStringValue:s];
		[tfActiveProject setTextColor:[NSColor lightGrayColor]];	
	} else {
		[tfActiveProject setStringValue:@"New Project - 00:00:00"];
		[tfActiveProject setTextColor:[NSColor lightGrayColor]];
	}
	
}

- (IBAction)clickedCountIdleTimeNo:(id)sender
{
//	[NSApp stopModal];
	// assert _lastNonIdleTime != nil
	[self stopTimer:_lastNonIdleTime];
	[_lastNonIdleTime release];
	_lastNonIdleTime = nil;
    [NSApp endSheet:panelIdleNotification returnCode:NSCancelButton];

}

-(BOOL) autosaveCsv 
{
    return _autosaveCsv;
}
-(void) setAutosaveCsv:(BOOL)autosave 
{
    _autosaveCsv = autosave;
}

-(void) setDecimalHours:(BOOL)decimal 
{
    _decimalHours = decimal;
    _intervalValueFormatter.decimalMode = decimal;
    [self reloadWorkPeriods];
    [tvProjects reloadData];
    [tvTasks reloadData];
}

-(NSString*) autosaveCsvFilename 
{
    return _autosaveCsvFilename;
}

-(void) setAutosaveCsvFilename:(NSString*)filename
{
    if (_autosaveCsvFilename != filename) {
        [_autosaveCsvFilename release];
        _autosaveCsvFilename = nil;
        _autosaveCsvFilename = [filename retain];
    }
}

-(void) setUpdateURL:(NSString *)updateURL {
    if (_updateURL != updateURL) {
        [_updateURL release];
        _updateURL = nil;
        _updateURL = [updateURL retain];
    }

    [[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:updateURL]];
}

-(NSString*) csvSeparatorChar
{
    return _csvSeparatorChar;
}

-(void) setCsvSeparatorChar:(NSString*) separator
{
    [_csvSeparatorChar release];
    _csvSeparatorChar = nil;
    _csvSeparatorChar = [separator retain];
}

-(NSArray*)lruTasks
{
    return _lruTasks;
}

-(int) maxLruSize
{
    return _maxLruSize;
}

-(void) setMaxLruSize:(int)size 
{
    if (size >= 2 && size < 99) {
        _maxLruSize = size;
    }
}

-(void) setShowTimeInMenuBar:(BOOL)show
{
    _showTimeInMenuBar = show;
    if (!show) {
        [statusItem setTitle:@""];
    } else {
        [self updateProminentDisplay];
    }
}
-(BOOL) showTimeInMenuBar
{
    return _showTimeInMenuBar;
}


-(void) setIdleTimeoutSeconds:(int)seconds
{
    if (seconds > 30 && seconds < 10000) {
        _idleTimeoutSeconds = seconds;
    }
}

-(int) idleTimeoutSeconds
{
    return _idleTimeoutSeconds;
}

-(void) setEnableStandbyDetection:(BOOL)enable
{
    _enableStandbyDetection = enable;
}
-(BOOL) enableStandbyDetection
{
    return _enableStandbyDetection;
}

-(TTask *)findTaskById:(int)taskId
{
	NSEnumerator *enumTasks = [_metaTask objectEnumerator];
	TTask *task = nil;
	while ((task = [enumTasks nextObject]) != nil) {
		if ([task taskId] == taskId) {
            return task;
        }
	}
    return nil;
}

#pragma mark NSApplicationDelegate methods
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (timer != nil) {
        [self stopTimer];        
    }
    [self saveData];
    NSLog(@"exiting app...........");
    return NSTerminateNow;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return NO;
}

#pragma mark ----
#pragma mark TableView Data Source

- (NSArray*) determineCurrentTasks {
	NSLog(@"DetermineCurrentTasks: selPro %@ (%@), selTask %@", _selProject, [_selProject name],_selTask);
	if (_selProject == nil)
		return nil;
	else if (ONLY_NON_NULL_TASKS_FOR_OVERVIEW) {
		if (_selProject == _metaProject && _filteredTasks != nil) {
			return _filteredTasks;
		}
	} 
	return _selProject.tasks;
}

- (void) setCurrentTasks:(NSArray*) tasks {
	if (_currentTasks == tasks) {
		return;
	}
	NSMutableArray *newTasks = [[NSMutableArray alloc] initWithCapacity:[tasks count] + 1];
	[newTasks addObject:_metaTask];
	[newTasks addObjectsFromArray:tasks];
	[_currentTasks release];
	_currentTasks = newTasks;
}

- (NSArray*) currentTasks {
	return _currentTasks;
/*	if (_selProject == nil)
		return nil;
	else if (ONLY_NON_NULL_TASKS_FOR_OVERVIEW) {
		if (_selProject == _metaProject && _filteredTasks != nil) {
			return _filteredTasks;
		}
	} 
	return _selProject.tasks;*/
}	

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == tvProjects) {
		return [_projects count] + 1;
	}
	if (tableView == tvTasks) {
		if (_selProject == nil) {
			return 0;
		}
		return [[self currentTasks] count] + 1;
	}
	return 0;
}


- (void)tableView:(NSTableView *)tableView 
   setObjectValue:(id)obj 
   forTableColumn:(NSTableColumn *)tableColumn 
              row:(NSInteger)rowIndex
{
	if (tableView == tvProjects) {
		if ([[tableColumn identifier] isEqualToString: @"ProjectName"] && [_selProject isKindOfClass:[TProject class]]) {
            // first check if the name is actually different
            TProject* theProject = (TProject*)_selProject;
            if ([[theProject name] isEqualToString:obj]) {
                // nothing to do
                return;
            }
            // check for duplicate project names
            if (![self doesProjectNameExist:obj]) {
                [theProject setName: obj];
            } else {
                NSRunAlertPanel(@"A Project with that name already exists", 
                                @"Please choose a different name",
                                @"OK", nil/*@"NO"*/, /*ThirdButtonHere:*/nil
                                /*, args for a printf-style msg go here */);
            }                
		}
	}
	if (tableView == tvTasks) {
		if ([[tableColumn identifier] isEqualToString: @"TaskName"] && [_selTask isKindOfClass:[TTask class]]) {
            // check if the name actually changed
            if ([[_selTask name] isEqualToString:obj]) {
                // nothing to do
                return;
            }
            // Check for duplicate task names 
            TProject *taskProject = [((TTask*)_selTask) parentProject];
            if (![taskProject doesTaskNameExist:obj]) { 
                [(TTask*)_selTask setName: obj];
            } else {
                NSRunAlertPanel(@"A Task with that name already exists", 
                                @"Please choose a different name",
                                @"OK", nil/*@"NO"*/, /*ThirdButtonHere:*/nil
                                /*, args for a printf-style msg go here */);
            }                
		}
	}
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if (tableView == tvProjects) {
		id project = nil;
		if (rowIndex == 0) {
			project = _metaProject;
		} else {
			project = [_projects objectAtIndex: rowIndex - 1];
		}
		if ([[tableColumn identifier] isEqualToString: @"ProjectName"]) {
			return [project name];
		}
		if ([[tableColumn identifier] isEqualToString: @"TotalTime"]) {
            int seconds = [project filteredTime:[self filterPredicate]];
            return [_intervalValueFormatter transformSeconds:seconds];
		}
	}
	
	if (tableView == tvTasks) {
		
		id<ITask> task = nil;
		if (rowIndex == 0) {
			task = _metaTask;
		} else {
			task = [[self currentTasks] objectAtIndex: rowIndex - 1];
		}
		if ([[tableColumn identifier] isEqualToString: @"TaskName"]) {
			if (_selProject == _metaProject && rowIndex > 0) {
				NSMutableString *name = [NSMutableString stringWithFormat:@"%@ (%@)", [task name], [[((TTask*)task) parentProject] name]];
				return name;
			}
			return [task name];
		}
		if ([[tableColumn identifier] isEqualToString: @"TotalTime"]) {
            int seconds = [task filteredTime:[self filterPredicate]];
            return [_intervalValueFormatter transformSeconds:seconds];
		}
	}
	return nil;
}

#pragma mark NSTableViewDataSource methods

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
     toPasteboard:(NSPasteboard *)pboard
{
	if (aTableView == tvProjects)
	{
		NSArray *typesArray = [NSArray arrayWithObjects:PBOARD_TYPE_PROJECT_ROWS, nil];
		[pboard declareTypes:typesArray owner:self];
		
		NSData *rowIndexesArchive = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	    [pboard setData:rowIndexesArchive forType:PBOARD_TYPE_PROJECT_ROWS];
        
		return YES;
	}
	if (aTableView == tvTasks)
	{
		NSArray *typesArray = [NSArray arrayWithObjects:PBOARD_TYPE_TASK_ROWS, nil];
		[pboard declareTypes:typesArray owner:self];
        
		NSData *rowIndexesArchive = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
		[pboard setData:rowIndexesArchive forType:PBOARD_TYPE_TASK_ROWS];
		
		return YES;
	}
	return NO;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView 
                validateDrop:(id < NSDraggingInfo >)info 
                 proposedRow:(NSInteger)row 
       proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (row == 0 || _selProject == _metaProject) {
        // the all projects / all tasks row
        // neither allow dragging when in "All projects mode" since this wouldnt make too much sense.
        return NSDragOperationNone;
    }
	if (aTableView == tvProjects && [info draggingSource] == tvProjects)
	{
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
		return NSDragOperationMove;
	}
	if (aTableView == tvTasks && [info draggingSource] == tvTasks)
	{
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
		return NSDragOperationMove;
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info 
              row:(NSInteger)row 
    dropOperation:(NSTableViewDropOperation)operation
{
	if (aTableView == tvProjects && [info draggingSource] == tvProjects)
	{
		NSData *rowsData = [[info draggingPasteboard] dataForType:PBOARD_TYPE_PROJECT_ROWS];
		NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:rowsData];
		
		int sourceRow = [indexSet firstIndex] - 1;
        //		[document moveProject:[document objectInProjectsAtIndex:sourceRow] toIndex:row];
        TProject* sourceProject = [_projects objectAtIndex:sourceRow];
		[self moveProject:sourceProject toIndex:row - 1];
		
		[tvProjects reloadData];
		return YES;
	}
	if (aTableView == tvTasks && [info draggingSource] == tvTasks)
	{
		NSData *rowsData = [[info draggingPasteboard] dataForType:PBOARD_TYPE_TASK_ROWS];
		NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:rowsData];
		
		int sourceRow = [indexSet firstIndex] - 1;
		[_selProject moveTask:[_selProject.tasks objectAtIndex:sourceRow] toIndex:row - 1];
		
		[tvTasks reloadData];
		return YES;
	}
	return NO;
}




#pragma mark ----
#pragma mark TableView Delegate implementation

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if (_normalCol == nil) {
		_normalCol = [[aCell textColor] retain];
		_highlightCol = [[NSColor colorWithCalibratedRed:1.0f green:0.2f blue:0.2f alpha:1.0f] retain];//[[_normalCol highlightWithLevel:0.5] retain];
        _highlightBgCol = [[NSColor colorWithCalibratedRed:1.0f green:1.0f blue:0.0f alpha:1.0f] retain];//[[_normalCol highlightWithLevel:0.5] retain];
        _greyCol = [[NSColor colorWithCalibratedRed:0.4f green:0.4f blue:0.4f alpha:1.0f] retain];
	}
	if (aTableView == tvWorkPeriods) {
        TWorkPeriod *wp = [[workPeriodController arrangedObjects] objectAtIndex:rowIndex];
        // if we are showing the current task, apply different text color
        if (wp == _curWorkPeriod) {
            [aCell setTextColor:_highlightCol];
            [aCell setBackgroundColor:_highlightBgCol];
            [aCell setDrawsBackground:YES];
        }
        else {
            [aCell setTextColor:_normalCol];
            [aCell setDrawsBackground:NO];
        }
    } else if (aTableView == tvTasks) {
        BOOL closed = NO;
        if (rowIndex > 0 && _currentTasks != nil && rowIndex < [_currentTasks count]) {
            id<ITask> task = [_currentTasks objectAtIndex:rowIndex];
            closed = task.closed;
        }
        [aCell setTextColor:closed? _greyCol : _normalCol];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == tvProjects) {
		// Update the new selection
		// first remove the cached tasks
		[_filteredTasks release];
		_filteredTasks = nil;
        
		_taskNameTransformer.showProjectName = NO;

		if ([self selectedProjectRow] == -2) {
			self.selectedProject = nil;
		} else if ([self selectedProjectRow] == -1) {
			self.selectedProject = _metaProject;
			// all projects was selected, so show the project column
			if ([NSTableColumn instancesRespondToSelector:@selector(setHidden:)]) {
				[[tvWorkPeriods tableColumnWithIdentifier:@"Project"] setHidden:NO];
			}
			// if we have a filter on then already cache the tasks
			_taskNameTransformer.showProjectName = YES;
			[self updateTaskFilterCache];
		} else {
			// user has selected a valid project
			self.selectedProject = [_projects objectAtIndex: [self selectedProjectRow]];
			if ([NSTableColumn instancesRespondToSelector:@selector(setHidden:)]) {
				[[tvWorkPeriods tableColumnWithIdentifier:@"Project"] setHidden:YES];
			}
		}
        
		[self reloadTasks];
        // we have changed the selected project, select the metatask by default
        [self selectAndUpdateMetaTask];
		// apply the current filter if any
		[self applyFilterToCurrentTasks];
		[self updateProminentDisplay];
	}
	
	if ([notification object] == tvTasks) {		
		NSArray *tasks = [self currentTasks];
		
		if ([self selectedTaskRow] == -2) {
			NSLog(@"selecting null task");
			self.selectedTask = nil;
		} else if ([self selectedTaskRow] == -1) {
			[self selectAndUpdateMetaTask];
			if ([NSTableColumn instancesRespondToSelector:@selector(setHidden:)]) {
				[[tvWorkPeriods tableColumnWithIdentifier:@"Task"] setHidden:NO];
			}
		} else {
			// assert _selProject != nil
			self.selectedTask = [tasks objectAtIndex: [self selectedTaskRow]+1];
			NSLog(@"selected new task: %@", self.selectedTask.name);
			if ([NSTableColumn instancesRespondToSelector:@selector(setHidden:)]) {
				[[tvWorkPeriods tableColumnWithIdentifier:@"Task"] setHidden:YES];
			}
		}
			
		//		[self reloadWorkPeriods];
		[self updateProminentDisplay];
	}
	
	NSLog(@"selected project: %@, task: %@", _selProject, self.selectedTask);
}



#pragma mark ----


- (void) newFilterSelected {
    
}

#pragma mark ----
#pragma mark Object lifetime

-(void) dealloc {
    [_highlightCol release];
    [_normalCol release];
    [_highlightBgCol release];
    [_greyCol release];
	[_startTaskMenuDelegate release];
    [_taskNameTransformer release];
    [super dealloc];
}

@end
