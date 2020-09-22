//
//  Process.m
//  ProcessMonitor
//
//  Created by Patrick Wardle on 9/1/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import <libproc.h>
#import <bsm/libbsm.h>
#import <sys/sysctl.h>

#import "signing.h"
#import "utilities.h"
#import "ProcessMonitor.h"

/* FUNCTIONS */

//helper function
// get parent of arbitrary process
pid_t getParentID(pid_t child);

@implementation Process

@synthesize pid;
@synthesize exit;
@synthesize path;
@synthesize ppid;
@synthesize event;
@synthesize ancestors;
@synthesize arguments;
@synthesize env;
@synthesize timestamp;
@synthesize signingInfo;
@synthesize target_pid;
@synthesize p_message;

//init
// flag controls code signing options
-(id)init:(es_message_t*)message csOption:(NSUInteger)csOption
{
    //init super
    self = [super init];
    if(nil != self)
    {
        //the original message
        self.p_message = message;
        
        //process from msg
        es_process_t* process = NULL;
        
        //string value
        // used for various conversions
        NSString* string = nil;
        
        //alloc array for args
        self.arguments = [NSMutableArray array];

        //alloc array for env
        self.env = [NSMutableArray array];
        
        //alloc array for parents
        self.ancestors = [NSMutableArray array];
        
        //alloc dictionary for signing info
        self.signingInfo = [NSMutableDictionary dictionary];
        
        //init exit
        self.exit = -1;
        
        //init user id
        self.uid = -1;
        
        //init event
        self.event = -1;
        
        //set start time
        self.timestamp = [NSDate date];
        
        //set type
        self.event = message->event_type;
        
        //event specific logic
        // set type
        // extract (relevant) process object, etc
        switch (message->event_type) {
            
            //exec
            case ES_EVENT_TYPE_AUTH_EXEC:
                //set process (target)
                process = message->event.exec.target;
                
                //extract/format args
                [self extractArgs:&message->event];
                [self extractEnvs:&message->event];

                break;
        
            //task for pid
            case ES_EVENT_TYPE_AUTH_GET_TASK:
                process = message->process;
                break;
            //default
            default:
                
                //set process
                process = message->process;
                break;
        }
        
        self.target_pid = audit_token_to_pid(message->event.get_task.target->audit_token);

        //init pid
        self.pid = audit_token_to_pid(process->audit_token);
        
        //init ppid
        self.ppid = process->ppid;
        
        //init uuid
        self.uid = audit_token_to_euid(process->audit_token);
        
        //init path
        self.path = convertStringToken(&process->executable->path);
    
        //add cs flags
        self.csFlags = [NSNumber numberWithUnsignedInt:process->codesigning_flags];
        
        //convert/add signing id
        if(nil != (string = convertStringToken(&process->signing_id)))
        {
            //add
            self.signingID = string;
        }
        
        //convert/add team id
        if(nil != (string = convertStringToken(&process->team_id)))
        {
            //add
            self.teamID = string;
        }
        
        //add platform binary
        self.isPlatformBinary = [NSNumber numberWithBool:process->is_platform_binary];
        
        //alloc
        self.cdHash = [NSMutableString string];
        
        //format cdhash
        for(uint32_t i=0; i<CS_CDHASH_LEN; i++)
        {
            //append
            [self.cdHash appendFormat:@"%02X", process->cdhash[i]];
        }
        
        //when specified
        // generate full code signing info
        if(csNone != csOption)
        {
            //generate code signing info
            [self generateCSInfo:csOption];
        }
    
        //enum ancestors
        [self enumerateAncestors];
    }
    
    return self;
}


//generate code signing info
// sets 'signingInfo' iVar
-(void)generateCSInfo:(NSUInteger)csOption
{
    //generate via helper function
    self.signingInfo = generateSigningInfo(self, csOption, kSecCSDefaultFlags);
    
    return;
}

//extract/format args
-(void)extractArgs:(es_events_t *)event
{
    //number of args
    uint32_t count = 0;
    
    //argument
    NSString* argument = nil;
    
    //get # of args
    count = es_exec_arg_count(&event->exec);
    if(0 == count)
    {
        //bail
        goto bail;
    }
    
    //extract all args
    for(uint32_t i = 0; i < count; i++)
    {
        //current arg
        es_string_token_t currentArg = {0};
        
        //extract current arg
        currentArg = es_exec_arg(&event->exec, i);
        
        //convert argument
        argument = convertStringToken(&currentArg);
        if(nil != argument)
        {
            //append
            [self.arguments addObject:argument];
        }
    }
    
bail:
    
    return;
}

//extract/format environment variables
-(void)extractEnvs:(es_events_t *)event
{
    //number of envs
    uint32_t count = 0;
    
    //env
    NSString* environment = nil;
    
    //get # of envs
    count = es_exec_env_count(&event->exec);
    if(0 == count)
    {
        //bail
        goto bail;
    }
    
    //extract all envs
    for(uint32_t i = 0; i < count; i++)
    {
        //current env
        es_string_token_t currentEnv = {0};
        
        //extract current env
        currentEnv = es_exec_env(&event->exec, i);
        
        //convert env
        environment = convertStringToken(&currentEnv);
        if(nil != env)
        {
            //append
            [self.env addObject:environment];
        }
    }
    
bail:
    
    return;
}

//generate list of ancestors
-(void)enumerateAncestors
{
    //current process id
    pid_t currentPID = -1;
    
    //parent pid
    pid_t parentPID = -1;
    
    //add parent
    if(-1 != self.ppid)
    {
        //add
        [self.ancestors addObject:[NSNumber numberWithInt:self.ppid]];
        
        //set current to parent
        currentPID = self.ppid;
    }
    //don't know parent
    // just start with self
    else
    {
        //start w/ self
        currentPID = self.pid;
    }
    
    //complete ancestry
    while(YES)
    {
        //get parent pid
        parentPID = getParentID(currentPID);
        if( (0 == parentPID) ||
            (-1 == parentPID) ||
            (currentPID == parentPID) )
        {
            //bail
            break;
        }
        
        //update
        currentPID = parentPID;
        
        //add
        [self.ancestors addObject:[NSNumber numberWithInt:parentPID]];
    }
    
    return;
}


@end

//helper function
// get parent of arbitrary process
pid_t getParentID(pid_t child)
{
    //parent id
    pid_t parentID = -1;
    
    //kinfo_proc struct
    struct kinfo_proc processStruct = {0};
    
    //size
    size_t procBufferSize = 0;
    
    //mib
    const u_int mibLength = 4;
    
    //syscall result
    int sysctlResult = -1;
    
    //init buffer length
    procBufferSize = sizeof(processStruct);
    
    //init mib
    int mib[mibLength] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, child};
    
    //make syscall
    sysctlResult = sysctl(mib, mibLength, &processStruct, &procBufferSize, NULL, 0);
    
    //check if got ppid
    if( (noErr == sysctlResult) &&
        (0 != procBufferSize) )
    {
        //save ppid
        parentID = processStruct.kp_eproc.e_ppid;
    }
    
    return parentID;
}
