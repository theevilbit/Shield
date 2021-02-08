//
//  NotificationWindow.h
//  Shield
//
//  Created by csaby on 2021. 02. 07..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NotificationWindowController : NSWindowController <NSWindowDelegate>

@property NSDictionary* notification;

@end

NS_ASSUME_NONNULL_END
