//
//  GraphViewDelegate.h
//  Neuron
//
//  Created by Louise Schie on 2/13/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GraphViewDelegate1 <NSObject>
- (int)numberOfPointsInGraph;
- (float)valueForIndex:(NSInteger)index;
//- (int)valueForOffset:(NSInteger)index;
@end
