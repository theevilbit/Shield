//original: https://raw.githubusercontent.com/objective-see/LuLu/master/LuLu/Extension/XPCListener.h

//
//  XPCListener.h
//  Shield System Extension
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//


#import "XPCExtensionProtocol.h"

//function def
OSStatus SecTaskValidateForRequirement(SecTaskRef task, CFStringRef requirement);

@interface XPCListener : NSObject <NSXPCListenerDelegate>
{
    
}

/* PROPERTIES */

//XPC listener
@property(nonatomic, retain)NSXPCListener* listener;

//XPC connection for login item
@property(weak)NSXPCConnection* client;

@end
