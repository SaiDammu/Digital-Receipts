//
//  DevicesListViewController.m
//  QppClient
//
//  Created by Derek on 12/05/13.
//  Copyright (c) 2012 QN Inc. All rights reserved.
//

#import "QBlueDeviceViewController.h"

@interface QBlueDeviceViewController ()

@end

@implementation QBlueDeviceViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Peripheral List";
    QppClient *qppc = [QppClient sharedInstance];
    qppc.connectionDelegate = self;
    [qppc startScan];
}

- (void)dealloc {
    QppClient *qppc = [QppClient sharedInstance];
    qppc.connectionDelegate = nil;
    [qppc stopScan];
}

#pragma mark - QppClientDelegate

- (void)qppClient:(QppClient *)client didDiscoverPeripheral:(CBPeripheral *)aPeripheral {
    // [self.tableView reloadData];

    [[NSNotificationCenter defaultCenter]postNotificationName : otaScanPeriEndNoti object:nil /* userInfo:dictPeripherals */];

}

- (void)qppClient:(QppClient *)client didConnectPeripheral:(CBPeripheral *)aPeripheral {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)qppClient:(QppClient *)client didFailToConnectPeripheral:(CBPeripheral *)aPeripheral {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Connect failed!"
                                                message:[aPeripheral description]
                                               delegate:self
                                      cancelButtonTitle:nil
                                      otherButtonTitles:nil, nil];
    [av show];
}

- (void)qppClient:(QppClient *)client didDisconnectPeripheral:(CBPeripheral *)aPeripheral {
    //TODO
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [[QppClient sharedInstance] startScan];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[QppClient sharedInstance].discoveredPeripherals count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = nil;
    //[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSArray *pripherals = [[QppClient sharedInstance] discoveredPeripherals];
    CBPeripheral *pripheral = [pripherals objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [pripheral name];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QppClient *qppc = [QppClient sharedInstance];
    [qppc stopScan];
    
    NSArray *pripherals = [qppc discoveredPeripherals];
    CBPeripheral *pripheral = [pripherals objectAtIndex:indexPath.row];
    
    [qppc connectPeripheral:pripheral];
}

@end
