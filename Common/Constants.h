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

#define PREF_ELECTRON @"prefElectron"
#define PREF_ENVVARS @"prefEnvVars"
#define PREF_TFP @"prefTFP"
#define PREF_DYLIB @"prefDylib"
#define PREF_SKIPAPPLE @"skipApple"
#define PREF_ISBLOCKING @"isBlocking"
#define PREF_ISLEARNING @"isLearning"
#define PREF_ISRUNNING @"isRunning"

//notification strings
#define NOTIFICATION_TYPE @"type"
#define NOTIFICATION_ID @"id"
#define NOTIFICATION_VICTIM_PATH @"victim_path"
#define NOTIFICATION_ATTACKER_PATH @"attacker_path"
#define NOTIFICATION_DYLIB_PATH @"dylib_path"
#define NOTIFICATION_ENV @"env"
#define NOTIFICATION_ARGUMENTS @"arguments"

#define CS_VALID 0x00000001
#define CS_RUNTIME 0x00010000
#define CS_REQUIRE_LV               0x00002000

#endif /* Constants_h */
