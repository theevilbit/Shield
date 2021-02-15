//
//  AppDelegate.h
//  menuBar
//
//  Created by csaby on 2020. 06. 07..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

@import OSLog;
@import Cocoa;

#import <SystemExtensions/SystemExtensions.h>
#import <ServiceManagement/ServiceManagement.h>

#import "Constants.h"
#import "AllowList.h"
#import "Preferences.h"
#import "XPCApp.h"
#import "XPCExtensionClient.h"
#import "InstallerWindowController.h"
#import "AllowListWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

/* properties */

//drop down menu
@property (readwrite, retain) IBOutlet NSStatusItem *statusItem;

//is endpoint security client running
@property BOOL isRunning;

//track extension loading
@property BOOL extensionLoaded;

//preferences to store locally
@property NSMutableDictionary* prefs;

//xpc connection
//@property XPCExtensionClient* xpc_extension_client;

//installer window
@property InstallerWindowController* installer_window;

//allow list window
@property AllowListWindowController* allowlist_window;



/* methods */

//build menu
- (NSMenu *)buildMenu;

//initialize xpc communication with the extension
- (void) init_xpc;
@end

