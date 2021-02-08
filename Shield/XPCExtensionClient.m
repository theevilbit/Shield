//
//  XPCExtensionClient.m
//  Shield
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCExtensionClient.h"
#import "XPCExtensionProtocol.h"
#import "XPCAppProtocol.h"
#import "XPCApp.h"
#import "Constants.h"

extern os_log_t log_handle;

@implementation XPCExtensionClient

//init
// create XPC connection & set remote obj interface
-(id)init
{
    //super
    self = [super init];
    if(nil != self)
    {
        //alloc/init
        self.extension = [[NSXPCConnection alloc] initWithMachServiceName:MACH_SERVICE options:0];
    
        //set remote object interface
        self.extension.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCExtensionProtocol)];
        
        //set exported object interface (protocol)
        self.extension.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCAppProtocol)];
        
        //set exported object
        // this will allow daemon to invoke user methods!
        self.extension.exportedObject = [[XPCApp alloc] init];
    
        //resume
        [self.extension resume];
    }
    
    return self;
}


//start ES client
-(es_new_client_result_t)start {
    
    __block es_new_client_result_t started = ES_NEW_CLIENT_RESULT_ERR_NOT_PERMITTED;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
     }] startWithReply:^(es_new_client_result_t rep)
     {
         //dbg msg
         os_log_debug(log_handle, "got start reply: %d", rep);
         
         //save
         started = rep;
         
     }];
    return started;
}

//stop ES client
-(BOOL)stop {
    
    __block BOOL stopped = NO;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
     }] stopWithReply:^(BOOL rep)
     {
         //dbg msg
         os_log_debug(log_handle, "got stop reply: %d", rep);
         
         //save
        stopped = rep;
         
     }];
    return stopped;
}

-(NSDictionary*) getStatus {
    
    //placeholder for status
    __block NSDictionary* extension_status = nil;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
     }] getStatus:^(NSDictionary* rep)
     {
         //dbg msg
         os_log_debug(log_handle, "got getStatus reply: %@", rep);
         
         //save
        extension_status = rep;
         
     }];
    return extension_status;
}

-(NSDictionary*) get_allowlist {
    
    //placeholder for allowlist
    __block NSDictionary* wl = nil;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
     }] get_allowlist:^(NSDictionary* rep)
     {
         //dbg msg
         os_log_debug(log_handle, "got get_allowlist reply: %@", rep);
         
         //save
        wl = rep;
         
     }];
    return wl;
}

-(BOOL) update_preferences:(NSDictionary *)prefs {
    
    //placeholder for allowlist
    __block BOOL ok = NO;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
    }] update_preferences:prefs reply:^(BOOL rep)
     {
         //dbg msg
         os_log_debug(log_handle, "got update_preferences reply: %d", rep);
         
         //save
        ok = rep;
         
     }];
    return ok;
}


-(BOOL) update_allowlist:(NSMutableDictionary *)al {
    
    //placeholder for allowlist
    __block BOOL ok = NO;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
    }] update_allowlist:al reply:^(BOOL rep)
     {
         //dbg msg
         os_log_debug(log_handle, "got update_allowlist reply: %d", rep);
         
         //save
        ok = rep;
         
     }];
    return ok;
}

@end
