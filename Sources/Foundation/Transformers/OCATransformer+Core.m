//
//  OCATransformer+Core.m
//  Objective-Chain
//
//  Created by Martin Kiss on 31.12.13.
//  Copyright © 2014 Martin Kiss. All rights reserved.
//

#import "OCATransformer+Core.h"
#import "OCAPredicate.h"





@implementation OCATransformer (Core)





#pragma mark Basic


+ (OCATransformer *)pass {
    return [[OCATransformer fromClass:nil toClass:nil symetric:OCATransformationPass]
            describe:@"pass"];
}


+ (OCATransformer *)discard {
    return [[OCATransformer fromClass:nil toClass:nil symetric:OCATransformationDiscard]
            describe:@"discard"];
}


+ (OCATransformer *)replaceWith:(id)replacement {
    return [[OCATransformer fromClass:nil toClass:[replacement classForKeyedArchiver] transform:^id(id input) {
        return replacement;
    } reverse:OCATransformationPass]
            describe:[NSString stringWithFormat:@"replace with %@", replacement]];
}





#pragma mark Conditions


+ (OCATransformer *)if:(NSPredicate *)predicate then:(NSValueTransformer *)thenTransformer else:(NSValueTransformer *)elseTransformer {
    Class inputClass = [OCAObject valueClassForClasses:@[ [thenTransformer.class valueClass] ?: [NSNull null],
                                                          [elseTransformer.class valueClass] ?: [NSNull null] ]];
    Class outputClass = [OCAObject valueClassForClasses:@[ [thenTransformer.class transformedValueClass] ?: [NSNull null],
                                                           [elseTransformer.class transformedValueClass] ?: [NSNull null] ]];
    
    return [[OCATransformer fromClass:inputClass toClass:outputClass transform:^id(id input) {
        BOOL condition = ( ! predicate || [predicate evaluateWithObject:input]);
        if (condition)
            return [thenTransformer transformedValue:input];
        else
            return (elseTransformer ? [elseTransformer transformedValue:input] : input);
    } reverse:OCATransformationPass]
            describe:[NSString stringWithFormat:@"if (%@) then %@ else %@", predicate, thenTransformer, elseTransformer ?: @"pass"]];
}


+ (OCATransformer *)passesPredicate:(NSPredicate *)predicate or:(id)replacement {
    return [OCATransformer if:predicate
            then:[OCATransformer pass]
            else:[OCATransformer replaceWith:replacement]];
}


+ (OCATransformer *)replaceNil:(id)replacement {
    return [OCATransformer if:[OCAPredicate isNil]
            then:[OCATransformer replaceWith:replacement]
            else:[OCATransformer pass]];
}


+ (OCATransformer *)kindOfClass:(Class)class or:(id)replacement {
    return [OCATransformer if:[OCAPredicate isKindOf:class]
            then:[[OCATransformer pass] specializeFromClass:nil toClass:class]
            else:[OCATransformer replaceWith:replacement]];
}


+ (OCATransformer *)ifTrue:(id)yesReplacement else:(id)noReplacement {
    return [OCATransformer map:@{
                                 @YES: yesReplacement ?: NSNull.null,
                                 @NO: noReplacement ?: NSNull.null,
                                 }];
}





#pragma mark Boolean


+ (OCATransformer *)evaluatePredicate:(NSPredicate *)predicate {
    return [OCATransformer if:predicate
            then:[OCATransformer replaceWith:@YES]
            else:[OCATransformer replaceWith:@NO]];
}


+ (OCATransformer *)negateBoolean {
    return [OCATransformer if:[OCAPredicate isTrue]
            then:[OCATransformer replaceWith:@NO]
            else:[OCATransformer replaceWith:@YES]];
}





#pragma mark Accessors


+ (OCATransformer *)access:(OCAAccessor *)accessor {
    return [[OCATransformer fromClass:accessor.objectClass toClass:accessor.valueClass
                            asymetric:^id(id input) {
                                return [accessor accessObject:input];
                            }]
            describe:accessor.description];
}


+ (OCATransformer *)modify:(OCAAccessor *)accessor value:(id)value {
    return [[OCATransformer fromClass:accessor.objectClass toClass:accessor.objectClass
                             symetric:^id(id input) {
                                 return [accessor modifyObject:input withValue:value];
                             }]
            describe:[NSString stringWithFormat:@"%@ = %@", accessor, value]];
}


+ (OCATransformer *)modify:(OCAAccessor *)accessor transformer:(NSValueTransformer *)transformer {
    return [[OCATransformer fromClass:accessor.objectClass toClass:accessor.objectClass
                            transform:^id(id input) {
                                
                                id value = [accessor accessObject:input];
                                value = [transformer transformedValue:value];
                                return [accessor modifyObject:input withValue:value];
                                
                            } reverse:^id(id input) {
                                id value = [accessor accessObject:input];
                                value = [transformer reverseTransformedValue:value];
                                return [accessor modifyObject:input withValue:value];
                            }]
            describe:[NSString stringWithFormat:@"transform %@ using %@", accessor, transformer]
            reverse:[NSString stringWithFormat:@"transform %@ using %@", accessor, [transformer reversed]]];
}


+ (OCATransformer *)evaluateExpression:(NSExpression *)expression {
    return [[OCATransformer fromClass:nil toClass:nil asymetric:^id(id input) {
        return [expression expressionValueWithObject:input context:nil];
    }]
            describe:[NSString stringWithFormat:@"evaluate “%@”", expression]];
}


+ (OCATransformer *)map:(NSDictionary *)dictionary {
    // Using classForKeyedArchiver, because __NSCFString is not very friendly class.
    Class inputClass = [OCAObject valueClassForClasses:[dictionary.allKeys valueForKey:OCAKP(NSObject, classForKeyedArchiver)]];
    Class outputClass = [OCAObject valueClassForClasses:[dictionary.allValues valueForKey:OCAKP(NSObject, classForKeyedArchiver)]];
    
    return [[OCATransformer fromClass:inputClass toClass:outputClass transform:^id(id input) {
        return [dictionary objectForKey:input];
    } reverse:^id(id input){
        return [[dictionary allKeysForObject:input] firstObject];
    }]
            describe:[NSString stringWithFormat:@"map %@ pairs from %@ to %@", @(dictionary.count), inputClass ?: @"various", outputClass ?: @"various"]
            reverse:[NSString stringWithFormat:@"map %@ pairs from %@ to %@", @(dictionary.count), outputClass ?: @"various", inputClass ?: @"various"]];
}


+ (OCATransformer *)makeCopy {
    return [[OCATransformer fromClass:nil toClass:nil symetric:^id(id input) {
        if ([input conformsToProtocol:@protocol(NSCopying)]) return [input copy];
        else return nil;
    }] describe:@"count"];
}






#pragma mark Control Flow


+ (OCATransformer *)sequence:(NSArray *)transformers {
    if ( ! transformers.count) return [self pass];
    transformers = [transformers copy];
    
    NSValueTransformer *firstTransformer = transformers.firstObject;
    NSValueTransformer *lastTransformer = transformers.lastObject;
    
    BOOL areReversible = YES;
    NSMutableArray *descriptions = [[NSMutableArray alloc] init];
    NSMutableArray *reverseDescriptions = [[NSMutableArray alloc] init];
    
    Class previousOutputClass = nil;
    for (NSValueTransformer *t in transformers) {
        areReversible &= [t.class allowsReverseTransformation];
        [descriptions addObject:t.description ?: @"unknown"];
        [reverseDescriptions addObject:t.reversed.description ?: @"unknown"];
        
        OCAAssert(previousOutputClass == Nil || [t.class valueClass] == Nil || [[t.class valueClass] isSubclassOfClass:previousOutputClass], @"Classes of transformers in sequence are incompatible.") return [OCATransformer discard];
        previousOutputClass = [t.class transformedValueClass];
    }
    return [[OCATransformer fromClass:[firstTransformer.class valueClass]
                              toClass:[lastTransformer.class transformedValueClass]
                            transform:^id(id input) {
                                id value = input;
                                for (NSValueTransformer *t in transformers) {
                                    value = [t transformedValue:value];
                                }
                                return value;
                            } reverse:^id(id input) {
                                id value = input;
                                for (NSValueTransformer *t in transformers.reverseObjectEnumerator.allObjects) {
                                    value = [t reverseTransformedValue:value];
                                }
                                return value;
                            }]
            describe:[NSString stringWithFormat:@"[%@]", [descriptions componentsJoinedByString:@", "]]
            reverse:[NSString stringWithFormat:@"[%@]", [reverseDescriptions.reverseObjectEnumerator.allObjects componentsJoinedByString:@", "]]];
}


+ (OCATransformer *)convertTo:(Class)finalClass using:(NSArray *)transformers {
    NSMapTable *byInputClass = [NSMapTable strongToStrongObjectsMapTable];
    NSMapTable *byOutputClass = [NSMapTable strongToStrongObjectsMapTable];
    NSMutableSet *inputClasses = [[NSMutableSet alloc] init];
    for (NSValueTransformer *t in transformers) {
        //TODO: Warn about multiple matches.
        Class inputClass = [t.class valueClass] ?: [NSObject class];
        Class outputClass = [t.class transformedValueClass] ?: [NSObject class];
        [byInputClass setObject:t forKey:inputClass];
        [byOutputClass setObject:t forKey:outputClass];
        [inputClasses addObject:inputClass];
        
        OCAAssert([outputClass isSubclassOfClass:finalClass], @"Provided transformer doesn't have requested output class.");
    }
    NSString *inputClassesString = [inputClasses.allObjects componentsJoinedByString:@", "];
    
    Class inputClass = [OCAObject valueClassForClasses:inputClasses.allObjects];
    return [[OCATransformer fromClass:inputClass toClass:finalClass transform:^id(id input) {
        Class class = [input class];
        while (class) {
            NSValueTransformer *t = [byInputClass objectForKey:class];
            if (t) return [t transformedValue:input];
            class = class.superclass;
        }
        return nil; //TODO: Instantinate default transformer.
    } reverse:^id(id input) {
        // Reverse is basically undefined, but this should do it. Using first most concrete transformer.
        Class class = [input class];
        while (class) {
            NSValueTransformer *t = [byOutputClass objectForKey:class];
            if (t) return [t reverseTransformedValue:input];
            class = class.superclass;
        }
        return input; // Lookup failed, pass.
    }]
            describe:[NSString stringWithFormat:@"convert { %@ } to %@", inputClassesString, finalClass]
            reverse:[NSString stringWithFormat:@"convert %@ to undefined { %@ }", finalClass, inputClassesString]];
}


+ (OCATransformer *)repeat:(NSUInteger)count transformer:(NSValueTransformer *)transformer {
    Class inputClass = [transformer.class valueClass];
    Class outputClass = [transformer.class transformedValueClass];
    OCAAssert(inputClass == Nil || outputClass == Nil || [inputClass isSubclassOfClass:outputClass], @"Transformer cannot be repeated.") return [OCATransformer discard];
    
    return [[OCATransformer fromClass:inputClass toClass:outputClass transform:^id(id input) {
        id value = input;
        for (NSUInteger iteration = 0; iteration < count; iteration++) {
            value = [transformer transformedValue:value];
        }
        return value;
    } reverse:^id(id input) {
        id value = input;
        for (NSUInteger iteration = 0; iteration < count; iteration++) {
            value = [transformer reverseTransformedValue:value];
        }
        return value;
    }]
            describe:[NSString stringWithFormat:@"%@ times %@", @(count), transformer]
            reverse:[NSString stringWithFormat:@"%@ times %@", @(count), [transformer reversed]]];
}





#pragma mark Side Effects


+ (OCATransformer *)sideEffect:(void(^)(id value))block {
    return [[OCATransformer fromClass:nil toClass:nil symetric:^id(id input) {
        if (block) block(input);
        return input;
    }] describe:@"[side effect]"];
}


+ (OCATransformer *)debugPrintWithPrefix:(NSString *)prefix {
    return [[OCATransformer sideEffect:^(id value) {
        NSLog(@"%@: %@", prefix ?: @"Debug", value);
    }] describe:[NSString stringWithFormat:@"[debug print “%@”]", prefix]];
}






@end

