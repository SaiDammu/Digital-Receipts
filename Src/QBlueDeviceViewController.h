//
//  DevicesListViewController.h
//  Neuron Project
//
//  Created by Derek on 12/05/13.
//  Copyright (c) 2012 QN Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QppClient.h"

@interface QBlueDeviceViewController : UITableViewController<QppClientConnectionDelegate, UIAlertViewDelegate>

@end
