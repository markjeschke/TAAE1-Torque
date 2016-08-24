//
//  AudioController.m
//  TAAE1-Torque
//
//  Created by Mark Jeschke on 8/23/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//s

#import "AudioController.h"
#import <AVFoundation/AVFoundation.h>
#import "TimecodeFormatter.h"

#define Check(status) { OSStatus result = (status); if (result != noErr) [NSException raise:@"DrumsAUSampler" format:@"status = %d", (int)result]; }

@interface AudioController () {
    AEChannelGroupRef _backgroundAudioGroup;
}

// Audio engine
@property (strong, nonatomic) AEAudioController *audioController;

// Create the background audio loop
@property (nonatomic, strong) AEAudioFilePlayer * backgroundAudioLoop;

@property (nonatomic, strong) AEAudioFilePlayer * effectTail;

// Path to the sound folder
@property (nonatomic, assign) NSString *samplesFolderPath;

@property (nonatomic, strong, readwrite) AENewTimePitchFilter * newtimepitch;
@property (nonatomic, strong, readwrite) AEBandpassFilter * bandpass;
@property (nonatomic, strong, readwrite) AEDelayFilter * delay;
@property (nonatomic, strong, readwrite) AEDistortionFilter * distortion;
@property (nonatomic, strong, readwrite) AEExpanderFilter * expander;
@property (nonatomic, strong, readwrite) AEHighPassFilter * highpass;
@property (nonatomic, strong, readwrite) AEHighShelfFilter * highshelf;
@property (nonatomic, strong, readwrite) AELimiterFilter * limiter;
@property (nonatomic, strong, readwrite) AELowPassFilter * lowpass;
@property (nonatomic, strong, readwrite) AELowShelfFilter * lowshelf;
@property (nonatomic, strong, readwrite) AEParametricEqFilter * parametriceq;
@property (nonatomic, strong, readwrite) AEPeakLimiterFilter * peaklimiter;
@property (nonatomic, strong, readwrite) AEReverbFilter * reverb;
@property (nonatomic, strong, readwrite) AEVarispeedFilter * varispeed;

@property (nonatomic) TimecodeFormatter *timecodeFormatter;

@end

@implementation AudioController

#pragma mark -
#pragma mark === Setters for Public Access Updates from ViewController ===
#pragma mark

-(void)setVarispeedPlaybackCents:(double)varispeedPlaybackCents {
    _varispeedPlaybackCents = varispeedPlaybackCents;
    self.varispeed.playbackCents = varispeedPlaybackCents;
}

-(void)setBackgroundAudioLoopVolume:(double)backgroundAudioLoopVolume {
    _backgroundAudioLoopVolume = backgroundAudioLoopVolume;
    self.backgroundAudioLoop.volume = backgroundAudioLoopVolume;
    NSLog(@"self.backgroundAudioLoop.volume: %f", self.backgroundAudioLoop.volume);
}

-(void)setBackgroundAudioLoopChannelIsMuted:(double)backgroundAudioLoopChannelIsMuted {
    _backgroundAudioLoopChannelIsMuted = backgroundAudioLoopChannelIsMuted;
    self.backgroundAudioLoop.channelIsMuted = backgroundAudioLoopChannelIsMuted;
}

-(void)setBackgroundAudioLoopChannelIsPlaying:(double)backgroundAudioLoopChannelIsPlaying {
    _backgroundAudioLoopChannelIsPlaying = backgroundAudioLoopChannelIsPlaying;
    self.backgroundAudioLoop.channelIsPlaying = backgroundAudioLoopChannelIsPlaying;
}

-(void)setBackgroundAudioLoopCurrentTime:(double)backgroundAudioLoopCurrentTime {
    _backgroundAudioLoopCurrentTime = backgroundAudioLoopCurrentTime;
    self.backgroundAudioLoop.currentTime = backgroundAudioLoopCurrentTime;
}

-(void)setBackgroundAudioLoopPan:(double)backgroundAudioLoopPan {
    _backgroundAudioLoopPan = backgroundAudioLoopPan;
    self.backgroundAudioLoop.pan = backgroundAudioLoopPan;
}

-(void)setDelayWetDryMix:(double)delayWetDryMix {
    _delayWetDryMix = delayWetDryMix;
    self.delay.wetDryMix = delayWetDryMix;
}

-(NSString *)getCurrentTimecode {
    return [_timecodeFormatter timeFormatted:_backgroundAudioLoop.currentTime];
}

-(NSString *)getDurationTimecode {
    return [_timecodeFormatter timeFormatted:_backgroundAudioLoop.duration];
}

#pragma mark -
#pragma mark === Initialize Audio Engine ===
#pragma mark

- (instancetype)init {
    if ( !(self = [super init]) ) return nil;
    
    // Create an instance of the audio controller, set it up and start it running
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:AEAudioStreamBasicDescriptionNonInterleavedFloatStereo inputEnabled:YES];
    _audioController.preferredBufferDuration = 0.005;
    _audioController.useMeasurementMode = YES;
    
    [self startEngine];
    
    _timecodeFormatter = [[TimecodeFormatter alloc] init];
    
    return self;
}

#pragma mark -
#pragma mark === Start/Stop Audio Engine ===
#pragma mark

- (void)startEngine {
    NSError *error = NULL;
    BOOL result = [_audioController start:&error];
    if ( !result ) {
        // Report error
        NSLog(@"The Amazing Audio Engine didn't start!");
    } else {
        NSLog(@"The Amazing Audio Engine started perfectly!");
        [self initializeAudioFilesFiles];
        
    }
}

- (void)stopEngine {
    [_audioController stop];
    NSLog(@"Audio engine was stopped");
}

#pragma mark -
#pragma mark === Initialize Audio Files ===
#pragma mark

- (void)initializeAudioFilesFiles {
    
    // Create AudioFilePlayer
    self.backgroundAudioLoop = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Sounds/Isolated Association" withExtension:@"m4a"] error:NULL];
    _backgroundAudioLoop.volume = 1.0;
    _backgroundAudioLoop.channelIsPlaying = NO;
    _backgroundAudioLoop.currentTime = 0;
    _backgroundAudioLoop.pan = 0.0; // <- Range is -1.0 (left) to 1.0 (right). Center is 0.0
    _backgroundAudioLoop.loop = YES;
    
    self.effectTail = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Sounds/empty" withExtension:@"m4a"] error:NULL];
    _effectTail.loop = YES;
    
    // Create a group for the backgroundAudioLoop and the effect tail.
    // The effect tail is necessary to keep the effect from getting cut off when an effect is applied to dedicated channels or groups.
    _backgroundAudioGroup = [_audioController createChannelGroup];
    [_audioController addChannels:@[_backgroundAudioLoop, _effectTail] toChannelGroup:_backgroundAudioGroup];
    
    // Apply effects filters
    [self applyFilterEffectsToChannels];
    
}

#pragma mark -
#pragma mark === Set the Effects Filters ===
#pragma mark

- (void) applyFilterEffectsToChannels {

    // Apply available effects filters to the audioController.
    
    // Feel free to remove filters that you know won't be used.
    
    // Delay
    _delay = [[AEDelayFilter alloc] init];
    //_delay.delayTime = _backgroundAudioLoop.duration/4;
    _delay.delayTime = 0.25; // <- Range: Secs, 0.0 - 2.0, 1.0 is the default
    _delay.feedback = 10.0; // <- Range: Percent, -100->100, 50 is the default
    _delay.lopassCutoff = 15000; // <- Range: Hz, 10->(SampleRate/2), 15000
    _delay.wetDryMix = 3.0; // <- Range: Percent, 0->100, 50 is the default
    _delay.bypassed = true; // <- Boolean: true or false, basically turns the effect on or off.
    
    [_audioController addFilter:_delay toChannelGroup:_backgroundAudioGroup]; // <- Add this filter only to this group channel.
    // If you omit 'toChannelGroup' or 'toChannel' arguments, then the filter will be applied to the global audio output.
    
    // Distortion
    _distortion = [[AEDistortionFilter alloc] init];
    _distortion.finalMix = 20;
    _distortion.bypassed = true;
    [_audioController addFilter:_distortion toChannelGroup:_backgroundAudioGroup]; // <- Add this filter only to this group channel.
    
    // Reverb
    _reverb = [[AEReverbFilter alloc] init];
    _reverb.decayTimeAt0Hz = 10.0;
    _reverb.decayTimeAtNyquist = 0.5;
    _reverb.minDelayTime = 0.008;
    _reverb.maxDelayTime = 0.050;
    _reverb.gain = 4.0;
    _reverb.randomizeReflections = 50;
    _reverb.dryWetMix = 15.0;
    _reverb.bypassed = false;
    [_audioController addFilter:_reverb toChannelGroup:_backgroundAudioGroup]; // <- Add this filter only to this group channel.
    
    // Varispeed
    _varispeed = [[AEVarispeedFilter alloc] init];
    _varispeed.playbackRate = 1.0;
    _varispeed.playbackCents = 0.0;
    _varispeed.bypassed = false;
    [_audioController addFilter:_varispeed toChannelGroup:_backgroundAudioGroup]; // <- Add this filter only to this group channel.
    
    
    // Bandpass
    _bandpass = [[AEBandpassFilter alloc] init];
    _bandpass.bandwidth = 12000.0;
    _bandpass.centerFrequency = 5000.0;
    _bandpass.bypassed = false;
    [_audioController addFilter:_bandpass toChannelGroup:_backgroundAudioGroup]; // <- Add this filter only to this group channel.
    
    /*
    // Expander
    _expander = [[AEExpanderFilter alloc] init];
    //[_audioController addFilter:_expander];
    
    // High Pass
    _highpass = [[AEHighPassFilter alloc] init];
    _highpass.bypassed = true;
    [_audioController addFilter:_highpass];
    
    // High Shelf
    _highshelf = [[AEHighShelfFilter alloc] init];
    _highshelf.bypassed = true;
    [_audioController addFilter:_highshelf];
    
    // Limiter
    //_limiter = [[AELimiterFilter alloc] init];
    [_audioController addFilter:_limiter];
    
    // Low Pass
    _lowpass = [[AELowPassFilter alloc] init];
    _lowpass.bypassed = true;
    [_audioController addFilter:_lowpass];
    
    // Low Shelf
    _lowshelf = [[AELowShelfFilter alloc] init];
    _lowshelf.bypassed = true;
    [_audioController addFilter:_lowshelf];
    
    // New Time Pitch
    _newtimepitch = [[AENewTimePitchFilter alloc] init];
    _newtimepitch.pitch = 0.0;
    _newtimepitch.bypassed = true;
    [_audioController addFilter:_newtimepitch];
    
    // Parametric EQ
    _parametriceq = [[AEParametricEqFilter alloc] init];
    _parametriceq.bypassed = true;
    [_audioController addFilter:_parametriceq];
    
    // Peak Limiter
    _peaklimiter = [[AEPeakLimiterFilter alloc] init];
    _peaklimiter.bypassed = true;
    [_audioController addFilter:_peaklimiter];
     */
    
}

#pragma mark -
#pragma mark === Public Action to Play Audio Loop ===
#pragma mark

- (void)backgroundAudioPlayPauseButtonPressed {
    if ( _backgroundAudioLoop ) {
        if (!_backgroundAudioLoop.channelIsPlaying) {
            _backgroundAudioLoop.channelIsPlaying = YES;
        }
        //NSLog(@"Music loop is playing: %@", _backgroundAudioLoop.channelIsPlaying ? @"YES" : @"NO");
    }
}

@end
