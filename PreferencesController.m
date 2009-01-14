#import "PreferencesController.h"

#import "MainController.h"

@implementation PreferencesController
- (void)windowWillClose:(NSNotification *)notification
{
    // to be sure remove the focus from the filename field in order to trigger it binding the new value
    [[_csvFilenameField window] makeFirstResponder:[_csvFilenameField window]];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    return [self init];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
}

- (IBAction) pickOutputFileClicked:(id) sender {
    NSSavePanel *sp;
    int savePanelResult;
    
    sp = [NSSavePanel savePanel];
    
    [sp setTitle:@"Autosave CSV"];
    [sp setNameFieldLabel:@"Filename:"];
    [sp setPrompt:@"Save"];
    
    [sp setRequiredFileType:@"csv"];
    
    savePanelResult = [sp runModalForDirectory:nil file:@"Time Tracker Data.csv"];
    
    if (savePanelResult == NSOKButton) {
        [_mainController setAutosaveCsvFilename:[sp filename]];
    }
}
@end
