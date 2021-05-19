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


@implementation AllowListTableController

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

@interface AllowListWindowController ()
//@property (weak) IBOutlet NSTableView *allowlist_table;
@property (weak) IBOutlet NSTableHeaderView *allowlist_table_header_injection;
@property (weak) IBOutlet NSTableColumn *column_1;
@property (weak) IBOutlet NSTableColumn *column_2;
@property (weak) IBOutlet NSTableColumn *column_3;
@property (weak) IBOutlet NSTableColumn *column_4;
@property (weak) IBOutlet NSTableColumn *column_5;
@property (weak) IBOutlet NSTableColumn *column_6;

//table for file links
@property (weak) IBOutlet NSTableHeaderView *allowlist_table_header_link;
@property (weak) IBOutlet NSTableColumn *filelink_column_1;
@property (weak) IBOutlet NSTableColumn *filelink_column_2;
@property (weak) IBOutlet NSTableColumn *filelink_column_3;
@property (weak) IBOutlet NSTableColumn *filelink_column_4;
@property (weak) IBOutlet NSTableColumn *filelink_column_5;
@property (weak) IBOutlet NSTableColumn *filelink_column_6;

//tabs
@property (weak) IBOutlet NSTabViewItem *tab_injection;
@property (weak) IBOutlet NSTabViewItem *tab_links;


@end

@implementation AllowListWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    //injection columns
    self.column_1.identifier = NOTIFICATION_TYPE;
    self.column_2.identifier = NOTIFICATION_ATTACKER_PATH;
    self.column_3.identifier = NOTIFICATION_VICTIM_PATH;
    self.column_4.identifier = NOTIFICATION_DYLIB_PATH;
    self.column_5.identifier = NOTIFICATION_ARGUMENTS;
    self.column_6.identifier = NOTIFICATION_ENV;

    //file link columns
    self.filelink_column_1.identifier = NOTIFICATION_LINK_TYPE;
    self.filelink_column_2.identifier = NOTIFICATION_LINK_PROCESS_PATH;
    self.filelink_column_3.identifier = NOTIFICATION_LINK_PROCESS_UID;
    self.filelink_column_4.identifier = NOTIFICATION_LINK_SOURCE_PATH;
    self.filelink_column_5.identifier = NOTIFICATION_LINK_DESTINATION_PATH;
    self.filelink_column_6.identifier = NOTIFICATION_LINK_FILE_UID;

    
    self.allow_inj_table_ctl = [AllowListTableController new];
    self.allow_link_table_ctl = [AllowListTableController new];
    
    [self.allowlist_table_injection setDelegate:self.allow_inj_table_ctl];
    [self.allowlist_table_link setDelegate:self.allow_link_table_ctl];
    
    [self.allowlist_table_injection setDataSource:self.allow_inj_table_ctl];
    [self.allowlist_table_link setDataSource:self.allow_link_table_ctl];

    //refresh allow list
    [self get_split_allow_list];
    
    [self.window setDelegate:self];
}

- (void)get_split_allow_list {
    self.allowlist_app = [xpc_extension_client get_allowlist];
    NSMutableArray* allowed_inj = [NSMutableArray new];
    NSMutableArray* allowed_links = [NSMutableArray new];
    for (NSDictionary* element in self.allowlist_app) {
        if ([element[NOTIFICATION_ATTACK_TYPE] isEqualToNumber:ATTACK_INJECTION]) {
            [allowed_inj addObject:element];
        }
        else if ([element[NOTIFICATION_ATTACK_TYPE] isEqualToNumber:ATTACK_FILELINKS]) {
            [allowed_links addObject:element];
        }
    }
    self.allow_link_table_ctl.allowlist_app = allowed_links;
    self.allow_inj_table_ctl.allowlist_app = allowed_inj;
    //reload data
    [self.allowlist_table_link reloadData];
    [self.allowlist_table_injection reloadData];
}

- (IBAction)clear_all_button_action:(id)sender {
    BOOL success = [xpc_extension_client clear_allowlist];
    if(success) {
        [self get_split_allow_list];
    }
}

- (IBAction)clear_selected_button_action:(id)sender {
    
    //check which tab is active
    if([self.tab_injection tabState] == NSSelectedTab) {
        NSInteger row = [self.allowlist_table_injection selectedRow];
        BOOL success = [xpc_extension_client remove_item_from_allowlist:[self.allow_inj_table_ctl.allowlist_app objectAtIndex:row]];
        if(success) {
            [self get_split_allow_list];
        }
    }
    else if([self.tab_links tabState] == NSSelectedTab) {
        NSInteger row = [self.allowlist_table_link selectedRow];
        BOOL success = [xpc_extension_client remove_item_from_allowlist:[self.allow_link_table_ctl.allowlist_app objectAtIndex:row]];
        if(success) {
            [self get_split_allow_list];
        }
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [self get_split_allow_list];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    [self get_split_allow_list];
}

@end

