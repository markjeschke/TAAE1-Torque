//
//  ViewController.m
//  TAAE1-Torque
//
//  Created by Mark Jeschke on 8/23/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <CoreMotion/CoreMotion.h>

@interface ViewController () {
    BOOL musicPaused;
    
    double currentTorqueSpeed;
    double pausePlaybackTorqueSpeed;
    double restartPlaybackTorqueSpeed;
    
    double currentVarispeed;
    double targetVarispeed;
    double slowSpeed;
    double normalSpeed;
    double varispeedChangeInterval;
    
    double currentVolume;
    double targetVolume;
    double volumeChangeInterval;
    
    double timerFadeInterval;
    
    double timecodeTimerInterval;
}

@property (strong, nonatomic) AppDelegate *appDelegate;

@property (weak, nonatomic) IBOutlet UIButton *pausePlayButton;
@property (nonatomic) NSTimer *timecodeTimer;
@property (nonatomic) NSTimer *audioSpeedTimer;
@property (nonatomic) NSTimer *microFadeTimer;
@property (nonatomic, strong) NSString *timecodeDisplay;
@property (weak, nonatomic) IBOutlet UILabel *timecodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (nonatomic) CMMotionManager * manager;

@property (weak, nonatomic) IBOutlet UISlider *panSlider;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

- (IBAction)playKick:(UIButton *)sender;
- (IBAction)playOpenHiHat:(UIButton *)sender;
- (IBAction)playClosedHiHat:(UIButton *)sender;
- (IBAction)playSnare:(UIButton *)sender;
- (IBAction)pausePlay:(UIButton *)sender;
- (IBAction)panLevel:(UISlider *)sender;
- (IBAction)volumeLevel:(UISlider *)sender;

@end

@implementation ViewController

#pragma mark -
#pragma mark === Initialize Parameters ===
#pragma mark

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        // Access audio engine object instantiated in the application delegate header.
        _appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
        
        // Initialize parameters
        
        musicPaused = false;
        
        currentTorqueSpeed = 0.0; // Torque speed gets set in the 'changeAudioSpeed' method.
        pausePlaybackTorqueSpeed = 0.003;
        restartPlaybackTorqueSpeed = 0.006;
        
        currentVarispeed = 0.0; // Initial speed
        targetVarispeed = 0.0; // Target varispeed gets set in the 'changeAudioSpeed' method.
        slowSpeed = -2400.0; // The ending speed when the audio slows to a halt.
        normalSpeed = 0.0;
        varispeedChangeInterval = 20.0; // Slowed-down  torque pitch
        
        currentVolume = _volumeSlider.value; // Set via the volume UISlider.
        targetVolume = 0.0; // Target volume gets updated to the volume UISlider value.
        volumeChangeInterval = 0.1;
        timerFadeInterval = 0.04; // The speed of the audio fade out transition.
        
        timecodeTimerInterval = 0.1; // The refresh time interval for the timecode display NSTimer.
        
        // Set the timecode playback and duration textLabels
        _timecodeLabel.text = [_appDelegate.audioController getCurrentTimecode];
        _durationLabel.text = [_appDelegate.audioController getDurationTimecode];
        
        // Set the UIButton state
        [self checkMusicStatus];
    }
    return self;
}

#pragma mark -
#pragma mark === AUSampler Trigger Actions for Drum Sounds ===
#pragma mark

// Trigger the AUSampler sounds from the AudioController class.

- (IBAction)playKick:(UIButton *)sender {
    [_appDelegate.audioController playKickSound];
}

- (IBAction)playSnare:(UIButton *)sender {
    [_appDelegate.audioController playSnareSound];
}

- (IBAction)playClosedHiHat:(UIButton *)sender {
    [_appDelegate.audioController playClosedHiHatSound];
}

- (IBAction)playOpenHiHat:(UIButton *)sender {
    [_appDelegate.audioController playOpenHiHatSound];
}

#pragma mark -
#pragma mark === UIButton Actions for Audio Playback ===
#pragma mark

- (IBAction)pausePlay:(UIButton *)sender {
    [_appDelegate.audioController backgroundAudioPlayPauseButtonPressed]; // Toggles play/pause
    [self checkMusicStatus]; // Update UIButton states
    [self changeAudioSpeed]; // Changes the audio's torque, AKA slow-down and start-up speed.
    
}

- (IBAction)panLevel:(UISlider *)sender {
    _appDelegate.audioController.backgroundAudioLoopPan = sender.value;
}

- (IBAction)volumeLevel:(UISlider *)sender {
    _appDelegate.audioController.backgroundAudioLoopVolume = sender.value;
    currentVolume = sender.value;
}

#pragma mark -
#pragma mark === Update Play/Pause UIButton state and Timecode ===
#pragma mark

- (void) checkMusicStatus {
    if (musicPaused) {
        [_pausePlayButton setTitle:@"Pause" forState:UIControlStateNormal];
        _pausePlayButton.selected = true;
        musicPaused = false;
        // Start timecode display of background audio loop
        [self startTimecode];
    } else {
        [_pausePlayButton setTitle:@"Play" forState:UIControlStateNormal];
        _pausePlayButton.selected = false;
        musicPaused = true;
        // Clear the timecodeTimer, so that it stops running.
        [_timecodeTimer invalidate];
        _timecodeTimer = nil;
    }
}

#pragma mark -
#pragma mark === Timecode Functions ===
#pragma mark

- (void) startTimecode {
    _timecodeTimer = [NSTimer scheduledTimerWithTimeInterval:timecodeTimerInterval
                                                      target:self
                                                    selector:@selector(displayTimecode)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void) displayTimecode {
    _timecodeDisplay = [_appDelegate.audioController getCurrentTimecode];
    _timecodeLabel.text = _timecodeDisplay;
}

#pragma mark -
#pragma mark === Update Audio Varispeed Timer ===
#pragma mark

- (void) changeAudioSpeed {
    targetVarispeed = musicPaused ? slowSpeed : normalSpeed; // If musicPaused: true, set the 'targetVarispeed' to 2 octaves below the normal pitch (-2400.0). Otherwise, set it to its normal pitch (0.0)
    currentTorqueSpeed = musicPaused ? pausePlaybackTorqueSpeed : restartPlaybackTorqueSpeed; // If musicPaused: true, set the timerInterval to 'pauseTorque' speed. Otherwise set it to 'restartPlaybackTorqueSpeed' speed.
    _audioSpeedTimer = [NSTimer scheduledTimerWithTimeInterval: currentTorqueSpeed
                                                        target: self
                                                      selector:@selector(audioChangeTimeout)
                                                      userInfo: nil repeats:YES];
}

- (void) audioChangeTimeout {
    if (targetVarispeed < currentVarispeed) {
        currentVarispeed -= varispeedChangeInterval;
    } else {
        currentVarispeed += varispeedChangeInterval;
    }
    // Update the effect parameter over time.
    _appDelegate.audioController.varispeedPlaybackCents = currentVarispeed;
    
    if (musicPaused) {
        if (currentVarispeed == targetVarispeed/2) {
            [self fadeAudioTransition];
        }
    }
    
    if (currentVarispeed == targetVarispeed) {
        if (musicPaused) {
            // Pause the audio clip once the default parameter equals the target parameter.
            _appDelegate.audioController.backgroundAudioLoopChannelIsPlaying = false;
            NSLog(@"Music loop is playing: %@", _appDelegate.audioController.backgroundAudioLoopChannelIsPlaying ? @"YES" : @"NO");
        }
        // Clear the timer, so that it stops running.
        [_audioSpeedTimer invalidate];
        _audioSpeedTimer = nil;
    }
}

#pragma mark -
#pragma mark === Update Audio Fade Timer ===
#pragma mark

- (void) fadeAudioTransition {
    _microFadeTimer = [NSTimer scheduledTimerWithTimeInterval: timerFadeInterval
                                                       target: self
                                                     selector:@selector(audioFaderTimeout)
                                                     userInfo: nil repeats:YES];
}

- (void) audioFaderTimeout {
    if (targetVolume < currentVolume) {
        currentVolume -= volumeChangeInterval;
    }
    // Update the effect parameter over time.
    _appDelegate.audioController.backgroundAudioLoopVolume = currentVolume;
    if (currentVolume <= targetVolume) {
        currentVolume = _volumeSlider.value; // Return the default volume level to the UISlider volume value from 0 (silent).
        targetVolume = currentVolume; // Reset the target volume level
        _appDelegate.audioController.backgroundAudioLoopVolume = currentVolume;
        _appDelegate.audioController.delayWetDryMix = 0.0;
        // Clear the timer, so that it stops running.
        [_microFadeTimer invalidate];
        _microFadeTimer = nil;
    }
}

@end