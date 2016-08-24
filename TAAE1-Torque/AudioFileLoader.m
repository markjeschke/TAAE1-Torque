//
//  AudioFileLoader.m
//  DrumsAUSampler
//
//  Created by Mark Jeschke on 7/18/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import "AudioFileLoader.h"
#import "TheAmazingAudioEngine.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#define Check(status) { OSStatus result = (status); if (result != noErr) [NSException raise:@"TFA Weapons" format:@"status = %d", (int)result]; }

#define RES_URL(f) [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:(f) ofType:NULL]]

@interface AudioFileLoader ()

@end

@implementation AudioFileLoader {
    AEAudioController *_audioController;
    NoteInstanceID _note;
}


/*
- (instancetype)initWithFilePath:(NSString *)filePath
                                    fileName:(NSString *)fileName
                                  fileVolume:(float)fileVolume
                                     filePan:(float)filePan
                                   filePitch:(int)filePitch
                                fileVelocity:(int)fileVelocity {
    
    if ( !(self = [super init]) ) return nil;
    
    // Init as an AUSampler audio unit channel.
    AudioComponentDescription componentDescription = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_MusicDevice, kAudioUnitSubType_Sampler);
    
    self = [super initWithComponentDescription:componentDescription];
    
    //_audioController = audioController;
    
    NSLog(@"audioController: %@", _audioController);
    
    self.pan = filePan;
    self.volume = fileVolume;
    
    if (filePath != nil) {
        _filePath = filePath;
    }
    
    NSLog(@"Name of this loaded is: %@", fileName);
    
    [self loadSample];
    
    return self;
}
*/
// ---------------------------------------------------------------------------------------------------------
#pragma mark - INIT
// ---------------------------------------------------------------------------------------------------------


-(id)init {
    if ( !(self = [super init]) ) return nil;
    
    // Init as an AUSampler audio unit channel.
    AudioComponentDescription componentDescription = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_MusicDevice, kAudioUnitSubType_Sampler);
    
    self = [super initWithComponentDescription:componentDescription];
    
    return self;
}


- (void)setupWithAudioController:(AEAudioController *)audioController {
    [super setupWithAudioController:audioController];
    // Keep a reference to the audio controller.
    // (knowledge of the audio graph is needed)
    _audioController = audioController;
    self.volume = _fileVolume;
    self.pan = _filePan;
    
    [self loadSample];

}



// ---------------------------------------------------------------------------------------------------------
#pragma mark - SOUNDS
// ---------------------------------------------------------------------------------------------------------

-(void)loadSample {

    // Load audio file from
    
    NSArray *filePath = [[NSArray alloc] initWithObjects:_filePath, nil];
    
    NSLog(@"filePath: %@", filePath);
    
    NSMutableArray *urls = [NSMutableArray arrayWithCapacity:filePath.count];
    
    for (NSString *name in filePath) {
        [urls addObject:[NSURL fileURLWithPath:[@"" stringByAppendingPathComponent:name]]];
        NSLog(@"fileURLWithPath urls: %@", urls);
    }
    
    CFArrayRef urlArrayRef = (__bridge CFArrayRef)urls;
    {
        OSStatus status = AudioUnitSetProperty(self.audioUnit,
                                               kAUSamplerProperty_LoadAudioFiles,
                                               kAudioUnitScope_Global,
                                               0,
                                               &urlArrayRef,
                                               sizeof(urlArrayRef));
        if (status != noErr) {
            NSLog(@"Failed to load samples. OSStatus was %ld", (long)status);
            return;
        }
    }
}

- (void)playSample {
    AudioUnit sampler = self.audioUnit;
    [self voiceOn:sampler pitch:_filePitch velocity:_fileVelocity];
    NSLog(@"_fileVelocity: %d", _fileVelocity);
}

- (void)voiceOn:(AudioUnit)sampler pitch:(NoteInstanceID)pitch velocity:(UInt8)velocity {
    NoteInstanceID noteNum = pitch;
    UInt32 onVelocity = velocity;
    
    UInt32 offsetSampleFrame = 0;
    MusicDeviceGroupID groupID = 0;
    MusicDeviceNoteParams noteParams = {2,(Float32)(noteNum),(Float32)(onVelocity),0};
    Check(MusicDeviceStartNote(sampler,
                               kMusicNoteEvent_Unused,
                               groupID,
                               &_note,
                               offsetSampleFrame,
                               &noteParams));
}

- (void)voiceOff:(AudioUnit)sampler note:(NoteInstanceID)note {
    UInt32 offsetSampleFrame = 0;
    MusicDeviceGroupID groupID = 0;
    Check(MusicDeviceStopNote(sampler, groupID, note, offsetSampleFrame));
}


@end
