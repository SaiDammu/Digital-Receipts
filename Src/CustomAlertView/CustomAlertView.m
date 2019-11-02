//
//  CustomAlertView.m
//  textAlertView
//
//  Created by Fuquan.Zhang on 10/12/2013.
//  Copyright (c) 2013 Quintic Labs. All rights reserved.
//  For the complete copyright notice, read Source Code License.
//
#define kAlertViewBounce         20
#define kAlertViewBorder         10
#define kAlertButtonHeight       44

#define kAlertViewTitleFont             [UIFont boldSystemFontOfSize:20]
#define kAlertViewTitleTextColor        [UIColor colorWithWhite:244.0/255.0 alpha:1.0]
#define kAlertViewTitleShadowColor      [UIColor blackColor]
#define kAlertViewTitleShadowOffset     CGSizeMake(0, -1)

#define kAlertViewMessageFont           [UIFont systemFontOfSize:18]
#define kAlertViewMessageTextColor      [UIColor colorWithWhite:244.0/255.0 alpha:1.0]
#define kAlertViewMessageShadowColor    [UIColor blackColor]
#define kAlertViewMessageShadowOffset   CGSizeMake(0, -1)

#define kAlertViewButtonFont            [UIFont boldSystemFontOfSize:18]
#define kAlertViewButtonTextColor       [UIColor whiteColor]
#define kAlertViewButtonShadowColor     [UIColor blackColor]
#define kAlertViewButtonShadowOffset    CGSizeMake(0, -1)

#define kAlertViewBackground            @"alert-window.png"
#define kAlertViewBackgroundCapHeight   38
#import "CustomAlertView.h"

@implementation CustomAlertView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}



-(void)layoutSubviews{
    for (UIView *v in self.subviews) {
        if ([v isKindOfClass:[UIImageView class]]) {
            UIImageView *imageV = (UIImageView *)v;
            UIImage *image = [UIImage imageNamed:kAlertViewBackground];
            image = [image stretchableImageWithLeftCapWidth:0 topCapHeight:kAlertViewBackgroundCapHeight /* retain */];
            [imageV setImage:image];
        }
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)v;
            if ([label.text isEqualToString:self.title]) {
                label.font = kAlertViewTitleFont;
                label.numberOfLines = 0;
                label.lineBreakMode = 0;// zfq UILineBreakModeWordWrap;
                label.textColor = kAlertViewTitleTextColor;
                label.backgroundColor = [UIColor clearColor];
                label.textAlignment = 1;// zfq UITextAlignmentCenter;
                label.shadowColor = kAlertViewTitleShadowColor;
                label.shadowOffset = kAlertViewTitleShadowOffset;
            }else{
                label.font = kAlertViewMessageFont;
                label.numberOfLines = 0;
                label.lineBreakMode = 0;// zfq UILineBreakModeWordWrap;
                label.textColor = kAlertViewMessageTextColor;
                label.backgroundColor = [UIColor clearColor];
                label.textAlignment = 1;// zfq UITextAlignmentCenter;
                label.shadowColor = kAlertViewMessageShadowColor;
                label.shadowOffset = kAlertViewMessageShadowOffset;
            }
        }
        if ([v isKindOfClass:NSClassFromString(@"UIAlertButton")]) {
            UIButton *button = (UIButton *)v;
            UIImage *image = nil;
            if (button.tag == 1) {
                image = [UIImage imageNamed:[NSString stringWithFormat:@"alert-%@-button.png", @"gray"]];
            }else{
                image = [UIImage imageNamed:[NSString stringWithFormat:@"alert-%@-button.png", @"black"]];
            }
            image = [image stretchableImageWithLeftCapWidth:(int)(image.size.width+1)>>1 topCapHeight:0];
            
            button.titleLabel.font = kAlertViewButtonFont;
            // button.titleLabel.minimumFontSize = 10;
            button.titleLabel.textAlignment = 1;// zfq UITextAlignmentCenter;
            button.titleLabel.shadowOffset = kAlertViewButtonShadowOffset;
            button.backgroundColor = [UIColor clearColor];
            [button setBackgroundImage:image forState:UIControlStateNormal];
            [button setTitleColor:kAlertViewButtonTextColor forState:UIControlStateNormal];
            [button setTitleShadowColor:kAlertViewButtonShadowColor forState:UIControlStateNormal];
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
