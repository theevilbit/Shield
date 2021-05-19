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
        os_log_debug(log_handle, "got %s reply: %d", __PRETTY_FUNCTION__, rep);

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
        os_log_debug(log_handle, "got %s reply: %d", __PRETTY_FUNCTION__, rep);

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
        os_log_debug(log_handle, "got %s reply: %@", __PRETTY_FUNCTION__, rep);

         //save
        extension_status = rep;
         
     }];
    return extension_status;
}

-(NSArray*) get_allowlist {
    
    //placeholder for allowlist
    __block NSArray* al = nil;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
     }] get_allowlist:^(NSArray* rep)
     {
         //dbg msg
        os_log_debug(log_handle, "got %s reply: %@", __PRETTY_FUNCTION__, rep);

         //save
        al = rep;
         
     }];
    return al;
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
        os_log_debug(log_handle, "got %s reply: %d", __PRETTY_FUNCTION__, rep);

         //save
        ok = rep;
         
     }];
    return ok;
}


-(BOOL) add_item_to_allowlist:(NSDictionary *)al generic:(BOOL)generic{
    
    __block BOOL ok = NO;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
    }] add_item_to_allowlist:al generic:generic reply:^(BOOL rep)
     {
         //dbg msg
         os_log_debug(log_handle, "got %s reply: %d", __PRETTY_FUNCTION__, rep);
         
         //save
        ok = rep;
         
     }];
    return ok;
}

-(BOOL) remove_item_from_allowlist:(NSDictionary *)al {
    
    __block BOOL ok = NO;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
    }] remove_item_from_allowlist:al reply:^(BOOL rep)
     {
         //dbg msg
        os_log_debug(log_handle, "got %s reply: %d", __PRETTY_FUNCTION__, rep);

         //save
        ok = rep;
         
     }];
    return ok;
}

-(BOOL) clear_allowlist {
    
    __block BOOL ok = NO;
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
    }] clear_allowlist:^(BOOL rep)
     {
         //dbg msg
         os_log_debug(log_handle, "got %s reply: %d", __PRETTY_FUNCTION__, rep);
         
         //save
        ok = rep;
         
     }];
    return ok;
}

//clear cache - to reset state if somethign was blocked but the user allows it
-(void)clear_cache {
    [[self.extension synchronousRemoteObjectProxyWithErrorHandler:^(NSError * proxyError)
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed to execute daemon XPC method '%s' (error: %@)", __PRETTY_FUNCTION__, proxyError);
        
    }] clear_cache];
}

@end
