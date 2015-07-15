//
//  TCPClient.h
//  listenHere
//
//  Created by Ted Howard on 7/14/15.
//  Copyright (c) 2015 Ted C. Howard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCPServer : NSThread<NSStreamDelegate>

- (instancetype)initWithPort:(uint16_t)port;

- (void)pushData:(NSData *)data;

@end
