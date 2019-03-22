//
// DVFramePacket.m
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

#import "DVFramePacket.h"

@implementation DVFramePacket

+ (DVFramePacket *)packetFromData:(NSData *)data {
    if ([data length] != 27)
        return nil;
    
    char packet[27];
    
    [data getBytes:packet length:27];
    if (packet[0] != 'D' || packet[1] != 'S' || packet[2] != 'V' || packet[3] != 'T' || packet[4] != 0x20 || packet[8] != 0x20)
        return nil;
    DSTARFrame *dstarFrame = [DSTARFrame fromData:[NSData dataWithBytes:&(packet[15]) length:12]];
    if (dstarFrame == nil)
        return nil;
    unsigned char band1 = packet[9];
    unsigned char band2 = packet[10];
    unsigned char band3 = packet[11];
    unsigned short streamId = NSSwapLittleShortToHost(packet[12] | (packet[13] << 8));
    unsigned char packetId = packet[14];
    
    return [[DVFramePacket alloc] initWithBand1:band1
                                          band2:band2
                                          band3:band3
                                       streamId:streamId
                                       packetId:packetId
                                     dstarFrame:dstarFrame];
}

- (id)initWithBand1:(unsigned char)band1
              band2:(unsigned char)band2
              band3:(unsigned char)band3
           streamId:(unsigned short)streamId
           packetId:(unsigned char)packetId
         dstarFrame:(DSTARFrame *)dstarFrame {
    if (self = [super init]) {
        self.band1 = band1;
        self.band2 = band2;
        self.band3 = band3;
        self.streamId = streamId;
        self.packetId = packetId;
        self.dstarFrame = dstarFrame;
    }
    return self;
}

- (BOOL)isLast {
    return (self.packetId & 0x40) != 0;
}

- (NSData *)toData {
    char packet[27];
    
    char buffer[] = {'D', 'S', 'V', 'T', 0x20, 0x00, 0x00, 0x00, 0x20};
    memcpy(packet, buffer, 9);
    packet[9] = self.band1;
    packet[10] = self.band2;
    packet[11] = self.band3;
    unsigned short streamId = NSSwapHostShortToLittle(self.streamId);
    packet[12] = streamId & 0xff;
    packet[13] = ((streamId & 0xff00) >> 8) & 0xff;
    packet[14] = self.packetId;
    [[self.dstarFrame toData] getBytes:&(packet[15]) length:12];
    
    return [NSData dataWithBytes:packet length:27];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DVFramePacket band1: %hhu band2: %hhu band3: %hhu streamId: %hu packetId: %hhu dstarFrame: %@", self.band1, self.band2, self.band3, self.streamId, self.packetId, self.dstarFrame];
}

@end
