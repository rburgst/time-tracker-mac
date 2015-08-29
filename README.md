# time-tracker-mac

## HowToUse  
A very brief introduction on how to use TimeTracker. 

### Getting Started
In order to get started with TimeTracker do the following:

1. Start TimeTracker
2. Create a project by clicking on the "New Project" button in the toolbar and give it a meaningful name
3. select your new project
4. create a task within your new project and give it a meaningful name
5. select the task within the project
6. Now the green recording button will become active and you can start recording your times

### Using the status bar

The status bar allows you to quickly start/stop recording of your last recently used tasks. You can configure the number of last tasks TimeTracker will record in the settings screen. Furthermore, you can also start the currently selected task / project from the main window.

## FAQ

#### Where is the data stored?
Old versions of TimeTracker stored the data in `<userhome>/Library/Preferences/com.slooz.timetracker.plist`. In fact this is still used but only for settings.

Newer versions of TimeTracker store their data in `<userhome>/Library/Application Support/TimeTracker/data.plist`. In this file all your recordings are stored.

If you want to move to a new computer or backup your data, you only need to store the data.plist file.

#### Is Power PC still supported?
In fact it is, only a few versions dropped the support but 1.3.11 will add it back in. Newer version wont anymore.

#### What is the minimum OS version?
TimeTracker requires at least OSX 10.5.

#### Is it possible to import from XLS or CSV?
Nope.

#### How do I edit a task / project / recording?
Just double click.

#### How do I delete a task/recording?
Select the item and hit the backspace key.
