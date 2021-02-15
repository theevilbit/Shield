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

//allowlist
@property(nonatomic, retain)NSMutableDictionary* allowlist_full;
@property(nonatomic, retain)NSMutableArray* allowlist_items;

/* METHODS */

//load/save prefs from disk
-(BOOL)load;
-(BOOL)save;
-(BOOL)init_file;

//check if item in allowlist
-(BOOL)is_item_in_allowlist:(NSDictionary*)item;

//manage allowlist
-(BOOL)add_item_to_allowlist:(NSDictionary*)item;

-(BOOL)remove_item_from_allowlist:(NSDictionary*)item;

-(NSDictionary*) get_allowlist;

-(BOOL)clear_allowlist;

@end
