//
//  TimecodeFormatter.h
//  DrumsAUSampler
//
//  Created by Mark Jeschke on 7/18/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimecodeFormatter : NSObject

- (NSString *)timeFormatted:(int)totalSeconds;

@end
