//
// DExtraClient.m
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

#import "DExtraClient.h"

#ifdef DEXTRA_DEBUG
#define DebugLog(...) NSLog(__VA_ARGS__)
#else
#define DebugLog(...)
#endif

#import "DExtraConnectPacket.h"
#import "DExtraConnectAckPacket.h"
#import "DExtraConnectNackPacket.h"
#import "DExtraDisconnectPacket.h"
#import "DExtraDisconnectAckPacket.h"
#import "DExtraKeepAlivePacket.h"

typedef NS_ENUM(NSInteger, DExtraPacketTag) {
    DExtraPacketTagConnect,
    DExtraPacketTagDisconnect,
    DExtraPacketTagKeepAlive,
    DExtraPacketTagDV
};

NSString *NSStringFromDExtraClientStatus(DExtraClientStatus status) {
    switch (status) {
        case DExtraClientStatusIdle:
            return @"Not Connected";
        case DExtraClientStatusConnecting:
            return @"Connecting";
        case DExtraClientStatusConnected:
            return @"Connected";
        case DExtraClientStatusFailed:
            return @"Connection Failed";
        case DExtraClientStatusDisconnecting:
            return @"Disconnecting";
        case DExtraClientStatusLost:
            return @"Connection Lost";
    }
}

@interface DExtraClient ()

- (void)ensureConnected:(NSTimer *)timer;
- (void)ensureDisonnected:(NSTimer *)timer;

@property (nonatomic, assign) DExtraClientStatus status;
@property (nonatomic, strong) GCDAsyncUdpSocket *socket;
@property (atomic, strong) NSDate *lastHeard;

@property (nonatomic, strong) NSTimer *timeoutTimer;
@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, strong) NSTimer *disconnectTimer;

@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, strong) NSString *reflectorCallsign;
@property (nonatomic, strong) NSString *reflectorModule;
@property (nonatomic, strong) NSString *userCallsign;

@end

@implementation DExtraClient

- (id)initWithHost:(NSString *)host
              port:(NSInteger)port
          callsign:(NSString *)reflectorCallsign
            module:(NSString *)reflectorModule
     usingCallsign:(NSString *)userCallsign {
    if ((self = [super init])) {
        _delegate = nil;
        _status = DExtraClientStatusIdle;
        _socket = nil;
        _lastHeard = nil;
        
        _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(ensureAlive:) userInfo:nil repeats:YES];

        self.host = host;
        self.port = port;
        self.reflectorCallsign = reflectorCallsign;
        self.reflectorModule = reflectorModule;
        self.userCallsign = userCallsign;
    }
    
    return self;
}

- (void)dealloc {
    if (self.socket)
        [self.socket close];
    if (self.timeoutTimer)
        [self.timeoutTimer invalidate];
    if (self.connectTimer)
        [self.connectTimer invalidate];
    if (self.disconnectTimer)
        [self.disconnectTimer invalidate];
}

// Custom property, so the same protection mechanism can be used by other internal functions
@synthesize status = _status;

- (void)setStatus:(DExtraClientStatus)status {
    @synchronized (self) {
        _status = status;
    }
    [self.delegate dextraClient:self didChangeStatusTo:status];
}

- (DExtraClientStatus)status {
    @synchronized (self) {
        return _status;
    }
}

- (void)connect {
    @synchronized (self) {
        if (_status != DExtraClientStatusIdle)
            return;
        
        _status = DExtraClientStatusConnecting;
    }
    [self.delegate dextraClient:self didChangeStatusTo:DExtraClientStatusConnecting];

    self.socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.socket setPreferIPv4];
    
    NSError *error = nil;
    
    if (![self.socket bindToPort:0 error:&error] || ![self.socket beginReceiving:&error]) {
        NSLog(@"DExtraClient: Error binding or receiving on socket: %@", error);
        BOOL statusChanged = NO;
        @synchronized (self) {
            if (_status == DExtraClientStatusConnecting) {
                _status = DExtraClientStatusFailed;
                statusChanged = YES;
            }
        }
        if (statusChanged)
            [self.delegate dextraClient:self didChangeStatusTo:DExtraClientStatusFailed];
        return;
    }

    DExtraConnectPacket *connectPacket = [[DExtraConnectPacket alloc] initWithSrcCallsign:self.userCallsign
                                                                                srcModule:@""
                                                                               destModule:self.reflectorModule
                                                                                 revision:1];
    [self.socket sendData:[connectPacket toData] toHost:self.host port:self.port withTimeout:3 tag:DExtraPacketTagConnect];
    if (self.connectTimer)
        [self.connectTimer invalidate];
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(ensureConnected:) userInfo:nil repeats:NO];
    DebugLog(@"DExtraClient: Sent packet with data: %@", [connectPacket toData]);
}

- (void)disconnect {
    @synchronized (self) {
        if (_status != DExtraClientStatusConnected)
            return;
        
        _status = DExtraClientStatusDisconnecting;
    }
    [self.delegate dextraClient:self didChangeStatusTo:DExtraClientStatusDisconnecting];

    DExtraDisconnectPacket *disconnectPacket = [[DExtraDisconnectPacket alloc] initWithSrcCallsign:self.userCallsign srcModule:@""];
    [self.socket sendData:[disconnectPacket toData] toHost:self.host port:self.port withTimeout:3 tag:DExtraPacketTagDisconnect];
    if (self.disconnectTimer)
        [self.disconnectTimer invalidate];
    self.disconnectTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(ensureDisonnected:) userInfo:nil repeats:NO];
    DebugLog(@"DExtraClient: Sent packet with data: %@", [disconnectPacket toData]);
}

- (void)sendDVPacket:(id)packet {
    if (!(self.status == DExtraClientStatusConnected) ||
        !([packet isKindOfClass:[DVFramePacket class]] || [packet isKindOfClass:[DVHeaderPacket class]]))
        return;

    DebugLog(@"DExtraClient: Sending packet: %@", packet);
    DebugLog(@"DExtraClient: Packet data: %@", [packet toData]);
    [self.socket sendData:[packet toData] toHost:self.host port:self.port withTimeout:1 tag:DExtraPacketTagDV];
}

- (void)ensureAlive:(NSTimer *)timer {
    DebugLog(@"DExtraClient: Checking if connection is alive");
    if (!self.lastHeard)
        return;
    NSTimeInterval lastHeardInterval = [[NSDate date] timeIntervalSinceDate:self.lastHeard];

    BOOL statusChanged = NO;
    @synchronized (self) {
        if (_status == DExtraClientStatusConnected && lastHeardInterval > 30) {
            _status = DExtraClientStatusLost;
            statusChanged = YES;
        }
    }
    if (statusChanged)
        [self.delegate dextraClient:self didChangeStatusTo:DExtraClientStatusLost];
}

- (void)ensureConnected:(NSTimer *)timer {
    DebugLog(@"DExtraClient: Checking if connect succeeded");
    BOOL statusChanged = NO;
    @synchronized (self) {
        if (_status == DExtraClientStatusConnecting) {
            _status = DExtraClientStatusFailed;
            statusChanged = YES;
        }
    }
    if (statusChanged)
        [self.delegate dextraClient:self didChangeStatusTo:DExtraClientStatusFailed];
}

- (void)ensureDisonnected:(NSTimer *)timer {
    DebugLog(@"DExtraClient: Checking if disconnect succeeded");
    BOOL statusChanged = NO;
    @synchronized (self) {
        if (_status == DExtraClientStatusDisconnecting) {
            _status = DExtraClientStatusIdle;
            statusChanged = YES;
        }
    }
    if (statusChanged)
        [self.delegate dextraClient:self didChangeStatusTo:DExtraClientStatusIdle];
}

#pragma mark GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    DebugLog(@"DExtraClient: Could not send data with tag: %ld error: %@", tag, [error localizedDescription]);
    if (tag == DExtraPacketTagConnect) {
        BOOL statusChanged = NO;
        @synchronized (self) {
            if (_status == DExtraClientStatusConnecting) {
                _status = DExtraClientStatusLost;
                statusChanged = YES;
            }
        }
        if (statusChanged)
            [self.delegate dextraClient:self didChangeStatusTo:DExtraClientStatusLost];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext {
    id packet;

    if ((packet = [DVFramePacket packetFromData:data]) == nil &&
        (packet = [DVHeaderPacket packetFromData:data]) == nil &&
        (packet = [DExtraKeepAlivePacket packetFromData:data]) == nil &&
        (packet = [DExtraConnectAckPacket packetFromData:data]) == nil &&
        (packet = [DExtraConnectNackPacket packetFromData:data]) == nil &&
        (packet = [DExtraDisconnectPacket packetFromData:data]) == nil &&
        (packet = [DExtraDisconnectAckPacket packetFromData:data]) == nil) {
        NSLog(@"DExtraClient: Unknown packet with data: %@", data);
        return;
    }

    DebugLog(@"DExtraClient: Received packet: %@", packet);
    DebugLog(@"DExtraClient: Packet data: %@", data);
    self.lastHeard = [NSDate date];
    
    // Packets that don't change state
    if ([packet isKindOfClass:[DVFramePacket class]] ||
        [packet isKindOfClass:[DVHeaderPacket class]]) {
        if (!(self.status == DExtraClientStatusConnected))
            return;
        [self.delegate dextraClient:self didReceiveDVPacket:(id)packet];
        return;
    }
    if ([packet isKindOfClass:[DExtraKeepAlivePacket class]]) {
        if (!(self.status == DExtraClientStatusConnected))
            return;
        DExtraKeepAlivePacket *keepAlivePacket = [[DExtraKeepAlivePacket alloc] initWithSrcCallsign:self.userCallsign];
        [self.socket sendData:[keepAlivePacket toData] toHost:self.host port:self.port withTimeout:3 tag:DExtraPacketTagKeepAlive];
        DebugLog(@"DExtraClient: Exchanged keep alive packets");
        return;
    }

    BOOL statusChanged = NO;
    DExtraClientStatus newStatus;
    BOOL invalidateConnectTimer = NO;
    BOOL invalidateDisconnectTimer = NO;

    @synchronized (self) {
        if ([packet isKindOfClass:[DExtraConnectAckPacket class]]) {
            if (_status == DExtraClientStatusConnecting) {
                _status = DExtraClientStatusConnected;
                invalidateConnectTimer = YES;
                statusChanged = YES;
            }
        } else if ([packet isKindOfClass:[DExtraConnectNackPacket class]]) {
            if (_status == DExtraClientStatusConnecting) {
                _status = DExtraClientStatusFailed;
                invalidateConnectTimer = YES;
                statusChanged = YES;
            }
        } else if ([packet isKindOfClass:[DExtraDisconnectPacket class]]) {
            _status = DExtraClientStatusIdle;
            statusChanged = YES;
        } else if ([packet isKindOfClass:[DExtraDisconnectAckPacket class]]) {
            if (_status == DExtraClientStatusDisconnecting) {
                _status = DExtraClientStatusIdle;
                invalidateDisconnectTimer = YES;
                statusChanged = YES;
            }
        }
        newStatus = _status;
    }
    if (statusChanged)
        [self.delegate dextraClient:self didChangeStatusTo:newStatus];
    if (invalidateConnectTimer) {
        if (self.connectTimer)
            [self.connectTimer invalidate];
        self.connectTimer = nil;
    }
    if (invalidateDisconnectTimer) {
        if (self.disconnectTimer)
            [self.disconnectTimer invalidate];
        self.disconnectTimer = nil;
    }
}

@end
