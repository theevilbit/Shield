// source: https://raw.githubusercontent.com/objective-see/FileMonitor/master/Library/Source/File.m
//  File.m
//  FileMonitor
//
//  Created by Patrick Wardle on 9/1/19.
//  Copyright © 2020 Objective-See. All rights reserved.
//

#import <libproc.h>
#import <bsm/libbsm.h>
#import <sys/sysctl.h>

#import "utilities.h"
#import "File.h"
#import "Process.h"

/* GLOBALS */

//process cache
extern NSCache* processCache;

/* FUNCTIONS */

@implementation File

@synthesize process;
@synthesize timestamp;
@synthesize sourcePath;
@synthesize destinationPath;

//init
-(id)init:(es_message_t*)message csOption:(NSUInteger)csOption
{
    //process audit token
    NSData* auditToken = nil;
    
    //init super
    self = [super init];
    if(nil != self)
    {
        //set type
        self.event = message->event_type;
        
        //set timestamp
        self.timestamp = [NSDate date];
        
        //sync for process creation
        @synchronized (processCache) {
            
            //init audit token
            auditToken = [NSData dataWithBytes:&message->process->audit_token length:sizeof(audit_token_t)];
            
            //check cache for process
            // not found? create process obj...
            self.process = [processCache objectForKey:auditToken];
            if(nil == self.process)
            {
                //create process
                self.process = [[Process alloc] init:message csOption:csOption];
            }
    
            //sanity check
            // process creation failed?
            if(nil == process)
            {
                //unset
                self = nil;
            
                //bail
                goto bail;
            }
            
            //add to cache
            [processCache setObject:process forKey:auditToken];
        }
        
        //extract file path(s)
        // logic is specific to event
        [self extractPaths:message];
    }
    
bail:
    
    return self;
}

//extract source & destination path
// this requires event specific logic
-(void)extractPaths:(es_message_t*)message
{
    //event specific logic
    switch (message->event_type) {
        
        //create
        case ES_EVENT_TYPE_AUTH_CREATE:
        case ES_EVENT_TYPE_NOTIFY_CREATE:
        {
            //directory
            NSString* directory = nil;
            
            //file name
            NSString* fileName = nil;
            
            //existing file?
            // grab file path
            if(ES_DESTINATION_TYPE_EXISTING_FILE == message->event.create.destination_type)
            {
                //set path
                self.destinationPath = convertStringToken(&message->event.create.destination.existing_file->path);
            }
            //new file
            // build file path from directory + name
            else
            {
                //extract directory
                directory = convertStringToken(&message->event.create.destination.new_path.dir->path);
                
                //extact file name
                fileName = convertStringToken(&message->event.create.destination.new_path.filename);
                
                //combine
                self.destinationPath = [directory stringByAppendingPathComponent:fileName];
            }
            
            break;
        }
            
        //open
        case ES_EVENT_TYPE_AUTH_OPEN:
        case ES_EVENT_TYPE_NOTIFY_OPEN:
            
            //set path
            self.destinationPath = convertStringToken(&message->event.open.file->path);
            
            break;
            
        //write
        case ES_EVENT_TYPE_NOTIFY_WRITE:
            
            //set path
            self.destinationPath = convertStringToken(&message->event.write.target->path);
            
            break;
            
        //close
        case ES_EVENT_TYPE_NOTIFY_CLOSE:
            
            //set path
            self.destinationPath = convertStringToken(&message->event.close.target->path);
            
            break;
            
        //link
        case ES_EVENT_TYPE_AUTH_LINK:
        case ES_EVENT_TYPE_NOTIFY_LINK:

            //set (src) path
            self.sourcePath = convertStringToken(&message->event.link.source->path);
            
            //set (dest) path
            // combine dest dir + dest file
            self.destinationPath = [convertStringToken(&message->event.link.target_dir->path) stringByAppendingPathComponent:convertStringToken(&message->event.link.target_filename)];
            
            break;
            
        //rename
        case ES_EVENT_TYPE_AUTH_RENAME:
        case ES_EVENT_TYPE_NOTIFY_RENAME:

            //set (src) path
            self.sourcePath = convertStringToken(&message->event.rename.source->path);
            
            //existing file ('ES_DESTINATION_TYPE_EXISTING_FILE')
            if(ES_DESTINATION_TYPE_EXISTING_FILE == message->event.rename.destination_type)
            {
                //set (dest) file
                self.destinationPath = convertStringToken(&message->event.rename.destination.existing_file->path);
            }
            //new path ('ES_DESTINATION_TYPE_NEW_PATH')
            else
            {
                //set (dest) path
                // combine dest dir + dest file
                self.destinationPath = [convertStringToken(&message->event.rename.destination.new_path.dir->path) stringByAppendingPathComponent:convertStringToken(&message->event.rename.destination.new_path.filename)];
            }
            
            break;
            
        //unlink
        case ES_EVENT_TYPE_AUTH_UNLINK:
        case ES_EVENT_TYPE_NOTIFY_UNLINK:

            //set path
            self.destinationPath = convertStringToken(&message->event.unlink.target->path);
                
            break;
            
        //mount
        case ES_EVENT_TYPE_AUTH_MOUNT:
        case ES_EVENT_TYPE_NOTIFY_MOUNT:

            //set path
            self.destinationPath = [[NSString alloc] initWithBytes:&message->event.mount.statfs->f_mntonname length:strlen(&message->event.mount.statfs->f_mntonname) encoding:NSUTF8StringEncoding];
                
            break;
            

        default:
            break;
    }
    
    return;
}

@end
