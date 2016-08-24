//
//  AudioFileLoader.h
//  TAAE1-Torque
//
//  Created by Mark Jeschke on 8/23/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TheAmazingAudioEngine.h"

@interface AudioFileLoader : AEAudioUnitChannel

/*
- (instancetype)initWithFilePath:(NSString *)filePath
                                    fileName:(NSString *)fileName
                                  fileVolume:(float)fileVolume
                                     filePan:(float)filePan
                                   filePitch:(int)filePitch
                                fileVelocity:(int)fileVelocity;
 
 */

// Load & play sounds.
- (void)loadSample;
- (void)playSample;

@property (nonatomic, assign) NSString *filePath;
@property (nonatomic) float fileVolume;
@property (nonatomic) float filePan;
@property (nonatomic) int filePitch;
@property (nonatomic) int fileVelocity;

//- (void)loadPreset:(NSURL*)fileURL;



@end
