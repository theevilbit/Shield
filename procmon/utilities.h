//
//  utilities.h
//  ProcessMonitor
//
//  Created by Patrick Wardle on 9/1/19.
//  Copyright © 2019 Objective-See. All rights reserved.
//

#ifndef utilities_h
#define utilities_h

#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>
#import "../Common/logging.h"

//return the first existing path
NSString* existing_path(NSString *path);
NSNumber* get_file_uid(NSString *path);

//convert es_string_token_t to string
NSString* convertStringToken(es_string_token_t* stringToken);
NSString* getProcessPath(pid_t pid);

#endif /* utilities_h */
