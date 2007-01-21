#include <IOKit/IOKitLib.h>

#import "MainController.h"
#import "TTask.h"
#import "TProject.h"
#import "TimeIntervalFormatter.h"
#import "TWorkPeriod.h"

@implementation MainController

- (id) init
{
	_projects = [NSMutableArray new];
	_selProject = nil;
	_selTask = nil;
	_curTask = nil;
	_curProject = nil;
	timer = nil;
	timeSinceSave = 0;
	
	return self;
}

- (IBAction)clickedStartStopTimer:(id)sender
{
	if (timer == nil) {
		[self startTimer];
	} else {
		[self stopTimer];
	}
}

- (void)startTimer
{
	// assert _selProject != nil
	if (_selTask == nil)
		return;
	timer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector (timerFunc:)
					userInfo: nil repeats: YES];
	
	[self updateStartStopState];
	
	_curWorkPeriod = [TWorkPeriod new];
	[_curWorkPeriod setStartTime: [NSDate date]];
	[_curWorkPeriod setEndTime: [NSDate date]];
	
	[_selTask addWorkPeriod: _curWorkPeriod];
	[tvWorkPeriods reloadData];	
	_curProject = _selProject;
	_curTask = _selTask;
}

- (void)stopTimer
{
	[self stopTimer:[NSDate date]];
}

- (void)stopTimer:(NSDate*)endTime
{
	if (timer == nil) return;
	
	[timer invalidate];
	timer = nil;
	
	[_curWorkPeriod setEndTime:endTime];
	[_curTask updateTotalTime];
	[_curProject updateTotalTime];
	_curProject = nil;
	_curTask = nil;
	
	[self saveData];
	
	[self updateStartStopState];
	
	[tvProjects reloadData];
	[tvTasks reloadData];
	[tvWorkPeriods reloadData];
	
	//[defaults setObject: [NSNumber numberWithInt: totalTime] forKey: @"TotalTime"];
	
}

- (void)toolbarWillAddItem:(NSNotification *)notification
{
}

- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
    
	if ([itemIdentifier isEqual: @"Startstop"]) {
		startstopToolbarItem = toolbarItem;
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(clickedStartStopTimer:)];
		[self updateStartStopState];
    }
	
	if ([itemIdentifier isEqual: @"AddProject"]) {
		addProjectToolbarItem = toolbarItem;
		[toolbarItem setLabel:@"New project"];
		[toolbarItem setPaletteLabel:@"New project"];
		[toolbarItem setToolTip:@"New project"];
		[toolbarItem setImage: addProjectToolImage];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(clickedAddProject:)];
    }
	
	if ([itemIdentifier isEqual: @"AddTask"]) {
		addTaskToolbarItem = toolbarItem;
		[toolbarItem setLabel:@"New task"];
		[toolbarItem setPaletteLabel:@"New task"];
		[toolbarItem setToolTip:@"New task"];
		[toolbarItem setImage: addTaskToolImage];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(clickedAddTask:)];
    }
    
    return toolbarItem;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects: @"Startstop", NSToolbarSeparatorItemIdentifier, @"AddProject", @"AddTask", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects: @"Startstop", NSToolbarSeparatorItemIdentifier, @"AddProject", @"AddTask", nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return nil;
}

- (void)awakeFromNib
{

	defaults = [NSUserDefaults standardUserDefaults];
	
	NSData *theData=[[NSUserDefaults standardUserDefaults] dataForKey:@"ProjectTimes"];
	if (theData != nil)
		_projects = (NSMutableArray *)[[NSMutableArray arrayWithArray: [NSUnarchiver unarchiveObjectWithData:theData]] retain];
	
	_projects_lastTask = [[NSMutableDictionary alloc] initWithCapacity:[_projects count]];
	
	//NSNumber *numTotalTime = [defaults objectForKey: @"TotalTime"];
	
	/*NSZone *menuZone = [NSMenu menuZone];
	NSMenu *m = [[NSMenu allocWithZone:menuZone] init];

	startStopMenuItem = (NSMenuItem *)[m addItemWithTitle:@"Start" action:@selector(clickedStartStopTimer:) keyEquivalent:@""];
	[startStopMenuItem setTarget:self];
	[startStopMenuItem setTag:1];*/

	/*if ([preferences isGrowlRunning]) {
		[tempMenuItem setTitle:kRestartGrowl];
		[tempMenuItem setToolTip:kRestartGrowlTooltip];
	} else {
		[tempMenuItem setToolTip:kStartGrowlTooltip];
	}

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStopGrowl action:@selector(stopGrowl:) keyEquivalent:@""];
	[tempMenuItem setTag:2];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kStopGrowlTooltip];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStopGrowlMenu action:@selector(terminate:) keyEquivalent:@""];
	[tempMenuItem setTag:5];
	[tempMenuItem setTarget:NSApp];
	[tempMenuItem setToolTip:kStopGrowlMenuTooltip];

	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kSquelchMode action:@selector(squelchMode:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:4];
	[tempMenuItem setToolTip:kSquelchModeTooltip];

	NSMenu *displays = [[NSMenu allocWithZone:menuZone] init];
	NSString *name;
	NSEnumerator *displayEnumerator = [[[GrowlPluginController controller] allDisplayPlugins] objectEnumerator];
	while ((name = [displayEnumerator nextObject])) {
		tempMenuItem = (NSMenuItem *)[displays addItemWithTitle:name action:@selector(defaultDisplay:) keyEquivalent:@""];
		[tempMenuItem setTarget:self];
		[tempMenuItem setTag:3];
	}
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kDefaultDisplay action:NULL keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setSubmenu:displays];
	[displays release];
	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kOpenGrowlPreferences action:@selector(openGrowlPreferences:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kOpenGrowlPreferencesTooltip];*/


	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	
	[statusItem setTarget: self];
	[statusItem setAction: @selector (clickedStartStopTimer:)];

	NSBundle *bundle = [NSBundle mainBundle];

	playItemImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"playitem" ofType:@"png"]];
	playItemHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"playitem_hl" ofType:@"png"]];
	stopItemImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"stopitem" ofType:@"png"]];
	stopItemHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"stopitem_hl" ofType:@"png"]];

	playToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"playtool" ofType:@"png"]];
	stopToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"stoptool" ofType:@"png"]];
	addTaskToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"addtasktool" ofType:@"png"]];
	addProjectToolImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"addprojecttool" ofType:@"png"]];

	//[statusItem setMenu:m]; // retains m
	[statusItem setToolTip:@"Time Tracker"];
	[statusItem setHighlightMode:NO];

	//[m release];		
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: @"TimeTrackerToolbar"];
	[toolbar setDelegate: self];
	[mainWindow setToolbar: toolbar];	

	[self updateStartStopState];
	
	[tvWorkPeriods setTarget: self];
	[tvWorkPeriods setDoubleAction: @selector(doubleClickWorkPeriod:)];
	
	[tvProjects reloadData];
}

- (void) doubleClickWorkPeriod: (id) sender
{
	TWorkPeriod *wp = [[_selTask workPeriods] objectAtIndex: [tvWorkPeriods selectedRow]];
	[dtpEditWorkPeriodStartTime setDateValue: [wp startTime]];
	[dtpEditWorkPeriodEndTime setDateValue: [wp endTime]];
	[panelEditWorkPeriod makeKeyAndOrderFront: self];
	[NSApp runModalForWindow: panelEditWorkPeriod];
}

- (IBAction)clickedChangeWorkPeriod:(id)sender
{
	TWorkPeriod *wp = [[_selTask workPeriods] objectAtIndex: [tvWorkPeriods selectedRow]];
	[wp setStartTime: [dtpEditWorkPeriodStartTime dateValue]];
	[wp setEndTime: [dtpEditWorkPeriodEndTime dateValue]];
	[_selTask updateTotalTime];
	[_selProject updateTotalTime];
	[tvProjects reloadData];
	[tvTasks reloadData];
	[tvWorkPeriods reloadData];
	[NSApp stopModal];
	[panelEditWorkPeriod orderOut: self];
}

- (void) timerFunc: (NSTimer *) atimer
{	
	[_curWorkPeriod setEndTime: [NSDate date]];
	[_curTask updateTotalTime];
	[_curProject updateTotalTime];
	[tvProjects reloadData];
	[tvTasks reloadData];
	[tvWorkPeriods reloadData];
	int idleTime = [self idleTime];
	if (idleTime == 0) {
		[_lastNonIdleTime release];
		_lastNonIdleTime = nil;
		_lastNonIdleTime = [[NSDate date] retain];
	}
	if (idleTime > 5 * 60) {
		[timer setFireDate: [NSDate distantFuture]];
		[NSApp activateIgnoringOtherApps: YES];
		[NSApp runModalForWindow: panelIdleNotification];
		[panelIdleNotification orderOut: self];
	}
	
	if (timeSinceSave > 5 * 60) {
		[self saveData];
	} else {
		timeSinceSave++;
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	if ([notification object] == mainWindow)
		[NSApp terminate: self];
	if ([notification object] == panelEditWorkPeriod)
		[NSApp stopModal];
}

- (void)saveData
{
	NSData *theData=[NSArchiver archivedDataWithRootObject:_projects];
	[[NSUserDefaults standardUserDefaults] setObject:theData forKey:@"ProjectTimes"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	timeSinceSave = 0;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if (timer != nil)
		[self stopTimer];
	[self saveData];
	return NSTerminateNow;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == tvProjects) {
		return [_projects count];
	}
	if (tableView == tvTasks) {
		if (_selProject == nil)
			return 0;
		else
			return [[_selProject tasks] count];
	}
	if (tableView == tvWorkPeriods) {
		if (_selTask == nil)
			return 0;
		else
			return [[_selTask workPeriods] count];
	}
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	if (tableView == tvProjects) {
		if ([[tableColumn identifier] isEqualToString: @"ProjectName"]) {
			return [[_projects objectAtIndex: rowIndex] name];
		}
		if ([[tableColumn identifier] isEqualToString: @"TotalTime"]) {
			return [TimeIntervalFormatter secondsToString: [[_projects objectAtIndex: rowIndex] totalTime]];
		}
	}
	
	if (tableView == tvTasks) {
		if ([[tableColumn identifier] isEqualToString: @"TaskName"]) {
			return [[[_selProject tasks] objectAtIndex: rowIndex] name];
		}
		if ([[tableColumn identifier] isEqualToString: @"TotalTime"]) {
			return [TimeIntervalFormatter secondsToString: [[[_selProject tasks] objectAtIndex: rowIndex] totalTime]];
		}
	}
	
	if (tableView == tvWorkPeriods) {
		if ([[tableColumn identifier] isEqualToString: @"Date"]) {
			return [[[[_selTask workPeriods] objectAtIndex: rowIndex] startTime] 
				descriptionWithCalendarFormat: @"%m/%d/%Y"
				timeZone: nil locale: nil];
		}
		if ([[tableColumn identifier] isEqualToString: @"StartTime"]) {
			return [[[[_selTask workPeriods] objectAtIndex: rowIndex] startTime] 
				descriptionWithCalendarFormat: @"%H:%M:%S"
				timeZone: nil locale: nil];
		}
		if ([[tableColumn identifier] isEqualToString: @"EndTime"]) {
			NSDate *endTime = [[[_selTask workPeriods] objectAtIndex: rowIndex] endTime];
			if (endTime == nil)
				return @"";
			else
				return [endTime 
					descriptionWithCalendarFormat: @"%H:%M:%S"
					timeZone: nil locale: nil];
		}
		if ([[tableColumn identifier] isEqualToString: @"Duration"]) {
			return [TimeIntervalFormatter secondsToString: [[[_selTask workPeriods] objectAtIndex: rowIndex] totalTime]];
		}
	}
	
	return nil;
}

- (IBAction)clickedAddProject:(id)sender
{
	TProject *proj = [TProject new];
	[_projects addObject: proj];
	[tvProjects reloadData];
	int index = [_projects count] - 1;
	[tvProjects selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[tvProjects editColumn:[tvProjects columnWithIdentifier:@"ProjectName"] row:index withEvent:nil select:YES];
}

- (IBAction)clickedAddTask:(id)sender
{
	TTask *task = [TTask new];
	[_selProject addTask: task];
	[tvTasks reloadData];
	int index = [[_selProject tasks] count] - 1;
	[tvTasks selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	[tvTasks editColumn:[tvTasks columnWithIdentifier:@"TaskName"] row:index withEvent:nil select:YES];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == tvProjects) {
		// Save the last task for the old project
		if (_selProject != nil) {
			NSNumber *index = [NSNumber numberWithInt:[tvTasks selectedRow]];
			[_projects_lastTask setObject:index forKey:[_selProject name]];
		}
	
		// Update the new selection
		if ([tvProjects selectedRow] == -1) {
			_selProject = nil;
		} else {
			_selProject = [_projects objectAtIndex: [tvProjects selectedRow]];
		}

		[tvTasks deselectAll: self];
		[tvTasks reloadData];
		
		if (_selProject != nil && [[_selProject tasks] count] > 0) {
			NSNumber *lastTask = [_projects_lastTask objectForKey:[_selProject name]];
			if (lastTask == nil || [lastTask intValue] == -1) {
				[tvTasks selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
			} else {
				[tvTasks selectRowIndexes:[NSIndexSet indexSetWithIndex:[lastTask intValue]] byExtendingSelection:NO];
			}
		}
	}
	
	if ([notification object] == tvTasks) {
		if ([tvTasks selectedRow] == -1) {
			_selTask = nil;
		} else {
			_selTask = [[_selProject tasks] objectAtIndex: [tvTasks selectedRow]];
		}
		[tvWorkPeriods reloadData];
	}

}

- (void)tableView:(NSTableView *)tableView 
	setObjectValue:(id)obj 
	forTableColumn:(NSTableColumn *)tableColumn 
	row:(int)rowIndex
{
	if (tableView == tvProjects) {
		if ([[tableColumn identifier] isEqualToString: @"ProjectName"])
			[_selProject setName: obj];
	}
	if (tableView == tvTasks) {
		if ([[tableColumn identifier] isEqualToString: @"TaskName"])
			[_selTask setName: obj];
	}
}

- (IBAction)clickedDelete:(id)sender
{
	if ([mainWindow firstResponder] == tvWorkPeriods) {
		[[_selTask workPeriods] removeObjectAtIndex: [tvWorkPeriods selectedRow]];
		[_selTask updateTotalTime];
		[_selProject updateTotalTime];
		[tvWorkPeriods deselectAll: self];
		[tvWorkPeriods reloadData];
		[tvTasks reloadData];
		[tvProjects reloadData];
	}
	if ([mainWindow firstResponder] == tvTasks) {
		if (_selTask == _curTask) {
			[self stopTimer];
		}
		TTask *delTask = _selTask;
		[tvTasks deselectAll: self];
		[[_selProject tasks] removeObject: delTask];
		[_selProject updateTotalTime];
		[tvTasks reloadData];
		[tvProjects reloadData];
	}
	if ([mainWindow firstResponder] == tvProjects) {
		if (_selProject == _curProject) {
			[self stopTimer];
		}
		TProject *delProject = _selProject;
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
	[timer setFireDate: [NSDate dateWithTimeIntervalSinceNow: 1]];
	[NSApp stopModal];
}

- (BOOL) validateUserInterfaceItem:(id)anItem
{
	if ([anItem action] == @selector(clickedStartStopTimer:)) {
		if (timer != nil) return YES;
		if (_selTask != nil) return YES;
		return NO;
	} else
	if ([anItem action] == @selector(clickedAddProject:)) {
		return YES;
	} else
	if ([anItem action] == @selector(clickedAddTask:)) {
		if (_selProject != nil) return YES;
		return NO;
	}
	return YES;
}

- (void)updateStartStopState
{
	if (timer == nil) {
		// Timer is stopped: show the Start button
		[startstopToolbarItem setLabel:@"Start"];
		[startstopToolbarItem setPaletteLabel:@"Start"];
		[startstopToolbarItem setToolTip:@"Start timer"];
		[startstopToolbarItem setImage: playToolImage];
		
		[statusItem setImage:playItemImage];
		[statusItem setAlternateImage:playItemHighlightImage];
		
		[startMenuItem setTitle:@"Start Timer"];
	} else {
		[startstopToolbarItem setLabel:@"Stop"];
		[startstopToolbarItem setPaletteLabel:@"Stop"];
		[startstopToolbarItem setToolTip:@"Stop timer"];
		[startstopToolbarItem setImage: stopToolImage];
		
		[statusItem setImage:stopItemImage];
		[statusItem setAlternateImage:stopItemHighlightImage];
		
		[startMenuItem setTitle:@"Stop Timer"];
	}
	
}

- (IBAction)clickedCountIdleTimeNo:(id)sender
{
	[NSApp stopModal];
	[_curWorkPeriod setEndTime: _lastNonIdleTime];
	[_lastNonIdleTime release];
	_lastNonIdleTime = nil;
	
	//XXX this code is duplicated from stopTimer: ??
	[_curTask updateTotalTime];
	[_curProject updateTotalTime];
	[tvProjects reloadData];
	[tvTasks reloadData];
	[tvWorkPeriods reloadData];
	
	[self stopTimer:_lastNonIdleTime];
}


@end
