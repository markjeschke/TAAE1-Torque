//
//  AudioManager.h
//  DrumsAUSampler
//
//  Created by Mark Jeschke on 7/18/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import <Foundation/Foundation.h>

// Import The Amazing Audio Engine
#import "TheAmazingAudioEngine.h"

// Import effects filters
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

// Public methods for other ViewControllers to access.

// Start/stop the audio engine
- (void)startEngine;
- (void)stopEngine;

// Triggering the AUSampler/MIDI event sounds
- (void)playKickSound;
- (void)playSnareSound;
- (void)playClosedHiHatSound;
- (void)playOpenHiHatSound;

- (void)backgroundAudioPlayPauseButtonPressed;

- (NSString *)getCurrentTimecode;
- (NSString *)getDurationTimecode;

// Access Varispeed playbackCents parameter
@property (nonatomic) double varispeedPlaybackCents;

// Access backgroundAudioLoop's AudioFilePlayer properties
@property (nonatomic) double backgroundAudioLoopVolume;
@property (nonatomic) double backgroundAudioLoopChannelIsMuted;
@property (nonatomic) double backgroundAudioLoopChannelIsPlaying;
@property (nonatomic) double backgroundAudioLoopCurrentTime;
@property (nonatomic) double backgroundAudioLoopPan;

@property (nonatomic) double delayWetDryMix;

@end
