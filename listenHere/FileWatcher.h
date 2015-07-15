//
//  FileWatcher.h
//  listenHere
//
//  Created by Ted Howard on 7/13/15.
//  Copyright (c) 2015 Ted C. Howard. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^fileWatcherCallback)(NSString *path, FSEventStreamEventFlags flags);

@interface FileWatcher : NSThread

- (instancetype)initWithPath:(NSString *)path callback:(fileWatcherCallback)callback;

@end
