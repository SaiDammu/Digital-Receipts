//
//  DevicesQppViewController.h
//  VoLE Demo
//
//  Created by Sai Seshu Sarath Chandra Dammu on 12/3/19.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DevicesQppViewController : UIViewController{
    IBOutlet UITableView *deviceList;
}

@property (nonatomic,retain) UIRefreshControl *refreshControl;

- (IBAction)backQppMainVC : (id)sender;

-(void) updatePeriInTableView:(UIRefreshControl *)refreshControl;

+(DevicesQppViewController *)sharedInstance;

@end
