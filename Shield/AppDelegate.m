//
//  AppDelegate.m
//  menuBar
//
//  Created by csaby on 2020. 06. 07..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//
//app icon: Icons made by <a href="http://www.freepik.com/" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>

#import "AppDelegate.h"
#import <SystemExtensions/SystemExtensions.h>
#import <ServiceManagement/ServiceManagement.h>

enum menuItems
{
    status = 100,
    mode,
    toggle,
    prefs,
    block,
    install,
    uninstall,
    autorun,
    end
};

@interface AppDelegate ()<OSSystemExtensionRequestDelegate, AppCommunication>

//switch buttons
@property (weak) IBOutlet NSSwitch *electronSwitch;
@property (weak) IBOutlet NSSwitch *tfpSwitch;
@property (weak) IBOutlet NSSwitch *envVarSwitch;
@property (weak) IBOutlet NSSwitch *dylibHijackSwitch;

@property (weak) IBOutlet NSSwitch *skipAppleSwitch;
@property (weak) IBOutlet NSSwitch *isBlockedSwitch;
@property (weak) IBOutlet NSSwitch *onoffSwitch;
@property (weak) IBOutlet NSWindow *prefWindow;
@property (weak) IBOutlet NSSwitch *loginItemSwitch;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.prefs = [NSMutableDictionary new];
    self.prefs[@"prefElectron"] = @YES;
    self.prefs[@"prefEnvVars"] = @YES;
    self.prefs[@"prefTFP"] = @YES;
    self.prefs[@"prefDylib"] = @YES;
    self.prefs[@"skipApple"] = @YES;
    self.prefs[@"isBlocking"] = @YES;


    self.isRunning = NO;
    self.isRegistered = NO;
    self.machServiceName = @"33YRLYRBYV.com.csaba.fitzl.shield.Extension.xpc";
    //create status bar
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    //the image to use for the icon, the system will auto-inverrt it, as Logo is a template
    NSImage *icon = [NSImage imageNamed:@"Logo"];
    self.statusItem.button.image = icon;
    self.statusItem.menu = [self buildMenu];
    [self registerProvider];
    [self getStatus];

    //init logging, with non-root user
    setLoggingUser(1);
    if(YES != initLogging(logFilePath(0))) {
        //err msg
        logMsg(LOG_ERR, @"failed to init logging");
        [self exit:NULL];
            
    }

    //check if helper app is running
    self.helperBundleID = @"com.csaba.fitzl.shield.ShieldHelper";

    //lookup under running apps
    NSArray<NSRunningApplication *> *runningShieldHelper = [NSRunningApplication runningApplicationsWithBundleIdentifier:self.helperBundleID];
    //running app not found
    if (runningShieldHelper == nil || [runningShieldHelper count] == 0) {
        self.loginItemSwitch.state = NSControlStateValueOff;
    }
    //running app found
    else {
        self.loginItemSwitch.state = NSControlStateValueOn;
    }
    
}

//setup XPC connection
- (void)connect {
    logMsg(LOG_NOTICE|LOG_TO_FILE, [NSString stringWithFormat:@"Connecting to Mach service: %@", self.machServiceName]);
    NSString*  service_name = self.machServiceName;

    self.connection = [[NSXPCConnection alloc] initWithMachServiceName:service_name options:0x1000];

    self.interface = [NSXPCInterface interfaceWithProtocol:@protocol(ProviderCommunication)];

    [self.connection setRemoteObjectInterface:self.interface];

    [self.connection resume];

    self.connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppCommunication)];
    self.connection.exportedObject = self;
}

- (void)registerProvider {

    if(self.isRegistered == NO)
    {
       [self connect];
    
        self.systemExtensionProvider = [self.connection remoteObjectProxyWithErrorHandler:^(NSError* error) {
             logMsg(LOG_ERR|LOG_TO_FILE, @"[-] Shield: Something went wrong with the remote object");
             logMsg(LOG_ERR|LOG_TO_FILE, [NSString stringWithFormat:@"[-] Shield: error --> %@", error]);
            self.isRegistered = NO;
         }];
        [self.systemExtensionProvider registerWithReply:^(BOOL b){
            logMsg(LOG_NOTICE|LOG_TO_FILE, [NSString stringWithFormat:@"Shield: SystemExtension registration: %hdd", b]);
            self.isRegistered = YES;
        }];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self stopSystemExtension];
    deinitLogging();
}

-(void)notify:(NSString *)notification blocked:(BOOL)blockStatus{
    NSUserNotification *n = [[NSUserNotification alloc] init];
    n.title = @"Shield Alert!";
    n.informativeText = notification;
    n.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:n];
}

/*
-(void)alertUser:(NSString *)alertString {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:alertString];
    [alert addButtonWithTitle:@"I'm not happy, but OK"];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:self.prefWindow completionHandler:nil];
}
 */

- (NSMenu*)buildMenu {
    //create status bar menu
    NSMenu *menu = [[NSMenu alloc] init];
    if (menu == nil) {
        logMsg(LOG_ERR|LOG_TO_FILE, @"[-] Shield error: can't create menu, terminating");
        [NSApp terminate:self];
    }
    NSMenuItem* menuStatus = [NSMenuItem new];
    menuStatus.tag = status;
    menuStatus.title = @"Status: Stopped";
    [menu addItem:menuStatus];

    NSMenuItem* menuMode = [NSMenuItem new];
    menuMode.tag = mode;
    menuMode.title = @"Mode: Blocking";
    [menu addItem:menuMode];

    [menu addItem:[NSMenuItem separatorItem]]; // A thin grey line
    
    NSMenuItem* menuToggle = [NSMenuItem new];
    menuToggle.tag = toggle;
    menuToggle.title = @"Start";
    menuToggle.action = @selector(onoffActionMenu:);
    [menu addItem:menuToggle];
    
    NSMenuItem* menuPrefs = [NSMenuItem new];
    menuPrefs.tag = prefs;
    menuPrefs.title = @"Preferences";
    menuPrefs.action = @selector(showPrefWindow:);
    [menu addItem:menuPrefs];

    [menu addItem:[NSMenuItem separatorItem]]; // A thin grey line

    NSMenuItem* menuInstall = [NSMenuItem new];
    menuInstall.tag = install;
    menuInstall.title = @"Install System Extension";
    menuInstall.action = @selector(installSystemExtension:);
    [menu addItem:menuInstall];

    NSMenuItem* menuUninstall = [NSMenuItem new];
    menuUninstall.tag = uninstall;
    menuUninstall.title = @"Uninstall System Extension";
    menuUninstall.action = @selector(uninstallSystemExtension:);
    [menu addItem:menuUninstall];

    [menu addItem:[NSMenuItem separatorItem]]; // A thin grey line

    [menu addItemWithTitle:@"Quit Shield" action:@selector(exit:) keyEquivalent:@""];
    return menu;
}

- (IBAction)showPrefWindow:(id)sender {
    [self getStatus];
    self.prefWindow.isVisible = YES;
    [NSApp activateIgnoringOtherApps:YES];

}

- (void)stopSystemExtension {
    [self registerProvider];
    if(self.isRunning == YES)
        [self.systemExtensionProvider stopWithReply:^(BOOL b){
            logMsg(LOG_NOTICE|LOG_TO_FILE, [NSString stringWithFormat:@"[i] Shield: SystemExtension stopped: %hdd", b]);
            [self getStatus];
        }];
}


- (IBAction)stopSystemExtensionAction:(id)sender {
    [self stopSystemExtension];
}

- (void)startSystemExtension {
    [self registerProvider];
    if(self.isRunning == NO)
        [self.systemExtensionProvider startWithReply:^(BOOL b){
            logMsg(LOG_NOTICE|LOG_TO_FILE, [NSString stringWithFormat:@"Shield: SystemExtension started: %hdd", b]);
            [self getStatus];
        }];
}


- (IBAction)startSystemExtensionAction:(id)sender {
    [self startSystemExtension];
}


- (IBAction) installSystemExtension:(id)sender {
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    OSSystemExtensionRequest *req;
    req = [OSSystemExtensionRequest activationRequestForExtension:@"com.csaba.fitzl.shield.Extension" queue:q];
    if (req) {
        req.delegate = self;
        [[OSSystemExtensionManager sharedManager] submitRequest:req];
    }
}

- (IBAction) uninstallSystemExtension:(id)sender {
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    OSSystemExtensionRequest *req;
    req = [OSSystemExtensionRequest deactivationRequestForExtension:@"com.csaba.fitzl.shield.Extension" queue:q];
    if (req) {
        req.delegate = self;
        [[OSSystemExtensionManager sharedManager] submitRequest:req];
    }
}


- (void)exit:(id)sender {
    [self stopSystemExtension];
    deinitLogging();
    [NSApp terminate:self];
}

//here follows the switch button actions

- (IBAction)onoffAction:(id)sender {
    if(self.onoffSwitch.state == NSControlStateValueOn) {
        [self startSystemExtension];
    }
    else {
        [self stopSystemExtension];
    }
}

- (IBAction)onoffActionMenu:(id)sender {
    if(self.isRunning == NO) {
        [self startSystemExtension];
    }
    else {
        [self stopSystemExtension];
    }
}


- (IBAction)blockAction:(id)sender {
    if (self.isBlockedSwitch.state == NSControlStateValueOn) {
        self.prefs[@"isBlocking"] = @YES;
        [self updatePrefs];
    }
    else {
        self.prefs[@"isBlocking"] = @NO;
        [self updatePrefs];
    }
    [self getStatus];
}

//refresh GUI based on SE's state
- (void) getStatus {
    [self registerProvider];
    [self.systemExtensionProvider getStatus:^(NSDictionary* reply) {
        if(reply != nil) {
            self.prefs[@"isRunning"] = reply[@"isRunning"];
            self.prefs[@"prefElectron"] = reply[@"prefElectron"];
            self.prefs[@"prefEnvVars"] = reply[@"prefEnvVars"];
            self.prefs[@"prefTFP"] = reply[@"prefTFP"];
            self.prefs[@"prefDylib"] = reply[@"prefDylib"];
            self.prefs[@"skipApple"] = reply[@"skipApple"];
            self.prefs[@"isBlocking"] = reply[@"isBlocking"];
            self.isRunning = [[reply objectForKey:@"isRunning"] boolValue];
            if ([[self.prefs objectForKey:@"prefElectron"] boolValue] == YES)
                self.electronSwitch.state = NSControlStateValueOn;
            else
                self.electronSwitch.state = NSControlStateValueOff;

            if ([[self.prefs objectForKey:@"prefDylib"] boolValue] == YES)
                self.dylibHijackSwitch.state = NSControlStateValueOn;
            else
                self.dylibHijackSwitch.state = NSControlStateValueOff;

            if ([[self.prefs objectForKey:@"prefEnvVars"] boolValue] == YES)
                self.envVarSwitch.state = NSControlStateValueOn;
            else
                self.envVarSwitch.state = NSControlStateValueOff;

            if ([[self.prefs objectForKey:@"prefTFP"] boolValue] == YES)
                self.tfpSwitch.state = NSControlStateValueOn;
            else
                self.tfpSwitch.state = NSControlStateValueOff;

            if (self.isRunning == NO) {
                [self.statusItem.menu itemWithTag:status].title = @"Stopped";
                [self.statusItem.menu itemWithTag:toggle].title = @"Start";
                self.onoffSwitch.state = NSControlStateValueOff;
            }
            else {
                [self.statusItem.menu itemWithTag:status].title = @"Running";
                [self.statusItem.menu itemWithTag:toggle].title = @"Stop";
                self.onoffSwitch.state = NSControlStateValueOn;
            }

            if ([[self.prefs objectForKey:@"skipApple"] boolValue] == YES)
                self.skipAppleSwitch.state = NSControlStateValueOn;
            else
                self.skipAppleSwitch.state = NSControlStateValueOff;

            if ([[self.prefs objectForKey:@"isBlocking"] boolValue] == YES) {
                [self.statusItem.menu itemWithTag:mode].title = @"Mode: Blocking";
                //[self.statusItem.menu itemWithTag:block].title = @"Alert";
                self.isBlockedSwitch.state = NSControlStateValueOn;
            }
            else {
                self.isBlockedSwitch.state = NSControlStateValueOff;
                [self.statusItem.menu itemWithTag:mode].title = @"Mode: Alerting";
                //[self.statusItem.menu itemWithTag:block].title = @"Block";
            }
        }
    }];
}

- (void) updatePrefs {
    NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:self.prefs copyItems:YES];
    [self.systemExtensionProvider updatePrefs:dict];
}

- (IBAction)skipAppleAction:(id)sender {
    [self registerProvider];
    if(self.skipAppleSwitch.state == NSControlStateValueOn)
        self.prefs[@"skipApple"] = @YES;
    else
        self.prefs[@"skipApple"] = @NO;
    [self updatePrefs];
    [self getStatus];
    
}

- (IBAction)injEnvVarsAction:(id)sender {
    [self registerProvider];
    if(self.envVarSwitch.state == NSControlStateValueOn)
        self.prefs[@"prefEnvVars"] = @YES;
    else
        self.prefs[@"prefEnvVars"] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injTfpAction:(id)sender {
    [self registerProvider];
    if(self.tfpSwitch.state == NSControlStateValueOn)
        self.prefs[@"prefTFP"] = @YES;
    else
        self.prefs[@"prefTFP"] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injElectronAction:(id)sender {
    [self registerProvider];
    if(self.electronSwitch.state == NSControlStateValueOn)
        self.prefs[@"prefElectron"] = @YES;
    else
        self.prefs[@"prefElectron"] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injDylibAction:(id)sender {
    [self registerProvider];
    if(self.dylibHijackSwitch.state == NSControlStateValueOn)
        self.prefs[@"prefDylib"] = @YES;
    else
        self.prefs[@"prefDylib"] = @NO;
    [self updatePrefs];
    [self getStatus];
}

//install / uninstall login item
- (IBAction)loginItemAction:(id)sender {
    BOOL loginOnOff = NO;
    if(self.loginItemSwitch.state == NSControlStateValueOn) {
        loginOnOff = YES;
    }
    else {
        loginOnOff = NO;
    }
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)self.helperBundleID, loginOnOff)) {
      logMsg(LOG_ERR, @"Shield: Login Item Was Not Successful");
    }
}


#pragma mark OSSystemExtensionRequestDelegate

- (OSSystemExtensionReplacementAction)request:(OSSystemExtensionRequest *)request
                  actionForReplacingExtension:(OSSystemExtensionProperties *)old
                                withExtension:(OSSystemExtensionProperties *)new
    API_AVAILABLE(macos(10.15)) {
  logMsg(LOG_NOTICE|LOG_TO_FILE, [NSString stringWithFormat:@"SystemExtension \"%@\" request for replacement", request.identifier]);
  return OSSystemExtensionReplacementActionReplace;
}

- (void)requestNeedsUserApproval:(OSSystemExtensionRequest *)request API_AVAILABLE(macos(10.15)) {
    NSString* logmsg = [NSString stringWithFormat:@"SystemExtension \"%@\" request needs user approval", request.identifier];
    logMsg(LOG_ERR|LOG_TO_FILE, logmsg);
    self.extensionLoaded = NO;
}

- (void)request:(OSSystemExtensionRequest *)request
    didFailWithError:(NSError *)error API_AVAILABLE(macos(10.15)) {
    NSString* logmsg = [NSString stringWithFormat:@"SystemExtension \"%@\" request did fail: %@", request.identifier, error];
    logMsg(LOG_ERR|LOG_TO_FILE, logmsg);
    self.extensionLoaded = NO;
}

- (void)request:(OSSystemExtensionRequest *)request
    didFinishWithResult:(OSSystemExtensionRequestResult)result API_AVAILABLE(macos(10.15)) {
  logMsg(LOG_NOTICE|LOG_TO_FILE, [NSString stringWithFormat:@"SystemExtension \"%@\" request did finish: %ld", request.identifier, (long)result]);
    if(result == OSSystemExtensionRequestCompleted) {
        self.extensionLoaded = YES;
        [self registerProvider];
    }
    else {
        self.extensionLoaded = NO;
    }
}
@end
