//
//  AppDelegate.m
//  menuBar
//
//  Created by csaby on 2020. 06. 07..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//
//app icon: Icons made by <a href="http://www.freepik.com/" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>

#import "AppDelegate.h"


/* GLOBALS */
extern os_log_t log_handle;

extern Preferences* preferences;

extern XPCExtensionClient* xpc_extension_client;

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
    end,
    allowlist
};

@interface AppDelegate ()<OSSystemExtensionRequestDelegate>

//switch buttons
@property (weak) IBOutlet NSSwitch *switch_electron_debug;
@property (weak) IBOutlet NSSwitch *switch_taskforpid;
@property (weak) IBOutlet NSSwitch *switch_env_vars;
@property (weak) IBOutlet NSSwitch *switch_dylib_hijack;

@property (weak) IBOutlet NSSwitch *switch_skip_apple;
@property (weak) IBOutlet NSSwitch *switch_isblocked;
@property (weak) IBOutlet NSSwitch *switch_onoff;
@property (weak) IBOutlet NSWindow *window_preferences;
@property (weak) IBOutlet NSSwitch *switch_loginitem;
@property (weak) IBOutlet NSSwitch *switch_learning_mode;
@property (weak) IBOutlet NSSwitch *switch_selfprotection;

@property (weak) IBOutlet NSSwitch *switch_hardlink;
@property (weak) IBOutlet NSSwitch *switch_symbolic;

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
    self.prefs[PREF_ELECTRON] = @YES;
    self.prefs[PREF_ENVVARS] = @YES;
    self.prefs[PREF_TFP] = @YES;
    self.prefs[PREF_DYLIB] = @YES;
    self.prefs[PREF_SKIPAPPLE] = @YES;
    self.prefs[PREF_ISBLOCKING] = @YES;
    self.prefs[PREF_ISLEARNING] = @NO;
    self.prefs[PREF_FILELINK_HARD] = @YES;
    self.prefs[PREF_FILELINK_SYMBOLIC] = @YES;
    self.prefs[PREF_SELFPROTECTION] = @NO;

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
        self.switch_loginitem.state = NSControlStateValueOff;
    }
    //running app found
    else {
        self.switch_loginitem.state = NSControlStateValueOn;
    }
    
    //disable menus until extsnion is installed
    [self disable_menu_actions];
    
    //auto-load extension
    [self install_system_extension];
    
    //create allowlist window
    self.allowlist_window = [[AllowListWindowController alloc] initWithWindowNibName:@"AllowListWindow"];
    self.allowlist_window.allowlist_app = [NSArray new];

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
    xpc_extension_client = [XPCExtensionClient new];
    [self getStatus];
}

//enable actions in the menu, this will be invoked if the sext is loaded
- (void) enable_menu_actions {
    [self.statusItem.menu itemWithTag:toggle].action = @selector(onoffActionMenu:);
    [self.statusItem.menu itemWithTag:prefs].action = @selector(showPrefWindow:);
    [self.statusItem.menu itemWithTag:uninstall].action = @selector(uninstall_system_extension);
    [self.statusItem.menu itemWithTag:allowlist].action = @selector(showAllowWindow:);
    //disable install button
    [self.statusItem.menu itemWithTag:install].action = nil;
}

//disable actions in the menu, this will be invoked if the sext is unloaded
- (void) disable_menu_actions {
    [self.statusItem.menu itemWithTag:toggle].action = nil;
    [self.statusItem.menu itemWithTag:prefs].action = nil;
    [self.statusItem.menu itemWithTag:uninstall].action = nil;
    [self.statusItem.menu itemWithTag:allowlist].action = nil;
    //disable install button
    [self.statusItem.menu itemWithTag:install].action = @selector(install_system_extension);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [xpc_extension_client stop];
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

    NSMenuItem* menuAllow = [NSMenuItem new];
    menuAllow.tag = allowlist;
    menuAllow.title = @"Allowed Items";
    [menu addItem:menuAllow];

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

//show window for editing allow list
- (IBAction)showAllowWindow:(id)sender {
    self.allowlist_window.allowlist_app = [xpc_extension_client get_allowlist];
    [self.allowlist_window.allowlist_table_injection reloadData];

    self.allowlist_window.window.isVisible = YES;
    [NSApp activateIgnoringOtherApps:YES];

}

//display pref window
- (IBAction)showPrefWindow:(id)sender {
    [self getStatus];
    self.window_preferences.isVisible = YES;
    [NSApp activateIgnoringOtherApps:YES];

}

- (void)stopSystemExtension {
    if(self.isRunning == YES) {
        BOOL stopped = [xpc_extension_client stop];
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

        es_new_client_result_t started = [xpc_extension_client start];
        //successfully started
        if(started == ES_NEW_CLIENT_RESULT_SUCCESS) {
            os_log_info(log_handle, "Shield: SystemExtension started");
            self.isRunning = YES;
        }
        
        //requires FDA right
        else if(started == ES_NEW_CLIENT_RESULT_ERR_NOT_PERMITTED) {
            os_log_error(log_handle, "Shield: SystemExtension couldn't be started because it lacks full disk access");
            
            //show installation helper
            //only create a window if we don't have one already, otherwise we will just update it
            if (self.installer_window == nil) {
                self.installer_window = [[InstallerWindowController alloc] initWithWindowNibName:@"InstallerWindowController"];
            }
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
    [xpc_extension_client stop];
    [NSApp terminate:self];
}

//here follows the switch button actions

- (IBAction)onoffAction:(id)sender {
    if(self.switch_onoff.state == NSControlStateValueOn) {
        [self startSystemExtension];
    }
    else {
        [self stopSystemExtension];
    }
}

- (IBAction)learningAction:(id)sender {
    if(self.switch_learning_mode.state == NSControlStateValueOn) {
        self.prefs[PREF_ISLEARNING] = @YES;
        [self updatePrefs];
    }
    else {
        self.prefs[PREF_ISLEARNING] = @NO;
        [self updatePrefs];
    }
    [self getStatus];
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
    if (self.switch_isblocked.state == NSControlStateValueOn) {
        self.prefs[PREF_ISBLOCKING] = @YES;
        [self updatePrefs];
    }
    else {
        self.prefs[PREF_ISBLOCKING] = @NO;
        [self updatePrefs];
    }
    [self getStatus];
}

//refresh GUI based on SE's state
- (void) getStatus {
    self.allowlist_window.allowlist_app = [xpc_extension_client get_allowlist];
    NSDictionary* reply = [xpc_extension_client getStatus];
    if(reply != nil) {
        self.prefs[PREF_ISRUNNING] = reply[PREF_ISRUNNING];
        self.prefs[PREF_ISLEARNING] = reply[PREF_ISLEARNING];
        self.prefs[PREF_ELECTRON] = reply[PREF_ELECTRON];
        self.prefs[PREF_ENVVARS] = reply[PREF_ENVVARS];
        self.prefs[PREF_TFP] = reply[PREF_TFP];
        self.prefs[PREF_DYLIB] = reply[PREF_DYLIB];
        self.prefs[PREF_SKIPAPPLE] = reply[PREF_SKIPAPPLE];
        self.prefs[PREF_ISBLOCKING] = reply[PREF_ISBLOCKING];
        self.prefs[PREF_FILELINK_HARD] = reply[PREF_FILELINK_HARD];
        self.prefs[PREF_FILELINK_SYMBOLIC] = reply[PREF_FILELINK_SYMBOLIC];
        self.isRunning = [[reply objectForKey:PREF_ISRUNNING] boolValue];

        if ([[self.prefs objectForKey:PREF_SELFPROTECTION] boolValue] == YES)
            self.switch_selfprotection.state = NSControlStateValueOn;
        else
            self.switch_selfprotection.state = NSControlStateValueOff;

        if ([[self.prefs objectForKey:PREF_FILELINK_HARD] boolValue] == YES)
            self.switch_hardlink.state = NSControlStateValueOn;
        else
            self.switch_hardlink.state = NSControlStateValueOff;

        if ([[self.prefs objectForKey:PREF_FILELINK_SYMBOLIC] boolValue] == YES)
            self.switch_symbolic.state = NSControlStateValueOn;
        else
            self.switch_symbolic.state = NSControlStateValueOff;

        if ([[self.prefs objectForKey:PREF_ELECTRON] boolValue] == YES)
            self.switch_electron_debug.state = NSControlStateValueOn;
        else
            self.switch_electron_debug.state = NSControlStateValueOff;

        if ([[self.prefs objectForKey:PREF_DYLIB] boolValue] == YES)
            self.switch_dylib_hijack.state = NSControlStateValueOn;
        else
            self.switch_dylib_hijack.state = NSControlStateValueOff;

        if ([[self.prefs objectForKey:PREF_ENVVARS] boolValue] == YES)
            self.switch_env_vars.state = NSControlStateValueOn;
        else
            self.switch_env_vars.state = NSControlStateValueOff;

        if ([[self.prefs objectForKey:PREF_TFP] boolValue] == YES)
            self.switch_taskforpid.state = NSControlStateValueOn;
        else
            self.switch_taskforpid.state = NSControlStateValueOff;

        if (self.isRunning == NO) {
            [self.statusItem.menu itemWithTag:status].title = @"Stopped";
            [self.statusItem.menu itemWithTag:toggle].title = @"Start";
            self.switch_onoff.state = NSControlStateValueOff;
        }
        else {
            [self.statusItem.menu itemWithTag:status].title = @"Running";
            [self.statusItem.menu itemWithTag:toggle].title = @"Stop";
            self.switch_onoff.state = NSControlStateValueOn;
        }

        if ([[self.prefs objectForKey:PREF_SKIPAPPLE] boolValue] == YES)
            self.switch_skip_apple.state = NSControlStateValueOn;
        else
            self.switch_skip_apple.state = NSControlStateValueOff;

        if ([[self.prefs objectForKey:PREF_ISLEARNING] boolValue] == YES)
            self.switch_learning_mode.state = NSControlStateValueOn;
        else
            self.switch_learning_mode.state = NSControlStateValueOff;

        if ([[self.prefs objectForKey:PREF_ISBLOCKING] boolValue] == YES) {
            [self.statusItem.menu itemWithTag:mode].title = @"Mode: Blocking";
            //[self.statusItem.menu itemWithTag:block].title = @"Alert";
            self.switch_isblocked.state = NSControlStateValueOn;
            self.switch_learning_mode.enabled = false;
        }
        else {
            self.switch_isblocked.state = NSControlStateValueOff;
            [self.statusItem.menu itemWithTag:mode].title = @"Mode: Alerting";
            //[self.statusItem.menu itemWithTag:block].title = @"Block";
            self.switch_learning_mode.enabled = true;
        }
    }
}

- (void) updatePrefs {
    NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:self.prefs copyItems:YES];
    [xpc_extension_client update_preferences:dict];
}

- (IBAction)skipAppleAction:(id)sender {
    if(self.switch_skip_apple.state == NSControlStateValueOn)
        self.prefs[PREF_SKIPAPPLE] = @YES;
    else
        self.prefs[PREF_SKIPAPPLE] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injEnvVarsAction:(id)sender {
    if(self.switch_env_vars.state == NSControlStateValueOn)
        self.prefs[PREF_ENVVARS] = @YES;
    else
        self.prefs[PREF_ENVVARS] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injTfpAction:(id)sender {
    if(self.switch_taskforpid.state == NSControlStateValueOn)
        self.prefs[PREF_TFP] = @YES;
    else
        self.prefs[PREF_TFP] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injElectronAction:(id)sender {
    if(self.switch_electron_debug.state == NSControlStateValueOn)
        self.prefs[PREF_ELECTRON] = @YES;
    else
        self.prefs[PREF_ELECTRON] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)injDylibAction:(id)sender {
    if(self.switch_dylib_hijack.state == NSControlStateValueOn)
        self.prefs[PREF_DYLIB] = @YES;
    else
        self.prefs[PREF_DYLIB] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)hardlink_action:(id)sender {
    if(self.switch_hardlink.state == NSControlStateValueOn)
        self.prefs[PREF_FILELINK_HARD] = @YES;
    else
        self.prefs[PREF_FILELINK_HARD] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)symbolic_action:(id)sender {
    if(self.switch_symbolic.state == NSControlStateValueOn)
        self.prefs[PREF_FILELINK_SYMBOLIC] = @YES;
    else
        self.prefs[PREF_FILELINK_SYMBOLIC] = @NO;
    [self updatePrefs];
    [self getStatus];
}

- (IBAction)selfprotection_action:(id)sender {
    if(self.switch_selfprotection.state == NSControlStateValueOn)
        self.prefs[PREF_SELFPROTECTION] = @YES;
    else
        self.prefs[PREF_SELFPROTECTION] = @NO;
    [self updatePrefs];
    [self getStatus];
}


//install / uninstall login item
- (IBAction)loginItemAction:(id)sender {
    BOOL loginOnOff = NO;
    if(self.switch_loginitem.state == NSControlStateValueOn) {
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
        
        //close window if SEXT is installed
        if(self.installer_window) {
            [self.installer_window close];
        }
        
    }
    if(result == OSSystemExtensionRequestWillCompleteAfterReboot) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self create_alert:@"The action requires a reboot"];
            self.extensionLoaded = NO;
        });
        
    }
}
@end
