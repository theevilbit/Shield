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
-(BOOL)update_preferences:(NSDictionary *)prefs;

//allowlist operation
-(BOOL)add_item_to_allowlist:(NSDictionary *)al;
-(BOOL)remove_item_from_allowlist:(NSDictionary *)al;
-(NSArray*)get_allowlist;
-(BOOL)clear_allowlist;

//clear cache - to reset state if somethign was blocked but the user allows it
-(void)clear_cache;

@end
