//
//  ShieldExtension.h
//  Shield System Extension
//
//  Created by csaby on 2020. 06. 08..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#import "../Common/logging.h"
#import "ProcessMonitor.h"
#import "Preferences.h"
#import "AllowList.h"
#import "XPCAppClient.h"
#import "XPCExtension.h"
@import Foundation;
#import "Constants.h"
#import "utilities.h"

@interface ShieldMonitor: NSObject

@property BOOL isRunning;
@property NSArray* monitoredEnvVars;
@property ProcessMonitor* procMon;
@property XPCAppClient* xpc_client;

- (BOOL) monitor;
- (es_new_client_result_t) start;
- (BOOL) stop;

- (void) clear_cache;


@end

