//
//  AllowList.h
//  Shield System Extension
//
//  Created by csaby on 2021. 02. 06..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#ifndef AllowList_h
#define AllowList_h


#endif /* AllowList_h */

#import <Foundation/Foundation.h>

@interface AllowList : NSObject

/* PROPERTIES */

//allowlist for various injections
@property(nonatomic, retain)NSMutableArray* allowlist_task_for_pid;
@property(nonatomic, retain)NSMutableArray* allowlist_dylib;
@property(nonatomic, retain)NSMutableArray* allowlist_envvars;
@property(nonatomic, retain)NSMutableArray* allowlist_electron;
@property(nonatomic, retain)NSMutableDictionary* allowlist_full;

/* METHODS */

//load/save prefs from disk
-(BOOL)load;
-(BOOL)save;

@end
