//
//  NotificationWindow.m
//  Shield
//
//  Created by csaby on 2021. 02. 07..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import "NotificationWindowController.h"
#import "AppDelegate.h"

extern os_log_t log_handle;


@interface NotificationWindowController ()
@property (weak) IBOutlet NSTextField *label_attacker_process;
@property (weak) IBOutlet NSTextField *label_attack_type;
@property (weak) IBOutlet NSTextField *label_victim_process;
@property (weak) IBOutlet NSTextField *label_arguments;
@property (weak) IBOutlet NSTextField *label_env;
@property (weak) IBOutlet NSTextField *label_dylib_path;
@property (weak) IBOutlet NSButton *button_ok;
@property (weak) IBOutlet NSButton *button_allow;

@end

@implementation NotificationWindowController

// also, transparency
-(void)awakeFromNib
{
    //center
    [self.window center];
    
    self.window.title = @"Shield Notification";

    return;
}

- (void)windowDidLoad {
    
    //self.
    [super windowDidLoad];
    if(self.notification != nil) {
        [self.label_arguments setStringValue:self.notification[@"arguments"]];
        [self.label_env setStringValue:self.notification[@"env"]];
        [self.label_dylib_path setStringValue:self.notification[@"dylib_path"]];
        [self.label_attacker_process setStringValue:self.notification[@"attacker_path"]];
        [self.label_victim_process setStringValue:self.notification[@"victim_path"]];
        [self.label_attack_type setStringValue:self.notification[@"type"]];
        //[self.label_env setToolTip:self.notification[@"env"]];
    }
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
}


- (IBAction)button_allow_action:(id)sender {
    os_log_debug(log_handle, "button_allow clicked '%s'", __PRETTY_FUNCTION__);
    [self.window close];
}


- (IBAction)button_ok_action:(id)sender {
    os_log_debug(log_handle, "button_ok clicked '%s'", __PRETTY_FUNCTION__);
    [self.window close];
    
}

@end
