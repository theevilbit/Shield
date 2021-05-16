//
//  Process.h
//  Shield System Extension
//
//  Created by csaby on 2021. 05. 15..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

/* CONSTS */

//code signing keys
#define KEY_SIGNATURE_FLAGS @"csFlags"
#define KEY_SIGNATURE_STATUS @"signatureStatus"
#define KEY_SIGNATURE_SIGNER @"signatureSigner"
#define KEY_SIGNATURE_IDENTIFIER @"signatureID"
#define KEY_SIGNATURE_TEAM_IDENTIFIER @"teamID"
#define KEY_SIGNATURE_AUTHORITIES @"signatureAuthorities"

//code sign options
enum csOptions{csNone, csStatic, csDynamic};

//signers
enum Signer{None, Apple, AppStore, DevID, AdHoc};

//cs options
#define CS_STATIC_CHECK YES
#define CS_CDHASH_LEN 20

//architectures
enum Architectures{ArchUnknown, ArchAppleSilicon, ArchIntel};




/* CLASSES */
@class Process;

/* OBJECT: PROCESS */

@interface Process : NSObject

/* PROPERTIES */

//the original message
@property es_message_t* _Nonnull p_message;

//pid
@property pid_t pid;

//ppid
@property pid_t ppid;

//target process pid
@property pid_t target_pid;

//user id
@property uid_t uid;

//event
// exec, fork, exit
@property u_int32_t event;

//exit code
@property int exit;

//path
@property(nonatomic, retain)NSString* _Nullable path;

//args
@property(nonatomic, retain)NSMutableArray* _Nonnull arguments;

//environment variables
@property(nonatomic, retain)NSMutableArray* _Nonnull env;

//ancestors
@property(nonatomic, retain)NSMutableArray* _Nonnull ancestors;

//platform binary
@property(nonatomic, retain)NSNumber* _Nonnull isPlatformBinary;

//csflags
@property(nonatomic, retain)NSNumber* _Nonnull csFlags;

//cd hash
@property(nonatomic, retain)NSMutableString* _Nonnull cdHash;

//signing ID
@property(nonatomic, retain)NSString* _Nonnull signingID;

//team ID
@property(nonatomic, retain)NSString* _Nonnull teamID;

//signing info
// manually generated via CS APIs if `codesign:TRUE` is set
@property(nonatomic, retain)NSMutableDictionary* _Nonnull signingInfo;

//timestamp
@property(nonatomic, retain)NSDate* _Nonnull timestamp;

/* METHODS */

//init
// flag controls code signing options
-(id _Nullable)init:(es_message_t* _Nonnull)message csOption:(NSUInteger)csOption;
//-(BOOL)alerting;
@end
