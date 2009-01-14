#import <Cocoa/Cocoa.h>
@class MainController;

@interface StartTaskMenuDelegate : NSObject {
    MainController *_controller;
}

-(id) initWithController:(MainController*) controller;
@end
