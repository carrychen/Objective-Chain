//
//  OCABridge.m
//  Objective-Chain
//
//  Created by Martin Kiss on 5.1.14.
//  Copyright (c) 2014 Martin Kiss. All rights reserved.
//

#import "OCABridge.h"
#import "OCAProducer+Subclass.h"
#import "OCATransformer.h"










@implementation OCABridge





#pragma mark Creating Bridge


- (instancetype)initWithValueClass:(Class)valueClass {
    NSValueTransformer *transformer = [[OCATransformer pass] specializeFromClass:valueClass toClass:valueClass];
    return [self initWithTransformer:transformer];
}


- (instancetype)initWithTransformer:(NSValueTransformer *)transformer {
    self = [super initWithValueClass:[transformer.class transformedValueClass]];
    if (self) {
        self->_transformer = transformer ?: [OCATransformer pass];
    }
    return self;
}


+ (OCABridge *)bridge {
    return [[self alloc] initWithTransformer:nil];
}


+ (OCABridge *)bridgeForClass:(Class)class {
    NSValueTransformer *transformer = [[OCATransformer pass] specializeFromClass:class toClass:class];
    return [[self alloc] initWithTransformer:transformer];
}


+ (OCABridge *)bridgeWithTransformer:(NSValueTransformer *)transformer {
    return [[self alloc] initWithTransformer:transformer];
}





#pragma mark Lifetime of Bridge


- (Class)consumedValueClass {
    return [self.transformer.class valueClass];
}


- (void)consumeValue:(id)value {
    id transformedValue = [self.transformer transformedValue:value];
    [self produceValue:transformedValue];
}


- (void)finishConsumingWithError:(NSError *)error {
    [self finishProducingWithError:error];
}





#pragma mark Describing Bridge


- (NSString *)descriptionName {
    return @"Bridge";
}





@end










@implementation OCAProducer (OCABridge)





- (OCAProducer *)produceTransformed:(NSArray *)transformers CONVENIENCE {
    OCABridge *bridge = [[OCABridge alloc] initWithTransformer:[OCATransformer sequence:transformers]];
    [self addConsumer:bridge];
    return bridge;
}




@end

