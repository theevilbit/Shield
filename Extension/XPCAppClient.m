//original: https://raw.githubusercontent.com/objective-see/LuLu/master/LuLu/Extension/XPCUserClient.m

//
//  XPCClient.m
//  ShieldProject
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import "XPCAppClient.h"

/* GLOBALS */

//xpc connection
extern XPCListener* xpc_listener;

//log handle
extern os_log_t log_handle;

@implementation XPCAppClient

//deliver alert to user
-(BOOL)send:(NSDictionary*)notification blocked:(BOOL)blockStatus;
{
    //flag
    __block BOOL xpcError = NO;
    
    //sanity check
    // no client connection?
    if(nil == xpc_listener.client)
    {
        //dbg msg
        os_log_debug(log_handle, "no client is connected, alert will not be delivered");
        
        //set error
        xpcError = YES;
        
        //bail
        //goto bail;
    }
    else
    {
        //dbg msg
        os_log_debug(log_handle, "invoking user XPC method: 'notify:blocked:reply:'");

        //send to user
        [[xpc_listener.client remoteObjectProxyWithErrorHandler:^(NSError * proxyError)
        {
            //err msg
            os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %{public}@)", __PRETTY_FUNCTION__, proxyError);
            
            //set error
            xpcError = YES;
            
        }] notify:notification blocked:blockStatus reply:^(NSDictionary* userReply)
        {
            //dbg msg
            os_log_debug(log_handle, "reply received");
            
            //respond
            //to act based on the reply
        }];
    }

bail:

    return !xpcError;
}


@end
