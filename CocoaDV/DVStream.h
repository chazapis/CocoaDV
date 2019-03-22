//
// DVStream.h
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

#import "DSTARHeader.h"
#import "DSTARFrame.h"

@interface DVStream : NSObject

- (id)initWithDSTARHeader:(DSTARHeader *)dstarHeader;

- (void)appendDSTARFrame:(DSTARFrame *)dstarFrame;
- (void)markLast;

- (id)dvPacketAtIndex:(NSUInteger)index;

@property (nonatomic, readonly) unsigned short streamId;
@property (nonatomic, readonly, getter=getDVPacketCount) NSUInteger dvPacketCount;

@end
