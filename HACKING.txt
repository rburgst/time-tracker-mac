This file contains information for building and packaging TimeTracker.

== If you only want to develop ==

Then all you need to do is open the Time Tracker.xcodeproj in XCode 3. Build
and run as you please.

== Prerequisites == 
* Rubygems
* gem install text-format
* gem install builder
* PowerPC XCode build symbols (you should have this if you have a default XCode install)

== Release Packaging ==

1. Make sure the version number is updated:
    1a. Update CURRENT_PROJECT_VERSION for "All Configurations" in the 
        Project Info within XCode. To be on the safe side do it for the 
        generic project as well as for the Time Tracker target in the "Targets"
        section.

2. Update the ChangeLog.yml.

3. Build the Time Tracker.zip release file:
    4a. Run `rake build_release`.  This will create "build/Release/Time Tracker-$(CURRENT_PROJECT_VERSION).zip".

4. If Sparkle or the release file configuration has been changed, test the auto-update system:
    5a. Install the previous version of Time Tracker.
    5b. Update and post appcast/timetracker-test.xml
    5c. Open ~/Library/Preferences/com.slooz.timetracker.plist and change
        SUFeedURL to the location of timetracker-test.xml  (If the URL contains
        spaces, replace them with "%20".)
    5d. Ensure that the old version of Time Tracker can update to the new version.
    5e. Ensure that the new version of Time Tracker can update to itself.

5. Run `rake appcast` to generate appcast/timetracker-$(CURRENT_PROJECT_VERSION).html

6. Publish the release:
    6a. Run `rake upload`.  You will need to enter your google code username and your googlecode
        password which is found at http://code.google.com/hosting/settings
        This will upload Time Tracker-$(CURRENT_PROJECT_VERSION).zip and 
        timetracker-$(CURRENT_PROJECT_VERSION).html to
        http://time-tracker-mac.googlecode.com
    6b. Check in appcast/timetracker-stable.xml or copy the latest release to the 
        appcast/timetracker-beta.xml (if you want to release it as beta).
        Once you push the commit to google, the new release is visible to all users.
    

7. Update the website:
    7a. Update the homepage http://time-tracker-mac.googlecode.com
    7b. Make the new release the featured download http://time-tracker-mac.googlecode.com
    7c. (Update iusethis.com)
    7d. (Update versiontracker.com)

8. Tag the release with "v$(CURRENT_PROJECT_VERSION)" and push the commit.

== Appcast updates with Sparkle ==

There is a dummy appcast which will alway contain a fake "update" for Time
Tracker.  To use this to test the Sparkle updating, edit Info.plist and change
"SUFeedURL" to point to "timetracker-test.xml" instead of
"timetracker-stable.xml"

