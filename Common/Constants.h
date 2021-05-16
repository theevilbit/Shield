//
//  Constants.h
//  ShieldProject
//
//  Created by csaby on 2020. 06. 11..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#define TEAM_ID     @"33YRLYRBYV"
#define MAIN_APP_ID @"com.csaba.fitzl.shield"
#define BUNDLE_ID "com.csaba.fitzl.shield"
#define HELPER_BUNDLE_ID @"com.csaba.fitzl.shield.ShieldHelper"
#define APP_NAME @"Shield.app"

#define PREFS_FILE  @"com.csaba.fitzl.shield.preferences.plist"
#define ALLOWLIST_FILE @"com.csaba.fitzl.shield.allowlist.plist"
#define LOG_FILE_NAME    @"shield.log"
#define DIR_PATH_ES  @"/Library/Application Support/Shield"
#define MACH_SERVICE @"33YRLYRBYV.com.csaba.fitzl.shield.Extension.xpc"

//preferences strings

#define PREF_ELECTRON @"pref_electron_debug"
#define PREF_ENVVARS @"pref_env_vars"
#define PREF_TFP @"pref_taskforpid"
#define PREF_DYLIB @"pref_dylib"
#define PREF_SKIPAPPLE @"skip_apple"
#define PREF_ISBLOCKING @"is_blocking"
#define PREF_ISLEARNING @"is_learning"
#define PREF_ISRUNNING @"is_running"
#define PREF_SELFPROTECTION @"pref_selfprotection"
#define PREF_FILELINK_SYMBOLIC @"pref_filelink_symbolic"
#define PREF_FILELINK_HARD @"pref_filelink_hard"

//define attack types
#define ATTACK_INJECTION @0
#define ATTACK_FILELINKS @1

//notification strings
#define NOTIFICATION_ATTACK_TYPE @"attack_type"
#define NOTIFICATION_TYPE @"type"
#define NOTIFICATION_ID @"id"
#define NOTIFICATION_VICTIM_PATH @"victim_path"
#define NOTIFICATION_ATTACKER_PATH @"attacker_path"
#define NOTIFICATION_DYLIB_PATH @"dylib_path"
#define NOTIFICATION_ENV @"env"
#define NOTIFICATION_ARGUMENTS @"arguments"

//notification strings for symlink/hardlink detection
#define NOTIFICATION_LINK_TYPE @"type"
#define NOTIFICATION_LINK_PROCESS_PATH @"process_path"
#define NOTIFICATION_LINK_SOURCE_PATH @"source_path"
#define NOTIFICATION_LINK_DESTINATION_PATH @"destination_path"
#define NOTIFICATION_LINK_FILE_UID @"file_uid"
#define NOTIFICATION_LINK_PROCESS_UID @"process_uid"


#define CS_VALID 0x00000001
#define CS_RUNTIME 0x00010000
#define CS_REQUIRE_LV               0x00002000

#endif /* Constants_h */
