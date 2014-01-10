//
//  OCAFoundation+Base.m
//  Objective-Chain
//
//  Created by Martin Kiss on 10.1.14.
//  Copyright (c) 2014 Martin Kiss. All rights reserved.
//

#import "OCAFoundation+Base.h"





@implementation OCAFoundation

@end





extern NSUInteger OCANormalizeIndex(NSInteger index, NSUInteger length) {
    
    if (index < 0)
        index = length + index;
    
    if (index < 0)
        return 0;
    
    if (index >= length)
        index = length;
    
    return index;
}


extern NSRange OCANormalizeRange(NSRange range, NSUInteger length) {
    
    if (range.location > length)
        range.location = length;
    
    NSUInteger end = length - range.location;
    
    if (range.length > end)
        range.length = end;
    
    return range;
}


