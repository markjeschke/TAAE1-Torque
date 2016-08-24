//
//  AudioController.h
//  TAAE1-Torque
//
//  Created by Mark Jeschke on 8/23/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import <Foundation/Foundation.h>

// Import The Amazing Audio Engine via CocoaPods: http://theamazingaudioengine.com/
#import "TheAmazingAudioEngine.h"

// Import the available effects filters
#import "AEBandpassFilter.h"
#import "AEDelayFilter.h"
#import "AEDistortionFilter.h"
#import "AEDynamicsProcessorFilter.h"
#import "AEExpanderFilter.h"
#import "AEHighPassFilter.h"
#import "AEHighShelfFilter.h"
#import "AELimiterFilter.h"
#import "AELowPassFilter.h"
#import "AELowShelfFilter.h"
#import "AENewTimePitchFilter.h"
#import "AEParametricEqFilter.h"
#import "AEPeakLimiterFilter.h"
#import "AEReverbFilter.h"
#import "AEVarispeedFilter.h"

@interface AudioController : NSObject

// Public methods for ViewControllers to access.

// Start/stop the audio engine
- (void)startEngine;
- (void)stopEngine;

- (void)backgroundAudioPlayPauseButtonPressed;

// Get the timecode and duration in seconds
- (NSString *)getCurrentTimecode;
- (NSString *)getDurationTimecode;

// Access varispeed playbackCents parameter for audio slow-down effect
@property (nonatomic) double varispeedPlaybackCents;

// Access delay wet/dry mix between 0-100%.
@property (nonatomic) double delayWetDryMix;

// Access backgroundAudioLoop's AudioFilePlayer properties
@property (nonatomic) double backgroundAudioLoopVolume;
@property (nonatomic) double backgroundAudioLoopChannelIsMuted;
@property (nonatomic) double backgroundAudioLoopChannelIsPlaying;
@property (nonatomic) double backgroundAudioLoopCurrentTime;
@property (nonatomic) double backgroundAudioLoopPan;

@end
