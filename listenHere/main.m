//
//  main.m
//  listenHere
//
//  Created by Ted Howard on 7/13/15.
//  Copyright (c) 2015 Ted C. Howard. All rights reserved.
//

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
