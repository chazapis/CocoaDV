//
// DExtraConnectAckPacket.m
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

#import "DExtraConnectAckPacket.h"

@implementation DExtraConnectAckPacket

+ (DExtraConnectAckPacket *)packetFromData:(NSData *)data {
    if ([data length] != 14)
        return nil;
    
    char packet[14];
    
    [data getBytes:packet length:14];
    NSString *ack = [[NSString alloc] initWithBytes:&(packet[10]) length:3 encoding:NSASCIIStringEncoding];
    if (ack == nil || ![ack isEqualToString:@"ACK"])
        return nil;
    NSString *srcCallsign = [[NSString alloc] initWithBytes:&(packet[0]) length:8 encoding:NSASCIIStringEncoding];
    NSString *srcModule = [[NSString alloc] initWithBytes:&(packet[8]) length:1 encoding:NSASCIIStringEncoding];
    NSString *destModule = [[NSString alloc] initWithBytes:&(packet[9]) length:1 encoding:NSASCIIStringEncoding];
    if (srcCallsign == nil || srcModule == nil || destModule == nil)
        return nil;
    if ([destModule isEqualToString:@" "])
        return nil;
    srcCallsign = [srcCallsign stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return [[DExtraConnectAckPacket alloc] initWithSrcCallsign:srcCallsign
                                                     srcModule:srcModule
                                                    destModule:destModule
                                                      revision:0];
}

- (id)initWithSrcCallsign:(NSString *)srcCallsign
                srcModule:(NSString *)srcModule
               destModule:(NSString *)destModule
                 revision:(unsigned char)revision {
    if (self = [super init]) {
        self.srcCallsign = srcCallsign;
        self.srcModule = srcModule;
        self.destModule = destModule;
        self.revision = revision;
    }
    return self;
}

- (NSData *)toData {
    char packet[14];
    
    NSString *paddedCallsign;
    NSString *paddedModule;
    
    paddedCallsign = [self.srcCallsign stringByPaddingToLength:8 withString:@" " startingAtIndex:0];
    [paddedCallsign getCString:&(packet[0]) maxLength:9 encoding:NSASCIIStringEncoding];
    paddedModule = [self.srcModule stringByPaddingToLength:1 withString:@" " startingAtIndex:0];
    [paddedModule getCString:&(packet[8]) maxLength:2 encoding:NSASCIIStringEncoding];
    paddedModule = [self.destModule stringByPaddingToLength:1 withString:@" " startingAtIndex:0];
    [paddedModule getCString:&(packet[9]) maxLength:2 encoding:NSASCIIStringEncoding];
    if (self.revision == 2) {
        packet[10] = 0;
        return [NSData dataWithBytes:packet length:11];
    } else {
        [@"ACK" getCString:&(packet[10]) maxLength:4 encoding:NSASCIIStringEncoding];
    	return [NSData dataWithBytes:packet length:14];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DExtraConnectAckPacket srcCallsign: %@ srcModule: %@ destModule: %@ revision: %hhu", self.srcCallsign, self.srcModule, self.destModule, self.revision];
}

@end
