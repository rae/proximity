#import <Cocoa/Cocoa.h>

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
	
	NSImage *outOfRangeImage;
	NSImage *outOfRangeAltImage;
	NSImage *inRangeImage;
	NSImage *inRangeAltImage;
}

@property(nonatomic) IBOutlet NSButton *checkUpdatesOnStartup;
@property(nonatomic) IBOutlet NSTextField *deviceName;
@property(nonatomic) IBOutlet NSTextField *inRangeScriptPath;
@property(nonatomic) IBOutlet NSButton *monitoringEnabled;
@property(nonatomic) IBOutlet NSTextField *outOfRangeScriptPath;
@property(nonatomic) IBOutlet NSWindow *prefsWindow;
@property(nonatomic) IBOutlet NSProgressIndicator *progressIndicator;
@property(nonatomic) IBOutlet NSButton *runScriptsOnStartup;
@property(nonatomic) IBOutlet NSTextField *timerInterval;

// AppController methods
- (void)createMenuBar;
- (void)userDefaultsLoad;
- (void)userDefaultsSave;
- (BOOL)isInRange;
- (void)menuIconInRange;
- (void)menuIconOutOfRange;
- (void)runInRangeScript;
- (void)runOutOfRangeScript;
- (void)startMonitoring;
- (void)stopMonitoring;


// UI methods
- (IBAction)changeDevice:(id)sender;
- (IBAction)checkConnectivity:(id)sender;
- (IBAction)enableMonitoring:(id)sender;
- (IBAction)inRangeScriptChange:(id)sender;
- (IBAction)inRangeScriptClear:(id)sender;
- (IBAction)inRangeScriptTest:(id)sender;
- (IBAction)outOfRangeScriptChange:(id)sender;
- (IBAction)outOfRangeScriptClear:(id)sender;
- (IBAction)outOfRangeScriptTest:(id)sender;
- (IBAction)showWindow:(id)sender;

@end
