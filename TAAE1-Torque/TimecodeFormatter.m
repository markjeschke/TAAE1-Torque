//
//  TimecodeFormatter.h
//  DrumsAUSampler
//
//  Created by Mark Jeschke on 7/18/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import "TimecodeFormatter.h"

@implementation TimecodeFormatter

- (NSString *)timeFormatted:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

@end
