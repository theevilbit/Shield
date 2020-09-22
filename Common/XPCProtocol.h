//
//  XPCProtocol.h
//  ShieldProject
//
//  Created by csaby on 2020. 06. 08..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#ifndef XPCProtocol_h
#define XPCProtocol_h
@protocol ProviderCommunication

//start ES client
-(void)startWithReply:(void (^)(BOOL))reply;
//stop ES client
-(void)stopWithReply:(void (^)(BOOL))reply;
//register ES client
-(void)registerWithReply:(void (^)(BOOL))reply;
-(void)getStatus:(void (^)(NSDictionary *))reply;
-(void)updatePrefs:(NSDictionary *)prefs;

@end

@protocol AppCommunication
//notify app
-(void)notify:(NSString *)notification blocked:(BOOL)blockStatus;
@end


#endif /* XPCProtocol_h */
