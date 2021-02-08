//core: https://github.com/objective-see/LuLu/blob/master/LuLu/App/XPCUser.m
//
//  XPCApp.m
//  Shield
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

@import Foundation;
@import OSLog;

#import "XPCApp.h"
#import "NotificationWindowController.h"

@implementation XPCApp

/* GLOBALS */

//log handle
extern os_log_t log_handle;

//alert (windows)
extern NSMutableDictionary* notification_collection;

//show an alert window
-(void)notify:(NSDictionary*)notification blocked:(BOOL)blockStatus reply:(void (^)(NSDictionary*))reply
{
    //get the notification id
    NSString* string_id =[notification[@"id"] stringValue];

    //dbg msg
    os_log_debug(log_handle, "extension invoked user XPC method, '%s', with %{public}@", __PRETTY_FUNCTION__, notification);
    os_log_debug(log_handle, "number of alerts so far %lu, new notification number: %@", [notification_collection count], string_id);

    //on main (ui) thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        
        //notification window
        NotificationWindowController* notification_window = nil;
        
        //alloc/init notification window
        notification_window = [[NotificationWindowController alloc] initWithWindowNibName:@"NotificationWindow"];
                
        //sync to save alert
        // ensures there is a (memory) reference to the window
        @synchronized(notification_collection)
        {
            //save
            notification_collection[string_id] = notification_window;
        }
        
        notification_window.notification = notification;
                
        //show window
        [notification_window showWindow:self];
    
        //'request' user attention
        //  bounces icon on the dock
        [NSApp requestUserAttention:NSInformationalRequest];
        
        //make alert window key
        [notification_window.window makeKeyAndOrderFront:self];
        
        //bring to front
        [NSApp activateIgnoringOtherApps:YES];

        
    });
    
    return;
}

@end
