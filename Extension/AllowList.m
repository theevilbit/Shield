//
//  AllowList.m
//  Shield System Extension
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "AllowList.h"
#import "../Common/Constants.h"

@import OSLog;

//global log handle
extern os_log_t log_handle;

@implementation AllowList

//init
// loads prefs
-(id)init
{
    //super
    self = [super init];
    if(nil != self)
    {
        //load
        if(YES != [self load])
        {
            //err msg
            os_log_error(log_handle, "'%s' failed to load allowlist from %@", __PRETTY_FUNCTION__, ALLOWLIST_FILE);
            
            //self = nil;
            [self init_file];
            //bail
            goto bail;
        }
    }
    
bail:
    
    return self;
}

//initialize a allowlist file
-(BOOL)init_file {
    BOOL isDir = NO;
    BOOL isDirExists = [[NSFileManager defaultManager] fileExistsAtPath:DIR_PATH_ES isDirectory:&isDir];
    if (isDirExists == NO) {
        NSError * error = nil;

        [[NSFileManager defaultManager] createDirectoryAtPath:DIR_PATH_ES
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error != nil) {
            os_log_error(log_handle, "'%s' Error creating directory: %@",__PRETTY_FUNCTION__, error);

            goto bail;
        }
    }
    self.allowlist_full = [NSMutableDictionary new];
    self.allowlist_dylib = [NSMutableArray new];
    self.allowlist_task_for_pid = [NSMutableArray new];
    self.allowlist_envvars = [NSMutableArray new];
    self.allowlist_electron = [NSMutableArray new];

    [self.allowlist_full setObject:self.allowlist_dylib forKey:@"allowlist_dylib"];
    [self.allowlist_full setObject:self.allowlist_task_for_pid forKey:@"allowlist_task_for_pid"];
    [self.allowlist_full setObject:self.allowlist_envvars forKey:@"allowlist_envvars"];
    [self.allowlist_full setObject:self.allowlist_electron forKey:@"allowlist_electron"];

    
    BOOL saved = [self save];
    if(saved == NO) {
        os_log_error(log_handle, "'%s' Error saving preferences",__PRETTY_FUNCTION__);

        goto bail;
    }
    
    return YES;
    bail:
        return NO;
}

//load prefs from disk
-(BOOL)load
{
    //flag
    BOOL loaded = NO;
    
    //load
    self.allowlist_full = [NSMutableDictionary dictionaryWithContentsOfFile:[DIR_PATH_ES stringByAppendingPathComponent:ALLOWLIST_FILE]];
    if(nil == self.allowlist_full)
    {
        //bail
        goto bail;
    }
    
    //get specific allowlist from dictionary
    self.allowlist_electron = self.allowlist_full[@"allowlist_electron"];
    self.allowlist_dylib = self.allowlist_full[@"allowlist_dylib"];
    self.allowlist_envvars = self.allowlist_full[@"allowlist_envvars"];
    self.allowlist_task_for_pid = self.allowlist_full[@"allowlist_task_for_pid"];

    //replace NSArrays in dictionary to new ones
    [self.allowlist_full setObject:self.allowlist_dylib forKey:@"allowlist_dylib"];
    [self.allowlist_full setObject:self.allowlist_task_for_pid forKey:@"allowlist_task_for_pid"];
    [self.allowlist_full setObject:self.allowlist_envvars forKey:@"allowlist_envvars"];
    [self.allowlist_full setObject:self.allowlist_electron forKey:@"allowlist_electron"];
    
    //dbg msg
    os_log_error(log_handle, "'%s' loaded allowlist: %@", __PRETTY_FUNCTION__, self.allowlist_full);

    //happy
    loaded = YES;
    
bail:
    
    return loaded;
}

//save to disk
-(BOOL)save
{
    //save
    return [self.allowlist_full writeToFile:[DIR_PATH_ES stringByAppendingPathComponent:ALLOWLIST_FILE] atomically:YES];
}

@end
