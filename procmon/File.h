// source: https://raw.githubusercontent.com/objective-see/FileMonitor/master/Library/Source/FileMonitor.h

#import <Foundation/Foundation.h>
#import <EndpointSecurity/EndpointSecurity.h>
#import "Process.h"

/* CLASSES */
@class File;

/* OBJECT: FILE */

@interface File : NSObject

/* PROPERTIES */

//event
// create, write, etc...
@property u_int32_t event;

//timestamp
@property(nonatomic, retain)NSDate* _Nonnull timestamp;

//src path
@property(nonatomic, retain)NSString* _Nullable sourcePath;

//dest path
@property(nonatomic, retain)NSString* _Nullable destinationPath;

//process
@property(nonatomic, retain)Process* _Nullable process;

/* METHODS */

//init
-(id _Nullable)init:(es_message_t* _Nonnull)message csOption:(NSUInteger)csOption;

@end
