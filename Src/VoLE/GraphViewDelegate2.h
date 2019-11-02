//
//  GraphViewDelegate2.h
//  VoLE Demo
//
//  Created by David Schie on 6/5/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GraphViewDelegate2 <NSObject>
- (int)numberOfPointsInGraph1;
- (float)valueForIndex1:(NSInteger)index;
//- (int)valueForOffset1:(NSInteger)index;
@end
