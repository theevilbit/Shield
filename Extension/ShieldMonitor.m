//
//  ShieldExtension.m
//  Shield System Extension
//
//  Created by csaby on 2020. 06. 08..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//



#import "ShieldMonitor.h"


//global variables
extern Preferences* preferences;

extern AllowList* allowlist;

extern os_log_t log_handle;

//global for endpoint
extern es_client_t* endpointClient;

@implementation ShieldMonitor


/*
 Initialization methods
 */
-(id)init
{
    //init super
    self = [super init];
    if(self != nil)
    {
        self.monitoredEnvVars = [NSArray arrayWithObjects:@"DYLD_INSERT_LIBRARIES",@"CFNETWORK_LIBRARY_PATH",@"RAWCAMERA_BUNDLE_PATH",@"ELECTRON_RUN_AS_NODE",nil];
        /*
         ELECTRON_RUN_AS_NODE
         https://www.trustedsec.com/blog/macos-injection-via-third-party-frameworks
         */
        self.xpc_client = [[XPCAppClient alloc] init];
        self.isRunning = NO;

    }
    return self;
}

-(es_new_client_result_t)start
{
    es_new_client_result_t result = 0;
    if (!self.isRunning) {
        result = [self monitor];
        if(result == ES_NEW_CLIENT_RESULT_SUCCESS) {
            self.isRunning = YES;
        }
    }
    return result;
}

-(BOOL)stop
{
    BOOL stopped = YES;
    if (self.isRunning) {
        stopped = [self.procMon stop];
        self.isRunning = !stopped;
        if(stopped) {
            self.procMon = nil;
        }
    }
    return stopped;
}

-(void)clear_cache {
    if(endpointClient) {
        es_clear_cache(endpointClient);
    }
}

/*
 Methods to handle ES
 */
- (BOOL) monitor
{
    //(process) events of interest
    es_event_type_t events[] = {ES_EVENT_TYPE_AUTH_GET_TASK, ES_EVENT_TYPE_AUTH_EXEC, ES_EVENT_TYPE_AUTH_MMAP};

    //init monitor
    self.procMon = [[ProcessMonitor alloc] init];

    //define block
    // automatically invoked upon process events
    ProcessCallbackBlock block = ^(Process* process, es_client_t *client, es_message_t *message)
    {
        //ingore apple?
        if( (YES == [[preferences.preferences objectForKey:PREF_SKIPAPPLE] boolValue]) && (YES == process.isPlatformBinary.boolValue))
        {
            /*
             Apple processes getting task ports extremly frequently, and causing ~20% CPU usage
             I filter out these all, as we are not interested in them
             On the long run probably need to filter out only core processes, like launchd, etc...
             */
            if(process.event == ES_EVENT_TYPE_AUTH_GET_TASK) {
                es_mute_process(client, &message->process->audit_token);
            }
            
            //we need to allow everything we ignore, otherwise everything will hang
            if(ES_ACTION_TYPE_AUTH == message->action_type) {
                es_respond_auth_result(client,
                                       message,
                                       ES_AUTH_RESULT_ALLOW,
                                       false
                                       );
            }
            //ignore
            return;
        }
        
        es_respond_result_t res;
        NSMutableDictionary* notification = [NSMutableDictionary new];
        BOOL notify = NO;
        BOOL blocked = NO;
        notification[NOTIFICATION_TYPE] = @"";
        notification[NOTIFICATION_VICTIM_PATH] = process.path;
        notification[NOTIFICATION_ATTACKER_PATH] = @"-";
        notification[NOTIFICATION_DYLIB_PATH] = @"-";
        notification[NOTIFICATION_ENV] = @"";//[[process.env valueForKey:@"description"] componentsJoinedByString:@""];
        notification[NOTIFICATION_ARGUMENTS] = [[process.arguments valueForKey:@"description"] componentsJoinedByString:@" "];
        
        //timestamp is not sufficient id for mass alert, like Firefox, we use UUID
        notification[@"id"] = [[NSUUID UUID] UUIDString];

        //main logic
        switch(process.event)
        {
            //mmap event
            case ES_EVENT_TYPE_AUTH_MMAP:
            {
                es_auth_result_t authResult = ES_AUTH_RESULT_ALLOW;
                bool set_cache = false;
                //check if we care about dylib hijack
                if([[preferences.preferences objectForKey:PREF_DYLIB] boolValue] == YES) {
                    //enable cache if we verify the dylib
                    set_cache = true;
                    //extract mmap event
                    es_event_mmap_t * mmap = &message->event.mmap;
                    
                    //extract path from mmap event
                    NSString *path = convertStringToken(&mmap->source->path);
                    
                    //get extension
                    NSString *ext = [path pathExtension];
                    if ([ext isEqualToString:@"dylib"]) {
                        os_log_debug(log_handle,"checking dylib for process %@, dylib: %@",process.path, path);
                        //variables for code signing
                        SecStaticCodeRef staticCode = NULL;
                        SecRequirementRef requirementRef = NULL;
                        //hold status
                        OSStatus status = !noErr;

                        //create static code ref from path
                        CFURLRef cfurl = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (const UInt8*)[path cStringUsingEncoding:NSUTF8StringEncoding], path.length, false);
                        //conversion successful
                        if(cfurl) {
                            status = SecStaticCodeCreateWithPath(cfurl, kSecCSDefaultFlags, &staticCode);
                            os_log_debug(log_handle,"SecStaticCodeCreateWithPath error: 0x%x",status);
                            if (status == noErr) {
                                //create req string
                                //set req string, teamid = of the process
                               NSString *requirementString = [NSString stringWithFormat:@"(anchor apple) or (anchor apple generic and certificate leaf[subject.OU] = \"%@\")", process.teamID];
                                os_log_debug(log_handle,"Req string: %@", requirementString);

                                status = SecRequirementCreateWithString((__bridge CFStringRef _Nonnull)(requirementString), kSecCSDefaultFlags, &requirementRef);
                                os_log_debug(log_handle,"SecRequirementCreateWithString error: 0x%x",status);
                                if (status == noErr) {
                                    //check code validity
                                    status = SecStaticCodeCheckValidity(staticCode, kSecCSCheckAllArchitectures, requirementRef);
                                    os_log_debug(log_handle,"SecStaticCodeCheckValidity error: 0x%x",status);
                                   if (status != noErr) {
                                        notification[NOTIFICATION_TYPE] = @"Dylib hijacking";
                                        notification[NOTIFICATION_DYLIB_PATH] = path;
                                        //check whitelist
                                        if([allowlist is_item_in_allowlist:notification]) {
                                            res = es_respond_auth_result(client, message, authResult, false);
                                            break;
                                        }
                                        notify = YES;
                                        if([[preferences.preferences objectForKey:PREF_ISBLOCKING] boolValue] == NO) {
                                            /*
                                             we notify users about detection, but postpone AUTH decision to later in case
                                            other checks find issues
                                             */
                                            os_log_error(log_handle,"dylib hijackign detected in process %@, dylib: %@",process.path, path);
                                        }
                                        //blocking mode
                                        else {
                                            authResult = ES_AUTH_RESULT_DENY;
                                            os_log_error(log_handle,"dylib hijackign blocked in process %@, dylib: %@",process.path, path);
                                            blocked = YES;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                //set cache to true
                res = es_respond_auth_result(client, message, authResult, set_cache);

                break;
            }
            //exec authorization
            case ES_EVENT_TYPE_AUTH_EXEC:
            {
                //we allow by default
                es_auth_result_t authResult = ES_AUTH_RESULT_ALLOW;
                if([[preferences.preferences objectForKey:PREF_ENVVARS] boolValue] == YES) {
                    //loop through all monitored env vars
                    for (NSString *searchString in self.monitoredEnvVars) {
                        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",searchString];
                        NSArray *searchResults = [process.env filteredArrayUsingPredicate:searchPredicate];
                        if([searchResults count] > 0)
                        {
                            notification[NOTIFICATION_ENV] = [[searchResults valueForKey:@"description"] componentsJoinedByString:@" "];
                            notification[NOTIFICATION_TYPE] = @"Injection through environment variables";
                            //check whitelist
                            if([allowlist is_item_in_allowlist:notification]) {
                                res = es_respond_auth_result(client, message, authResult, false);
                                break;
                            }
                            notify = YES;
                            if([[preferences.preferences objectForKey:PREF_ISBLOCKING] boolValue] == NO) {
                                /*
                                 we notify users about detection, but postpone AUTH decision to later in case
                                other checks find issues
                                 */
                                os_log_error(log_handle, "Environment variable %@ injection detected, victim process:%@ env: %@", searchString, process.path, [[process.env valueForKey:@"description"] componentsJoinedByString:@""]);
                                //check if learning mode, this is only important when in non-blocking mode
                            }
                            //blocking mode
                            else {
                                authResult = ES_AUTH_RESULT_DENY;
                                blocked = YES;
                                os_log_error(log_handle, "Environment variable %@ injection blocked, victim process:%@ env: %@", searchString, process.path, [[process.env valueForKey:@"description"] componentsJoinedByString:@""]);
                            }
                        }

                    }
                }
                
                //check for electron debug port use
                if([[preferences.preferences objectForKey:PREF_ELECTRON] boolValue] == YES) {
                    NSString *electronDebugSearchString = @"--inspect";
                    NSPredicate *electronDebugPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",electronDebugSearchString];
                    NSArray *electronDebugSearchResults = [process.arguments filteredArrayUsingPredicate:electronDebugPredicate];
                    if ([electronDebugSearchResults count] > 0)
                    {
                        notification[NOTIFICATION_TYPE] = @"Injection through Electron debug port";
                        //check whitelist
                        if([allowlist is_item_in_allowlist:notification]) {
                            res = es_respond_auth_result(client, message, authResult, false);
                            break;
                        }
                        notify = YES;
                        if([[preferences.preferences objectForKey:PREF_ISBLOCKING] boolValue] == NO) {
                            /*
                             we notify users about detection, but postpone AUTH decision to later in case
                            other checks find issues
                             */
                            os_log_error(log_handle, "Electrong debug port injection detected, victim process:%@ arg: %@", process.path, [[process.arguments valueForKey:@"description"] componentsJoinedByString:@""]);
                        }
                        else {
                            authResult = ES_AUTH_RESULT_DENY;
                            blocked = YES;
                            os_log_error(log_handle, "Electrong debug port injection blocked, victim process:%@ arg: %@", process.path, [[process.arguments valueForKey:@"description"] componentsJoinedByString:@""]);
                        }
                    }
                }
                //final decision
                //this is how we send authorization respond
                res = es_respond_auth_result(client, message, authResult, false);
                                
                break;
            }
            
            //hit when someone runs task_for_pid
            case ES_EVENT_TYPE_AUTH_GET_TASK:
            {
                es_auth_result_t authResult = ES_AUTH_RESULT_ALLOW;
                if([[preferences.preferences objectForKey:PREF_TFP] boolValue] == YES) {
                    notification[NOTIFICATION_TYPE] = @"Task For Pid injection";
                    notification[NOTIFICATION_ATTACKER_PATH] = process.path;
                    notification[NOTIFICATION_VICTIM_PATH] = @(message->event.exec.target->executable->path.data);
                    //check whitelist
                    if([allowlist is_item_in_allowlist:notification]) {
                        res = es_respond_auth_result(client, message, authResult, false);
                        break;
                    }
                    notify = YES;
                    if([[preferences.preferences objectForKey:PREF_ISBLOCKING] boolValue] == NO) {
                        os_log_error(log_handle, "task_for_pid injection detected, attacker process:%@ , target process:%s", process.path, message->event.exec.target->executable->path.data);
                    }
                    else {
                        authResult = ES_AUTH_RESULT_DENY;
                        os_log_error(log_handle, "task_for_pid injection blocked, attacker process:%@ , target process:%s", process.path, message->event.exec.target->executable->path.data);
                        blocked = YES;
                    }
                }

                res = es_respond_auth_result(client, message, authResult, false);

                break;
            }
            default:
            {
                es_auth_result_t authResult = ES_AUTH_RESULT_ALLOW;
                res = es_respond_auth_result(client, message, authResult, false);
                break;
            }
        }
        
        //something was detected
        if(notify) {
            //learning mode check, only effective if non-blocking
            if(([preferences.preferences[PREF_ISLEARNING] boolValue] == YES) && ([preferences.preferences[PREF_ISBLOCKING] boolValue] == NO)) {
                //add to allowlist
                [allowlist add_item_to_allowlist:notification];
            }
            //notify otherwise
            else {
                [self.xpc_client send:[notification copy] blocked:blocked];
            }
        }
        
    };
        
    //start monitoring
    // pass in events, count, and callback block for events
    return [self.procMon start:events count:sizeof(events)/sizeof(events[0]) csOption:csStatic callback:block];
}

@end
