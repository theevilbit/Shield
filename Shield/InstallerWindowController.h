//
//  InstallerWindowController.h
//  Shield
//
//  Created by csaby on 2021. 02. 08..
//  Copyright © 2021. csaba.fitzl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface InstallerWindowController : NSWindowController
@property (weak) IBOutlet NSTextField *label_message;
@property (weak) IBOutlet NSImageView *image_instruction;
@property NSString* message;
@property NSString* image_name;

@end

NS_ASSUME_NONNULL_END
