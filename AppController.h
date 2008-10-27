#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#import <IOBluetoothUI/IOBluetoothUI.h>

int thisVersionMajor = 1;
int thisVersionMinor = 3;

typedef enum _BPStatus {
	InRange,
	OutOfRange
} BPStatus;

@interface AppController : NSObject
{
	IOBluetoothDevice *device;
	NSTimer *timer;
	BPStatus priorStatus;
	NSStatusItem *statusItem;
	int failures;
	
    IBOutlet id deviceName;
    IBOutlet id enabledButton;
    IBOutlet id errorScanInterval;
    IBOutlet id errorScans;
    IBOutlet id executeOnStartup;
    IBOutlet id inRangeScriptPath;
    IBOutlet id outOfRangeScriptPath;
    IBOutlet id prefsWindow;
    IBOutlet id progressIndicator;
    IBOutlet id timerInterval;
    IBOutlet id updatesEnabled;
}

// AppController methods
- (void)createMenuBar;
- (void)loadUserDefaults;
- (void)saveUserDefaults;
- (NSString *)newVersionAvailable;
- (void)checkForUpdatesOnStartup;

// ProximityMonitor methods
- (void)startMonitoring;
- (void)stopMonitoring;
- (BOOL)isInRange;
- (void)handleTimer:(NSTimer *)theTimer;
- (void)startErrorTimer;
- (void)runOutOfRangeScript;
- (void)runInRangeScript;

// Interface methods
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
