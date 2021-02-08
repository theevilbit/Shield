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

/* GLOBALS */
extern os_log_t log_handle;

extern AllowList* allowlist;

extern Preferences* preferences;

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

@interface AppDelegate ()<OSSystemExtensionRequestDelegate>

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

    // must be run from /Applications
    if(YES != [NSBundle.mainBundle.bundlePath isEqualToString:[@"/Applications" stringByAppendingPathComponent:APP_NAME]])
    {
        //dbg msg
        os_log_debug(log_handle, "Shield was started from %{public}@, not from within /Applications", NSBundle.mainBundle.bundlePath);
        
        //foreground
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        
        //show alert
        [self create_alert:[NSString stringWithFormat:@"Shield must run from:\n  %@", [@"/Applications" stringByAppendingPathComponent:APP_NAME]]];
        
        //exit
        [NSApplication.sharedApplication terminate:self];
    }
    
    self.prefs = [NSMutableDictionary new];
    self.prefs[@"prefElectron"] = @YES;
    self.prefs[@"prefEnvVars"] = @YES;
    self.prefs[@"prefTFP"] = @YES;
    self.prefs[@"prefDylib"] = @YES;
    self.prefs[@"skipApple"] = @YES;
    self.prefs[@"isBlocking"] = @YES;

    self.isRunning = NO;
    
    //create status bar
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

    //the image to use for the icon, the system will auto-inverrt it, as Logo is a template
    NSImage *icon = [NSImage imageNamed:@"Logo"];
    self.statusItem.button.image = icon;
    self.statusItem.menu = [self buildMenu];
    
    //check if helper app is running
    
    //lookup under running apps
    NSArray<NSRunningApplication *> *runningShieldHelper = [NSRunningApplication runningApplicationsWithBundleIdentifier:HELPER_BUNDLE_ID];
    //running app not found
    if (runningShieldHelper == nil || [runningShieldHelper count] == 0) {
        self.loginItemSwitch.state = NSControlStateValueOff;
    }
    //running app found
    else {
        self.loginItemSwitch.state = NSControlStateValueOn;
    }
    
    //disable menus until extsnion is installed
    [self disable_menu_actions];
    
    //auto-load extension
    [self install_system_extension];
    


}

//create alert
- (void) create_alert: (NSString* )message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}

//create xpc
- (void) init_xpc {
    self.xpc_extension_client = [XPCExtensionClient new];
    [self getStatus];
}

//enable actions in the menu, this will be invoked if the sext is loaded
- (void) enable_menu_actions {
    [self.statusItem.menu itemWithTag:toggle].action = @selector(onoffActionMenu:);
    [self.statusItem.menu itemWithTag:prefs].action = @selector(showPrefWindow:);
    [self.statusItem.menu itemWithTag:uninstall].action = @selector(uninstall_system_extension);
    //disable install button
    [self.statusItem.menu itemWithTag:install].action = nil;
}

//disable actions in the menu, this will be invoked if the sext is loaded
- (void) disable_menu_actions {
    [self.statusItem.menu itemWithTag:toggle].action = nil;
    [self.statusItem.menu itemWithTag:prefs].action = nil;
    [self.statusItem.menu itemWithTag:uninstall].action = nil;
    //disable install button
    [self.statusItem.menu itemWithTag:install].action = @selector(install_system_extension);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [self.xpc_extension_client stop];
}

-(void)notify:(NSString *)notification blocked:(BOOL)blockStatus{
    NSUserNotification *n = [[NSUserNotification alloc] init];
    n.title = @"Shield Alert!";
    n.informativeText = notification;
    n.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:n];
}


- (NSMenu*)buildMenu {
    //create status bar menu
    NSMenu *menu = [[NSMenu alloc] init];
    if (menu == nil) {
        os_log_error(log_handle,"error: can't create menu, terminating");
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
    [menu addItem:menuToggle];
    
    NSMenuItem* menuPrefs = [NSMenuItem new];
    menuPrefs.tag = prefs;
    menuPrefs.title = @"Preferences";
    [menu addItem:menuPrefs];

    [menu addItem:[NSMenuItem separatorItem]]; // A thin grey line

    NSMenuItem* menuInstall = [NSMenuItem new];
    menuInstall.tag = install;
    menuInstall.title = @"Install System Extension";
    menuInstall.action = @selector(install_system_extension);
    [menu addItem:menuInstall];

    NSMenuItem* menuUninstall = [NSMenuItem new];
    menuUninstall.tag = uninstall;
    menuUninstall.title = @"Uninstall System Extension";
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
    if(self.isRunning == YES) {
        BOOL stopped = [self.xpc_extension_client stop];
        if(stopped) {
            os_log_info(log_handle, "Shield: SystemExtension stopped");
            self.isRunning = NO;
        }
        else {
            os_log_error(log_handle, "Shield: SystemExtension couldn't be stopped");
        }
    }
    [self getStatus];
}


- (IBAction)stopSystemExtensionAction:(id)sender {
    [self stopSystemExtension];
}

- (void)startSystemExtension {
    if(self.isRunning == NO) {

        es_new_client_result_t started = [self.xpc_extension_client start];
        //successfully started
        if(started == ES_NEW_CLIENT_RESULT_SUCCESS) {
            os_log_info(log_handle, "Shield: SystemExtension started");
            self.isRunning = YES;
        }
        
        //requires FDA right
        else if(started == ES_NEW_CLIENT_RESULT_ERR_NOT_PERMITTED) {
            os_log_error(log_handle, "Shield: SystemExtension couldn't be started because it lacks full disk access");
            //show installation helper
            self.installer_window = [[InstallerWindowController alloc] initWithWindowNibName:@"InstallerWindowController"];
            self.installer_window.message = @"Please grant Full Disk Access for the system extension in\nSystem Preferences -> Security & Privacy -> Privacy";
            self.installer_window.image_name = @"sext_fda";
            [self.installer_window showWindow:self];
            [NSApp activateIgnoringOtherApps:YES];
        }
        
        //other unspecified reason
        else {
            [self create_alert:[NSString stringWithFormat:@"Shield: SystemExtension couldn't be started, es_new_client_result_t: %d", started]];
            os_log_error(log_handle, "Shield: SystemExtension couldn't be started, es_new_client_result_t: %d", started);
        }
    }
    [self getStatus];
}


- (IBAction)startSystemExtensionAction:(id)sender {
    [self startSystemExtension];
}

//install extension
- (void) install_system_extension {
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    OSSystemExtensionRequest *req;
    req = [OSSystemExtensionRequest activationRequestForExtension:@"com.csaba.fitzl.shield.Extension" queue:q];
    if (req) {
        req.delegate = self;
        [[OSSystemExtensionManager sharedManager] submitRequest:req];
    }
}

- (void) uninstall_system_extension {
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    OSSystemExtensionRequest *req;
    req = [OSSystemExtensionRequest deactivationRequestForExtension:@"com.csaba.fitzl.shield.Extension" queue:q];
    if (req) {
        req.delegate = self;
        [[OSSystemExtensionManager sharedManager] submitRequest:req];
    }
}


- (void)exit:(id)sender {
    [self.xpc_extension_client stop];
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
    NSDictionary* reply = [self.xpc_extension_client getStatus];
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
}

- (void) updatePrefs {
    NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:self.prefs copyItems:YES];
    [self.xpc_extension_client update_preferences:dict];
}

- (IBAction)skipAppleAction:(id)sender {
    if(self.skipAppleSwitch.state == NSControlStateValueOn)
        self.prefs[@"skipApple"] = @YES;
    else
        self.prefs[@"skipApple"] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injEnvVarsAction:(id)sender {
    if(self.envVarSwitch.state == NSControlStateValueOn)
        self.prefs[@"prefEnvVars"] = @YES;
    else
        self.prefs[@"prefEnvVars"] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injTfpAction:(id)sender {
    if(self.tfpSwitch.state == NSControlStateValueOn)
        self.prefs[@"prefTFP"] = @YES;
    else
        self.prefs[@"prefTFP"] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injElectronAction:(id)sender {
    if(self.electronSwitch.state == NSControlStateValueOn)
        self.prefs[@"prefElectron"] = @YES;
    else
        self.prefs[@"prefElectron"] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injDylibAction:(id)sender {
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
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)HELPER_BUNDLE_ID, loginOnOff)) {
      os_log_error(log_handle, "Shield: Login Item Was Not Successful");
    }
}


#pragma mark OSSystemExtensionRequestDelegate

- (OSSystemExtensionReplacementAction)request:(OSSystemExtensionRequest *)request
                  actionForReplacingExtension:(OSSystemExtensionProperties *)old
                                withExtension:(OSSystemExtensionProperties *)new
    API_AVAILABLE(macos(10.15)) {
  os_log_info(log_handle,"SystemExtension \"%@\" request for replacement", request.identifier);
  return OSSystemExtensionReplacementActionReplace;
}

- (void)requestNeedsUserApproval:(OSSystemExtensionRequest *)request API_AVAILABLE(macos(10.15)) {
    NSString* logmsg = [NSString stringWithFormat:@"SystemExtension \"%@\" request needs user approval", request.identifier];
    os_log_error(log_handle, "%@", logmsg);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //show installation helper
        self.installer_window = [[InstallerWindowController alloc] initWithWindowNibName:@"InstallerWindowController"];
        self.installer_window.message = @"Please approve system extension in\nSystem Preferences -> Security & Privacy -> General";
        self.installer_window.image_name = @"sext_approve";
        [self.installer_window showWindow:self];
        [NSApp activateIgnoringOtherApps:YES];
    });

    self.extensionLoaded = NO;
}

- (void)request:(OSSystemExtensionRequest *)request
    didFailWithError:(NSError *)error API_AVAILABLE(macos(10.15)) {
    NSString* logmsg = [NSString stringWithFormat:@"SystemExtension \"%@\" request did fail: %@", request.identifier, error];
    os_log_error(log_handle, "%@", logmsg);
    self.extensionLoaded = NO;

}

- (void)request:(OSSystemExtensionRequest *)request
    didFinishWithResult:(OSSystemExtensionRequestResult)result API_AVAILABLE(macos(10.15)) {
    os_log_info(log_handle, "SystemExtension \"%@\" request did finish: %ld", request.identifier, (long)result);
    if(result == OSSystemExtensionRequestCompleted) {
        self.extensionLoaded = YES;
        
        //now that the extesion is loaded we can init xpc
        [self init_xpc];
        
        //enable menus
        [self enable_menu_actions];
        
    }
    if(result == OSSystemExtensionRequestWillCompleteAfterReboot) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self create_alert:@"The action requires a reboot"];
            self.extensionLoaded = NO;
        });
        
    }
}
@end
