//
//  AppController.m
//  Proximity
//
//  Copyright (c) Denver Timothy
//  See License.txt for license information.
//


#import "AppController.h"
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>


@implementation AppController

- (id)init
{
	[super self];
	
	proximityController = [[BluetoothProximityController alloc] init];
	
	return self;
}

- (IBAction)changeDevice:(id)sender
{
	IOBluetoothDeviceSelectorController *deviceSelector;
	deviceSelector = [[IOBluetoothDeviceSelectorController alloc] init];
	[deviceSelector runModal];
	
	NSArray *results;
	results = [deviceSelector getResults];
	
	if( !results )
		return;
	
	IOBluetoothDevice *device;
	device = [results objectAtIndex:0];
	
	[deviceStatus setStringValue:[NSString stringWithFormat:@"%@ (%@)",
		[device getName], [device getAddressString]]];
	
	[proximityController setDevice:device];
}

- (IBAction)changeInRangePath:(id)sender
{
	// Open the panel and select a file
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op runModalForDirectory:@"~" file:nil types:[NSArray arrayWithObject:@"scpt"]];
	
	// Get the selected filenames (only one file can be selected)
	NSArray *filenames = [op filenames];
	
	// Display the path of the selected file in the window
	[inRangePath setStringValue:[filenames objectAtIndex:0]];
	
	// Set the path in the proximity controller
	[proximityController setInRangeScriptPath:[filenames objectAtIndex:0]];
}

- (IBAction)changeOutOfRangePath:(id)sender
{
	// Open the panel and select the file
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op runModalForDirectory:@"~" file:nil types:[NSArray arrayWithObject:@"scpt"]];
	
	// Get the selected filenames (only one file can be selected)
	NSArray *filenames = [op filenames];
	
	// Display the path of the selected file in the window
	[outOfRangePath setStringValue:[filenames objectAtIndex:0]];
	
	// Set the path in the proximity controller
	[proximityController setOutOfRangeScriptPath:[filenames objectAtIndex:0]];
}

- (IBAction)checkConnection:(id)sender
{
	[progress startAnimation:nil];
	
	if( [proximityController isInRange] ) {
		[progress stopAnimation:nil];
		NSRunAlertPanel( @"Found", @"Device is powered on and in-range", nil, nil, nil, nil );
	} else {
		[progress stopAnimation:nil];
		NSRunAlertPanel( @"Not Found", @"Device is powered off or out-of-range",
						 nil, nil, nil, nil );
	}
}

- (IBAction)enable:(id)sender
{
	[proximityController startTimer];
}

- (IBAction)testInRangeScript:(id)sender
{
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	
	script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[inRangePath stringValue]] error:&errDict];
	ae = [script executeAndReturnError:&errDict];
}

- (IBAction)testOutOfRangeScript:(id)sender
{
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	
	script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[outOfRangePath stringValue]] error:&errDict];
	ae = [script executeAndReturnError:&errDict];
}

@end
