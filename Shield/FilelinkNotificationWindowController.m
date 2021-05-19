//
//  FilelinkNotificationWindowController.m
//  Shield
//
//  Created by csaby on 2021. 05. 15..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import "FilelinkNotificationWindowController.h"
#import "XPCExtensionClient.h"
#import "AppDelegate.h"

//GLOBALS

extern os_log_t log_handle;

extern XPCExtensionClient* xpc_extension_client;

@interface FilelinkNotificationWindowController ()
@property (weak) IBOutlet NSTextField *label_process_path;
@property (weak) IBOutlet NSTextField *label_process_uid;
@property (weak) IBOutlet NSTextField *label_file_source;
@property (weak) IBOutlet NSTextField *label_file_destination;
@property (weak) IBOutlet NSTextField *label_file_uid;
@property (weak) IBOutlet NSTextField *label_attack_type;
@property (weak) IBOutlet NSTextField *label_blocked;

@property (weak) IBOutlet NSButton *button_ok;
@property (weak) IBOutlet NSButton *button_allow;
@property (weak) IBOutlet NSButton *button_ignore_process;

@end

@implementation FilelinkNotificationWindowController

// also, transparency
-(void)awakeFromNib
{
    //center
    [self.window center];
    
    self.window.title = @"Shield Notification";

    return;
}

- (void)windowDidLoad {
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [super windowDidLoad];
    if(self.notification != nil) {
        [self.label_process_path setStringValue:self.notification[NOTIFICATION_LINK_PROCESS_PATH]];
        [self.label_process_uid setStringValue:self.notification[NOTIFICATION_LINK_PROCESS_UID]];
        [self.label_file_source setStringValue:self.notification[NOTIFICATION_LINK_SOURCE_PATH]];
        [self.label_file_destination setStringValue:self.notification[NOTIFICATION_LINK_DESTINATION_PATH]];
        [self.label_file_uid setStringValue:self.notification[NOTIFICATION_LINK_FILE_UID]];
        [self.label_attack_type setStringValue:self.notification[NOTIFICATION_LINK_TYPE]];
    }
    if(self.blocked) {
        [self.label_blocked setStringValue:@"BLOCKED"];
    }
    else {
        [self.label_blocked setStringValue:@"DETECTED"];
    }
    
}


- (IBAction)button_allow_action:(id)sender {
    os_log_debug(log_handle, "button_allow clicked '%s'", __PRETTY_FUNCTION__);

    [xpc_extension_client add_item_to_allowlist:self.notification generic:NO];
    [xpc_extension_client clear_cache];

    [self.window close];
}


- (IBAction)button_ok_action:(id)sender {
    os_log_debug(log_handle, "button_ok clicked '%s'", __PRETTY_FUNCTION__);
    [self.window close];
    
}

- (IBAction)button_ignore_process_action:(id)sender {
    os_log_debug(log_handle, "button_ignore_process clicked '%s'", __PRETTY_FUNCTION__);
    [xpc_extension_client add_item_to_allowlist:self.notification generic:YES];
    [xpc_extension_client clear_cache];
    [self.window close];
}
@end
