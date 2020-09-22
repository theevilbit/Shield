//
//  Preferences.h
//  Shield System Extension
//
//  Created by csaby on 2020. 06. 11..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#ifndef Preferences_h
#define Preferences_h

//
//  Preferences.h
//  Daemon
//
//  Created by Patrick Wardle on 2/22/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Preferences : NSObject

/* PROPERTIES */

//preferences
@property(nonatomic, retain)NSMutableDictionary* preferences;

/* METHODS */

//load/save prefs from disk
-(BOOL)load;
-(BOOL)save;

@end
#endif /* Preferences_h */
