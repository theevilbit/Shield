//
//  AppDelegate.h
//  menuBar
//
//  Created by csaby on 2020. 06. 07..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "../Common/XPCProtocol.h"
#import "../Common/logging.h"
#import "../Common/Constants.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readwrite, retain) IBOutlet NSStatusItem *statusItem;
@property BOOL isRunning;
@property BOOL isRegistered;
@property BOOL extensionLoaded;
@property NSMutableDictionary* prefs;
@property NSString* machServiceName;
@property id<ProviderCommunication> systemExtensionProvider;
@property NSXPCInterface * interface;
@property NSXPCConnection * connection;
@property NSString* helperBundleID;

- (NSMenu *)buildMenu;

@end

