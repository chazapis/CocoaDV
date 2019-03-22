//
// DSTARHeader.m
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

#import "DSTARHeader.h"

#import "NSData+CRC.h"

@implementation DSTARHeader

+ (DSTARHeader *)fromData:(NSData *)data {
    if ([data length] != 41)
        return nil;
    
    char packet[41];
    
    [data getBytes:packet length:41];
    NSString *repeater1Callsign = [[NSString alloc] initWithBytes:&(packet[3]) length:8 encoding:NSASCIIStringEncoding];
    NSString *repeater2Callsign = [[NSString alloc] initWithBytes:&(packet[11]) length:8 encoding:NSASCIIStringEncoding];
    NSString *urCallsign = [[NSString alloc] initWithBytes:&(packet[19]) length:8 encoding:NSASCIIStringEncoding];
    NSString *myCallsign = [[NSString alloc] initWithBytes:&(packet[27]) length:8 encoding:NSASCIIStringEncoding];
    NSString *mySuffix = [[NSString alloc] initWithBytes:&(packet[35]) length:4 encoding:NSASCIIStringEncoding];
    if (repeater1Callsign == nil || repeater2Callsign == nil || urCallsign == nil || myCallsign == nil || mySuffix == nil)
        return nil;
    repeater1Callsign = [repeater1Callsign stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    repeater2Callsign = [repeater2Callsign stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    urCallsign = [urCallsign stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    myCallsign = [myCallsign stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    mySuffix = [mySuffix stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    unsigned char flag1 = packet[0];
    unsigned char flag2 = packet[1];
    unsigned char flag3 = packet[2];
    // unsigned short crc = packet[39] | (packet[40] << 8);

    return [[DSTARHeader alloc] initWithFlag1:flag1
                                        flag2:flag2
                                        flag3:flag3
                            repeater1Callsign:repeater1Callsign
                            repeater2Callsign:repeater2Callsign
                                   urCallsign:urCallsign
                                   myCallsign:myCallsign
                                     mySuffix:mySuffix];
}

- (id)initWithFlag1:(unsigned char)flag1
              flag2:(unsigned char)flag2
              flag3:(unsigned char)flag3
  repeater1Callsign:(NSString *)repeater1Callsign
  repeater2Callsign:(NSString *)repeater2Callsign
         urCallsign:(NSString *)urCallsign
         myCallsign:(NSString *)myCallsign
           mySuffix:(NSString *)mySuffix {
    if (self = [super init]) {
        self.flag1 = flag1;
        self.flag2 = flag2;
        self.flag3 = flag3;
        self.repeater1Callsign = repeater1Callsign;
        self.repeater2Callsign = repeater2Callsign;
        self.urCallsign = urCallsign;
        self.myCallsign = myCallsign;
        self.mySuffix = mySuffix;
    }
    return self;
}

- (NSData *)toData {
    char packet[41];
    
    NSString *paddedCallsign;
    NSString *paddedSuffix;
    
    packet[0] = self.flag1;
    packet[1] = self.flag2;
    packet[2] = self.flag3;
    paddedCallsign = [self.repeater1Callsign stringByPaddingToLength:8 withString:@" " startingAtIndex:0];
    [paddedCallsign getCString:&(packet[3]) maxLength:9 encoding:NSASCIIStringEncoding];
    paddedCallsign = [self.repeater2Callsign stringByPaddingToLength:8 withString:@" " startingAtIndex:0];
    [paddedCallsign getCString:&(packet[11]) maxLength:9 encoding:NSASCIIStringEncoding];
    paddedCallsign = [self.urCallsign stringByPaddingToLength:8 withString:@" " startingAtIndex:0];
    [paddedCallsign getCString:&(packet[19]) maxLength:9 encoding:NSASCIIStringEncoding];
    paddedCallsign = [self.myCallsign stringByPaddingToLength:8 withString:@" " startingAtIndex:0];
    [paddedCallsign getCString:&(packet[27]) maxLength:9 encoding:NSASCIIStringEncoding];
    paddedSuffix = [self.mySuffix stringByPaddingToLength:4 withString:@" " startingAtIndex:0];
    [paddedSuffix getCString:&(packet[35]) maxLength:5 encoding:NSASCIIStringEncoding];
    unsigned short crc = [[NSData dataWithBytes:packet length:39] crc];
    packet[39] = crc & 0xff;
    packet[40] = ((crc & 0xff00) >> 8) & 0xff;

    return [NSData dataWithBytes:packet length:41];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"DSTARHeader flag1: %hhu flag2: %hhu flag3: %hhu repeater1Callsign: %@ repeater2Callsign: %@ urCallsign: %@ myCallsign: %@ mySuffix: %@", self.flag1, self.flag2, self.flag3, self.repeater1Callsign, self.repeater2Callsign, self.urCallsign, self.myCallsign, self.mySuffix];
}

@end
