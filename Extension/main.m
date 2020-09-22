//
//  main.m
//  Extension
//
//  Created by csaby on 2020. 06. 07..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#import "ProcessMonitor.h"
#import "ShieldExtension.h"
#import "../Common/logging.h"
#import "../Common/Constants.h"

dispatch_source_t dispatchSource = nil;

//close logging
void goodbye()
{
    //close logging
    deinitLogging();
    
    return;
}

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
        logMsg(LOG_DEBUG, @"caught 'SIGTERM' message....shutting down");
        
        //bye!
        // close logging
        goodbye();
        
        //bye bye!
        exit(SIGTERM);
    });
    
    //resume
    dispatch_resume(dispatchSource);

    return;
}

int main(int argc, const char * argv[]) {
    int status = 0;
    setLoggingUser(LOG_ROOT);
    @autoreleasepool {
        //init logging
        if(YES != initLogging(logFilePath(0)))
        {
            //err msg
            logMsg(LOG_ERR, @"failed to init logging");
            
            //bail
            goto bail;
        }
        register4Shutdown();
        logMsg(LOG_DEBUG, @"registered for shutdown events");
        ShieldExtension* sed = [ShieldExtension new];
        [[NSRunLoop currentRunLoop] run];
        //dispatch_main();

        }
            
    bail:
        return status;
}

