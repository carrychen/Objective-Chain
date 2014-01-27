//
//  OCATransformer+CGSize.h
//  Objective-Chain
//
//  Created by Martin Kiss on 13.1.14.
//  Copyright (c) 2014 Martin Kiss. All rights reserved.
//

#import <CoreGraphics/CGGeometry.h>
#import <CoreGraphics/CGAffineTransform.h>
#import "OCATransformer+Base.h"





@interface OCATransformer (CGSize)





#pragma mark -
#pragma mark Predicates
#pragma mark -

+ (NSPredicate *)predicateForSize:(BOOL(^)(CGSize size))block;
+ (NSPredicate *)isSizeEqualTo:(CGSize)otherSize;
+ (NSPredicate *)isSizeZero;



#pragma mark -
#pragma mark Transformers
#pragma mark -


#pragma mark Creating Sizes

+ (OCATransformer *)sizeFromString;
+ (OCATransformer *)makeSize;
+ (OCATransformer *)makeSizeWithWidth:(CGFloat)width;
+ (OCATransformer *)makeSizeWithHeight:(CGFloat)height;


#pragma mark Modifying Sizes

+ (OCATransformer *)modifySize:(CGSize(^)(CGSize size))block;
+ (OCATransformer *)extendSizeBy:(CGSize)otherSize;
+ (OCATransformer *)shrinkSizeBy:(CGSize)otherSize;
+ (OCATransformer *)multiplySizeBy:(CGFloat)multiplier;
+ (OCATransformer *)transformSize:(CGAffineTransform)affineTransform;
+ (OCATransformer *)roundSizeTo:(CGFloat)scale;
+ (OCATransformer *)floorSizeTo:(CGFloat)scale;
+ (OCATransformer *)ceilSizeTo:(CGFloat)scale;
+ (OCATransformer *)standardizeSize;


#pragma mark Disposing Sizes

+ (OCATransformer *)stringFromSize;
+ (OCATransformer *)sizeArea;
+ (OCATransformer *)sizeRatio;





@end





#pragma mark -
#pragma mark Functions
#pragma mark -

extern CGSize OCASizeFromString(NSString *);
extern NSString * OCAStringFromSize(CGSize);

extern CGSize OCASizeExtendBySize(CGSize, CGSize);
extern CGSize OCASizeShrinkBySize(CGSize, CGSize);
extern CGSize OCASizeMultiply(CGSize, CGFloat);
extern CGSize OCASizeStandardize(CGSize size);

extern CGSize OCASizeRound(CGSize size, CGFloat scale);
extern CGSize OCASizeFloor(CGSize size, CGFloat scale);
extern CGSize OCASizeCeil(CGSize size, CGFloat scale);

extern CGFloat OCASizeGetArea(CGSize size);
extern CGFloat OCASizeGetRatio(CGSize size);

