//
//  main.h
//  ShieldProject
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import "Preferences.h"
#import "AllowList.h"
#import "XPCListener.h"
#import "XPCExtension.h"
#import "XPCAppClient.h"
#import "ProcessMonitor.h"
#import "ShieldMonitor.h"
#import "../Common/logging.h"
#import "../Common/Constants.h"

@import OSLog;

#ifndef main_h
#define main_h
//GLOBALS

Preferences* preferences = nil;

AllowList* allowlist = nil;

ShieldMonitor* shield_monitor = nil;

XPCListener* xpc_listener = nil;

es_client_t* endpointClient = nil;

//log handle
os_log_t log_handle = nil;

#endif
