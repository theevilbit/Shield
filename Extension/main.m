//
//  main.m
//  Extension
//
//  Created by csaby on 2020. 06. 07..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#include "main.h"


dispatch_source_t dispatchSource = nil;


//init a handler for SIGTERM
// can perform actions such as disabling firewall and closing logging
void register4Shutdown()
{
    //ignore sigterm
    // handling it via GCD dispatch
    signal(SIGTERM, SIG_IGN);
    
    //init dispatch source for SIGTERM
    dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGTERM, 0, dispatch_get_main_queue());
    
    //set handler
    // ...(just) closes logging
    dispatch_source_set_event_handler(dispatchSource, ^{
        
        //dbg msg
        os_log_debug(log_handle, "caught 'SIGTERM' message....shutting down");
                
        //bye bye!
        exit(SIGTERM);
    });
    
    //resume
    dispatch_resume(dispatchSource);

    return;
}

int main(int argc, const char * argv[]) {
    int status = 0;
    //init logging
    log_handle = os_log_create(BUNDLE_ID, "systemextension");

    @autoreleasepool {
        
        //alloc/init/load prefs
        preferences = [[Preferences alloc] init];
        
        //alloc/init/load allowlist
        allowlist = [[AllowList alloc] init];
        
        //alloc/init XPC comms object
        xpc_listener = [[XPCListener alloc] init];
        
        register4Shutdown();

        shield_monitor = [ShieldMonitor new];
        [[NSRunLoop currentRunLoop] run];
        //dispatch_main();

        }
            
    bail:
        return status;
}

