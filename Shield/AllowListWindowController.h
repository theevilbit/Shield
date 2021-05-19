//
//  AllowListWindowController.h
//  Shield
//
//  Created by csaby on 2021. 02. 10..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AllowListTableController : NSTabViewController <NSTableViewDataSource, NSTableViewDelegate>

//allow list in the app
@property NSArray* allowlist_app;
@end

@interface AllowListWindowController : NSWindowController <NSWindowDelegate>

//allow list in the app
@property NSArray* allowlist_app;
@property (weak) IBOutlet NSTableView *allowlist_table_injection;
@property (weak) IBOutlet NSTableView *allowlist_table_link;
@property AllowListTableController* allow_inj_table_ctl;
@property AllowListTableController* allow_link_table_ctl;
@end




NS_ASSUME_NONNULL_END
