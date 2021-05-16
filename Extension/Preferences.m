//
//  Preferences.m
//  Shield System Extension
//
//  Created by csaby on 2020. 06. 11..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#import "Preferences.h"
#import "../Common/Constants.h"
#import "../Common/logging.h"

@import OSLog;

/* GLOBALS */
extern os_log_t log_handle;


@implementation Preferences

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
            os_log_error(log_handle, "failed to loads preferences from %@", PREFS_FILE);
            
            //unset
            //self = nil;
            [self initPrefFile];
            //bail
            goto bail;
        }
    }
    
bail:
    
    return self;
}

//initialize a pref file
-(BOOL)initPrefFile {
    BOOL isDir = NO;
    BOOL isDirExists = [[NSFileManager defaultManager] fileExistsAtPath:DIR_PATH_ES isDirectory:&isDir];
    if (isDirExists == NO) {
        NSError * error = nil;

        [[NSFileManager defaultManager] createDirectoryAtPath:DIR_PATH_ES
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error != nil) {
            os_log_error(log_handle, "Preferences: Error creating directory: %@", error);
            goto bail;
        }
    }

    BOOL reset_successful = [self reset];
    
    return reset_successful;
    bail:
        return NO;
}

-(BOOL)reset {
    self.preferences = [NSMutableDictionary new];
    self.preferences[@"version"] = @2;
    self.preferences[PREF_ELECTRON] = @YES;
    self.preferences[PREF_ENVVARS] = @YES;
    self.preferences[PREF_TFP] = @YES;
    self.preferences[PREF_DYLIB] = @YES;
    self.preferences[PREF_FILELINK_HARD] = @YES;
    self.preferences[PREF_FILELINK_SYMBOLIC] = @YES;
    self.preferences[PREF_SELFPROTECTION] = @NO;

    self.preferences[PREF_SKIPAPPLE] = @YES;
    self.preferences[PREF_ISBLOCKING] = @NO;
    self.preferences[PREF_ISLEARNING] = @NO;
    self.preferences[PREF_ISRUNNING] = @NO;

    BOOL saved = [self save];
    if(saved == NO) {
        os_log_error(log_handle, "Preferences: Error saving preferences");
    }
    
    return saved;
}

//load prefs from disk
-(BOOL)load
{
    //flag
    BOOL loaded = NO;
    
    //version
    NSNumber* pref_version = nil;
    
    //load
    self.preferences = [NSMutableDictionary dictionaryWithContentsOfFile:[DIR_PATH_ES stringByAppendingPathComponent:PREFS_FILE]];
    if(nil == self.preferences)
    {
        //bail
        goto bail;
    }
    
    //reset preferences if older version is found
    //1.0.1 didn't support versioning, so only checking if the key exists
    pref_version = self.preferences[@"version"];
    if (pref_version == nil) {
        BOOL reset_successful = [self reset];
        if(reset_successful == NO) {
            goto bail;
        }
    }
    
    //dbg msg
    os_log_debug(log_handle, "loaded preferences: %@", self.preferences);

    //happy
    loaded = YES;
    
bail:
    
    return loaded;
}

//save to disk
-(BOOL)save
{
    //save
    return [self.preferences writeToFile:[DIR_PATH_ES stringByAppendingPathComponent:PREFS_FILE] atomically:YES];
}

@end
