#import "AppController.h"

@implementation AppController

- (void)awakeFromNib
{	
	failures = 0;
	priorStatus = OutOfRange;
	
	[self createMenuBar];
	[self loadUserDefaults];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self saveUserDefaults];
}

#pragma mark -

- (void)loadUserDefaults
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Device
	deviceAsData = [defaults objectForKey:@"device"];
	if( [deviceAsData length] > 0 )
	{
		device = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
		[device retain];
		[deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
			[device getName], [device getAddressString]]];
				
		if( [self isInRange] ) {
			[statusItem setTitle:@"O"];
			priorStatus = InRange;
		}
	}
	
	// Timer interval
	if( [[defaults stringForKey:@"timerInterval"] length] > 0 )
		[timerInterval setStringValue:[defaults stringForKey:@"timerInterval"]];
	
	// Out of range script
	if( [[defaults stringForKey:@"outOfRangeScriptPath"] length] > 0 )
		[outOfRangeScriptPath setStringValue:[defaults stringForKey:@"outOfRangeScriptPath"]];
	
	// In range script
	if( [[defaults stringForKey:@"inRangeScriptPath"] length] > 0 )
		[inRangeScriptPath setStringValue:[defaults stringForKey:@"inRangeScriptPath"]];
	
	// Error scans
	if( [[defaults stringForKey:@"errorScans"] length] > 0 )
		[errorScans setStringValue:[defaults stringForKey:@"errorScans"]];
	
	// Error scan interval
	if( [[defaults stringForKey:@"errorScanInterval"] length] > 0 )
		[errorScanInterval setStringValue:[defaults stringForKey:@"errorScanInterval"]];
	
	// Monitoring enabled
	BOOL monitoring = [defaults boolForKey:@"enabled"];
	if( monitoring ) {
		[enabledButton setState:NSOnState];
		[self startMonitoring];
	}
	
	// Check for updates on startup
	BOOL updating = [defaults boolForKey:@"updating"];
	if( updating ) {
		[updatesEnabled setState:NSOnState];
		[self checkForUpdatesOnStartup];
	}
	
	BOOL startup = [defaults boolForKey:@"executeOnStartup"];
	if( startup )
	{
		[executeOnStartup setState:NSOnState];
		
		if( monitoring )
		{
			if( [self isInRange] ) {
				priorStatus = InRange;
				[self runInRangeScript];
			} else {
				[self runOutOfRangeScript];
			}
		}
	}
}

- (void)saveUserDefaults
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Monitoring enabled
	BOOL monitoring = ( [enabledButton state] == NSOnState ? TRUE : FALSE );
	[defaults setBool:monitoring forKey:@"enabled"];
	
	// Update checking
	BOOL updating = ( [updatesEnabled state] == NSOnState ? TRUE : FALSE );
	[defaults setBool:updating forKey:@"updating"];
	
	// Execute scripts on startup
	BOOL startup = ( [executeOnStartup state] == NSOnState ? TRUE : FALSE );
	[defaults setBool:startup forKey:@"executeOnStartup"];
	
	// Timer interval
	[defaults setObject:[timerInterval stringValue] forKey:@"timerInterval"];
	
	// In range script
	[defaults setObject:[inRangeScriptPath stringValue] forKey:@"inRangeScriptPath"];
	
	// Out of range script
	[defaults setObject:[outOfRangeScriptPath stringValue] forKey:@"outOfRangeScriptPath"];
	
	// Number of error corrective scans
	[defaults setObject:[errorScans stringValue] forKey:@"errorScans"];
	
	// Error corrective scan interval
	[defaults setObject:[errorScanInterval stringValue] forKey:@"errorScanInterval"];
	
	// Device
	if( device ) {
		deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:device];
		[defaults setObject:deviceAsData forKey:@"device"];
	}
	
	[defaults synchronize];
	
	[self startMonitoring];
}

- (BOOL)isInRange
{
	if( device && [device openConnection] == kIOReturnSuccess ) {
		[device closeConnection];
		return true;
	}
	
	return false;
}

- (void)startMonitoring
{
	timer = [NSTimer scheduledTimerWithTimeInterval:[timerInterval intValue]
											 target:self
										   selector:@selector(handleTimer:)
										   userInfo:nil
											repeats:NO];
	[timer retain];
}

- (void)startErrorTimer
{
	timer = [NSTimer scheduledTimerWithTimeInterval:[errorScanInterval intValue]
											target:self
										  selector:@selector(handleTimer:)
										  userInfo:nil
										   repeats:NO];
	[timer retain];
}

- (void)handleTimer:(NSTimer *)theTimer
{
	if( [self isInRange] )
	{
		if( priorStatus == OutOfRange ) {
			priorStatus = InRange;
			[statusItem setTitle:@"O"];
			[self runInRangeScript];
		}
		
		failures = 0;
	}
	else
	{
		failures++;
		
		if( priorStatus == InRange )
		{
			if( failures == [errorScans intValue] )
			{
				[self startErrorTimer];
				return;				
			}
			else
			{
				priorStatus = OutOfRange;
				[statusItem setTitle:@"X"];
				[self runOutOfRangeScript];
			}
		}
	}
	
	[self startMonitoring];
}

- (void)runOutOfRangeScript
{
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	
	script = [[NSAppleScript alloc]
		initWithContentsOfURL:[NSURL fileURLWithPath:[outOfRangeScriptPath stringValue]] 
						error:&errDict];
	ae = [script executeAndReturnError:&errDict];	
}

- (void)runInRangeScript
{
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	
	script = [[NSAppleScript alloc]
		initWithContentsOfURL:[NSURL fileURLWithPath:[inRangeScriptPath stringValue]]
						error:&errDict];
	ae = [script executeAndReturnError:&errDict];	
}

- (void)createMenuBar
{
	NSMenu *myMenu;
	NSMenuItem *menuItem;
	
	myMenu = [[NSMenu alloc] init];
	
	menuItem = [myMenu addItemWithTitle:@"Preferences"
								 action:@selector(showWindow:) keyEquivalent:@""];
	
	[menuItem setTarget:self];
	
	[myMenu addItemWithTitle:@"Quit"
					  action:@selector(terminate:) keyEquivalent:@""];
	
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setTitle:@"X"];
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:myMenu];
}

- (void)showWindow:(id)sender
{
	[prefsWindow makeKeyAndOrderFront:self];
}

- (NSString *)newVersionAvailable
{
	NSURL *url = [NSURL URLWithString:@"http://reduxcomputing.com/download/Proximity.plist"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:url];
	
	if( dict != nil )
		return [dict valueForKey:@"version"];
	else
		return nil;
}

- (void)checkForUpdatesOnStartup
{
	NSString *newVersion = [self newVersionAvailable];
	
	if( newVersion )
	{
		NSArray *version = [newVersion componentsSeparatedByString:@"."];
		int currentVersionMajor = [[version objectAtIndex:0] intValue];
		int currentVersionMinor = [[version objectAtIndex:1] intValue];
		
		if( thisVersionMajor < currentVersionMajor || thisVersionMinor < currentVersionMinor )
		{
			if( NSRunAlertPanel( @"Proxmity", @"A new version of Proximity is availabe for download.",
								 @"Close", @"Download", nil, nil ) == NSAlertAlternateReturn )
			{
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://reduxcomputing.com/proximity/"]];
			}
		}
	}
}

#pragma mark -

- (IBAction)changeDevice:(id)sender
{
	IOBluetoothDeviceSelectorController *deviceSelector;
	deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	[deviceSelector runModal];
	
	NSArray *results;
	results = [deviceSelector getResults];
	
	if( !results )
		return;
	
	device = [results objectAtIndex:0];
	[device retain];
	
	[deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
		[device getName],
		[device getAddressString]]];
}

- (IBAction)changeEnabledState:(id)sender
{
	if( [enabledButton state] == NSOnState )
		[self startMonitoring];
}

- (IBAction)changeInRangeScript:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op runModalForDirectory:@"~" file:nil types:[NSArray arrayWithObject:@"scpt"]];
	
	NSArray *filenames = [op filenames];
	[inRangeScriptPath setStringValue:[filenames objectAtIndex:0]];
}

- (IBAction)changeOutOfRangeScript:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op runModalForDirectory:@"~" file:nil types:[NSArray arrayWithObject:@"scpt"]];
	
	NSArray *filenames = [op filenames];
	[outOfRangeScriptPath setStringValue:[filenames objectAtIndex:0]];
}

- (IBAction)checkConnection:(id)sender
{
	[progressIndicator startAnimation:nil];
	
	if( [self isInRange] )
	{
		[progressIndicator stopAnimation:nil];
		NSRunAlertPanel( @"Found", @"Device is powered on and in range", nil, nil, nil, nil );
	} else {
		[progressIndicator stopAnimation:nil];
		NSRunAlertPanel( @"Not Found", @"Device is powered off or out of range", nil, nil, nil, nil );
	}
}

- (IBAction)checkForUpdates:(id)sender
{
	NSString *newVersion = [self newVersionAvailable];
	
	if( newVersion )
	{
		NSArray *version = [newVersion componentsSeparatedByString:@"."];
		int currentVersionMajor = [[version objectAtIndex:0] intValue];
		int currentVersionMinor = [[version objectAtIndex:1] intValue];
		
		if( thisVersionMajor < currentVersionMajor || thisVersionMinor < currentVersionMinor )
		{
			if( NSRunAlertPanel( @"Proxmity", @"A new version of Proximity is availabe for download.",
							 @"Close", @"Download", nil, nil ) == NSAlertAlternateReturn )
			{
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://reduxcomputing.com/proximity/"]];
			}
		}
		else
		{
			NSRunAlertPanel( @"Proxmity", @"You are using the latest version of Proximity.",
							 @"Close", nil, nil, nil );
		}
	}
	else
	{
		NSRunAlertPanel( @"Proxmity", @"Unable to download version information.",
						 nil, nil, nil, nil );
	}
}

- (IBAction)clearInRangeScript:(id)sender
{
	[inRangeScriptPath setStringValue:@""];
}

- (IBAction)clearOutOfRangeScript:(id)sender
{
	[outOfRangeScriptPath setStringValue:@""];
}

- (IBAction)makeDonation:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://reduxcomputing.com/proximity/"]];
}

- (IBAction)testInRangeScript:(id)sender
{
	[self runInRangeScript];
}

- (IBAction)testOutOfRangeScript:(id)sender
{
	[self runOutOfRangeScript];
}

@end
