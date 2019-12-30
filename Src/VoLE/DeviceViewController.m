//
//  DeviceViewController.h
//  Qpp Demo
//
//  @brief Application Source File for Device List View Controller.
//
//  Created by NXP on 5/18/14.
//  Copyright (c) 2014 NXP. All rights reserved.
//

#import "QBleClient.h"
#import "QbleQppClient.h"
#import "QppPublic.h"
#import "OtaAppPublic.h"
#import "DeviceViewController.h"

@interface DeviceViewController ()

@end

@implementation DeviceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
/*
+(DeviceViewController *)sharedInstance{
    static DeviceViewController *_sharedInstance = nil;
    if (_sharedInstance == nil) {
        _sharedInstance = [[DeviceViewController alloc] init];
    }
    
    return _sharedInstance;
}
*/
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
     self.view.backgroundColor = [UIColor blackColor];
    NSLog(@"%s", __func__);

    
    //OTA
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceListReloadDataRsp) name:appDevListReloadDataNoti object:nil];
     
     _refreshControl = [[UIRefreshControl alloc] init];
     [_refreshControl addTarget:self action:@selector(updatePeriInTableView:) forControlEvents:UIControlEventValueChanged];
     [deviceList addSubview:_refreshControl];
    
    
}

- (void)viewUnDidLoad
{
    deviceList = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *****************************************************************
 * @brief       back to MainViewController.
 *
 * @param[in]  sender   : current sender id .
 * @return :   IBAction : Button Id Action
 *****************************************************************
 */
- (IBAction)backQppMainVC:(id)sender {
  //  [[NSNotificationCenter defaultCenter] postNotificationName : qppMainStopScanNoti object:nil userInfo:nil];
    
    //OTA
      [[NSNotificationCenter defaultCenter] postNotificationName : mainVcStopScanNoti object:nil userInfo:nil];
    /// [self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 *****************************************************************
 * @brief       device number in the table view.
 *
 * @param[in]  sender   : current sender id.
 *
 * @return :   NSInteger : number of rows in the table
 *****************************************************************
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //    NSLog(@"%s ", __func__);
    if (self.isOTA) {
        return [[qBleClient sharedInstance].discoveredPeripherals count];
    }else{
        return [[qBleQppClient sharedInstance].discoveredPeripherals count];
    }
    
}

/**
 *****************************************************************
 * @brief
 * // Row display. Implementers should *always* try to reuse cells by setting each cell's
 *    reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
 * // Cell gets various attributes set automatically based on table (separators) and data
 *    source (accessory views, editing controls)
 *
 * @param[in]  indexPath   : index of the row.
 *
 * @return :   returns nil if cell is not visible or index path is out of range
 *****************************************************************
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = nil;
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSArray *peripherals;
    if (_isOTA) {
         if ([[qBleClient sharedInstance] discoveredPeripherals] == nil)
           {
               NSLog(@"cell:nil \n");
               return cell;
           }
           
            peripherals = [[qBleClient sharedInstance] discoveredPeripherals];

    }else{
        if ([[qBleQppClient sharedInstance] discoveredPeripherals] == nil)
           {
               NSLog(@"cell:nil \n");
               return cell;
           }
           
            peripherals = [[qBleQppClient sharedInstance] discoveredPeripherals];

    }
       
    //    NSLog(@"arr :%d \n",indexPath.row);
    CBPeripheral *peripheral = [peripherals objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [peripheral name];
    if(cell.textLabel.text == NULL)
    {
        cell.textLabel.text = @"Peripheral";
    }
    
    return cell;
}

/**
 *****************************************************************
 * @brief      // Called after the user changes the selection.
 *
 * @return :   none
 *****************************************************************
 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *peripherals;
    NSLog(@"test 11");
    if (_isOTA) {
        //qBleClient *dev = ;
        [[qBleClient sharedInstance] stopScan];
        
        peripherals = [[qBleClient sharedInstance] discoveredPeripherals];
        
        // protect code
        uint8_t perIndex = indexPath.row;
        
        if (perIndex > [peripherals count]){
            perIndex = [peripherals count];
        };
           CBPeripheral *selectedPeri = [peripherals objectAtIndex:perIndex /*indexPath.row*/];
           
           NSDictionary *dictPeri = [NSDictionary dictionaryWithObject : selectedPeri forKey:keyOtaAppSelectPeri];
           [[NSNotificationCenter defaultCenter] postNotificationName: otaAppSelOnePeripheralNoti object:nil userInfo:dictPeri];
       // dev.bleUpdateForOtaDelegate = self;
           [[qBleClient sharedInstance] pubConnectPeripheral : selectedPeri];
        
    }else{
        
       // if (!_isHeartRate) {
            qBleQppClient *dev = [qBleQppClient sharedInstance];
            [dev stopScan];
            
            peripherals = [dev discoveredPeripherals];
            
            // protect code
            uint8_t perIndex = indexPath.row;
            
            if (perIndex > [peripherals count]){
                perIndex = [peripherals count];
            };
            
            CBPeripheral *selectedPeri = [peripherals objectAtIndex:perIndex ];
            
        NSLog(@"sel peri %@",selectedPeri);
        
            [[NSNotificationCenter defaultCenter] postNotificationName: qppSelOnePeripheralNoti object:selectedPeri userInfo:nil];
                
           // [dev pubConnectPeripheral : selectedPeri];
            
        
       // }
        
 
    }

    

       
       [self backQppMainVC:nil];
}

- (void)endRefresh
{
    [_refreshControl endRefreshing];
}

-(void) updatePeriInTableView:(UIRefreshControl *)refreshControl
{
    NSLog(@"%s ", __func__);
    
    [refreshControl beginRefreshing];
    
    [deviceList reloadData];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(endRefresh) userInfo:nil repeats:NO];
    //[self performSelector:@selector(endRefresh:) withObject:refreshControl afterDelay:1.0f];
}

-(void)deviceListReloadDataRsp
{
    /// NSLog(@"%s ", __func__);
    [deviceList reloadData];
}
@end

