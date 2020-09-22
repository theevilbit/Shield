//
//  ShieldExtension.h
//  Shield System Extension
//
//  Created by csaby on 2020. 06. 08..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#ifndef ShieldExtension_h
#define ShieldExtension_h

#import "../Common/XPCProtocol.h"
#import "../Common/logging.h"
#import "ProcessMonitor.h"
#import "Preferences.h"

@interface ShieldExtension : NSObject<NSXPCListenerDelegate, ProviderCommunication>

//store the xpc connection
@property (weak) NSXPCConnection *connection;

//store the xpc listener
@property (nonatomic, retain) NSXPCListener* listener;

@property id<AppCommunication> remoteObject;

@property BOOL isRunning;

//properties for configuration of individual checks
@property Preferences* prefs;

@property NSArray* monitoredEnvVars;

@property ProcessMonitor* procMon;
//monitor
- (BOOL) monitor;

//methos to make xpc call to main app
-(void) notifyUser:(NSString*)message blocked:(BOOL)blockStatus;

//setup XPC listener
-(BOOL) initListener;

@end

#endif /* ShieldExtension_h */
