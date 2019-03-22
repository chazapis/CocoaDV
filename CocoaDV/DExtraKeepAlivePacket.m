//
// DExtraKeepAlivePacket.m
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

#import "DExtraKeepAlivePacket.h"

@implementation DExtraKeepAlivePacket

+ (DExtraKeepAlivePacket *)packetFromData:(NSData *)data {
    if ([data length] != 9)
        return nil;
    
    char packet[9];
    
    [data getBytes:packet length:9];
    NSString *srcCallsign = [[NSString alloc] initWithBytes:&(packet[0]) length:8 encoding:NSASCIIStringEncoding];
    if (srcCallsign == nil)
        return nil;
    srcCallsign = [srcCallsign stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [[DExtraKeepAlivePacket alloc] initWithSrcCallsign:srcCallsign];
}

- (id)initWithSrcCallsign:(NSString *)srcCallsign {
    if (self = [super init]) {
        self.srcCallsign = srcCallsign;
    }
    return self;
}

- (NSData *)toData {
    char packet[9];
    
    NSString *paddedCallsign;
    
    paddedCallsign = [self.srcCallsign stringByPaddingToLength:8 withString:@" " startingAtIndex:0];
    [paddedCallsign getCString:&(packet[0]) maxLength:9 encoding:NSASCIIStringEncoding];
    
    return [NSData dataWithBytes:packet length:9];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DExtraKeepAlivePacket srcCallsign: %@", self.srcCallsign];
}

@end
