//
// DVStream.m
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

#import "DVStream.h"

#include <stdlib.h>

@interface DVStream ()

@property (nonatomic, strong) NSMutableArray *packetArray;
@property (nonatomic, assign) unsigned char nextPacketId;
@property (nonatomic, assign) BOOL hasLast;

@end

@implementation DVStream

- (id)initWithDVHeaderPacket:(DVHeaderPacket *)dvHeaderPacket {
    if (self = [super init]) {
        self.packetArray = [[NSMutableArray alloc] initWithCapacity:1500]; // About 30 seconds of audio
        [self.packetArray addObject:dvHeaderPacket];
        
        _streamId = dvHeaderPacket.streamId;
        _dstarHeader = dvHeaderPacket.dstarHeader;
        _nextPacketId = 0;
        _hasLast = NO;
    }
    return self;
}

- (id)initWithDSTARHeader:(DSTARHeader *)dstarHeader {
    DVHeaderPacket *dvHeaderPacket = [[DVHeaderPacket alloc] initWithBand1:0
                                                                     band2:0
                                                                     band3:0
                                                                  streamId:arc4random_uniform(65536)
                                                               dstarHeader:dstarHeader];
    return [self initWithDVHeaderPacket:dvHeaderPacket];
}

- (void)appendDVFramePacket:(DVFramePacket *)dvFramePacket {
    if (_streamId != dvFramePacket.streamId)
        return;

    @synchronized (self) {
        if (self.hasLast)
            return;

        self.nextPacketId = (dvFramePacket.packetId + 1) % 21;
        if (dvFramePacket.isLast)
            self.hasLast = YES;
        [self.packetArray addObject:dvFramePacket];
    }
}

- (void)appendDSTARFrame:(DSTARFrame *)dstarFrame {
    @synchronized (self) {
        if (self.hasLast)
            return;
        
        DVFramePacket *dvFramePacket = [[DVFramePacket alloc] initWithBand1:0
                                                                      band2:0
                                                                      band3:0
                                                                   streamId:self.streamId
                                                                   packetId:self.nextPacketId
                                                                 dstarFrame:dstarFrame];
        
        self.nextPacketId = (self.nextPacketId + 1) % 21;
        [self.packetArray addObject:dvFramePacket];
    }
}

- (void)markLast {
    @synchronized (self) {
        if (self.hasLast)
            return;

        id packet = [self.packetArray lastObject];
        
        if ([packet isKindOfClass:[DVFramePacket class]]) {
            ((DVFramePacket *)packet).packetId |= 0x40;
        }
        self.hasLast = YES;
    }
}

- (void)removeAllDVFramePackets {
    @synchronized (self) {
        [self.packetArray removeObjectsInRange:NSMakeRange(1, self.packetArray.count - 1)];
    }
}

- (id)dvPacketAtIndex:(NSUInteger)index {
    @synchronized (self) {
        return [self.packetArray objectAtIndex:index];
    }
}

- (NSUInteger)getDVPacketCount {
    @synchronized (self) {
        return self.packetArray.count;
    }
}

@end
