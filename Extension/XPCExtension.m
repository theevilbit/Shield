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

//global allowlist obj
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
    preferences.preferences[PREF_ISRUNNING] = @(shield_monitor.isRunning);
    [preferences save];
    reply(started);
}

//stop ES client
-(void)stopWithReply:(void (^)(BOOL))reply
{
    BOOL stopped = [shield_monitor stop];
    preferences.preferences[PREF_ISRUNNING] = @(shield_monitor.isRunning);
    [preferences save];
    reply(stopped);
}

//set prefs
- (void) update_preferences:(NSDictionary *)prefs reply:(void (^)(BOOL))reply {
    os_log_debug(log_handle, "Updating preferences");
    if(prefs != nil) {
        for(id key in prefs) {
            //update all prefs except for is running
            if(![key isEqualToString:PREF_ISRUNNING]) {
                preferences.preferences[key] = [prefs objectForKey:key];
            }
        }
    }
    [preferences save];
    reply(YES);
}

//send our local status variables to the main app
- (void) getStatus:(void (^)(NSDictionary *))reply {
    os_log_debug(log_handle, "Sending status to app");
    preferences.preferences[PREF_ISRUNNING] = @(shield_monitor.isRunning);
    NSDictionary *dict = [[NSDictionary alloc] initWithDictionary:preferences.preferences copyItems:YES];
    reply(dict);
}

- (void) get_allowlist:(void (^)(NSArray *))reply {
    os_log_debug(log_handle, "Sending allowlist to app");
    reply([allowlist.allowlist_items copy]);
}

-(void)add_item_to_allowlist:(NSDictionary *)al generic:(BOOL)generic reply:(void (^)(BOOL))reply
{
    os_log_debug(log_handle, "Updating allowlist");
    reply([allowlist add_item_to_allowlist:[al mutableCopy] generic:generic]);
}

-(void)remove_item_from_allowlist:(NSDictionary *)al reply:(void (^)(BOOL))reply
{
    os_log_debug(log_handle, "Updating allowlist");
    reply([allowlist remove_item_from_allowlist:[al mutableCopy]]);
}

-(void)clear_allowlist:(void (^)(BOOL))reply
{
    os_log_debug(log_handle, "Clearing allowlist");
    reply([allowlist clear_allowlist]);
}

-(void)clear_cache {
    [shield_monitor clear_cache];
}

@end
