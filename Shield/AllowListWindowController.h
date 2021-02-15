//
//  AllowListWindowController.h
//  Shield
//
//  Created by csaby on 2021. 02. 10..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AllowListWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>

//allow list in the app
@property NSArray* allowlist_app;
@property (weak) IBOutlet NSTableView *allowlist_table;

@end

NS_ASSUME_NONNULL_END
