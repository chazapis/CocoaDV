//
// DVCodec.h
//
// Copyright (C) 2019 Antony Chazapis SV9OAN
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "DSTARFrame.h"
#import "DVStream.h"

@interface DVCodec : NSObject

- (id)initWithPlayerFormat:(AVAudioFormat *)playerFormat recorderFormat:(AVAudioFormat *)recorderFormat;

- (AVAudioPCMBuffer *)decodeDSTARFrame:(DSTARFrame *)dstarFrame;
- (void)encodeBuffer:(AVAudioPCMBuffer *)buffer intoStream:(DVStream *)stream;
    
@property (nonatomic, strong, readonly) AVAudioFormat *playerFormat; // What to decode to
@property (nonatomic, strong, readonly) AVAudioFormat *recorderFormat; // What to encode from
@property (nonatomic, strong, readonly) AVAudioFormat *internalFormat;

@end
