/* AppController */

#import <Cocoa/Cocoa.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

int thisVersionMajor = 1;
int thisVersionMinor = 2;

typedef enum _BPStatus {
	InRange,
	OutOfRange
} BPStatus;

@interface AppController : NSObject
{
    IBOutlet NSTextField *deviceName;
    IBOutlet NSButton *enabledButton;
    IBOutlet NSTextField *inRangeScriptPath;
    IBOutlet NSTextField *outOfRangeScriptPath;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSTextField *timerInterval;
	IBOutlet NSButton *updatesEnabled;
	IBOutlet NSButton *executeOnStartup;
	IBOutlet NSTextField *errorScans;
	IBOutlet NSTextField *errorScanInterval;
	IBOutlet NSWindow *prefsWindow;
	
	IOBluetoothDevice *device;
	NSTimer *timer;
	BPStatus priorStatus;
	NSStatusItem *statusItem;
	int failures;
}

- (BOOL)isInRange;
- (void)loadUserDefaults;
- (void)saveUserDefaults;
- (BOOL)isInRange;
- (void)startMonitoring;
- (void)startErrorTimer;
- (void)handleTimer:(NSTimer *)theTimer;
- (void)runOutOfRangeScript;
- (void)runInRangeScript;
- (void)createMenuBar;
- (NSString *)newVersionAvailable;
- (void)checkForUpdatesOnStartup;

- (IBAction)changeDevice:(id)sender;
- (IBAction)changeEnabledState:(id)sender;
- (IBAction)changeInRangeScript:(id)sender;
- (IBAction)changeOutOfRangeScript:(id)sender;
- (IBAction)checkConnection:(id)sender;
- (IBAction)checkForUpdates:(id)sender;
- (IBAction)clearInRangeScript:(id)sender;
- (IBAction)clearOutOfRangeScript:(id)sender;
- (IBAction)makeDonation:(id)sender;
- (IBAction)testInRangeScript:(id)sender;
- (IBAction)testOutOfRangeScript:(id)sender;

@end
