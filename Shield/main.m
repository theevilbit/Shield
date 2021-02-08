//
//  main.m
//  menuBar
//
//  Created by csaby on 2020. 06. 07..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Preferences.h"
#import "AllowList.h"
#import "XPCExtensionClient.h"
#import "XPCApp.h"
#import "Constants.h"

os_log_t log_handle = nil;

AllowList* allowlist = nil;

XPCExtensionClient* xpc_extension_client = nil;

Preferences* preferences = nil;

NSMutableDictionary* notification_collection = nil;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        log_handle = os_log_create(BUNDLE_ID, "app");
        
        notification_collection = [NSMutableDictionary new];
                
    }
    return NSApplicationMain(argc, argv);
}
