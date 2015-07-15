//
//  TCPClient.m
//  listenHere
//
//  Created by Ted Howard on 7/14/15.
//  Copyright (c) 2015 Ted C. Howard. All rights reserved.
//

#import "TCPServer.h"
#include <sys/socket.h>
#include <netinet/in.h>

void handleConnect(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info);

@interface TCPServer ()
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, assign) BOOL readyToWrite;
@property (nonatomic, strong) NSMutableArray *dataQueue;
@end

@implementation TCPServer {
    CFSocketRef _socket;
}

- (instancetype)initWithPort:(uint16_t)port {
    self = [super init];
    
    if (self) {
        self.dataQueue = [[NSMutableArray alloc] init];
        
        CFSocketContext socketContext = {0, (__bridge void *)(self), NULL, NULL, NULL};
        
        _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, handleConnect, &socketContext);
        
        int yes = 1;
        setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
        
        struct sockaddr_in sin;
        memset(&sin, 0, sizeof(sin));
        sin.sin_len = sizeof(sin);
        sin.sin_family = AF_INET;
        sin.sin_port = htons(port);
        sin.sin_addr.s_addr = htonl(INADDR_ANY);
        
        NSData *address4 = [NSData dataWithBytes:&sin length:sizeof(sin)];
        CFSocketError err;
        err = CFSocketSetAddress(_socket, (CFDataRef)address4);
        
        if (kCFSocketSuccess != err) {
            NSLog(@"Could not bind to IP Address, %ld", err);
            CFRelease(_socket);
            exit(EXIT_FAILURE);
        }
        
        NSLog(@"Server bound to port %d", port);
    }
    
    return self;
}

- (void)dealloc {
    CFSocketInvalidate(_socket);
    CFRelease(_socket);
}

- (void)setOutputStream:(NSOutputStream *)outputStream {
    if (_outputStream != nil) {
        [_outputStream close];
        [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _outputStream.delegate = nil;
    }
    
    _outputStream = outputStream;
    _outputStream.delegate = self;
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream open];
}

/**
 * Invoked from a different thread
 **/
- (void)pushData:(NSData *)data {
    [self performSelector:@selector(pushDataInternal:) onThread:self withObject:data waitUntilDone:NO];
}

- (void)pushDataInternal:(NSData *)data {
    if (_readyToWrite) {
        [self writeData:data];
    } else {
        [self.dataQueue addObject:data];
    }
}

- (void)writeData:(NSData *)data {
    self.readyToWrite = NO;
    
    uint8_t *bytes = (uint8_t *)data.bytes;
    NSUInteger maxLength = data.length;
    NSInteger bytesWritten = [_outputStream write:bytes maxLength:maxLength];
    
    if (bytesWritten < maxLength) {
        NSData *leftOverData = [data subdataWithRange:NSMakeRange(bytesWritten, data.length - bytesWritten)];
        [self.dataQueue insertObject:leftOverData atIndex:0];
    }
}

#pragma mark - NSThread

- (void)main {
    CFRunLoopSourceRef socketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), socketSource, kCFRunLoopDefaultMode);
    CFRelease(socketSource);
    NSLog(@"Server listening for connections.");
    [[NSRunLoop currentRunLoop] run];
}


#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
//    if (eventCode & NSStreamEventNone) {
//        NSLog(@"NSStreamEventNone");
//    }
//    
//    if (eventCode & NSStreamEventOpenCompleted) {
//        NSLog(@"NSStreamEventOpenCompleted");
//    }
//    
//    if (eventCode & NSStreamEventHasBytesAvailable) {
//        NSLog(@"NSStreamEventHasBytesAvailable");
//    }
    
    if (eventCode & NSStreamEventHasSpaceAvailable) {
//        NSLog(@"NSStreamEventHasSpaceAvailable");
        if (self.dataQueue.count > 0) {
            NSData *data = self.dataQueue[0];
            
            [self.dataQueue removeObjectAtIndex:0];
            
            [self writeData:data];
        } else {
            self.readyToWrite = YES;
        }
    }
    
    if (eventCode & NSStreamEventErrorOccurred) {
        NSLog(@"NSStreamEventErrorOccurred:\n%@", [[aStream streamError] localizedDescription]);
    }
    
//    if (eventCode & NSStreamEventEndEncountered) {
//        NSLog(@"NSStreamEventEndEncountered");
//    }
}

@end

void handleConnect(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info) {
    if (callbackType == kCFSocketAcceptCallBack) {
        NSLog(@"Server connected to client.");
        CFSocketNativeHandle nativeSocket = *(CFSocketNativeHandle *)data;
        TCPServer *tcpClient = (__bridge TCPServer *)info;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocket, NULL, &writeStream);
        tcpClient.outputStream = CFBridgingRelease(writeStream);
    }
}
