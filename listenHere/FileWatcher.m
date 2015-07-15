//
//  FileWatcher.m
//  listenHere
//
//  Created by Ted Howard on 7/13/15.
//  Copyright (c) 2015 Ted C. Howard. All rights reserved.
//

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