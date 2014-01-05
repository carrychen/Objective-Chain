//
//  OCAProducer.m
//  Objective-Chain
//
//  Created by Martin Kiss on 30.12.13.
//  Copyright © 2014 Martin Kiss. All rights reserved.
//

#import "OCAProducer+Private.h"
#import "OCAConnection+Private.h"





@interface OCAProducer ()


@property (OCA_atomic, readonly, strong) NSMutableArray *mutableConnections;


@end










@implementation OCAProducer





#pragma mark Creating Producer


- (instancetype)init {
    self = [super init];
    if (self) {
        OCAAssert(self.class != [OCAProducer class], @"Cannot instantinate abstract class.") return nil;
    }
    return self;
}





#pragma mark Managing Connections


OCALazyGetter(NSMutableArray *, mutableConnections) {
    return [[NSMutableArray alloc] init];
}


- (NSArray *)connections {
    return [self.mutableConnections copy];
}


- (void)addConnection:(OCAConnection *)connection {
    NSMutableArray *connections = self.mutableConnections;
    @synchronized(connections) {
        [connections addObject:connection];
        
        [self didAddConnection:connection];
    }
}


- (void)didAddConnection:(OCAConnection *)connection {
    if (self.finished) {
        [connection producerDidFinishWithError:self.error];
    }
}


- (void)removeConnection:(OCAConnection *)connection {
    [self willRemoveConnection:connection];
    
    NSMutableArray *connections = self.mutableConnections;
    @synchronized(connections) {
        [connections removeObjectIdenticalTo:connection];
    }
}


- (void)willRemoveConnection:(OCAConnection *)connection {
}





#pragma mark Connecting to Producer


- (OCAConnection *)connectTo:(id<OCAConsumer>)consumer {
    OCAConnection *connection = [[OCAConnection alloc] initWithProducer:self consumer:consumer];
    return connection;
}





#pragma mark Lifetime of Producer


- (void)produceValue:(id)value {
    if (self.finished) return;
    self->_lastValue = value;
    
    for (OCAConnection *connection in [self.mutableConnections copy]) {
        [connection producerDidProduceValue:value];
    }
}


- (void)finishProducingWithError:(NSError *)error {
    if (self.finished) return;
    
    self->_finished = YES;
    self->_error = error;
    
    for (OCAConnection *connection in [self.mutableConnections copy]) {
        [connection producerDidFinishWithError:error];
    }
    
    [self.mutableConnections setArray:nil];
}





@end


