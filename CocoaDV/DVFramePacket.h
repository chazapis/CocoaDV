//
// DVFramePacket.h
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

#import "DSTARFrame.h"

@interface DVFramePacket : NSObject

+ (DVFramePacket *)packetFromData:(NSData *)data;

- (id)initWithBand1:(unsigned char)band1
              band2:(unsigned char)band2
              band3:(unsigned char)band3
           streamId:(unsigned short)streamId
           packetId:(unsigned char)packetId
         dstarFrame:(DSTARFrame *)dstarFrame;

- (NSData *)toData;
- (NSString *)description;

@property(nonatomic, assign) unsigned char band1;
@property(nonatomic, assign) unsigned char band2;
@property(nonatomic, assign) unsigned char band3;
@property(nonatomic, assign) unsigned short streamId;
@property(nonatomic, assign) unsigned char packetId;
@property(nonatomic, strong) DSTARFrame *dstarFrame;

@property(nonatomic, readonly) BOOL isLast;

@end
