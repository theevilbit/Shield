//
//  XPCAppProtocol.h
//  ShieldProject
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#ifndef XPCAppProtocol_h
#define XPCAppProtocol_h


#endif /* XPCAppProtocol_h */

#import <Foundation/Foundation.h>

@protocol XPCAppProtocol
//notify app
-(void)notify:(NSDictionary*)notification blocked:(BOOL)blockStatus reply:(void (^)(NSDictionary*))reply;

@end
