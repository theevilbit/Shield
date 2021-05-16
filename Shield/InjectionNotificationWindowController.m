//
//  NotificationWindow.m
//  Shield
//
//  Created by csaby on 2021. 02. 07..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import "InjectionNotificationWindowController.h"
#import "AppDelegate.h"
#import "XPCExtensionClient.h"

extern os_log_t log_handle;

extern XPCExtensionClient* xpc_extension_client;


@interface InjectionNotificationWindowController ()
@property (weak) IBOutlet NSTextField *label_attacker_process;
@property (weak) IBOutlet NSTextField *label_attack_type;
@property (weak) IBOutlet NSTextField *label_victim_process;
@property (weak) IBOutlet NSTextField *label_arguments;
@property (weak) IBOutlet NSTextField *label_env;
@property (weak) IBOutlet NSTextField *label_dylib_path;
@property (weak) IBOutlet NSTextField *label_blocked;

@property (weak) IBOutlet NSButton *button_ok;
@property (weak) IBOutlet NSButton *button_allow;

@end

@implementation InjectionNotificationWindowController

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
        [self.label_arguments setStringValue:self.notification[NOTIFICATION_ARGUMENTS]];
        [self.label_env setStringValue:self.notification[NOTIFICATION_ENV]];
        [self.label_dylib_path setStringValue:self.notification[NOTIFICATION_DYLIB_PATH]];
        [self.label_attacker_process setStringValue:self.notification[NOTIFICATION_ATTACKER_PATH]];
        [self.label_victim_process setStringValue:self.notification[NOTIFICATION_VICTIM_PATH]];
        [self.label_attack_type setStringValue:self.notification[NOTIFICATION_TYPE]];
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
    [xpc_extension_client add_item_to_allowlist:self.notification];
    [xpc_extension_client clear_cache];
    [self.window close];
}


- (IBAction)button_ok_action:(id)sender {
    os_log_debug(log_handle, "button_ok clicked '%s'", __PRETTY_FUNCTION__);
    [self.window close];
    
}

@end
