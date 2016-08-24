//
//  AppDelegate.m
//  TAAE1-Torque
//
//  Created by Mark Jeschke on 8/23/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Instantiate the audioController object.
    self.audioController = [[AudioController alloc] init];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.audioController stopEngine];
}

@end
