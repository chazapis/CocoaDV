//
// DExtraDisconnectAckPacket.m
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

#import "DExtraDisconnectAckPacket.h"

@implementation DExtraDisconnectAckPacket

+ (DExtraDisconnectAckPacket *)packetFromData:(NSData *)data {
    if ([data length] != 12)
        return nil;
    
    char packet[12];
    [data getBytes:packet length:12];
    NSString *disconnected = [[NSString alloc] initWithBytes:packet length:12 encoding:NSASCIIStringEncoding];
    if (disconnected == nil || ![disconnected isEqualToString:@"DISCONNECTED"])
        return nil;

    return [[DExtraDisconnectAckPacket alloc] init];
}

- (NSData *)toData {
    char packet[] = {'D', 'I', 'S', 'C', 'O', 'N', 'N', 'E', 'C', 'T', 'E', 'D'};
    
    return [NSData dataWithBytes:packet length:12];
}

- (NSString *)description {
    return @"DExtraDisconnectAckPacket";
}

@end
