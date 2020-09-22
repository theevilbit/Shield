//
//  ShieldExtension.m
//  Shield System Extension
//
//  Created by csaby on 2020. 06. 08..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProcessMonitor.h"
#import "ShieldExtension.h"
#import <Security/Security.h>
#import "../Common/Constants.h"

//interface for 'extension' to NSXPCConnection
// ->allows us to access the 'private' auditToken iVar
@interface ExtendedNSXPCConnection : NSXPCConnection
{
    //private iVar
    audit_token_t auditToken;
}
//private iVar
@property audit_token_t auditToken;

@end

//implementation for 'extension' to NSXPCConnection
// ->allows us to access the 'private' auditToken iVar
@implementation ExtendedNSXPCConnection

//private iVar
@synthesize auditToken;

@end

OSStatus SecTaskValidateForRequirement(SecTaskRef task, CFStringRef requirement);


@implementation ShieldExtension


/*
 Initialization methods
 */
-(id)init
{
    //init super
    self = [super init];
    if(self != nil)
    {
        self.prefs = [Preferences new];
        if ([self.prefs.preferences count] < 5) {
            self.prefs.preferences[@"prefElectron"] = @YES;
            self.prefs.preferences[@"prefEnvVars"] = @YES;
            self.prefs.preferences[@"prefTFP"] = @YES;
            self.prefs.preferences[@"skipApple"] = @YES;
            self.prefs.preferences[@"isBlocking"] = @YES;
            [self.prefs save];
        }
        self.isRunning = NO;
        self.monitoredEnvVars = [NSArray arrayWithObjects:@"DYLD_INSERT_LIBRARIES",@"CFNETWORK_LIBRARY_PATH",@"RAWCAMERA_BUNDLE_PATH",@"ELECTRON_RUN_AS_NODE",nil];
        /*
         ELECTRON_RUN_AS_NODE
         https://www.trustedsec.com/blog/macos-injection-via-third-party-frameworks
         */
        
    }
    [self initListener];
    return self;
}

-(BOOL)initListener
{
    //result
    BOOL result = NO;
    
    //init listener
    self.listener = [[NSXPCListener alloc] initWithMachServiceName:@"33YRLYRBYV.com.csaba.fitzl.shield.Extension.xpc"];
    if(self.listener == nil)
    {
        logMsg(LOG_TO_FILE|LOG_ERR, @"ShieldExtension: failed to create mach service");
        goto bail;
    }
    
    logMsg(LOG_TO_FILE|LOG_NOTICE, @"ShieldExtension: created mach service");

    //set delegate
    self.listener.delegate = self;
    
    //ready to accept connections
    [self.listener resume];
    
    //happy
    result = YES;
    
bail:
    
    return result;
}

- (BOOL)validateClientCodeSignature:(NSXPCConnection *)connection {
    //flag
    BOOL shouldAccept = NO;
    
    //task ref
    SecTaskRef taskRef = 0;
    
    //signing req string (main app)
    NSString* requirementStringApp = nil;
            
    //init signing req string (main app)
    requirementStringApp = [NSString stringWithFormat:@"anchor trusted and identifier \"%@\" and certificate leaf[subject.OU] = \"%@\"", MAIN_APP_ID, TEAM_ID];
        
    //step 1: create task ref
    // uses NSXPCConnection's (private) 'auditToken' iVar
    taskRef = SecTaskCreateWithAuditToken(NULL, ((ExtendedNSXPCConnection*)connection).auditToken);
    if(taskRef == NULL)
    {
        //bail
        goto bail;
    }
    
    //step 2: validate
    // check that client is signed with Objective-See's and it's LuLu (main app or helper)
    if(0 != SecTaskValidateForRequirement(taskRef, (__bridge CFStringRef)(requirementStringApp)))
    {
        //bail
        goto bail;
    }
    
    shouldAccept = YES;
    
    bail:
    
    //release task ref object
    if(NULL != taskRef)
    {
        //release
        CFRelease(taskRef);
        
        //unset
        taskRef = NULL;
    }
    
    return shouldAccept;

}

/*
 Method to comform to NSXPCListenerDelegate protocol
 */
//handle incoming connections
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{

    logMsg(LOG_TO_FILE|LOG_NOTICE, @"ShieldExtension: Received new XPC connection request");
    BOOL allowConnection = [self validateClientCodeSignature:newConnection];
    if(allowConnection == YES) {
        [newConnection setExportedInterface: [NSXPCInterface interfaceWithProtocol:@protocol(ProviderCommunication)]];
        
        //we implement the protocol
        [newConnection setExportedObject: self];

        //set remote protocol
        newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol: @protocol(AppCommunication)];

        //handlers
        newConnection.invalidationHandler = ^{
            logMsg(LOG_TO_FILE|LOG_ERR, @"ShieldExtension: Connection invalidated");
            self.connection = nil;
        };

        newConnection.interruptionHandler = ^{
            logMsg(LOG_TO_FILE|LOG_ERR, @"ShieldExtension: Connection interrupted");
            self.connection = nil;
        };

        //save the connection
        self.connection = newConnection;
        
        [newConnection resume];
    }
    return allowConnection;
    
}

/*
 Methods to comform to ProviderCommunication protocol
 */

//start the ES client
-(void)startWithReply:(void (^)(BOOL))reply
{
    BOOL started = YES;
    if (!self.isRunning) {
        started = [self monitor];
        self.isRunning = started;
    }
    reply(started);
}

//stop ES client
-(void)stopWithReply:(void (^)(BOOL))reply
{
    BOOL stopped = YES;
    if (self.isRunning) {
        stopped = [self.procMon stop];
        self.isRunning = !stopped;
        if(stopped) {
            self.procMon = nil;
        }
    }
    reply(stopped);
}

//register ES client
-(void)registerWithReply:(void (^)(BOOL))reply
{
    logMsg(LOG_TO_FILE|LOG_NOTICE, @"ShieldExtension: registration started");
    self.remoteObject = [self.connection remoteObjectProxyWithErrorHandler:^(NSError* error) {
         logMsg(LOG_TO_FILE|LOG_ERR, @"ShieldExtension: Something went wrong with the remote object");
        logMsg(LOG_TO_FILE|LOG_ERR, [NSString stringWithFormat:@"ShieldExtension: error --> %@", error]);
     }];
    reply(YES);
}

//we send an XPC to the app
-(void) notifyUser:(NSString*)message blocked:(BOOL)blockStatus
{
    logMsg(LOG_TO_FILE|LOG_NOTICE, @"ShieldExtension: notification sent to user");
    [self.remoteObject notify:message blocked:blockStatus];
}

//set prefs
- (void) updatePrefs:(NSDictionary *)prefs {
    if(prefs != nil) {
        self.prefs.preferences[@"prefElectron"] = [prefs objectForKey:@"prefElectron"];
        self.prefs.preferences[@"prefEnvVars"] = [prefs objectForKey:@"prefEnvVars"];
        self.prefs.preferences[@"prefTFP"] = [prefs objectForKey:@"prefTFP"];
        self.prefs.preferences[@"skipApple"] = [prefs objectForKey:@"skipApple"];
        self.prefs.preferences[@"isBlocking"] = [prefs objectForKey:@"isBlocking"];
    }
    [self.prefs save];
}

//send our local status variables to the main app
- (void) getStatus:(void (^)(NSDictionary *))reply {

    logMsg(LOG_TO_FILE|LOG_NOTICE, @"ShieldExtension: sending status to app");
    self.prefs.preferences[@"isRunning"] = @(self.isRunning);
    NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:self.prefs.preferences copyItems:YES];
    logMsg(LOG_TO_FILE|LOG_INFO, [NSString stringWithFormat:@"ShieldExtension getStatus: %@", dict]);
    reply(dict);
}

/*
 Methods to handle ES
 */
- (BOOL) monitor
{
    //(process) events of interest
    es_event_type_t events[] = {ES_EVENT_TYPE_AUTH_GET_TASK, ES_EVENT_TYPE_AUTH_EXEC};

    //init monitor
    self.procMon = [[ProcessMonitor alloc] init];

    //define block
    // automatically invoked upon process events
    ProcessCallbackBlock block = ^(Process* process, es_client_t *client, es_message_t *message)
    {
        //ingore apple?
        if( (YES == [[self.prefs.preferences objectForKey:@"skipApple"] boolValue]) && (YES == process.isPlatformBinary.boolValue))
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
        //main logic
        switch(process.event)
        {
            //exec authorization
            case ES_EVENT_TYPE_AUTH_EXEC:
            {
                //we allow by default
                es_auth_result_t authResult = ES_AUTH_RESULT_ALLOW;
                if([[self.prefs.preferences objectForKey:@"prefEnvVars"] boolValue] == YES) {
                    //loop through all monitored env vars
                    for (NSString *searchString in self.monitoredEnvVars) {
                        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",searchString];
                        NSArray *searchResults = [process.env filteredArrayUsingPredicate:searchPredicate];
                        if([searchResults count] > 0)
                        {
                            if([[self.prefs.preferences objectForKey:@"isBlocking"] boolValue] == NO) {
                                /*
                                 we notify users about detection, but postpone AUTH decision to later in case
                                other checks find issues
                                 */
                                NSString* notificationString = [NSString stringWithFormat:@"Environment variable (%@) injection detected\nVictim process:\n%@", searchString, process.path];
                                logMsg(LOG_TO_FILE|LOG_WARNING, notificationString);
                                [self notifyUser:notificationString blocked:NO];
                            }
                            //blocking mode
                            else {
                                authResult = ES_AUTH_RESULT_DENY;
                                NSString* notificationString = [NSString stringWithFormat:@"Environment variable (%@) injection blocked\nVictim process:\n%@", searchString, process.path];
                                logMsg(LOG_TO_FILE|LOG_WARNING, notificationString);
                                [self notifyUser:notificationString blocked:YES];
                            }
                        }

                    }
                }
                
                //check for electron debug port use
                if([[self.prefs.preferences objectForKey:@"prefElectron"] boolValue] == YES) {
                    NSString *electronDebugSearchString = @"--inspect";
                    NSPredicate *electronDebugPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",electronDebugSearchString];
                    NSArray *electronDebugSearchResults = [process.arguments filteredArrayUsingPredicate:electronDebugPredicate];
                    if ([electronDebugSearchResults count] > 0)
                    {
                        if([[self.prefs.preferences objectForKey:@"isBlocking"] boolValue] == NO) {
                            /*
                             we notify users about detection, but postpone AUTH decision to later in case
                            other checks find issues
                             */
                            NSString* notificationString = [NSString stringWithFormat:@"Electrong debug port injection detected\nVictim process:\n%@", process.path];
                            logMsg(LOG_TO_FILE|LOG_WARNING, notificationString);
                            [self notifyUser:notificationString blocked:NO];
                        }
                        else {
                            authResult = ES_AUTH_RESULT_DENY;
                            NSString* notificationString = [NSString stringWithFormat:@"Electrong debug port injection blocked\nVictim process:\n%@", process.path];
                            logMsg(LOG_TO_FILE|LOG_WARNING, notificationString);
                            [self notifyUser:notificationString blocked:YES];
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
                if([[self.prefs.preferences objectForKey:@"prefTFP"] boolValue] == YES) {
                    if([[self.prefs.preferences objectForKey:@"isBlocking"] boolValue] == NO) {
                        NSString* notificationString = [NSString stringWithFormat:@"task_for_pid injection detected\nAttacker process:%@\nTarget process:%s\n", process.path, message->event.exec.target->executable->path.data];
                        logMsg(LOG_TO_FILE|LOG_WARNING, notificationString);
                        [self notifyUser:notificationString blocked:NO];
                    }
                    else {
                        authResult = ES_AUTH_RESULT_DENY;
                        NSString* notificationString = [NSString stringWithFormat:@"task_for_pid injection blocked\nAttacker process:%@\nTarget process:%s\n", process.path, message->event.exec.target->executable->path.data];
                        logMsg(LOG_TO_FILE|LOG_WARNING, notificationString);
                        [self notifyUser:notificationString blocked:YES];
                    }
                }

                res = es_respond_auth_result(client, message, authResult, false);

                break;
            }
            default:
                break;
        }
        
        };
        
    //start monitoring
    // pass in events, count, and callback block for events
    return [self.procMon start:events count:sizeof(events)/sizeof(events[0]) csOption:csStatic callback:block];
}

@end
