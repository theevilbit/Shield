//
//  XPCExtensionProtocol.h
//  ShieldProject
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#ifndef XPCExtensionProtocol_h
#define XPCExtensionProtocol_h


#endif /* XPCExtensionProtocol_h */

#import <EndpointSecurity/EndpointSecurity.h>


@protocol XPCExtensionProtocol

//start ES client
-(void)startWithReply:(void (^)(es_new_client_result_t))reply;
//stop ES client
-(void)stopWithReply:(void (^)(BOOL))reply;


-(void)getStatus:(void (^)(NSDictionary *))reply;
-(void)update_preferences:(NSDictionary *)prefs reply:(void (^)(BOOL))reply;

//allowlist operation
-(void)add_item_to_allowlist:(NSDictionary *)al reply:(void (^)(BOOL))reply;
-(void)remove_item_from_allowlist:(NSDictionary *)al reply:(void (^)(BOOL))reply;
-(void)clear_allowlist:(void (^)(BOOL))reply;
-(void)get_allowlist:(void (^)(NSArray *))reply;

//clear cache - to reset state if somethign was blocked but the user allows it
-(void)clear_cache;

@end
