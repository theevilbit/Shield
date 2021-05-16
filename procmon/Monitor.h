//
//  ProcessMonitor.h
//  ProcessMonitor
//
//  Created by Patrick Wardle on 9/1/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>
#import "Process.h"
#import "File.h"

/* TYPEDEFS */

//block for library
typedef void (^ESProcessCallbackBlock)(Process* _Nonnull, es_client_t* _Nonnull, es_message_t* _Nonnull);

typedef void (^ESFileCallbackBlock)(File* _Nonnull, es_client_t* _Nonnull, es_message_t* _Nonnull);

@interface Monitor : NSObject

//start monitoring
// pass in events of interest, count of said events, flag for codesigning, and callback
-(es_new_client_result_t)start:(es_event_type_t* _Nonnull)events count:(uint32_t)count csOption:(NSUInteger)csOption callbackProcess:(ESProcessCallbackBlock _Nonnull)callbackProcess callbackFile:(ESFileCallbackBlock _Nonnull)callbackFile;

//stop monitoring
-(BOOL)stop;

@end

