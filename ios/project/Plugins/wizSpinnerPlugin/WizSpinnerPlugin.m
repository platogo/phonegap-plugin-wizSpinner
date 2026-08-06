/* WizSpinnerPlugin - IOS side of the bridge to wizSpinner JavaScript for PhoneGap
 *
 * @author Ally Ogilvie
 * @copyright Wizcorp Inc. [ Incorporated Wizards ] 2011
 * @file wizSpinnerPlugin.m for PhoneGap
 *
 */ 

#import "WizSpinnerPlugin.h"
#import "WizAssetsPluginExtendCDVViewController.h"
#import "WizDebugLog.h"

@interface WizSpinnerPlugin () <UIWebViewDelegate>
+ (void)load;
+ (void)didFinishLaunching:(NSNotification *)notification;
+ (void)sceneDidBecomeActive:(NSNotification *)notification;
+ (void)willTerminate:(NSNotification *)notification;
+ (void)initializeSpinner;
@end

static NSDictionary *defaults = nil;
static BOOL spinnerInitialized = NO;

@implementation WizSpinnerPlugin

#pragma - Class Methods

+ (void)load
{
    // Register for didFinishLaunching notifications in class load method so that
    // this class can observe launch events.  Do this here because this needs to be
    // registered before the AppDelegate's application:didFinishLaunchingWithOptions:
    // method finishes executing.  A class's load method gets invoked before
    // application:didFinishLaunchingWithOptions is invoked (even if the plugin is
    // not loaded/invoked in the JavaScript).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification
                                               object:nil];

    // cordova-ios 8+: scene-based lifecycle. The window isn't available at
    // didFinishLaunching time, so we also observe UISceneDidActivateNotification
    // which fires once the scene's window is ready.
    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sceneDidBecomeActive:)
                                                     name:UISceneDidActivateNotification
                                                   object:nil];
    }
    
    // Register for willTerminate notifications here so that we can observer terminate
    // events and unregister observing launch notifications.  This isn't strictly
    // required (and may not be called according to the docs).
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

+ (void)didFinishLaunching:(NSNotification *)notification
{
    // This code will be called immediately after application:didFinishLaunchingWithOptions:.
    // In pre-scene (cordova-ios 7) apps, the window and viewController are available now.
    // In scene-based (cordova-ios 8+) apps, the window is not yet available — 
    // initialization will happen in sceneDidBecomeActive: instead.
    [self initializeSpinner];
}

+ (void)sceneDidBecomeActive:(NSNotification *)notification
{
    // cordova-ios 8+: the scene's window is now ready
    if (!spinnerInitialized) {
        [self initializeSpinner];
    }
}

+ (void)initializeSpinner
{
    if (spinnerInitialized) {
        return;
    }

    // Find the key window — supports both scene-based and legacy apps
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *w in windowScene.windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
                if (window) break;
            }
        }
    }
    if (!window) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        window = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
    }

    if (!window) {
        // Window still not available (will retry via sceneDidBecomeActive)
        return;
    }

    // Get the CDVViewController — either from rootViewController or legacy appDelegate.viewController
    CDVViewController *viewController = nil;
    UIViewController *rootVC = window.rootViewController;
    if ([rootVC isKindOfClass:[CDVViewController class]]) {
        viewController = (CDVViewController *)rootVC;
    } else {
        // Legacy fallback: check appDelegate.viewController
        id <UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
        SEL viewControllerSelector = @selector(viewController);
        if ([appDelegate respondsToSelector:viewControllerSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id vc = [appDelegate performSelector:viewControllerSelector];
#pragma clang diagnostic pop
            if ([vc isKindOfClass:[CDVViewController class]]) {
                viewController = (CDVViewController *)vc;
            }
        }
    }

    if (!viewController) {
        return;
    }

    SEL getCommandInstanceSelector = @selector(getCommandInstance:);
    if (![viewController respondsToSelector:getCommandInstanceSelector]) {
        return;
    }

    // Get options from the wizSpinner.plist (in the application bundle)
    NSString *path = [[NSBundle mainBundle] pathForResource:@"wizSpinner" ofType:@"plist"];
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithContentsOfFile:path];

    if (options == nil) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Missing wizSpinner.plist -- required when using the wizSpinner plugin.  Please add it to your application bundle."];
    }

    // Read specified defaults.
    defaults = [options objectForKey:@"defaults"];
    if (defaults == nil) {
        defaults = [[NSDictionary alloc] initWithObjectsAndKeys:
                    @"middle",              @"position",
                    @"0.7",                 @"opacity",
                    @"white",               @"spinnerColor",
                    @"white",               @"textColor",
                    @"Initializing App...", @"label",
                    nil];
    }
    [defaults retain];

    // Create/get the singleton.
    WizSpinnerPlugin *plugin = [viewController getCommandInstance:@"WizSpinnerPlugin"];

    // Create the spinner with defaults
    CDVInvokedUrlCommand *cmd = [[CDVInvokedUrlCommand alloc] initWithArguments:[NSArray arrayWithObjects:defaults, nil] callbackId:@"" className:@"wizSpinnerPlugin" methodName:@"create"];
    [plugin create:cmd];
    [cmd release];

    // Auto-show the spinner (if requested)
    BOOL autoShowSpinnerOnStart = [[options objectForKey:@"autoShowSpinnerOnStart"] boolValue];
    if (autoShowSpinnerOnStart) {
        CDVInvokedUrlCommand *cmd = [[CDVInvokedUrlCommand alloc] initWithArguments:[NSArray arrayWithObjects:defaults, nil] callbackId:@"" className:@"wizSpinnerPlugin" methodName:@"show"];
        [plugin show:cmd];
        [cmd release];
    }

    spinnerInitialized = YES;
}

+ (void)willTerminate:(NSNotification *)notification
{
    // Stop the class from observing all notification center notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Release the defaults.
    [defaults release];
}

#pragma - Instance Methods

// house keeping
- (void)dealloc
{
    // Stop the instance from observing all notification center notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    
    self = (WizSpinnerPlugin*)[super initWithWebView:theWebView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification" 
                                               object:nil];

    return self;
}


- (void) orientationChanged:(NSNotification *)notification {  
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if ( (orientation == 0) || (orientation == 5) ) {
        // unsupported orientations
        return;
    }
    
    
    // check orientation supported
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    
    NSArray *orientations;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // check ipad orientations
        orientations = [infoDict objectForKey:@"UISupportedInterfaceOrientations~ipad"];
    } else {
        // check iphone orientations
        orientations = [infoDict objectForKey:@"UISupportedInterfaceOrientations"];
    }
    
    if (orientations == NULL) {
        // NSLog(@"no orientations for this device");
        return;
    }
    
    
    // NSLog(@"IS ORIENTATION %d", orientation);
    //NSLog(@"THE orientations %@", orientations);
    
    NSString *orient;
    
    for (int i = 0; i < [orientations count]; i++) {
        
        orient = [orientations objectAtIndex:i];
        
        if ( ([orient isEqualToString:@"UIInterfaceOrientationPortrait"] ) && (orientation == 1) ) {
            [(CDVViewController *)self.viewController rotateCustomLoader:orientation];
        }
        if ( ([orient isEqualToString:@"UIInterfaceOrientationPortraitUpsideDown"] ) && (orientation == 2) ) {
            [(CDVViewController *)self.viewController rotateCustomLoader:orientation];
        }
        if ( ([orient isEqualToString:@"UIInterfaceOrientationLandscapeLeft"] ) && (orientation == 3) ) {
            [(CDVViewController *)self.viewController rotateCustomLoader:orientation];
        }
        if ( ([orient isEqualToString:@"UIInterfaceOrientationLandscapeRight"] ) && (orientation == 4) ) {
            [(CDVViewController *)self.viewController rotateCustomLoader:orientation];
        }
    }

    
}



- (void)create:(CDVInvokedUrlCommand*)command
{
    // CREATE IS ALWAYS CALLED FROM AUTOMATICALLY AT APP START
    // This allows the spinner to be ready for action immediately.
    // use show() and hide() - with options or a default
    
    NSDictionary *options = [command.arguments objectAtIndex:0];
    
    // NSLog(@"WARNING  - - - - - nativeSpinner.create() is depreciated. Create is called automatically by default.");
    
    [(CDVViewController *)self.viewController createCustomLoader:options];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallbackAsBool:YES];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)show:(CDVInvokedUrlCommand*)command
{
    WizLog(@"******************************************show shown var = %i", shown);
    if (shown) {
        return;
    }
    int timeoutInt = 20;
    
    NSDictionary *options;
    if ([command.arguments count] > 0) {
        options = [command.arguments objectAtIndex:0];
        // use custom options
        
        
        int timeoutOpt            = [[options objectForKey:@"timeout"] intValue];
        if (timeoutOpt) {
            // default show it
            timeoutInt = timeoutOpt;
        }
    } else {
        options = defaults;
    }
    
    WizLog(@"****************************************** timeout is %i seconds", timeoutInt);

    // default loader
    [(CDVViewController *)self.viewController showCustomLoader:options];
    shown = TRUE;
    
    // start timer
    timeout = [NSTimer scheduledTimerWithTimeInterval:timeoutInt
                                               target:self
                                             selector:@selector(timedHide:)
                                             userInfo:nil
                                              repeats:NO];

}

- (void)timedHide:(id)sender {
    CDVInvokedUrlCommand *cmd = [[CDVInvokedUrlCommand alloc] initWithArguments:[NSArray arrayWithObjects: nil] callbackId:@"" className:@"wizSpinnerPlugin" methodName:@"hide"];
    [self hide:cmd];
    [cmd release];
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    WizLog(@"******************************************hide shown var = %i", shown);

    // kill timer
    if (timeout) {
        [timeout invalidate];
        timeout = nil;
    }
    
    if (shown == FALSE) {
        return;
    }
    
    [(CDVViewController *)self.viewController hideCustomLoader:NULL];
    shown = FALSE;

}


- (void)rotate:(CDVInvokedUrlCommand*)command
{
    NSNumber *orientation = [command.arguments objectAtIndex:0];
    if (orientation) {
        [(CDVViewController *)self.viewController rotateCustomLoader:[orientation intValue]];
    }
}

@end
