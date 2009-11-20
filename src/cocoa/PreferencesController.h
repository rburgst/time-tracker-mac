#import <Cocoa/Cocoa.h>

@class MainController;

@interface PreferencesController : NSObject<NSCoding> {
    IBOutlet NSTextField* _csvFilenameField;
    IBOutlet MainController* _mainController;
}

- (IBAction) pickOutputFileClicked:(id) sender;
@end
