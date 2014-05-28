#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>
#import "AppController.h"

@implementation AppController

#pragma mark -
#pragma mark App Delegate Methods

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self stopMonitoring];
}

- (void)awakeFromNib
{
	NSBundle *bundle = [NSBundle mainBundle];
	inRangeImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"inRange" ofType: @"png"]];
	inRangeAltImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"inRangeAlt" ofType: @"png"]];	
	outOfRangeImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"outRange" ofType: @"png"]];
	outOfRangeAltImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"outOfRange" ofType: @"png"]];	

	priorStatus = OutOfRange;
	
	[self createMenuBar];
	[self userDefaultsLoad];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self userDefaultsSave];
	[self stopMonitoring];
	[self startMonitoring];
}


-(void)displayAlertWithText:(NSString *)title informativeText:(NSString *)info
{
	NSAlert *alert = [NSAlert alertWithMessageText:title
									 defaultButton:nil
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:@"%@", info];
	[alert beginSheetModalForWindow:self.prefsWindow completionHandler:nil];
}


#pragma mark -
#pragma mark AppController Methods

- (void)createMenuBar
{
	NSMenu *myMenu;
	NSMenuItem *menuItem;
	 
	// Menu for status bar item
	myMenu = [[NSMenu alloc] init];
	
	// Prefences menu item
	menuItem = [myMenu addItemWithTitle:@"Preferences" action:@selector(showWindow:) keyEquivalent:@""];
	[menuItem setTarget:self];
	
	// Quit menu item
	[myMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
	
	// Space on status bar
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	
	// Attributes of space on status bar
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:myMenu];

	[self menuIconOutOfRange];	
}

- (void)handleTimer:(NSTimer *)theTimer
{
	if(self.isInRange) {
		if(priorStatus == OutOfRange) {
			priorStatus = InRange;
			
			[self menuIconInRange];
			[self runInRangeScript];
		}
	} else {
		if(priorStatus == InRange) {
			priorStatus = OutOfRange;
			
			[self menuIconOutOfRange];
			[self runOutOfRangeScript];
		}
	}
	
	[self startMonitoring];
}

- (BOOL)isInRange
{
	if(device && [device remoteNameRequest:nil] == kIOReturnSuccess) {
		return true;
	}
	
	return false;
}

- (void)menuIconInRange
{	
	statusItem.image = inRangeImage;
	statusItem.alternateImage = inRangeAltImage;
	//statusItem.title = @"O";
}

- (void)menuIconOutOfRange
{
	statusItem.image = outOfRangeImage;
	statusItem.alternateImage = outOfRangeAltImage;
	//statusItem.title = @"X";
}

- (void)runInRangeScript
{
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	
	script = [[NSAppleScript alloc]
			  initWithContentsOfURL:[NSURL fileURLWithPath:[self.inRangeScriptPath stringValue]]
			  error:&errDict];
	ae = [script executeAndReturnError:&errDict];		
}

- (void)runOutOfRangeScript
{
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	
	script = [[NSAppleScript alloc]
			  initWithContentsOfURL:[NSURL fileURLWithPath:[self.outOfRangeScriptPath stringValue]]
			  error:&errDict];
	ae = [script executeAndReturnError:&errDict];	
}

- (void)startMonitoring
{
	if(self.monitoringEnabled.state == NSOnState) {
		timer = [NSTimer scheduledTimerWithTimeInterval:[self.timerInterval intValue]
												 target:self
											   selector:@selector(handleTimer:)
											   userInfo:nil
												repeats:NO];
	}		
}

- (void)stopMonitoring
{
	[timer invalidate];
}

- (void)userDefaultsLoad
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Device
	deviceAsData = [defaults objectForKey:@"device"];
	if([deviceAsData length] > 0)
	{
		device = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
		[self.deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
									device.name, device.addressString]];
		
		if([self isInRange])
		{			
			priorStatus = InRange;
			[self menuIconInRange];
		}
		else
		{
			priorStatus = OutOfRange;
			[self menuIconOutOfRange];
		}
	}
	
	//Timer interval
	if([[defaults stringForKey:@"timerInterval"] length] > 0)
		[self.timerInterval setStringValue:[defaults stringForKey:@"timerInterval"]];
	
	// Out of range script path
	if([[defaults stringForKey:@"outOfRangeScriptPath"] length] > 0)
		[self.outOfRangeScriptPath setStringValue:[defaults stringForKey:@"outOfRangeScriptPath"]];
	
	// In range script path
	if([[defaults stringForKey:@"inRangeScriptPath"] length] > 0)
		[self.inRangeScriptPath setStringValue:[defaults stringForKey:@"inRangeScriptPath"]];
	
	// Monitoring enabled
	BOOL monitoring = [defaults boolForKey:@"enabled"];
	if(monitoring) {
		[self.monitoringEnabled setState:NSOnState];
		[self startMonitoring];
	}
	
	// Run scripts on startup
	BOOL startup = [defaults boolForKey:@"executeOnStartup"];
	if(startup) {
		[self.runScriptsOnStartup setState:NSOnState];
		
		if(monitoring)
		{
			if([self isInRange]) {
				[self runInRangeScript];
			} else {
				[self runOutOfRangeScript];
			}
		}
	}
	
}

- (void)userDefaultsSave
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Monitoring enabled
	BOOL monitoring = (self.monitoringEnabled.state == NSOnState);
	[defaults setBool:monitoring forKey:@"enabled"];
	
	// Update checking
	BOOL updating = ([self.checkUpdatesOnStartup state] == NSOnState);
	[defaults setBool:updating forKey:@"updating"];
	
	// Execute scripts on startup
	BOOL startup = ([self.runScriptsOnStartup state] == NSOnState);
	[defaults setBool:startup forKey:@"executeOnStartup"];
	
	// Timer interval
	[defaults setObject:[self.timerInterval stringValue] forKey:@"timerInterval"];
	
	// In range script
	[defaults setObject:[self.inRangeScriptPath stringValue] forKey:@"inRangeScriptPath"];

	// Out of range script
	[defaults setObject:[self.outOfRangeScriptPath stringValue] forKey:@"outOfRangeScriptPath"];
		
	// Device
	if(device) {
		deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:device];
		[defaults setObject:deviceAsData forKey:@"device"];
	}
	
	[defaults synchronize];
}


#pragma mark -
#pragma mark Interface Methods

- (IBAction)changeDevice:(id)sender
{
	IOBluetoothDeviceSelectorController *deviceSelector;
	deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	[deviceSelector runModal];
	
	NSArray *results;
	results = [deviceSelector getResults];
	
	if(!results)
		return;
	
	device = results[0];
	
	[self.deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
								device.name,
								device.addressString]];
}

- (IBAction)checkConnectivity:(id)sender
{
	self.progressIndicator.hidden = NO;
	[self.progressIndicator startAnimation:nil];
	
	if([self isInRange]) {
		[self displayAlertWithText:@"Found" informativeText:@"Device is powered on and in range"];
	} else {
		[self displayAlertWithText:@"Not Found" informativeText:@"Device is powered off or out of range"];
	}
	[self.progressIndicator stopAnimation:nil];
	self.progressIndicator.hidden = YES;
}

- (IBAction)enableMonitoring:(id)sender
{
	// See windowWillClose: method
}

- (IBAction)inRangeScriptChange:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	op.directoryURL = [NSURL URLWithString:@"~"];
	op.allowedFileTypes = @[@"scpt"];
	[op runModal];

	if(op.URLs.count > 0) {
		NSURL *url = op.URLs[0];
		[self.inRangeScriptPath setStringValue:url.absoluteString];
	}
}

- (IBAction)inRangeScriptClear:(id)sender
{
	[self.inRangeScriptPath setStringValue:@""];
}

- (IBAction)inRangeScriptTest:(id)sender
{
	[self runInRangeScript];
}

- (IBAction)outOfRangeScriptChange:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	op.directoryURL = [NSURL URLWithString:@"~"];
	op.allowedFileTypes = @[@"scpt"];
	[op runModal];

	NSArray *urls = [op URLs];
	if(urls.count > 0) {
		NSURL *url = urls[0];
		[self.outOfRangeScriptPath setStringValue:url.absoluteString];
	}
}

- (IBAction)outOfRangeScriptClear:(id)sender
{
	[self.outOfRangeScriptPath setStringValue:@""];
}

- (IBAction)outOfRangeScriptTest:(id)sender
{
    [self runOutOfRangeScript];
}

- (void)showWindow:(id)sender
{
	[self.prefsWindow makeKeyAndOrderFront:self];
	[self.prefsWindow center];
	
	[self stopMonitoring];
}


@end
