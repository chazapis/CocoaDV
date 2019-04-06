//
//  DVCodec.m
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

#import "DVCodec.h"

#import <CocoaCodec2/codec2.h>
#import <CocoaCodec2/golay23.h>

@interface DVCodec () {
    struct CODEC2 *codec2Mode3200State;
    struct CODEC2 *codec2Mode2400State;
};

@property (nonatomic, strong) AVAudioFormat *playerFormat;
@property (nonatomic, strong) AVAudioFormat *recorderFormat;
@property (nonatomic, strong) AVAudioFormat *internalFormat;

@property (nonatomic, strong) AVAudioConverter *audioPlayerConverter;
@property (nonatomic, strong) AVAudioConverter *audioRecorderConverter;

@end

@implementation DVCodec

- (id)initWithPlayerFormat:(AVAudioFormat *)playerFormat recorderFormat:(AVAudioFormat *)recorderFormat {
    if ((self = [super init])) {
        codec2Mode3200State = codec2_create(CODEC2_MODE_3200);
        codec2Mode2400State = codec2_create(CODEC2_MODE_2400);
        golay23_init();

        self.playerFormat = playerFormat;
        self.recorderFormat = recorderFormat;
        self.internalFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:8000 channels:1 interleaved:NO];

        self.audioPlayerConverter = [[AVAudioConverter alloc] initFromFormat:self.internalFormat toFormat:self.playerFormat];
        self.audioRecorderConverter = [[AVAudioConverter alloc] initFromFormat:self.recorderFormat toFormat:self.internalFormat];
    }
    
    return self;
}

- (void)dealloc {
    codec2_destroy(codec2Mode3200State);
    codec2_destroy(codec2Mode2400State);
}

- (AVAudioPCMBuffer *)decodeDSTARFrame:(DSTARFrame *)dstarFrame fromStream:(DVStream *)stream {
    AVAudioPCMBuffer *internalBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.internalFormat frameCapacity:160];
    AVAudioPCMBuffer *playerBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.playerFormat frameCapacity:self.playerFormat.sampleRate * 0.02];

    if (stream.dstarHeader.flag3 == 0x01) {
        // Codec 2 mode 3200 without FEC
        codec2_decode(codec2Mode3200State, (short *)(internalBuffer.int16ChannelData[0]), dstarFrame.codec.bytes);
    } else if (stream.dstarHeader.flag3 == 0x03) {
        // Codec 2 mode 2400 with FEC

        unsigned char codec[9];
        int receivedCodeword;
        int correctedCodeword;
        unsigned char partialByte;
        // unsigned int bitErrors = 0;

        memcpy(codec, dstarFrame.codec.bytes, 9);

        receivedCodeword = ((codec[0] << 15) |
                            (((codec[1] >> 4) & 0x0F) << 11) |
                            (codec[6] << 3) |
                            ((codec[7] >> 5) & 0x07));
        correctedCodeword = golay23_decode(receivedCodeword);
        // bitErrors += golay23_count_errors(receivedCodeword, correctedCodeword);

        codec[0] = (unsigned char)((correctedCodeword >> 15) & 0xFF);
        partialByte = (unsigned char)(((correctedCodeword >> 11) & 0x0F) << 4);

        receivedCodeword = (((codec[1] & 0x0F) << 19) |
                            (codec[2] << 11) |
                            ((codec[7] & 0x1F) << 6) |
                            ((codec[8] >> 2) & 0x3F));
        correctedCodeword = golay23_decode(receivedCodeword);
        // bitErrors += golay23_count_errors(receivedCodeword, correctedCodeword);
        // NSLog(@"DVCodec: CPacket decoded with %u bit errors", bitErrors);

        codec[1] = partialByte | (unsigned char)((correctedCodeword >> 19) & 0x0F);
        codec[2] = (unsigned char)((correctedCodeword >> 11) & 0xFF);

        codec2_decode(codec2Mode2400State, (short *)(internalBuffer.int16ChannelData[0]), codec);
    }

    NSError *error;
    
    internalBuffer.frameLength = 160;
    AVAudioConverterOutputStatus status __unused = [self.audioPlayerConverter convertToBuffer:playerBuffer error:&error withInputFromBlock:^(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus *outStatus) {
        *outStatus = AVAudioConverterInputStatus_HaveData;
        return internalBuffer;
    }];
    // NSLog(@"DVCodec: Converted sample in the player buffer (status: %ld)", status);

    return playerBuffer;
}

- (void)encodeBuffer:(AVAudioPCMBuffer *)buffer intoStream:(DVStream *)stream {
    // NSLog(@"DVCodec: Got %d samples to encode with format %@", buffer.frameLength, buffer.format);

    NSError *error;
    
    AVAudioPCMBuffer *internalBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.internalFormat frameCapacity:self.internalFormat.sampleRate * (buffer.frameLength / buffer.format.sampleRate)];
    AVAudioConverterOutputStatus status __unused = [self.audioRecorderConverter convertToBuffer:internalBuffer error:&error withInputFromBlock:^(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus *outStatus) {
        *outStatus = AVAudioConverterInputStatus_HaveData;
        return buffer;
    }];
    // NSLog(@"DVCodec: Converted to %d samples in the internal buffer (status: %ld)", internalBuffer, status);
    
    unsigned char codec[9];
    unsigned char data[] = {0x00, 0x00, 0x00};
    for (int i = 0; i < internalBuffer.frameLength; i += 160) {
        codec2_encode(self->codec2Mode3200State, codec, &(internalBuffer.int16ChannelData[0][i]));
        codec[8] = 0x00;
        
        DSTARFrame *dstarFrame = [[DSTARFrame alloc] initWithCodec:[[NSData alloc] initWithBytes:codec length:9]
                                                              data:[[NSData alloc] initWithBytes:data length:3]];
        [stream appendDSTARFrame:dstarFrame];
    }
}

@end
