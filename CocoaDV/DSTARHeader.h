//
// DSTARHeader.h
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

@interface DSTARHeader : NSObject

+ (DSTARHeader *)fromData:(NSData *)data;

- (id)initWithFlag1:(unsigned char)flag1
              flag2:(unsigned char)flag2
              flag3:(unsigned char)flag3
  repeater1Callsign:(NSString *)repeater1Callsign
  repeater2Callsign:(NSString *)repeater2Callsign
         urCallsign:(NSString *)urCallsign
         myCallsign:(NSString *)myCallsign
           mySuffix:(NSString *)mySuffix;

- (NSData *)toData;
- (NSString *)description;

@property(nonatomic, assign) unsigned char flag1;
@property(nonatomic, assign) unsigned char flag2;
@property(nonatomic, assign) unsigned char flag3;
@property(nonatomic, strong) NSString *repeater1Callsign;
@property(nonatomic, strong) NSString *repeater2Callsign;
@property(nonatomic, strong) NSString *urCallsign;
@property(nonatomic, strong) NSString *myCallsign;
@property(nonatomic, strong) NSString *mySuffix;

@end
