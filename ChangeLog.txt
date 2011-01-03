=== 1.3.13 ===  2011-01-03

  * fixed issue 91 - the filter was not reapplied if you left TT running
    past midnight and it showed yesterdays entries in when having the
    today filter.
  * fixed issue 95 - replaced BWtoolkit styled but broken ok button with std
    button
  * general UI overhaul where a bunch of small annyoing issues were cleaned
    up
  * fixed a bug where on new years the last week/this week filters produced
    empty results

=== 1.3.12 ===  2010-12-02

  * IMPORTANT! requires Mac OS 10.5 or higher
  * Superfluous ";" character in exported CSV
  * fixed wrong version number (v1.3.12a)

=== 1.3.11 ===  2010-10-18

  * IMPORTANT! requires Mac OS 10.5 or higher
  * Fixed issue 79 made build universal again
  * added keyboard shortcut to confirm a change to a recording
  * fixed potential issue with KVO registration
  * fixed issue which would try to pop up an idle warning when an editor
    window was open
  * fixed issue 76 where deleting a task would not immediately show the task
    removed

=== 1.3.10 ===  2010-09-20

  * IMPORTANT! requires Mac OS 10.5 or higher
  * fixed a potential segfault when starting a recording after having "all
    projects" selected
  * fixed issue 75 adding a recording via the plus while last week filter is
    on does not show the recording until restart

=== 1.3.9 ===  2010-09-08

  * IMPORTANT! requires Mac OS 10.5 or higher
  * fixed the problem where "all tasks" was not updating the time in
    realtime.
  * fix the problem where after selecting a different project the "all
    tasks" didnt show the correct time (but the time from the previously
    selected project)
  * fixed issue 70 czech localization added (trial)
  * fixed issue 65 drag and drop support was broken for tasks

=== 1.3.8 ===  2010-08-17

  * IMPORTANT! requires Mac OS 10.5 or higher
  * fixed refresh of display after deleting a recording
  * migrated appcast update urls to new mercurial site
  * fixed calculation of filtered time (regression introduced by project
    closing support)
  * fixed issue 69 TT hangs when starting a task using the system menu while
    inactivity popup is shown

=== 1.3.7 ===  2010-07-10

  * IMPORTANT! requires Mac OS 10.5 or higher
  * added preliminary support for closing tasks (time is not counted against
    project)
  * CSV export now uses UTF-8 which should fix some issues with foreign
    characters
  * fixed display of time recordings when filter is selected
  * added filters for "last month" and "this month"

=== 1.3.6 ===  2010-04-30

  * IMPORTANT! requires Mac OS 10.5 or higher
  * changed toolbar icons to the ones courtesy of Bernard Bélanger (thanks
    a lot)
  * finder info now shows correct app version (thanks to Russe for the tip).
  * fixed issue 22 Now users can choose to display durations as decimal
    hours.
  * fixed issue 51 Keyboard shortcut for export CSV
  * fixed issue 52 resizing preferences window causes overlap

=== 1.3.5 ===  2010-04-13

  * IMPORTANT! requires Mac OS 10.5 or higher
  * fixed issue 44 where CSV export did not include seconds.
  * fixed issue 45 bring back drag and drop support for projects and tasks
  * fixed issue 28 added support to close the main window and leave
    TimeTracker running
  * fixed issue 49 Text filtering broken when used in conjunction with smart
    filters
  * fixed issue 47 filterbox sometimes appears partially out of view
  * now when loading data (importing from old versions) TT makes sure that
    task names are not duplicated within a project

=== 1.3.4 ===  2009-03-31

  * IMPORTANT! requires Mac OS 10.5 or higher!!
  * automatically check for updates in preferences properly hooked up to
    Sparkle
  * have proper default value for stable appcast in sparkle preferences
  * fixed wrong "custom filter" which didnt bring up any results
  * fixed version number in about panel

=== 1.3.3 ===  2009-03-23

  * itunes like interface
  * smart filters which can be saved
  * tableview on the bottom remembers column widths
  * split views remember their sizes
  * Sparkle updates with selection of stable and beta versions

=== 1.3.1 ===  2009-11-20

  * extended CSV export
  * system menu bar remembers list of recent tasks and allows quick start
    without activating the GUI
  * comments!
  * ability to edit and reassign entries to different tasks / projects
    (double click on a recording)
  * updated icons
  * prevent duplicate project / task names which can seriously screw up the
    database
  * laptop standby mode detection

=== 1.2.6 ===  2009-02-16

  * Edit work period and Delete work period now work properly when a date
    range filter is active.
  * New "week before last" filter.
  * The start button will create a new project/task if none is selected (or
    if there are no projects or tasks).

=== 1.2.5 ===  2008-09-30

  * Added basic filtering by day, week and month.

=== 1.2.4 ===  2008-08-14

  * Fixed a bug where projects could not be created the first time Time
    Tracker was run on a computer.
  * Projects and tasks can now be reordered by dragging and dropping them.
  * Added "Export CSV..." option to export Time Tracker data into Excel.
    Contributed by Rainer Burgstaller.

=== 1.2.3 ===  2008-07-09

  * Fixed the problem where project and task names could not be edited when
    the timer was running. ([http://tt-jira.avh4.net/browse/TT-2 TT-2])
  * You can now print the entire Time Tracker window (all three panes at
    once) using the new "Print Window" function, as requested by Rich
    Wojtas. ([http://tt-jira.avh4.net/browse/TT-24 TT-24])
  * You can now resize the Projects/Tasks tables relative to each other.
    ([http://tt-jira.avh4.net/browse/TT-23 TT-23])
  * Upgraded [http://sparkle.andymatuschak.org Sparkle] to version 1.5b4.
    Thanks to Andy Matuschak for maintaining and supporting Sparkle!
    ([http://tt-jira.avh4.net/browse/TT-19 TT-19])
  * (refactoring) removed updateTotalTime from TTask and TProject.

=== 1.2.2 ===  2008-07-03

  * Added auto-updating support via appcasts using Sparkle 1.5b2. <
    http://sparkle.andymatuschak.org/ >

=== 1.2.1 ===  2007-01-23
Packaged by Aaron VonderHaar <gruen0aermel@gmail.com>

  * Fixed bug 19: Re-enable basic print functionality that was present in
    version 1.1. Complete printing support will be added in version 1.3.

=== 1.2 ===  2007-01-21
Packaged by Aaron VonderHaar <gruen0aermel@gmail.com>

  * Fixed bug 9: Fixed occasional crashes when deleting tasks.
  * Fixed bug 10: Added menu items and keyboard shortcuts for
    starting/stopping the timer and creating new projects and tasks.

=== 1.1.002 ===  
NOT OFFICIALLY RELEASED, due to bug 9. Packaged by Aaron VonderHaar
<gruen0aermel@gmail.com>

  * Fixed bug 5: When adding a new project or task, the new entry is
    immediately selected for renaming.
  * Fixed bug 6: When selecting a project, the task that was previoudly
    selected is reselected.
  * Fixed bug 2: It is no longer possible to add work periods that are not
    associated with a task or project.

=== 1.1 ===  2007-01-11
Packaged by Aaron VonderHaar <gruen0aermel@gmail.com>

  * Data is now saved to disk every five minutes when the timer is running.
  * Data is now saved when the timer is stopped.
  * Project settings are changed to produce a Universal Binary.
  * Changed the nib file for more efficient use of space.
  * Made window resizable.
  * Window size and position is saved in the system defaults.
  * Ensures that the display is refreshed when the main window is first
    loaded (this was not the case when the window size/position was
    restored).

