//
//  XPCExtensionClient.h
//  Shield
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#ifndef XPCExtensionClient_h
#define XPCExtensionClient_h


#endif /* XPCExtensionClient_h */

@import OSLog;
@import Foundation;

#import "XPCExtensionProtocol.h"

@interface XPCExtensionClient : NSObject
{
}

/* PROPERTIES */

//xpc connection to extension
@property (atomic, strong, readwrite)NSXPCConnection* extension;
    
//start ES client
-(es_new_client_result_t)start;

//stop ES client
-(BOOL)stop;
-(NSDictionary*)getStatus;
-(NSDictionary*)get_allowlist;
-(BOOL)update_preferences:(NSDictionary *)prefs;
-(BOOL)update_allowlist:(NSMutableDictionary *)wl;


@end
