//
// DSTARFrame.m
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

#import "DSTARFrame.h"

@implementation DSTARFrame

+ (DSTARFrame *)fromData:(NSData *)data {
    if ([data length] != 12)
        return nil;
    
    char packet[12];
    
    [data getBytes:packet length:12];
    NSData *dvcodec = [NSData dataWithBytes:&(packet[0]) length:9];
    NSData *dvdata = [NSData dataWithBytes:&(packet[9]) length:3];
    
    return [[DSTARFrame alloc] initWithCodec:dvcodec
                                        data:dvdata];
}

- (id)initWithCodec:(NSData *)codec
               data:(NSData *)data {
    if (self = [super init]) {
        self.codec = codec;
        self.data = data;
    }
    return self;
}

- (NSData *)toData {
    char packet[12];
    
    [self.codec getBytes:&(packet[0]) length:9];
    [self.data getBytes:&(packet[9]) length:3];
    
    return [NSData dataWithBytes:packet length:12];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DSTARFrame codec: %@ data: %@", self.codec, self.data];
}

@end
