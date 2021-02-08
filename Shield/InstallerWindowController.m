//
//  InstallerWindowController.m
//  Shield
//
//  Created by csaby on 2021. 02. 08..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import "InstallerWindowController.h"

@interface InstallerWindowController ()

@end

@implementation InstallerWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.label_message setStringValue:self.message];
    [self.image_instruction setImage:[NSImage imageNamed:self.image_name]];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
