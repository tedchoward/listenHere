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

#import "FileWatcher.h"

void eventStreamCallbackFunction(ConstFSEventStreamRef streamRef, void *clientCallbackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@interface FileWatcher()
@property (nonatomic, strong) NSString *path;
@property (nonatomic, copy) fileWatcherCallback callback;
@end

@implementation FileWatcher {
    FSEventStreamRef _stream;
}

- (instancetype)initWithPath:(NSString *)path callback:(fileWatcherCallback)callback {
    self = [super init];
    
    if (self) {
        self.path = path;
        self.callback = callback;
        
        FSEventStreamContext context;
        context.info = (__bridge void *)(self);
        NSArray *paths = @[path];
        
        _stream = FSEventStreamCreate(NULL, &eventStreamCallbackFunction, &context, CFBridgingRetain(paths), kFSEventStreamEventIdSinceNow, 1.0, kFSEventStreamCreateFlagFileEvents);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup:) name:NSThreadWillExitNotification object:self];

    }
    
    return self;
}

- (void)main {
    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);
    [[NSRunLoop currentRunLoop] run];
}

- (void)cleanup:(NSNotification *)notification {
    if ([notification.name isEqualToString:NSThreadWillExitNotification]) {
        FSEventStreamStop(_stream);
        FSEventStreamInvalidate(_stream);
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    FSEventStreamRelease(_stream);
}

@end

void eventStreamCallbackFunction(ConstFSEventStreamRef streamRef, void *clientCallbackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    
    FileWatcher *watcher = (__bridge FileWatcher *)clientCallbackInfo;
    
    size_t i;
    char **paths = eventPaths;
    
    @autoreleasepool {
        for (i = 0; i < numEvents; i++) {
            NSString *path = [NSString stringWithCString:paths[i] encoding:NSUTF8StringEncoding];
            FSEventStreamEventFlags flags = eventFlags[i];
            dispatch_async(dispatch_get_main_queue(), ^{
                watcher.callback(path, flags);
            });
        }

    }
}