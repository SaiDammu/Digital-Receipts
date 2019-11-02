//
//  GraphView.m
//  Neuron
//
//  Created by Louise Schie on 2/11/14.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#import "GraphView2.h"

@implementation GraphView2

- (void)reloadGraph {
    
    [self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaults];
        // Initialization code
    }
    return self;
    
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [ self setDefaults];
    }
    return self;
    
}

-(void)setDefaults
{
    self.backgroundColor=[UIColor whiteColor];
    self.opaque=YES;
    self.gridSpacing=20.0;
    if (self.contentScaleFactor == 2.0 )
    {
        self.gridLineWidth=0.5;
        self.gridXOffset=0.25;
        self.gridYOffset=0.25;
    }
    else
    {
        self.gridLineWidth=1.0;
        self.gridXOffset=0.5;
        self.gridYOffset=0.5;
    }
    self.gridLineColor= [UIColor lightGrayColor];
    
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.


-(void)drawRect:(CGRect)rect
{
    // Drawing code
    //CGFloat width = CGRectGetWidth(self.bounds);
    //CGFloat height = CGRectGetHeight(self.bounds);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = self.gridLineWidth;
    CGFloat x = self.gridXOffset;
    while(x <= 1100)
    {
        [path moveToPoint:CGPointMake(x,0.0)];
        [path addLineToPoint:CGPointMake(x, 223)];
        x += self.gridSpacing;
    }
    CGFloat y = self.gridYOffset;
    while(y <= 223)
    {
        [path moveToPoint:CGPointMake(0.0,y)];
        [path addLineToPoint:CGPointMake(1050,y)];
        y += self.gridSpacing;
    }
    [self.gridLineColor setStroke];
    [path stroke];
    
    UIBezierPath *line=[UIBezierPath bezierPath];
    //line.lineWidth=self.guideLineWidth;
    line.lineWidth=1.5;
    self.guideLineColor= [UIColor blueColor];
    //[line setLineDash:pattern count:4 phase:0];
    
    self.guideLineColor= [UIColor redColor];
    int q;
    q=0;
    [line moveToPoint:CGPointMake(0,0)];
    while (q<1000)
    {
        
        [line addLineToPoint:CGPointMake(q,[self.delegate valueForIndex1:q])];
        q++;
    }
    [self.guideLineColor setStroke];
    [line stroke];
    //BOOL isConnected = [QBlueClient sharedInstance].isConnected;
    //  [QppClient sharedInstance].isConnected=NO;
    //   [DaveVariable sharedInstance].dd=@"hello";
}



@end