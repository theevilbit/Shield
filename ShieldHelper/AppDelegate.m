//
//  AppDelegate.m
//  ShieldHelper
//
//  Created by csaby on 2020. 06. 27..
//  Copyright © 2020. csaba.fitzl. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate


//souce: http://martiancraft.com/blog/2015/01/login-items/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    
    //check if main app is running
    NSString* mainBundleID = @"com.csaba.fitzl.shield";

    //lookup under running apps
    NSArray<NSRunningApplication *> *runningMainApp = [NSRunningApplication runningApplicationsWithBundleIdentifier:mainBundleID];
    //running app not found
    if (runningMainApp == nil || [runningMainApp count] == 0) {
        //launch app
        NSArray *pathComponents = [[[NSBundle mainBundle] bundlePath] pathComponents];
        /*
         The tricky part is to delete the last four path components of the helper app bundle path. It is because the helper app is actually embedded inside the main app bundle, under the subdirectory Contents/Library/LoginItems. So including the helper app name there will be a total of 4 path components to be deleted.
         https://medium.com/@hoishing/adding-login-items-for-macos-7d76458f6495
         */
        pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 4)];
        NSString *path = [NSString pathWithComponents:pathComponents];
        [[NSWorkspace sharedWorkspace] launchApplication:path];
        //[NSApp terminate:nil];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
