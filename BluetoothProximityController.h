//
//  BluetoothProximityController.h
//  Proximity
//
//  Created by Denver Timothy on 1/8/07.
//  Copyright 2007 Denver Timothy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

typedef enum _BPStatus {
	InRange,
	OutOfRange
} BPStatus;

@interface BluetoothProximityController : NSObject
{
	IOBluetoothDevice *device;
	NSString *inRangeScriptPath;
	NSString *outOfRangeScriptPath;
	NSTimer *timer;
	BPStatus lastKnownStatus;
	int intervalSeconds;
}

-(IOBluetoothDevice *)device;
-(void)setDevice:(IOBluetoothDevice *)aDevice;
-(NSString *)inRangeScriptPath;
-(void)setInRangeScriptPath:(NSString *)path;
-(NSString *)outOfRangeScriptPath;
-(void)setOutOfRangeScriptPath:(NSString *)path;
-(void)startTimer;
-(void)stopTimer;
-(BOOL)isInRange;
-(BPStatus)lastKnownStatus;
-(void)setLastKnownStatus:(BPStatus)status;
-(int)intervalSeconds;
-(void)setIntervalSeconds:(int)seconds;
-(void)cameInRange;
-(void)wentOutOfRange;
- (void)handleTimer:(NSTimer *)theTimer;

@end