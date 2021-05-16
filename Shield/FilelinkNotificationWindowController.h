//
//  FilelinkNotificationWindowController.h
//  Shield
//
//  Created by csaby on 2021. 05. 15..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface FilelinkNotificationWindowController : NSWindowController

@property NSDictionary* notification;
@property BOOL blocked;

@end

NS_ASSUME_NONNULL_END
