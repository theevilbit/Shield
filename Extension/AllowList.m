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
            [self load];
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
    self.allowlist_full[@"version"] = @"1.0";
    
    BOOL saved = [self save];
    if(saved == NO) {
        os_log_error(log_handle, "'%s' Error saving allow list",__PRETTY_FUNCTION__);

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
    
    //check if version is set, if not, we will create a new file, as the one without version was introduced in 0.9.5
    if(self.allowlist_full[@"version"] == nil) {
        //bail
        goto bail;
    }
    
    //create a mutable copy of the loaded NSArray
    self.allowlist_items = [self.allowlist_full[@"items"] mutableCopy];
    
    if (self.allowlist_items == nil) {
        self.allowlist_items = [NSMutableArray new];
    }

    //replace NSDictionary in dictionary to the previosuly created NSMutableDictionaries
    [self.allowlist_full setObject:self.allowlist_items forKey:@"items"];
    
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

//check for entries
-(BOOL)is_item_in_allowlist:(NSDictionary*)item {
    
    os_log_debug(log_handle, "Checking allowlist %s", __PRETTY_FUNCTION__);
    
    BOOL found = NO;
    //iterate over the array
    for (NSDictionary* element in self.allowlist_items) {
        //compare, normal isequaltodictionary doesn't work
        if([item[NOTIFICATION_TYPE] isEqualToString:element[NOTIFICATION_TYPE]] &&
           [item[NOTIFICATION_ATTACKER_PATH] isEqualToString:element[NOTIFICATION_ATTACKER_PATH]] &&
           [item[NOTIFICATION_VICTIM_PATH] isEqualToString:element[NOTIFICATION_VICTIM_PATH]] &&
           [item[NOTIFICATION_ENV] isEqualToString:element[NOTIFICATION_ENV]] &&
           [item[NOTIFICATION_ARGUMENTS] isEqualToString:element[NOTIFICATION_ARGUMENTS]] &&
           [item[NOTIFICATION_DYLIB_PATH] isEqualToString:element[NOTIFICATION_DYLIB_PATH]]) {
            found = YES;
            break;
        }
    }

    return found;
}

//add entry
-(BOOL)add_item_to_allowlist:(NSDictionary*)item {

    os_log_debug(log_handle, "Adding entry to allowlist %@ %s", item, __PRETTY_FUNCTION__);
    item = [self get_id_free_item:item];
    
    [self.allowlist_items addObject:item];
    
    return [self save];
}

//check for entries
-(BOOL)remove_item_from_allowlist:(NSDictionary*)item {
    
    //iterate over the array
    item = [self get_id_free_item:item];
    
    for (id element in self.allowlist_items) {
        //compare
        if([item isEqualToDictionary:element]) {
            [self.allowlist_items removeObject:element];
            break;
        }
    }
    
    return [self save];
}

-(NSDictionary*)get_allowlist {
    return [self.allowlist_items copy];
}

-(BOOL)clear_allowlist {
    [self init_file];
    return [self load];
}

-(NSDictionary* )get_id_free_item:(NSDictionary *)item {
    NSMutableDictionary* element = [item mutableCopy];
    [element removeObjectForKey:@"id"];
    return [element copy];
}

@end
