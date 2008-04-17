//
//  BluetoothProximityController.m
//  Proximity
//
//  Copyright (c) Denver Timothy
//  See License.txt for license information.
//

#import "BluetoothProximityController.h"


@implementation BluetoothProximityController

-(id)init
{
	[super init];
	
	intervalSeconds = 0;
	
	return self;
}

- (void)awakeFromNib
{
	[self loadUserDefaults];
}

- (void)loadUserDefaults
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	//
}

-(IOBluetoothDevice *)device
{
	return device;
}

-(void)setDevice:(IOBluetoothDevice *)aDevice
{
	[aDevice retain];
	[device release];
	device = aDevice;
}

-(NSString *)inRangeScriptPath
{
	return inRangeScriptPath;
}

-(void)setInRangeScriptPath:(NSString *)path
{
	[inRangeScriptPath release];
	[path retain];
	inRangeScriptPath = path;
}

-(NSString *)outOfRangeScriptPath
{
	return outOfRangeScriptPath;
}

-(void)setOutOfRangeScriptPath:(NSString *)path
{
	[outOfRangeScriptPath release];
	[path retain];
	outOfRangeScriptPath = path;
}

-(void)startTimer
{
	[self stopTimer];
	
	if( [self intervalSeconds] < 1 )
		[NSException raise:@"BPTimerInterval" format:@"The timer interval must be greater than 0 seconds"];
		
	timer = [NSTimer scheduledTimerWithTimeInterval:intervalSeconds
											 target:self
										   selector:@selector(handleTimer:)
										   userInfo:nil
											repeats:YES];
	
	[timer retain];
}

-(void)stopTimer
{
	if( timer ) [timer invalidate];
}

-(void)resetTimer
{
	[self startTimer];
}

-(BOOL)isInRange
{
	if( device && [device openConnection] == kIOReturnSuccess ) {
		[device closeConnection];
		return true;
	} else {
		return false;
	}
}

-(BPStatus)lastKnownStatus
{
	return lastKnownStatus;
}

-(void)setLastKnownStatus:(BPStatus)status
{
	lastKnownStatus = status;
}

-(int)intervalSeconds
{
	return intervalSeconds;
}

-(void)setIntervalSeconds:(int)seconds
{
	intervalSeconds = seconds;
}

-(void)checkProximity
{
	// If device is currently in-range, but was previously out-of-range...
	if( [self isInRange] )
		if( [self lastKnownStatus] == OutOfRange )
			[self cameInRange];
	
	// If device is currently out-of-range, but was previously in-range...
	else
		if( [self lastKnownStatus] == InRange )
			[self wentOutOfRange];
}

-(void)cameInRange
{
	NSLog( @"Came in range" );
	
	// Update last known status
	[self setLastKnownStatus:InRange];
	
	// Execute an AppleScript
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[self inRangeScriptPath]] error:&errDict];
	ae = [script executeAndReturnError:&errDict];
}

-(void)wentOutOfRange
{
	NSLog( @"Went out of range" );
	
	// Update last known status
	[self setLastKnownStatus:OutOfRange];
	
	// Execute an AppleScript
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[self outOfRangeScriptPath]] error:&errDict];
	ae = [script executeAndReturnError:&errDict];	
}

- (void)handleTimer:(NSTimer *)theTimer
{
	[self checkProximity];
}


@end
