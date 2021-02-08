//original: https://raw.githubusercontent.com/objective-see/LuLu/master/LuLu/Extension/XPCListener.m

//
//  XPCListener.m
//  Shield System Extension
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

@import Foundation;
@import OSLog;

#import <bsm/libbsm.h>

#import "XPCListener.h"

#import "XPCExtension.h"

#import "XPCAppProtocol.h"
#import "XPCExtensionProtocol.h"
#import "Constants.h"
#import "utilities.h"

/* GLOBALS */
extern os_log_t log_handle;

//interface for 'extension' to NSXPCConnection
// allows us to access the 'private' auditToken iVar
@interface ExtendedNSXPCConnection : NSXPCConnection
{
    //private iVar
    audit_token_t auditToken;
}
//private iVar
@property audit_token_t auditToken;

@end

//implementation for 'extension' to NSXPCConnection
// allows us to access the 'private' auditToken iVar
@implementation ExtendedNSXPCConnection

//private iVar
@synthesize auditToken;

@end

@implementation XPCListener

@synthesize client;
@synthesize listener;

//init
// create XPC listener
-(id)init
{
    //init super
    self = [super init];
    if(nil != self)
    {
        //init listener
        listener = [[NSXPCListener alloc] initWithMachServiceName:@"33YRLYRBYV.com.csaba.fitzl.shield.Extension.xpc"];
        
        //dbg msg
        os_log_info(log_handle, "created mach service");

        //set delegate
        self.listener.delegate = self;
        
        //ready to accept connections
        [self.listener resume];
    }
    else {
        os_log_error(log_handle, "failed to create mach service");
    }
    
    return self;
}

#pragma mark -
#pragma mark NSXPCConnection method overrides

//automatically invoked
// allows NSXPCListener to configure/accept/resume a new incoming NSXPCConnection
// shoutout to writeup: https://blog.obdev.at/what-we-have-learned-from-a-vulnerability
-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    //flag
    BOOL shouldAccept = NO;
    
    //status
    OSStatus status = !errSecSuccess;
    
    //audit token
    audit_token_t auditToken = {0};
    
    //task ref
    SecTaskRef taskRef = 0;
    
    //code ref
    SecCodeRef codeRef = NULL;
    
    //code signing info
    CFDictionaryRef csInfo = NULL;
    
    //cs flags
    uint32_t csFlags = 0;
    
    //signing req string (main app)
    NSString* requirement = nil;

    //extract audit token
    auditToken = ((ExtendedNSXPCConnection*)newConnection).auditToken;
    
    //dbg msg
    os_log_debug(log_handle, "received request to connect to XPC interface from: (%d)%{public}@", audit_token_to_pid(auditToken), getProcessPath(audit_token_to_pid(auditToken)));
    
    //obtain dynamic code ref
    status = SecCodeCopyGuestWithAttributes(NULL, (__bridge CFDictionaryRef _Nullable)(@{(__bridge NSString *)kSecGuestAttributeAudit : [NSData dataWithBytes:&auditToken length:sizeof(audit_token_t)]}), kSecCSDefaultFlags, &codeRef);
    if(errSecSuccess != status)
    {
        //err msg
        os_log_error(log_handle, "ERROR: 'SecCodeCopyGuestWithAttributes' failed with': %#x", status);
        
        //bail
        goto bail;
    }
    
    //validate code
    status = SecCodeCheckValidity(codeRef, kSecCSDefaultFlags, NULL);
    if(errSecSuccess != status)
    {
        //err msg
        os_log_error(log_handle, "ERROR: 'SecCodeCheckValidity' failed with': %#x", status);
       
        //bail
        goto bail;
    }
    
    //get code signing info
    status = SecCodeCopySigningInformation(codeRef, kSecCSDynamicInformation, &csInfo);
    if(errSecSuccess != status)
    {
        //err msg
        os_log_error(log_handle, "ERROR: 'SecCodeCopySigningInformation' failed with': %#x", status);
       
        //bail
        goto bail;
    }
    
    //dbg msg
    os_log_debug(log_handle, "client's code signing info: %{public}@", csInfo);
    
    //extract flags
    csFlags = [((__bridge NSDictionary *)csInfo)[(__bridge NSString *)kSecCodeInfoStatus] unsignedIntValue];
    
    //dbg msg
    os_log_debug(log_handle, "client code signing flags: %#x", csFlags);
    
    //gotta have hardened runtime
    if( !(CS_VALID & csFlags) &&
        !(CS_RUNTIME & csFlags) )
    {
        //err msg
        os_log_error(log_handle, "ERROR: invalid code signing flags: %#x", csFlags);
        
        //bail
        goto bail;
    }
    
    //dbg msg
    os_log_debug(log_handle, "client code signing flags, ok (includes 'CS_RUNTIME')");
    
    //init signing req
    requirement = [NSString stringWithFormat:@"anchor apple generic and identifier \"%@\" and certificate leaf [subject.OU] = \"%@\"", MAIN_APP_ID, TEAM_ID];
    
    //step 1: create task ref
    // uses NSXPCConnection's (private) 'auditToken' iVar
    taskRef = SecTaskCreateWithAuditToken(NULL, ((ExtendedNSXPCConnection*)newConnection).auditToken);
    if(NULL == taskRef)
    {
        //bail
        goto bail;
    }
    
    //step 2: validate
    // check that client is signed with Objective-See's and it's LuLu
    if(errSecSuccess != (status = SecTaskValidateForRequirement(taskRef, (__bridge CFStringRef)(requirement))))
    {
        //err msg
        os_log_error(log_handle, "ERROR: failed with validate client (error: %#x/%d)", status, status);
    
        //bail
        goto bail;
    }
    
    //dbg msg
    os_log_debug(log_handle, "client code signing information, ok");
    
    //set the interface that the exported object implements
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCExtensionProtocol)];
    
    //set object exported by connection
    newConnection.exportedObject = [[XPCExtension alloc] init];
    
    //set type of remote object
    // user (login item/main app) will set this object
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol: @protocol(XPCAppProtocol)];
    
    //set interruption handler
    [newConnection setInterruptionHandler:^{
        
        //dbg msg
        os_log_debug(log_handle, "XPC 'interruptionHandler' method invoked");
        
    }];

    //set invalidation handler
    [newConnection setInvalidationHandler:^{
        
        //dbg msg
        os_log_debug(log_handle, "XPC 'invalidationHandler' method invoked");
        
    }];
    
    //save
    self.client = newConnection;
    
    //resume
    [newConnection resume];
    
    //dbg msg
    os_log_debug(log_handle, "allowing XPC connection from client (pid: %d)", audit_token_to_pid(auditToken));
    
    //happy
    shouldAccept = YES;
    
bail:
    
    //release task ref object
    if(NULL != taskRef)
    {
        //release
        CFRelease(taskRef);
        taskRef = NULL;
    }
    
    //free cs info
    if(NULL != csInfo)
    {
        //free
        CFRelease(csInfo);
        csInfo = NULL;
    }
    
    //free code ref
    if(NULL != codeRef)
    {
        //free
        CFRelease(codeRef);
        codeRef = NULL;
    }
    
    return shouldAccept;
}

@end
