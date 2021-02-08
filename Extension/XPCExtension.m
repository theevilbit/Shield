//
//  XPCExtension.m
//  ShieldProject
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

@import Foundation;
@import OSLog;

#import "Preferences.h"
#import "AllowList.h"
#import "XPCExtension.h"
#import "ShieldMonitor.h"

//global prefs obj
extern Preferences* preferences;

//global whitelist obj
extern AllowList* allowlist;

//global shield monitor obj
extern ShieldMonitor* shield_monitor;

//global log handle
extern os_log_t log_handle;

@implementation XPCExtension

//start the ES client
-(void)startWithReply:(void (^)(es_new_client_result_t))reply
{
    es_new_client_result_t started = [shield_monitor start];
    reply(started);
}

//stop ES client
-(void)stopWithReply:(void (^)(BOOL))reply
{
    BOOL stopped = [shield_monitor stop];
    reply(stopped);
}

//set prefs
- (void) update_preferences:(NSDictionary *)prefs reply:(void (^)(BOOL))reply {
    os_log_debug(log_handle, "Updating preferences");
    if(prefs != nil) {
        preferences.preferences[@"prefElectron"] = [prefs objectForKey:@"prefElectron"];
        preferences.preferences[@"prefEnvVars"] = [prefs objectForKey:@"prefEnvVars"];
        preferences.preferences[@"prefTFP"] = [prefs objectForKey:@"prefTFP"];
        preferences.preferences[@"prefDylib"] = [prefs objectForKey:@"prefDylib"];
        preferences.preferences[@"skipApple"] = [prefs objectForKey:@"skipApple"];
        preferences.preferences[@"isBlocking"] = [prefs objectForKey:@"isBlocking"];
    }
    [preferences save];
    reply(YES);
}

//send our local status variables to the main app
- (void) getStatus:(void (^)(NSDictionary *))reply {
    os_log_debug(log_handle, "Sending status to app");
    preferences.preferences[@"isRunning"] = @(shield_monitor.isRunning);
    NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:preferences.preferences copyItems:YES];
    reply(dict);
}

- (void) get_allowlist:(void (^)(NSDictionary *))reply {
    os_log_debug(log_handle, "Sending allowlist to app");
    NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:allowlist.allowlist_full copyItems:YES];
    reply(dict);
}

-(void)update_allowlist:(NSMutableDictionary *)al reply:(void (^)(BOOL))reply
{
    os_log_debug(log_handle, "Updating whitelist");
    allowlist.allowlist_full = al;
    reply(YES);
}



@end
