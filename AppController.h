//
//  AppController.h
//  Proximity
//
//  Copyright (c) Denver Timothy
//  See License.txt for license information.
//

#import <Cocoa/Cocoa.h>
#import "BluetoothProximityController.h"


@interface AppController : NSObject
{
    IBOutlet NSTextField *deviceStatus;
    IBOutlet NSButton *enabled;
    IBOutlet NSTextField *inRangePath;
    IBOutlet NSTextField *outOfRangePath;
    IBOutlet NSTextField *seconds;
	IBOutlet NSProgressIndicator *progress;
	
	BluetoothProximityController *proximityController;
}

- (IBAction)changeDevice:(id)sender;
- (IBAction)changeInRangePath:(id)sender;
- (IBAction)changeOutOfRangePath:(id)sender;
- (IBAction)checkConnection:(id)sender;
- (IBAction)enable:(id)sender;
- (IBAction)testInRangeScript:(id)sender;
- (IBAction)testOutOfRangeScript:(id)sender;

@end
