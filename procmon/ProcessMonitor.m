//
//  ProcessMonitor.m
//  ProcessMonitor
//
//  Created by Patrick Wardle on 9/1/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

//  Inspired by https://gist.github.com/Omar-Ikram/8e6721d8e83a3da69b31d4c2612a68ba
//  NOTE: requires a) root b) the 'com.apple.developer.endpoint-security.client' entitlement

#import "utilities.h"
#import "ProcessMonitor.h"
#import "../Common/Constants.h"
#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>

@import OSLog;

//endpoint
es_client_t* endpointClient = nil;

extern os_log_t log_handle;

@implementation ProcessMonitor

//start monitoring
// pass in events of interest, count of said events, flag for codesigning, and callback
//we return the error code to propagte it to the main app
-(es_new_client_result_t)start:(es_event_type_t*)events count:(uint32_t)count csOption:(NSUInteger)csOption callback:(ProcessCallbackBlock)callback
{
        //flag
    BOOL started = NO;
        
    //check if already running
    
        //result
        es_new_client_result_t result = 0;
        
        //sync
        @synchronized (self) {
        
            //create client
            // callback invokes (user) callback for new processes
            result = es_new_client(&endpointClient, ^(es_client_t *client,const es_message_t *message)
            {
                //new process event
                Process* process = nil;
                
                //init process obj
                // do static check as well
                process = [[Process alloc] init:(es_message_t* _Nonnull)message csOption:csOption];
                if(nil != process)
                {
                    //invoke user callback
                    callback(process, client, (es_message_t* _Nonnull)message);
                }
            });
            if(result == ES_NEW_CLIENT_RESULT_SUCCESS) os_log_info(log_handle, "SUCCESS: es_new_client() registered");
            //error?
            if(ES_NEW_CLIENT_RESULT_SUCCESS != result)
            {
                //err msg 
                os_log_error(log_handle, "ERROR: es_new_client() failed");
                //provide more info
                switch (result) {
                        
                    //not entitled
                    case ES_NEW_CLIENT_RESULT_ERR_NOT_ENTITLED:
                        os_log_error(log_handle,"ES_NEW_CLIENT_RESULT_ERR_NOT_ENTITLED: \"The caller is not properly entitled to connect\"");
                        break;
                              
                    //not permitted
                    case ES_NEW_CLIENT_RESULT_ERR_NOT_PERMITTED:
                        os_log_error(log_handle,"ES_NEW_CLIENT_RESULT_ERR_NOT_PERMITTED: \"The caller is not permitted to connect. They lack Transparency, Consent, and Control (TCC) approval form the user.\"");
                        break;
                              
                    //not privileged
                    case ES_NEW_CLIENT_RESULT_ERR_NOT_PRIVILEGED:
                        os_log_error(log_handle,"ES_NEW_CLIENT_RESULT_ERR_NOT_PRIVILEGED: \"The caller is not running as root\"");
                        break;
                        
                    default:
                        break;
                }
            
                //bail
                goto bail;
            }
            
            //clear cache
            if(ES_CLEAR_CACHE_RESULT_SUCCESS != es_clear_cache(endpointClient))
            {
                //err msg
                os_log_error(log_handle,"ERROR: es_clear_cache() failed");
                
                //bail
                goto bail;
            }
            
            //subscribe
            if(ES_RETURN_SUCCESS != es_subscribe(endpointClient, events, count))
            {
                //err msg
                os_log_error(log_handle, "ERROR: es_subscribe() failed");
                
                //bail
                goto bail;
            }
            
        } //sync
        
        //happy
        started = YES;
    
    
bail:
    
    return result;
}

//stop
-(BOOL)stop
{
    //flag
    BOOL stopped = NO;
    
    //sync
    @synchronized (self) {
        
        //unsubscribe & delete
           //unsubscribe
           if(ES_RETURN_SUCCESS != es_unsubscribe_all(endpointClient))
           {
               //err msg
               os_log_error(log_handle,"ERROR: es_unsubscribe_all() failed");
               
               //bail
               goto bail;
           }
           
           //delete client
           if(ES_RETURN_SUCCESS != es_delete_client(endpointClient))
           {
               //err msg
               os_log_error(log_handle,"ERROR: es_delete_client() failed");
               
               //bail
               goto bail;
           }
           
           //unset
           endpointClient = NULL;
           
           //happy
           stopped = YES;
    } //sync
    
bail:
    
    return stopped;
}

@end
