//original:
//https://raw.githubusercontent.com/objective-see/LuLu/master/LuLu/Extension/XPCUserClient.h

//  XPCClient.h
//  Shield System Extension
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//


@import OSLog;
@import Foundation;

#import "XPCAppProtocol.h"
#import "Constants.h"
#import "XPCListener.h"

@interface XPCAppClient : NSObject
{
    
}

-(BOOL)send:(NSDictionary*)notification blocked:(BOOL)blockStatus;


@end
