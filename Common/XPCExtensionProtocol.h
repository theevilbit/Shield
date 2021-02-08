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
-(void)get_allowlist:(void (^)(NSDictionary *))reply;
-(void)update_preferences:(NSDictionary *)prefs reply:(void (^)(BOOL))reply;
-(void)update_allowlist:(NSMutableDictionary *)al reply:(void (^)(BOOL))reply;

@end
