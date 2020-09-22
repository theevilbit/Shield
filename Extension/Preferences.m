//
//  Preferences.m
//  Shield System Extension
//
//  Created by csaby on 2020. 06. 11..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Preferences.h"
#import "../Common/Constants.h"
#import "../Common/logging.h"

/* GLOBALS */

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
            logMsg(LOG_TO_FILE|LOG_ERR, [NSString stringWithFormat:@"failed to loads preferences from %@", PREFS_FILE]);
            
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
            logMsg(LOG_TO_FILE|LOG_ERR, [NSString stringWithFormat:@"Preferences: Error creating directory: %@", error]);
            goto bail;
        }
    }
    self.preferences = [NSMutableDictionary new];
    BOOL saved = [self save];
    if(saved == NO) {
        logMsg(LOG_TO_FILE|LOG_ERR, @"Preferences: Error saving preferences");
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
    self.preferences = [NSMutableDictionary dictionaryWithContentsOfFile:[DIR_PATH_ES stringByAppendingPathComponent:PREFS_FILE]];
    if(nil == self.preferences)
    {
        //bail
        goto bail;
    }
    
    //dbg msg
    logMsg(LOG_TO_FILE|LOG_DEBUG, [NSString stringWithFormat:@"loaded preferences: %@", self.preferences]);
    
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
