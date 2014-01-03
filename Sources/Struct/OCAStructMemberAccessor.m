//
//  OCAStructMemberAccessor.m
//  Objective-Chain
//
//  Created by Martin Kiss on 3.1.14.
//  Copyright (c) 2014 Martin Kiss. All rights reserved.
//

#import "OCAStructMemberAccessor.h"



@interface OCAStructMemberAccessor ()


@property (OCA_atomic, readonly, copy) NSValue *(^getBlock)(NSValue *);
@property (OCA_atomic, readonly, copy) NSValue *(^setBlock)(NSValue *, NSValue *);


@end










@implementation OCAStructMemberAccessor





- (instancetype)initWithStructType:(const char *)structType
                        memberType:(const char *)memberType
                        memberPath:(NSString *)memberPath
                          isNumeric:(BOOL)isNumeric
                          getBlock:(NSValue *(^)(NSValue *structValue))getBlock
                          setBlock:(NSValue *(^)(NSValue *structValue, NSValue *memberValue))setBlock {
    self = [super init];
    if (self) {
        //TODO: Assertions
        //TODO: Check structType to be really struct
        self->_structType = structType;
        self->_memberType = memberType;
        self->_memberPath = memberPath;
        self->_isNumeric = isNumeric;
        self->_getBlock = getBlock;
        self->_setBlock = setBlock;
    }
    return self;
}


- (NSValue *)memberFromStructure:(NSValue *)structValue {
    if ( ! structValue) return nil;
    OCAAssert(strcmp(structValue.objCType, self.structType) == 0, @"Type mismatch for struct.") return nil;
    
    return self.getBlock(structValue);
}


- (NSValue *)setMember:(NSValue *)memberValue toStructure:(NSValue *)structValue {
    if ( ! structValue) return nil;
    OCAAssert(strcmp(structValue.objCType, self.structType) == 0, @"Type mismatch for struct.") return nil;
    
    if (memberValue) {
        if ([memberValue isKindOfClass:[NSNumber class]]) {
            OCAAssert(self.isNumeric, @"Numbers accepted only for numeric members.") return nil;
        }
        else {
            OCAAssert( ! self.isNumeric, @"Non-Numbers accepted only for sub-struct members.") return nil;
            OCAAssert(strcmp(memberValue.objCType, self.memberType) == 0, @"Type mismatch for struct member") return nil;
        }
    }
    // What can pass here: nil, NSNumber (only if the member is numeric), NSValue (only if member is non-numeric)
    return self.setBlock(structValue, memberValue);
}


+ (BOOL)isNumericType:(const char *)type {
    return (strlen(type) == 1 && strchr("cCsSiIlLqQfd", type[0]) != NULL);
}





@end
