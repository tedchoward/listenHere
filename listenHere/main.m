/*
 * Copyright (c) 2015, Ted C. Howard
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "FileWatcher.h"
#import "TCPServer.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        NSArray *arguments = processInfo.arguments;
        
        if (arguments.count < 2) {
            fprintf(stderr, "Example usage:\n\tlistenHere <path>\n");
            exit(EXIT_FAILURE);
        }
        
        NSString *path = arguments[1];
        
        TCPServer *tcpClient = [[TCPServer alloc] initWithPort:4001];
        [tcpClient start];
        
        FileWatcher *fileWatcher = [[FileWatcher alloc] initWithPath:path callback:^(NSString *path, FSEventStreamEventFlags flags) {
            // ["file", "$event", "$fileDirectory", "$fileName"]
            
            NSString *eventType = nil;
            
            if (flags & kFSEventStreamEventFlagItemCreated) {
                eventType = @"added";
            } else if (flags & kFSEventStreamEventFlagItemRemoved) {
                eventType = @"removed";
            } else if (flags & kFSEventStreamEventFlagItemRenamed) {
                eventType = @"renamed";
            } else if (flags & kFSEventStreamEventFlagItemModified) {
                eventType = @"modified";
            }
            
            NSArray *pathComponents = [path pathComponents];
            NSString *folder = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange(0, pathComponents.count - 1)]];
            NSString *fileName = pathComponents[pathComponents.count - 1];
            
            NSArray *message = @[@"file", eventType, folder, fileName];
            NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:NULL];
            [tcpClient pushData:data];
            
            NSLog(@"%@ %@: %@",message[0], message[1], path);
        }];
        
        [fileWatcher start];
        
        [[NSRunLoop currentRunLoop] run];
        
    }
    return 0;
}
