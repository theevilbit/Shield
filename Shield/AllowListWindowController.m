//
//  AllowListWindowController.m
//  Shield
//
//  Created by csaby on 2021. 02. 10..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import "AllowListWindowController.h"
#import "XPCExtensionClient.h"
#import "Constants.h"
//globals
extern XPCExtensionClient* xpc_extension_client;
extern os_log_t log_handle;


@interface AllowListWindowController ()
//@property (weak) IBOutlet NSTableView *allowlist_table;
@property (weak) IBOutlet NSTableHeaderView *allowlist_table_header;
@property (weak) IBOutlet NSTableColumn *column_1;
@property (weak) IBOutlet NSTableColumn *column_2;
@property (weak) IBOutlet NSTableColumn *column_3;
@property (weak) IBOutlet NSTableColumn *column_4;
@property (weak) IBOutlet NSTableColumn *column_5;
@property (weak) IBOutlet NSTableColumn *column_6;

@end

@implementation AllowListWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.column_1.identifier = NOTIFICATION_TYPE;
    self.column_2.identifier = NOTIFICATION_ATTACKER_PATH;
    self.column_3.identifier = NOTIFICATION_VICTIM_PATH;
    self.column_4.identifier = NOTIFICATION_DYLIB_PATH;
    self.column_5.identifier = NOTIFICATION_ARGUMENTS;
    self.column_6.identifier = NOTIFICATION_ENV;
    //self.allowlist_table.dataSource = self;
    [self.allowlist_table setDelegate:self];
    self.allowlist_app = [xpc_extension_client get_allowlist];
    [self.allowlist_table reloadData];
    [self.window setDelegate:self];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)clear_all_button_action:(id)sender {
    BOOL success = [xpc_extension_client clear_allowlist];
    if(success) {
        self.allowlist_app = [xpc_extension_client get_allowlist];
        [self.allowlist_table reloadData];
    }
}

- (IBAction)clear_selected_button_action:(id)sender {
    NSInteger row = [self.allowlist_table selectedRow];
    BOOL success = [xpc_extension_client remove_item_from_allowlist:[self.allowlist_app objectAtIndex:row]];
    if(success) {
        self.allowlist_app = [xpc_extension_client get_allowlist];
        [self.allowlist_table reloadData];
    }

}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    self.allowlist_app = [xpc_extension_client get_allowlist];
    [self.allowlist_table reloadData];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    self.allowlist_app = [xpc_extension_client get_allowlist];
    [self.allowlist_table reloadData];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)table {
    os_log_debug(log_handle, "numberOfRowsInTableView was called, count: %lu", [self.allowlist_app count]);
    return [self.allowlist_app count];
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)rowIndex {
    os_log_debug(log_handle, "tableView was called, row %lu", rowIndex);
    NSDictionary *rowData = [self.allowlist_app objectAtIndex:rowIndex];
    return [rowData valueForKey:[column identifier]];
}



@end

