//
//  AudioController.m
//  TAAE1-Torque
//
//  Created by Mark Jeschke on 8/23/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//s

#import "AudioController.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioFileLoader.h"
#import "TimecodeFormatter.h"

#define Check(status) { OSStatus result = (status); if (result != noErr) [NSException raise:@"DrumsAUSampler" format:@"status = %d", (int)result]; }

@interface AudioController () {
    AEChannelGroupRef _backgroundAudioGroup;
}

// Audio engine
@property (strong, nonatomic) AEAudioController *audioController;

// Create the background audio loop
@property (nonatomic, strong) AEAudioFilePlayer * backgroundAudioLoop;

// Instrument playback via AUSampler
@property (strong, nonatomic) AudioFileLoader * kick;
@property (nonatomic) float kickVolume;
@property (nonatomic) float kickPan;
@property (nonatomic) int kickVelocity;
@property (nonatomic) float kickPitch;
@property (nonatomic, assign) NSString *kickFilePath;

@property (strong, nonatomic) AudioFileLoader * snare;
@property (nonatomic) float snareVolume;
@property (nonatomic) float snarePan;
@property (nonatomic) int snareVelocity;
@property (nonatomic) float snarePitch;
@property (nonatomic, assign) NSString *snareFilePath;

@property (strong, nonatomic) AudioFileLoader * closedHiHat;
@property (nonatomic) float closedHiHatVolume;
@property (nonatomic) float closedHiHatPan;
@property (nonatomic) int closedHiHatVelocity;
@property (nonatomic) float closedHiHatPitch;
@property (nonatomic, assign) NSString *closedHiHatFilePath;

@property (strong, nonatomic) AudioFileLoader * openHiHat;
@property (nonatomic) float openHiHatVolume;
@property (nonatomic) float openHiHatPan;
@property (nonatomic) int openHiHatVelocity;
@property (nonatomic) float openHiHatPitch;
@property (nonatomic, assign) NSString *openHiHatFilePath;

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
    
    // Add AUSampler files
    
    // Kick
    _kickVolume = 2.0;
    _kickPan = 0.0;
    _kickPitch = 60;
    _kickVelocity = (_kickVolume/2)*127;
    NSLog(@"kickVelocity: %d", _kickVelocity);
    _kickFilePath = @"/Sounds/CYCdh_AcouKick-15.m4a";
    
    _kick = [[AudioFileLoader alloc] init];
    _kick.filePath = _kickFilePath;
    _kick.filePan = _kickPan;
    _kick.filePitch = _kickPitch;
    _kick.fileVolume = _kickVolume;
    _kick.fileVelocity = _kickVelocity;
    
    [self.audioController addChannels:@[_kick]];
    
    // Snare
    _snareVolume = 2.0; // <- Audio volume is 0.0 min - 2.0 max
    _snarePan = 0.0; // <- Pan allows the audio to be stereo-panned. The center = 0.0, the far left pan = -1.0, and far right is 1.0
    _snarePitch = 60; // <- #60 is the MIDI note that matches the audio sample's original pitch. One octave up would be #72. One octave down would be #48.
    _snareVelocity = (_snareVolume/2)*127; // <- The MIDI velocity will be set from the audio file's volume level.
    _snareFilePath = @"/Sounds/CYCdh_LudRimA-04.m4a"; // <- Input the path location of the audio file that you'd like to use.
    
    _snare = [[AudioFileLoader alloc] init];
    _snare.filePath = _snareFilePath;
    _snare.filePan = _snarePan;
    _snare.filePitch = _snarePitch;
    _snare.fileVolume = _snareVolume;
    _snare.fileVelocity = _snareVelocity;
    
    [self.audioController addChannels:@[_snare]];
    
    // Closed Hi-Hat
    _closedHiHatVolume = 2.0;
    _closedHiHatPan = 0.0;
    _closedHiHatPitch = 60;
    _closedHiHatVelocity = (_closedHiHatVolume/2)*127;
    _closedHiHatFilePath = @"/Sounds/KHats Clsd-09.m4a";
    
    _closedHiHat = [[AudioFileLoader alloc] init];
    _closedHiHat.filePath = _closedHiHatFilePath;
    _closedHiHat.filePan = _closedHiHatPan;
    _closedHiHat.filePitch = _closedHiHatPitch;
    _closedHiHat.fileVolume = _closedHiHatVolume;
    _closedHiHat.fileVelocity = _closedHiHatVelocity;
    
    [self.audioController addChannels:@[_closedHiHat]];
    
    // Open Hi-Hat
    _openHiHatVolume = 2.0;
    _openHiHatPan = 0.0;
    _openHiHatPitch = 60;
    _openHiHatVelocity = (_openHiHatVolume/2)*127;
    _openHiHatFilePath = @"/Sounds/KHats Open-09.m4a";
    
    _openHiHat = [[AudioFileLoader alloc] init];
    _openHiHat.filePath = _openHiHatFilePath;
    _openHiHat.filePan = _openHiHatPan;
    _openHiHat.filePitch = _openHiHatPitch;
    _openHiHat.fileVolume = _openHiHatVolume;
    _openHiHat.fileVelocity = _openHiHatVelocity;
    
    [self.audioController addChannels:@[_openHiHat]];
    
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
#pragma mark === Public Actions to Trigger Audio Samples ===
#pragma mark

- (void) playKickSound {
    [_kick playSample];
}

- (void) playSnareSound {
    [_snare playSample];
}

- (void) playClosedHiHatSound {
    // If the open hi-hat's channel is playing, turn it off.
    if (_openHiHat) {
        _openHiHat.channelIsPlaying = false;
    }
    [_closedHiHat playSample];
}

- (void) playOpenHiHatSound {
    // Turn the open hi-hat channel to on.
    _openHiHat.channelIsPlaying = true;
    [_openHiHat playSample];
}

- (void)backgroundAudioPlayPauseButtonPressed {
    if ( _backgroundAudioLoop ) {
        if (!_backgroundAudioLoop.channelIsPlaying) {
            _backgroundAudioLoop.channelIsPlaying = YES;
        }
        //NSLog(@"Music loop is playing: %@", _backgroundAudioLoop.channelIsPlaying ? @"YES" : @"NO");
    }
}

@end
