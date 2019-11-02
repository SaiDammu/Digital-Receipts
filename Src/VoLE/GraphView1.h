//
//  GraphView.h
//  Neuron
//
//  Created by Louise Schie on 2/11/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QBlueClient.h"
#include "GraphViewDelegate1.h"

//@protocol GraphViewProtocolDelegate1 <NSObject>

//@required
//- (int)numberOfPointsInGraph;
//- (float)valueForIndex:(NSInteger)index;
//- (int)valueForOffset:(NSInteger)index;
//@end


@interface GraphView1 : UIView

//@synthesize *data3 = _delegate, discoveredPeripherals = _discoveredPeripherals;
@property (assign) IBOutlet id <GraphViewDelegate1> delegate;

//@synthesize *data3 = _delegate, discoveredPeripherals = _discoveredPeripherals;

@property (assign, nonatomic) CGFloat gridSpacing;
@property (assign, nonatomic) CGFloat gridLineWidth;
@property (assign, nonatomic) CGFloat gridXOffset;
@property (assign, nonatomic) CGFloat gridYOffset;
@property (strong, nonatomic) IBOutlet UIColor *gridLineColor;
@property (assign, nonatomic) CGFloat guideLineWidth;
@property (assign, nonatomic) CGFloat guideLineYOffset;
@property (strong, nonatomic) UIColor *guideLineColor;
@property (assign, nonatomic) CGFloat graphLineWidth;
@property (assign, nonatomic) CGFloat dotSize;
@property (strong, nonatomic) IBOutlet NSString *data2;

-(void)reloadGraph; // Instance method

@end
