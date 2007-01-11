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
		if (_selTask == nil)
			return;
		timer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector (timerFunc:)
			userInfo: nil repeats: YES];
			
		[statusItem setImage:stopItemImage];
		[statusItem setAlternateImage:stopItemHighlightImage];
		
		[startstopToolbarItem setLabel:@"Stop"];
		[startstopToolbarItem setPaletteLabel:@"Stop"];
		[startstopToolbarItem setToolTip:@"Stop timer"];
		[startstopToolbarItem setImage: stopToolImage];
		
		_curWorkPeriod = [TWorkPeriod new];
		[_curWorkPeriod setStartTime: [NSDate date]];
		[_curWorkPeriod setEndTime: [NSDate date]];
		
		[_selTask addWorkPeriod: _curWorkPeriod];
		[tvWorkPeriods reloadData];	
		_curProject = _selProject;
		_curTask = _selTask;	
	} else {
		_curProject = nil;
		_curTask = nil;
		if (_selTask == nil)
			[startstopToolbarItem setEnabled: NO];
		[startstopToolbarItem setLabel:@"Start"];
		[startstopToolbarItem setPaletteLabel:@"Start"];
		[startstopToolbarItem setToolTip:@"Start timer"];
		[startstopToolbarItem setImage: playToolImage];
		
		[timer invalidate];
		timer = nil;
	
		[statusItem setImage:playItemImage];
		[statusItem setAlternateImage:playItemHighlightImage];
		[self stopTimer];
		[self saveData];
		
		[_curWorkPeriod setEndTime: [NSDate date]];
		[_curTask updateTotalTime];
		[_curProject updateTotalTime];
		[tvProjects reloadData];
		[tvTasks reloadData];
		[tvWorkPeriods reloadData];
	}
}

- (void) stopTimer
{
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
		[toolbarItem setLabel:@"Start"];
		[toolbarItem setPaletteLabel:@"Start"];
		[toolbarItem setToolTip:@"Start timer"];
		[toolbarItem setImage: playToolImage];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(clickedStartStopTimer:)];
		[toolbarItem setAutovalidates: NO];
		[toolbarItem setEnabled: NO];
    }
	
	if ([itemIdentifier isEqual: @"AddProject"]) {
		addProjectToolbarItem = toolbarItem;
		[toolbarItem setLabel:@"Add project"];
		[toolbarItem setPaletteLabel:@"Add project"];
		[toolbarItem setToolTip:@"Add project"];
		[toolbarItem setImage: addProjectToolImage];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(clickedAddProject:)];
    }
	
	if ([itemIdentifier isEqual: @"AddTask"]) {
		addTaskToolbarItem = toolbarItem;
		[toolbarItem setLabel:@"Add task"];
		[toolbarItem setPaletteLabel:@"Add task"];
		[toolbarItem setToolTip:@"Add task"];
		[toolbarItem setImage: addTaskToolImage];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(clickedAddTask:)];
		[toolbarItem setAutovalidates: NO];
		[toolbarItem  setEnabled: NO];
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


	[statusItem setImage:playItemImage];
	[statusItem setAlternateImage:playItemHighlightImage];

	//[statusItem setMenu:m]; // retains m
	[statusItem setToolTip:@"Time Tracker"];
	[statusItem setHighlightMode:NO];

	//[m release];		
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: @"TimeTrackerToolbar"];
	[toolbar setDelegate: self];
	[mainWindow setToolbar: toolbar];	
	[startstopToolbarItem setEnabled: NO];	
	
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
	[self saveData];
	if (timer != nil)
		[self stopTimer];
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
}

- (IBAction)clickedAddTask:(id)sender
{
	TTask *task = [TTask new];
	[_selProject addTask: task];
	[tvTasks reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	if ([notification object] == tvProjects) {
		if ([tvProjects selectedRow] == -1) {
			_selProject = nil;
			[addTaskToolbarItem setEnabled: NO];
		} else {
			_selProject = [_projects objectAtIndex: [tvProjects selectedRow]];
			[addTaskToolbarItem setEnabled: YES];
		}
		[tvTasks deselectAll: self];
		[tvTasks reloadData];
	}
	
	if ([notification object] == tvTasks) {
		if ([tvTasks selectedRow] == -1) {
			if (timer == nil)
				[startstopToolbarItem setEnabled: NO];
			_selTask = nil;			
		} else {
			_selTask = [[_selProject tasks] objectAtIndex: [tvTasks selectedRow]];
			[startstopToolbarItem setEnabled: YES];
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
		[[_selProject tasks] removeObject: _selTask];
		[_selProject updateTotalTime];
		[tvTasks deselectAll: self];
		[tvTasks reloadData];
		[tvProjects reloadData];
	}
	if ([mainWindow firstResponder] == tvProjects) {
		[_projects removeObject: _selProject];
		[tvProjects deselectAll: self];
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

- (IBAction)clickedCountIdleTimeNo:(id)sender
{
	[NSApp stopModal];
	[_curWorkPeriod setEndTime: _lastNonIdleTime];
	[_lastNonIdleTime release];
	_lastNonIdleTime = nil;
	[_curTask updateTotalTime];
	[_curProject updateTotalTime];
	[tvProjects reloadData];
	[tvTasks reloadData];
	[tvWorkPeriods reloadData];
	
	_curProject = nil;
		_curTask = nil;
		if (_selTask == nil)
			[startstopToolbarItem setEnabled: NO];
		[startstopToolbarItem setLabel:@"Start"];
		[startstopToolbarItem setPaletteLabel:@"Start"];
		[startstopToolbarItem setToolTip:@"Start timer"];
		[startstopToolbarItem setImage: playToolImage];
		
		[timer invalidate];
		timer = nil;
	
		[statusItem setImage:playItemImage];
		[statusItem setAlternateImage:playItemHighlightImage];
		[self stopTimer];
		
		[_curTask updateTotalTime];
		[_curProject updateTotalTime];
		[tvProjects reloadData];
		[tvTasks reloadData];
		[tvWorkPeriods reloadData];
	
	
}


@end
