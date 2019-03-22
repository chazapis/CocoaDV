//
// DExtraClient.h
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
#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>

#import "DVHeaderPacket.h"
#import "DVFramePacket.h"

typedef NS_ENUM(NSInteger, DExtraClientStatus) {
    DExtraClientStatusIdle,             // Not connected
    DExtraClientStatusConnecting,       // In the process of connecting
    DExtraClientStatusConnected,        // Connected (normal operation)
    DExtraClientStatusFailed,           // Connection failed
    DExtraClientStatusDisconnecting,    // In the process of disconnecting
    DExtraClientStatusLost              // Connection lost
};

NSString *NSStringFromDExtraClientStatus(DExtraClientStatus status);

@class DExtraClient;

@protocol DExtraClientDelegate <NSObject>

- (void)dextraClient:(DExtraClient *)client didChangeStatusTo:(DExtraClientStatus)status;
- (void)dextraClient:(DExtraClient *)client didReceiveDVPacket:(id)packet;

@end

@interface DExtraClient : NSObject <GCDAsyncUdpSocketDelegate>

- (id)initWithHost:(NSString *)host
              port:(NSInteger)port
          callsign:(NSString *)reflectorCallsign
            module:(NSString *)reflectorModule
     usingCallsign:(NSString *)userCallsign;

- (void)connect;
- (void)disconnect;

- (void)sendDVPacket:(id)packet;

@property (nonatomic, weak) id <DExtraClientDelegate> delegate;
@property (nonatomic, assign, readonly) DExtraClientStatus status;

@property (nonatomic, strong, readonly) NSString *host;
@property (nonatomic, assign, readonly) NSInteger port;
@property (nonatomic, strong, readonly) NSString *reflectorCallsign;
@property (nonatomic, strong, readonly) NSString *reflectorModule;
@property (nonatomic, strong, readonly) NSString *userCallsign;

@end
