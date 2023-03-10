/*

===== IMPORTANT =====

This is sample code demonstrating API, technology or techniques in development.
Although this sample code has been reviewed for technical accuracy, it is not
final. Apple is supplying this information to help you plan for the adoption of
the technologies and programming interfaces described herein. This information
is subject to change, and software implemented based on this sample code should
be tested with final operating system software and final documentation. Newer
versions of this sample code may be provided with future seeds of the API or
technology. For information about updates to this and other developer
documentation, view the New & Updated sidebars in subsequent documentation
seeds.

=====================

File: AudioFX.h
Abstract: Convenience class wraps the AudioServices APIs from CoreAudio to allow
playback of small sound files with no panning or volume controls.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the following terms, and your
use, installation, modification or redistribution of this Apple software
constitutes acceptance of these terms.  If you do not agree with these terms,
please do not use, install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject
to these terms, Apple grants you a personal, non-exclusive license, under
Apple's copyrights in this original Apple software (the "Apple Software"), to
use, reproduce, modify and redistribute the Apple Software, with or without
modifications, in source and/or binary forms; provided that if you redistribute
the Apple Software in its entirety and without modifications, you must retain
this notice and the following text and disclaimers in all such redistributions
of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may be used
to endorse or promote products derived from the Apple Software without specific
prior written permission from Apple.  Except as expressly stated in this notice,
no other rights or licenses, express or implied, are granted by Apple herein,
including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import <Foundation/Foundation.h>

//CLASSES:

@class AudioFX;

//PROTOCOLS:

@protocol AudioFXDelegate <NSObject>
- (void) audioFXDidComplete:(AudioFX*)audioFX;
@end

//CLASS INTERFACES:

/*
This class wraps the AudioServices APIs from CoreAudio to allow playback of small sound files with no panning or volume controls.
Use this class to play casual sounds during user interface interaction (keyboard like, lock/unlock...).
Make sure the sound files are small and uncompressed or IMA.
When you have lots of small sounds and don't really care about the latency response when playing them, it's recommended to create and destroy AudioFX instances on demand instead of allocating them all upfront - or use the +playAtPath: method.
*/
@interface AudioFX : NSObject
{
@private
	UInt32					_soundID;
	NSInteger				_tag;
	id<AudioFXDelegate>		__weak _delegate;
	BOOL					_hasCallback;
}
#if TARGET_OS_IPHONE
+ (void) vibrate; //iPhone only
#endif

+ (BOOL) playAtPath:(NSString*)path; //One-shot sound playback

- (id) initWithPath:(NSString*)path; //If the path is not absolute, it is assumed to be relative to the main bundle's resources

@property NSInteger tag;

@property(nonatomic, weak) id<AudioFXDelegate> delegate;

- (void) play;
@end
