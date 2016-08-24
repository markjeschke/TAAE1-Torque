//
//  AppDelegate.h
//  TAAE1-Torque
//
//  Created by Mark Jeschke on 8/23/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// Public access to the audioController engine
@property (strong, nonatomic) AudioController *audioController;

@end

