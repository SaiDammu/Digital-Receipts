//
//  QppViewController.m
//  Qpp Demo
//
//  @brief Application source file for Peripheral to Centtral View Controller.
//
//  Created by NXP on 4/21/14.
//  Copyright (c) 2014 NXP. All rights reserved.
//
   
#import "QppPublic.h"
#import "QbleQppClient.h"
#import "QppApi.h"

#import "CustomAlertView.h"
#import "Utils.h"

#import "DevicesQppViewController.h"
//#import "HelpViewController.h"
#import "QppViewController.h"
 
#define QPP_DIDCONN_DEV_TIMEOUT      5



@interface QppViewController ()<ChartViewDelegate> {
    /// CBPeripheral *qppConnectedPeri;     /// the peripheral for Qpp
    
    NSTimer *qppDidConnDevTimeoutTimer; /// for connection timeout.
    uint8_t  qppDidConnDevTimeoutCount; /// for connection timeout.
    
    /// BOOL qppEnableStatus;               /// enable status.
    int lowerBound;
    int upperBound;
    /// DataRate
    int8_t dataRateStart;
    BOOL   flagDataMonitoring;
    uint16_t qppDataRateMin;
    uint16_t qppDataRateMax;
    NSString *values;
    /// send Data
    /// u_int64_t qppSendCounter;          /// repeat counter
    
    DevicesQppViewController *deviceVC;
    //HelpViewController *helpVC;
    
    BOOL flagOnePeriScanned;           /// one peripheral is scanned.
    
// @public
    u_int64_t preTimeMs, curTimeMs;
    u_int64_t dataReceived;
    
    u_int64_t dynRefTimeMs ;
    
    uint8_t qppWrData[512];
    
    QppApi *qppApi;
    DevicesCtrl *devInfo;
    
    NSTimer *repeatWrTimer;
    
    BOOL fEdited;
    NSMutableArray *dataArray;
    UIBarButtonItem *scanDisconnectItem;
    
    LineChartDataSet *set1;
    ChartYAxis *leftAxis;
    NSMutableArray *minMaxArray;
    NSString *fileNameString;
    NSString *filepath;
}

@property (readwrite) qppCentralState qppCentState;
@property (strong,nonatomic)NSMutableArray *ArrayOfValues1;
@end

@implementation QppViewController

@synthesize qppCentState;
@synthesize indata2send,inIntervalBtwPkg;
@synthesize repeatCounterLbl;
@synthesize btnSend;

-(id)init {
    self = [super init];
    
    if (self) {
        NSLog(@"%s",__func__);
    }
    
    return self;
}

- (qppCentralState)qppCentState
{
    @synchronized(self)
	{
        return qppCentState;
    }
}

- (void)setqppCentState : (qppCentralState) aStatus
{
	@synchronized(self)
	{
		if (qppCentState != aStatus)
		{
			qppCentState = aStatus;
		}
	}
}

+ (QppViewController *)sharedInstance
{
    static QppViewController *_sharedInstance = nil;
    
    if (_sharedInstance == nil) {
        _sharedInstance = [[QppViewController alloc] init];
    }
    
    return _sharedInstance;
}

-(void)qppReset{
    flagDataMonitoring = false;
    
    fEdited=false;
    
    dataRateStart = 0;
    dataReceived = 0;
    _qppDataRateAvgLbl.text = @"0";
    _qppDataRateDynLbl.text = @"0";
    
    preTimeMs = 0l;
    curTimeMs = 0l;
    
    dynRefTimeMs = 0l;
    
    qppDataRateMin = 10000;
    qppDataRateMax = 0;
    
    [self qppSendReset];
}

/*
 * description : user config
 *
 */
-(void)qppUserConfig
{
    /// Note : Please setup for qBleClient connections update delegate. 
    [qBleQppClient sharedInstance].bleDidConnectionsDelegate = self;
    
    /// Note : Please setup for QppApi update delegate. 
    [QppApi sharedInstance].ptReceiveDataDelegate = self;
    
    /// [QppApi sharedInstance].qppEnableConfirmDelegate = self;
}

-(void)initDevicesInfo{
    devInfo = [[DevicesCtrl alloc] init];
    
    devInfo.intervalBtwPkg=0.03f;
    devInfo.fQppWrRepeat = false;
    devInfo.lengOfPkg2Send=20;
    
//    for(int i=0; i<devInfo.lengOfPkg2Send;i++){
//        qppWrData[i]=i;
//    }
//    
//    devInfo.data2Send=[[NSMutableData alloc] initWithBytes:qppWrData length:devInfo.lengOfPkg2Send];
    devInfo.pkgIdx=0;
    
    [self refreshData2BeSent:devInfo];
    
    [self refreshQppDataToSend:devInfo ];
}

-(void)refreshData2BeSent:(DevicesCtrl *)_devCtrl{
    for(int i=0; i<_devCtrl.lengOfPkg2Send;i++){
        qppWrData[i]=i;
    }
    
    _devCtrl.data2Send=[[NSMutableData alloc] initWithBytes:qppWrData length:_devCtrl.lengOfPkg2Send];
}

-(void)regNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppDidPeriDiscoveredRsp) name: blePeriDiscoveredNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppDidDiscoveredServicesRsp) name: bleDiscoveredServicesNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppDidDiscoveredCharsRsp) name: bleDiscoveredCharacteristicsNoti object:nil];
    
    /// update data
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppUpdateStateForCharRsp:) name: strQppUpdateStateForCharNoti object:nil];
    
    /// UI
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppDisplayPeripherals) name:strQppScanPeriEndNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppUpdateDataRateAveraged:) name:strQppUpdateDataRateAvgNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppUpdateDataRateDynamic:) name:strQppUpdateDataRateDynNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppSelOnePeripheralRsp:) name : qppSelOnePeripheralNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppMainStopScan) name : qppMainStopScanNoti object:nil];
    //qpp
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didQppEnableConfirmForAppRsp:) name: didQppEnableConfirmForAppNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppWriteValueForCharRsp:) name : bleWriteValueForCharNoti object:nil];
}

-(void)initUIComAboutCOnnection:(BOOL)_flag{
    self.swRepeatSendData.enabled=_flag;
    self.btnSend.enabled=_flag;
    self.btnToggleNtf.enabled=_flag;
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnectQpp) name:@"DisconnectQpp" object:nil];
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"mm.MMM.yy-hh:mm:ss"];
    NSString *dateString = [formatter stringFromDate:date];
    fileNameString = [NSString stringWithFormat:@"ECG_%@.txt",dateString];
    

    filepath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject] stringByAppendingPathComponent:fileNameString];
    
    /// [self.qppVersion setText:[NSString stringWithFormat:@"v%1.1f.%d", _QBLUE_QPP_MAIN_VERSION, _QBLUE_QPP_REV_VERSION]];
        lowerBound = -100;
           upperBound = 500;
    scanDisconnectItem = [[UIBarButtonItem alloc]initWithTitle:@"Scan" style:UIBarButtonItemStylePlain target:self action:@selector(scanPeri:)];
    scanDisconnectItem.tag = 1;
    scanDisconnectItem.tintColor = [UIColor redColor];
    self.navigationItem.rightBarButtonItem = scanDisconnectItem;
    
    
    
    _chartView.delegate = self;
    _chartView.chartDescription.enabled = NO;
    
    _chartView.dragEnabled = YES;
    [_chartView setScaleEnabled:YES];
    _chartView.pinchZoomEnabled = NO;
    _chartView.drawGridBackgroundEnabled = NO;
    _chartView.highlightPerDragEnabled = YES;
    
    _chartView.backgroundColor = UIColor.whiteColor;
    
    _chartView.legend.enabled = NO;
    
    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionTopInside;
    xAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.f];
    xAxis.labelTextColor = [UIColor colorWithRed:255/255.0 green:192/255.0 blue:56/255.0 alpha:1.0];
    xAxis.drawAxisLineEnabled = NO;
    xAxis.drawGridLinesEnabled = YES;
    xAxis.centerAxisLabelsEnabled = YES;
    xAxis.granularity = 3600.0;
    
    
      leftAxis = _chartView.leftAxis;
      leftAxis.labelPosition = YAxisLabelPositionInsideChart;
      leftAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:00.f];
      leftAxis.labelTextColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
      leftAxis.drawGridLinesEnabled = YES;
      leftAxis.granularityEnabled = YES;
      leftAxis.axisMinimum = lowerBound;
      leftAxis.axisMaximum = upperBound;
      leftAxis.yOffset = -9.0;
      leftAxis.labelTextColor = [UIColor colorWithRed:255/255.0 green:192/255.0 blue:56/255.0 alpha:1.0];
      
      _chartView.rightAxis.enabled = NO;
      _chartView.legend.form = ChartLegendFormLine;
      [_chartView animateWithXAxisDuration:2.0 yAxisDuration:2.0];
      _chartView.userInteractionEnabled = NO;
      
    
    
    // Do any additional setup after loading the view from its nib.
    self.ArrayOfValues1 = [NSMutableArray new];
    [self subSetVersion];
    
    /// qppWrData[QPP_LENGTH_ AT_BLE4_2]={0};
    qppApi = [QppApi sharedInstance];
    
    [self initDevicesInfo];
    [self initUIComAboutCOnnection:NO];
    
    _ptScanDevActInd.hidesWhenStopped = YES;
    _ptDidConnDevActInd.hidesWhenStopped = YES;
    
    [self.ptScanDevActInd stopAnimating];
    [self.ptDidConnDevActInd stopAnimating];
    
    qppCentState = QPP_CENT_IDLE;
    
    [self refreshConnectBtns];
        
    [self regNotification];
    
    flagOnePeriScanned = FALSE;
    
    /// indata2 send.delegate = self;
    
    self.indata2send.keyboardType=UIKeyboardTypeNumberPad;
    self.inIntervalBtwPkg.keyboardType=UIKeyboardTypeNumberPad;
    
    /// load Device list VC
    deviceVC = [[DevicesQppViewController alloc] initWithNibName:@"DevicesQppViewController" bundle:nil];
    	
   // helpVC = [[HelpViewController alloc] initWithNibName:@"HelpViewController" bundle:nil];
    
    dataArray = [NSMutableArray new];
 //   [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(updateValues) userInfo:nil repeats:YES];
}
-(void)disconnectQpp{
    
    [self scanPeri:nil];
    
}
-(void)updateValues{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        for (int i=0; i<dataArray.count; i++) {
             NSData *data = dataArray[i];
             [dataArray removeObjectAtIndex:i];
             uint8_t * bytePtr = (uint8_t  * )[data bytes];
                    NSInteger totalData = [data length] / sizeof(uint8_t);
                    
                    for (int i = 0 ; i < totalData/2; i ++)
                    {

                        NSString *str = [NSString stringWithFormat:@"0x%02x%02x",bytePtr[i+1],bytePtr[i]];
                        
                        i++;

                        unsigned int outVal;
                        NSScanner* scanner1 = [NSScanner scannerWithString:str];
                        [scanner1 scanHexInt:&outVal];
                        
                        if (self.ArrayOfValues1.count>500){
                            [self.ArrayOfValues1 removeObjectAtIndex:0];
                        }
                        [self.ArrayOfValues1 addObject:[NSNumber numberWithInteger:outVal]];
                   
                    }
                    
                     NSLog(@"test %@",self.ArrayOfValues1);
         }
    });
    
    
}
- (void)viewDidUnload {
    [self setQppDevNameLabel:nil];
    [self setQppConnectStatusLabel:nil];
    [super viewDidUnload];
}

#pragma mark - the delegate from QBleClient
/**
 *****************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 *****************************************************************
 */
-(void)bleDidConnectPeripheral : (CBPeripheral *)aPeripheral{
    NSLog(@"line : %d, func: %s ",__LINE__, __func__);
    
    if(aPeripheral == devInfo.qppPeri)
    {
        [qppApi  qppEnable : devInfo.qppPeri
            withServiceUUID : UUID_QPP_SVC
                                withWrChar : UUID_QPP_CHAR_FOR_WRITE];
        
        qppCentState = QPP_CENT_CONNECTED;
     
        [self qppStopDidConnDevTimeout];
        [self refreshConnectBtns];
        
        [self initUIComAboutCOnnection:YES];
    }
}

/**
 *****************************************************************
 * @brief       delegate ble update disconnected peripheral.
 *
 * @param[out]  aPeripheral : the disconnected peripheral.
 * @param[out]  error
 *
 *****************************************************************
 */
-(void)bleDidDisconnectPeripheral : (CBPeripheral *)aPeripheral error : (NSError *)error{
    /// NSLog(@"%s",__func__);
    qppCentState = QPP_CENT_IDLE;
    
    [self qppStopDidConnDevTimeout];
    
    [self refreshConnectBtns];
    
    [[Utils sharedInst] cancelTimer:repeatWrTimer];
    
    [self initUIComAboutCOnnection:NO];
}

///**
// *****************************************************************
// * @brief       delegate ble update connected peripheral.
// *
// * @param[out]  aPeripheral : the connected peripheral.
// *
// *****************************************************************
// */
//-(void)bleDidRetrievePeripheral : (NSArray *)aPeripheral{
//    qppCentState = QPP_CENT_RETRIEVED;
//}

/**
 *****************************************************************
 * @brief       delegate ble update connected peripheral.
 *
 * @param[out]  aPeripheral : the connected peripheral.
 *
 *****************************************************************
 */
-(void)bleDidFailToConnectPeripheral : (CBPeripheral *)aPeripheral
                               error : (NSError *)error{
    qppCentState = QPP_CENT_IDLE;
}

#pragma mark - the delegate from QPP layer

/**
 *****************************************************************
 * @brief       Qpp receive data delegate .
 *
 * @param[out]  aPeripheral          : the connected peripheral.
 * @param[out]  qppUUIDForNotifyChar : the UUID for Notify Char.
 * @param[out]  qppData              : the data received.
 *
 *****************************************************************
 */
- (void)didQppReceiveData : (CBPeripheral *) aPeripheral
             withCharUUID : (CBUUID *)qppUUIDForNotifyChar
                 withData : (NSData *)data{
                     
                     scanDisconnectItem.tag = 0;
                     scanDisconnectItem.title = @"Disconnect";
                     
                     uint8_t * bytePtr = (uint8_t  * )[data bytes];
                     
                     for (int i = 0 ; i < data.length; i ++)
                     {
                         
                         NSString *str = [NSString stringWithFormat:@"0x%02x%02x",bytePtr[i+1],bytePtr[i]];
                         
                         i++;
                         
                         unsigned int outVal;
                         NSScanner* scanner1 = [NSScanner scannerWithString:str];
                         [scanner1 scanHexInt:&outVal];
                         
                         values = [NSString stringWithFormat:@"%@\n%u",values,outVal];
                         NSLog(@"values %u",outVal);
                         		
                         int spikes;
                         
                         if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
                         {
                             spikes = 500;
                         }else{
                             spikes = 500;
                         }
                         
                        /*  if (lowerBound>outVal){
                          
                          lowerBound = outVal;
                          leftAxis.axisMinimum = lowerBound-100;
                          }
                          if (upperBound<outVal){
                          upperBound = outVal;
                          leftAxis.axisMaximum = upperBound+100;
                          }
                         */
                         
                         if (self.ArrayOfValues1.count>spikes){
                             [self.ArrayOfValues1 removeObjectAtIndex:0];
                         }
                         [self.ArrayOfValues1 addObject:[NSNumber numberWithInteger:outVal]];
                         //[minMaxArray addObject:[NSNumber numberWithInteger:outVal]];
                         
                     }
                     
                     if (minMaxArray.count>500){
                         [minMaxArray removeAllObjects];
                     }
                     
                     NSArray *numbers = [minMaxArray sortedArrayUsingSelector:@selector(compare:)];
                     
                     int min = [[numbers firstObject] intValue];
                     int max = [[numbers lastObject] intValue];
                     
                     leftAxis.axisMinimum = min-50000;
                     leftAxis.axisMaximum = max+90000;
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         [self setDataCount];
                     });
                     
                     
                     NSError *error;
                     NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject] stringByAppendingPathComponent:fileNameString];
                     NSString *string = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
                     NSString *writeString = [NSString stringWithFormat:@"%@\n %@",string,values];
                     
                     [writeString writeToFile:filepath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                     values = @"";
                     
                     
                        [qppApi qppEnableNotify : devInfo.qppPeri
                                    withNtfChar : devInfo.aQppNtfChar
                                     withEnable : YES];
                 #if QPP_LOG_FILE
                     // write data to log file
                     // [writeBuf appendBytes:[data bytes] length:20 ];
                 #endif
                     
                 }


/*
{
    /// NSLog(@"qppData:%@, len:%lu", qppData,(unsigned long)[qppData length]);
    
      
      NSMutableString *buf = [NSMutableString stringWithCapacity:100];
      const unsigned char *value = qppData.bytes;
      
      for (int i=0; i<qppData.length; i++) {
          [buf appendFormat:@" %02lx",(unsigned long)value[i]];
      }
      NSLog(@"qpp OP %@",buf);  
    
    
    if(!devInfo.fQppEnableStatus )
    {
        /// NSLog(@"qppEnable failed!!!");
        
        return;
    }
    
    const int8_t *rspData = [qppData bytes];
    
    if(rspData == nil)
    {
        return;
    }
    
//    [_qppReceivedDataFromChar setText : [NSString stringWithFormat:@"%@", [self CBUUIDToUUID : qppUUIDForNotifyChar]]];
    
    [_qppReceivedData setText : [NSString stringWithFormat:@"%@", qppData]];
    
    
    /// NSLog(@"qppData:%lu", (unsigned long)[qppData length]);
    devInfo.lengOfPkg2Send=[self selectPkgLengMax:devInfo.lengOfPkg2Send withNewLength:(int)[qppData length]];
    
    /// devInfo. lengOfPkg2Send=(int)[qppData length];
    
    if(flagDataMonitoring)
    {
        if(dataRateStart == rspData[0])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName : strQppUpdateDataRateDynNoti object:qppData ];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName : strQppUpdateDataRateAvgNoti object:qppData ];
    }
    else{
        flagDataMonitoring = TRUE;
        [self qppDataRateAveragedReset];
        
        /// dynamic 
        _qppDataRateDynLbl.text = @"0";
        dynRefTimeMs = 0l;
        
        if(dataRateStart != rspData[0])
        {
            dataRateStart = rspData[0];
        }
    }
}*/
- (IBAction)sendButtonAction:(id)sender {
    
    
    // use UIAlertController
    UIAlertController *alert= [UIAlertController
                               alertControllerWithTitle:@"QPP Input"
                               message:nil
                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Send" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action){
        //Do Some action here
        UITextField *textField = alert.textFields[0];
        NSLog(@"text was %@", textField.text);
        
        
        if(devInfo.fQppEnableStatus == FALSE){
            NSLog(@"qppEnable failed!!!");
        }
        else
        {
            
            qppCentState = QPP_CENT_SENDING;
            
            NSString *strEdited = textField.text;
            
            if(fEdited){
                NSData *inData=[[Utils sharedInst] hexStrToBytes : strEdited withStrMin:TEXT_EDITED_LENGTH_MIN withStrMax: [strEdited length]];
                
                devInfo.data2Send=[[NSMutableData alloc] initWithData:inData];
            }
            
            if(devInfo.data2Send == NULL)
            {
                /// illegal input
                CustomAlertView *inputAlert = [[CustomAlertView alloc]
                                               initWithTitle : ALERT_INPUT_ERROR_TITLE
                                               message : @"Input error!"
                                               delegate : nil
                                               cancelButtonTitle : nil
                                               otherButtonTitles : @"OK", nil];
                [inputAlert show];
                
                return;
            }
            
            NSString *command = textField.text;
            
            command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSMutableData *commandToSend= [[NSMutableData alloc] init];
            unsigned char whole_byte;
            char byte_chars[3] = {'\0','\0','\0'};
            int i;
            for (i=0; i < [command length]/2; i++) {
                byte_chars[0] = [command characterAtIndex:i*2];
                byte_chars[1] = [command characterAtIndex:i*2+1];
                whole_byte = strtol(byte_chars, NULL, 16);
                [commandToSend appendBytes:&whole_byte length:1];
            }
            NSLog(@"%@", commandToSend);
            //pauseGraph = YES;
            // [_RespGraph reloadGraph];
            [qppApi qppSendData : devInfo.qppPeri
                       withData : commandToSend
                       withType : CBCharacteristicWriteWithoutResponse/* CBCharacteristicWriteWithResponse */];
            
            qppCentState = QPP_CENT_IDLE;
            [self readQpp];
            
            
        }
        
        
    }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
        
        NSLog(@"cancel btn");
        
        [alert dismissViewControllerAnimated:YES completion:nil];
        
    }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Input";
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    [self refreshData2BeSent:devInfo];
    
}
-(void)readQpp{
    
    [qppApi qppEnableNotify : devInfo.qppPeri
                withNtfChar : devInfo.aQppNtfChar
                 withEnable : YES];
    
    //  [self setDataCount];
    
}

-(void)setDataCount{
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    for (int i=0;i<_ArrayOfValues1.count;i++)
    {
        [values addObject:[[ChartDataEntry alloc] initWithX:(double)i y:[[_ArrayOfValues1 objectAtIndex:i] doubleValue]]];
    }
    
    
    if (_chartView.data && _chartView.data.dataSetCount > 0)
    {
        set1 = (LineChartDataSet *)_chartView.data.dataSets[0];
        [set1 replaceEntries: values];
        [_chartView.data notifyDataChanged];
        [_chartView notifyDataSetChanged];
    }
    else
    {
        set1 = [[LineChartDataSet alloc] initWithEntries:values label:@"DataSet 1"];
        set1.axisDependency = AxisDependencyLeft;
        set1.valueTextColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
        set1.lineWidth = 1.5;
        set1.drawCirclesEnabled = NO;
        set1.drawValuesEnabled = NO;
        set1.fillAlpha = 0.26;
        set1.fillColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
        set1.highlightColor = [UIColor colorWithRed:224/255.0 green:117/255.0 blue:117/255.0 alpha:1.0];
        set1.drawCircleHoleEnabled = NO;
        
        NSMutableArray *dataSets = [[NSMutableArray alloc] init];
        [dataSets addObject:set1];
        
        LineChartData *data = [[LineChartData alloc] initWithDataSets:dataSets];
        [data setValueTextColor:UIColor.whiteColor];
        [data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:9.0]];
        
        _chartView.data = data;
    }
}

-(void)didQppEnableConfirmForAppRsp : (NSNotification *)_noti
{
    NSDictionary *dictInfo=[_noti object];

    devInfo.aQppWriteChar = [dictInfo objectForKey:keyWrCharInQpp];
    devInfo.aQppNtfChar = [dictInfo objectForKey:keyNtfCharInQpp];
    devInfo.fQppEnableStatus = (BOOL)[dictInfo objectForKey:keyConfirmStatus];
    
    if(devInfo.fQppEnableStatus)
    {
        NSLog(@"qppEnable ok.");
//        [self.btnToggleNtf setTitle:@"Stop" forState : UIControlStateNormal];
//        [qppApi qppEnableNotify : devInfo.qppPeri
//                    withNtfChar : devInfo.aQppNtfChar
//                     withEnable : YES];
    }
    else
    {
        NSLog(@"qppEnable failed!!!");
        
    }
}

#if __BACKUP_CODE
-(void)didQppEnableConfirm : (CBPeripheral *)aPeripheral
                withStatus : (BOOL) qppEnableResult{
    
    qppEnableStatus = qppEnableResult;
    
    if(qppEnableStatus)
    {
        NSLog(@"qppEnable OK !");
    }
    else
    {
        NSLog(@"qppEnable failed!!!");
    }
}
#endif

/**
 *****************************************************************
 * @brief       app scan peripheral around.
 *
 * @param[in]  sender : id
 *
 *****************************************************************
 */
- (IBAction)scanPeri:(id)sender {
    qBleQppClient *dev = [qBleQppClient sharedInstance];
    
#if QPP_IOS8
    BOOL isConnected = qppConnectedPeri.isConnected;
    
    if (isConnected)
#endif
    
    CBPeripheralState stateConnected = devInfo.qppPeri.state; /// iOS 9.0.2
    if (stateConnected==CBPeripheralStateConnected)/// iOS 9.0.2
    {
        [self qppReset];
        
        qppCentState = QPP_CENT_DISCONNECTING;
        
        [dev pubDisconnectPeripheral : devInfo.qppPeri];
        [qppApi qppEnableNotify : devInfo.qppPeri
        withNtfChar : devInfo.aQppNtfChar
         withEnable : NO];
    }
    else
    {
        if((qppCentState != QPP_CENT_SCANNING) &&
           (qppCentState != QPP_CENT_CONNECTING) )
        {
            qppCentState = QPP_CENT_SCANNING;
            
            [self.ptScanDevActInd startAnimating];
            
            [dev stopScan];
            
            [dev startScan];
        }
    }
}

/**
 *****************************************************************
 * @brief app refresh scan button.
 *****************************************************************
 */
- (void)refreshConnectBtns {
#if QPP_IOS8
    BOOL isConnected = qppConnectedPeri.isConnected;
    if (isConnected)
#endif
    
    CBPeripheralState stateConnected = devInfo.qppPeri.state; /// iOS 9.0.2
    if (stateConnected==CBPeripheralStateConnected)/// iOS 9.0.2
    {
        scanDisconnectItem.title = @"Disconnect";
     
        
        NSString *dev_name = devInfo.qppPeri.name;
        if (dev_name) {
            self.qppDevNameLabel.text = dev_name; 
        }
        
        self.qppConnectStatusLabel.text = @"<>";
    }
    else {
        scanDisconnectItem.title = @"Scan";
        
        self.qppConnectStatusLabel.text = @"><";
        
        [self qppSendReset];
    }
}

#pragma mark - discovered ....
- (void)qppDidPeriDiscoveredRsp{
    
    NSLog(@"%s", __func__);
    
    [[NSNotificationCenter defaultCenter] postNotificationName: ReloadDevListDataNoti object:nil userInfo:nil];
    
    if(flagOnePeriScanned == FALSE)
    {
        flagOnePeriScanned = TRUE;
        
        [self.ptScanDevActInd stopAnimating];
        
        /// [self presentModalViewController : deviceVC animated:YES ];
        [self presentViewController: deviceVC animated:YES completion:nil];
    }
}

/**
 *****************************************************************
 * @brief app Discovered Services Response.
 *****************************************************************
 */
- (void)qppDidDiscoveredServicesRsp{
    NSLog(@"%s", __func__);
}

/**
 *****************************************************************
 * @brief  app Discovered Services Char.
 *****************************************************************
 */
- (void)qppDidDiscoveredCharsRsp{
    NSLog(@"%s", __func__); 
}

/// update data
/**
 *****************************************************************
 * @brief update state for notify char response.
 *****************************************************************
 */
- (void)qppUpdateStateForCharRsp:(NSNotification *)noti{
    NSLog(@"%s", __func__);
}

/**
 *****************************************************************
 * @brief Select one peripheral response.
 *****************************************************************
 */
- (void)qppSelOnePeripheralRsp :(NSNotification *)noti
{
    // CBPeripheral *selectedPeri
    devInfo.qppPeri=[noti object];
    
    [self qppUserConfig];  
    
    /// to conect the peripheral
    qBleQppClient *dev = [qBleQppClient sharedInstance];
    [dev stopScan];
    NSLog(@"ntfChar %@",devInfo.aQppNtfChar);
    qppCentState = QPP_CENT_CONNECTING;
    
    [dev pubConnectPeripheral : devInfo.qppPeri];
    

    
    [qppApi qppEnableNotify : devInfo.qppPeri
    withNtfChar : devInfo.aQppNtfChar
     withEnable : YES];
}

- (void)qppMainStopScan
{
    flagOnePeriScanned = FALSE;
    qppCentState = QPP_CENT_IDLE;
    
    [[qBleQppClient sharedInstance] stopScan];
}

-(void)qppSendReset{
    [btnSend setTitle:@"Send" forState : UIControlStateNormal];
    
    qppCentState = QPP_CENT_IDLE;
//    qppSendCounter = 0;
//    repeatCounterLbl.text = [NSString stringWithFormat:@"%lld", qppSendCounter];
}

- (IBAction)swRepeatQppSent:(id)sender {
    UISwitch *qppDataRepeatSw = (UISwitch*)sender;
    
    devInfo.fQppWrRepeat = [qppDataRepeatSw isOn];
    
    if(devInfo.fQppWrRepeat)
    {
        self.btnSend.hidden=YES;
        
//        devInfo.pkgIdx=0;
//        
//        repeatWrTimer= [NSTimer scheduledTimerWithTimeInterval:devInfo.intervalBtwPkg target:self selector:@selector(didRepeatWrData:) userInfo:devInfo repeats:YES];
        
    }
    else
    {
        [[Utils sharedInst] cancelTimer : repeatWrTimer];
             
        [self qppSendReset];

        self.btnSend.hidden=NO;
    }
    
    
#if _ENABLE_SUB_THREAD
    [qppApi startQppStateMachine ];
#endif
    
    [qppApi qppStart:devInfo.qppPeri withBlkInterval:devInfo.intervalBtwPkg
           withStart:devInfo.fQppWrRepeat];
}

- (IBAction)qppSendPackage:(id)sender {
    [self refreshData2BeSent:devInfo];
    
    if(devInfo.fQppEnableStatus == FALSE){
        NSLog(@"qppEnable failed!!!");
    }
    else
    {
//        if(qppCentState == QPP_CENT_SENDING)
//        {
//            [self qppSendReset];
//        }
//        else
        {
            qppCentState = QPP_CENT_SENDING;
            
#if 1  /// temp code
            NSString *strEdited =[[NSString alloc] init];
            if([indata2send.text isEqualToString:@" "])
            {
                strEdited =indata2send.text;
            }else{
                indata2send.placeholder=[NSString stringWithFormat: @"%@", devInfo.data2Send];
                
                strEdited=indata2send.placeholder;
                NSLog(@"indata2send.placeholder:%@",indata2send.placeholder);
            }
#else
            NSString *strEdited = indata2send.text;
#endif
            /// dataSentPkg = [[Utils sharedInstance] hexStrToBytes : strEdited withStrMin:TEXT_EDITED_LENGTH_MIN withStrMax:TEXT_EDITED_LENGTH_MAX];
            
          //  strEdited = @"13";
           
            
            if(fEdited){
                NSData *inData=[[Utils sharedInst] hexStrToBytes : strEdited withStrMin:TEXT_EDITED_LENGTH_MIN withStrMax: [strEdited length]];
                
                devInfo.data2Send=[[NSMutableData alloc] initWithData:inData];
            }
            
            if(devInfo.data2Send == NULL)
            {
                /// illegal input
                CustomAlertView *inputAlert = [[CustomAlertView alloc]
                                            initWithTitle : ALERT_INPUT_ERROR_TITLE
                                                  message : @"Input error!"
                                                 delegate : nil
                                        cancelButtonTitle : nil
                                        otherButtonTitles : @"OK", nil];
                [inputAlert show];
                
                return;
            }
            
            ///QppApi *qppApi = [QppApi sharedInstance];
         
           /*
            NSMutableString *tempHex=[[NSMutableString alloc] init];

            [tempHex appendString:@"0x11"];

            unsigned colorInt = 0;

            [[NSScanner scannerWithString:tempHex] scanHexInt:&colorInt];

           // lblAttString.backgroundColor=UIColorFromRGB(colorInt);
            NSString *dataString = [NSString stringWithFormat:@"%d",colorInt];
            devInfo.data2Send = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSMutableString *buf = [NSMutableString stringWithCapacity:devInfo.data2Send.length];
               const unsigned char *value = devInfo.data2Send.bytes;
               
               for (int i=0; i<devInfo.data2Send.length; i++) {
                   [buf appendFormat:@" %02lx",(unsigned long)value[i]];
               }
               NSLog(@"qpp I/P %@",buf);
             */
            NSString *command = indata2send.text;

            command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSMutableData *commandToSend= [[NSMutableData alloc] init];
            unsigned char whole_byte;
            char byte_chars[3] = {'\0','\0','\0'};
            int i;
            for (i=0; i < [command length]/2; i++) {
                byte_chars[0] = [command characterAtIndex:i*2];
                byte_chars[1] = [command characterAtIndex:i*2+1];
                whole_byte = strtol(byte_chars, NULL, 16);
                [commandToSend appendBytes:&whole_byte length:1];
            }
            NSLog(@"%@", commandToSend);
            
            [qppApi qppSendData : devInfo.qppPeri
                                withData : commandToSend
                                withType : CBCharacteristicWriteWithoutResponse/* CBCharacteristicWriteWithResponse */];
                     
                     qppCentState = QPP_CENT_IDLE;
            
//            if(devInfo.fQppWrRepeat){
//                repeatWrTimer= [NSTimer scheduledTimerWithTimeInterval:devInfo.intervalBtwPkg target:self selector:@selector(didRepeatWrData:) userInfo:devInfo repeats:YES];
//            }
        }
    }
}

-(void)refreshQppDataToSend:(DevicesCtrl *)_devInfo{
    ///qppWrData[0]=_devInfo.pkgIdx;
    uint16_t header=_devInfo.pkgIdx; /// todo more.
    /// _devInfo.data2Send=[[NSData alloc] init];
    /// _devInfo.data2Send=[NSData dataWithBytes:&qppWrData length:QPP_ LENGTH_AT_BLE4_2];
    NSRange headerRang;
    headerRang.length=sizeof(header);
    headerRang.location=0;
    
    [_devInfo.data2Send replaceBytesInRange:headerRang withBytes:&header length:sizeof(header)];
}

-(void)didRepeatWrData:(NSTimer *)_tmr {
#if _ENABLE_BACKCODE
    DevicesCtrl *_devInfo=[_tmr userInfo];

    _devInfo.pkgIdx++;
    [self refreshQppDataToSend:_devInfo];
    
    [qppApi qppSendData : _devInfo.qppPeri
               withData : _devInfo.data2Send
               withType : CBCharacteristicWriteWithoutResponse ];
#endif
    
#if 0 /// _ENABLE_BACKCODE
      [qppApi qppStart:_devInfo.qppPeri withBlkInterval:_devInfo.intervalBtwPkg withStart:0];
#endif
    
    /// self.repeatCounterLbl.text=[NSString stringWithFormat:@"%llu", _devInfo.pkgIdx];
}
 
-(void)qppWriteValueForCharRsp : (NSNotification *)noti
{
#if 0
    if(qppCentState == QPP_CENT_IDLE)
    {
        return;
    }
    
    if(devInfo.fQppWrRepeat)
    {
        CBPeripheral *aPeri = [noti.userInfo objectForKey: keyQppPeriWritten];
        if([aPeri isEqual: devInfo.qppPeri])
        {   
            [btnSend setTitle:@"Stop" forState : UIControlStateNormal];
            
            Byte *dataSentPkgArr = (Byte *)[devInfo.data2Send bytes];
            dataSentPkgArr[0]++;
    
            /// devInfo.dat a2Send = [[NSData alloc] initWithBytes : dataSentPkgArr length : [devInfo.data 2Send length]];
            ///QppApi *qppApi = [QppApi sharedInstance];
            
            [qppApi qppSendData : devInfo.qppPeri
                       withData : devInfo.data2Send
                       withType : CBCharacteristicWriteWithResponse];
            
            /// update UI
            qppSendCounter++;
            repeatCounterLbl.text = [NSString stringWithFormat:@"%lld", qppSendCounter];
        }
    }
#endif
}

/// just for testing
//- (IBAction)qppSendWoRsp:(id)sender {
//    NSString *strEdited = indata2send.text;
//    
//    dataSentPkg = [[Utils sharedInstance]
//                   hexStrToBytes : strEdited
//                   withStrMin : TEXT_EDITED_LENGTH_MIN
//                   withStrMax : TEXT_EDITED_LENGTH_MAX];
//    
//    Byte *dataSentPkgArr = (Byte *)[dataSentPkg bytes];
//    QppApi *qppApi = [QppApi sharedInstance];
//    ///if(fQppWrRepeat)
//    while(fQppWrRepeat)
//    {
//        // if(aPeri == qppConnectedPeri){
//        dataSentPkgArr[0]++;
//        
//        dataSentPkg = [[NSData alloc] initWithBytes : dataSentPkgArr length : [dataSentPkg length]];
//        
//        [qppApi qppSendData : qppConnectedPeri
//                   withData : dataSentPkg
//                   withType : CBCharacteristicWriteWithoutResponse];
//        
//        ///}
//    }
//}

/**
 *****************************************************************
 * @brief Qpp display peripherals scanned.
 *****************************************************************
 */
- (void)qppDisplayPeripherals 
{
    NSLog(@"%s", __func__);
    [self.ptScanDevActInd stopAnimating];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: ReloadDevListDataNoti object:nil userInfo:nil];
    
    /// [self presentModalViewController : deviceVC animated:YES];
}

/**
 *****************************************************************
 * @brief Qpp Stop connect device timeout.
 *****************************************************************
 */
- (void) qppStopDidConnDevTimeout
{
    qppDidConnDevTimeoutCount = 0;
    [qppDidConnDevTimeoutTimer invalidate];
    [self.ptDidConnDevActInd stopAnimating];
}

/**
 *****************************************************************
 * @brief Qpp Connect device timeout response.
 *****************************************************************
 */
- (void) qppDidConnDevTimeoutRsp{
    // if(qppDidConnDevTimeoutCount > QPP_DIDCONN_DEV_TIMEOUT)
    {
        [self qppStopDidConnDevTimeout];
        
        /// to scan a device timeout.
        CustomAlertView *pbDidConnDevAlert = [[CustomAlertView alloc] initWithTitle : ALERT_CONNECT_FAIL_TITLE
                                                                            message:@"Connection failed!"
                                                                           delegate:nil
                                                                  cancelButtonTitle:nil /*@"Cancel" */
                                                                  otherButtonTitles:@"OK", nil];
        [pbDidConnDevAlert show];
    }
}

/**
 *****************************************************************
 * @brief Qpp Start connect device Activity Indicator.
 *****************************************************************
 */
- (void) qppStartDidConnActInd
{
    [self.ptDidConnDevActInd startAnimating];
    
    qppDidConnDevTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval : QPP_DIDCONN_DEV_TIMEOUT target:self selector:@selector(qppDidConnDevTimeoutRsp) userInfo:nil repeats : NO];
}

///
/**
 *****************************************************************
 * @brief Qpp Get reference time.
 *****************************************************************
 */
- (NSDate *)getDateTimeFromMilliSeconds:(uint64_t) miliSeconds
{
    NSTimeInterval tempMilli = miliSeconds;
    NSTimeInterval seconds = tempMilli/1000.0;
 
    return [NSDate dateWithTimeIntervalSince1970:seconds];
}

/**
 *****************************************************************
 * @brief Qpp Start Scan device Activity Indicator.
 * convert time with NSDate format into NSInteger, from 1970/1/1
 *****************************************************************
 */
- (uint64_t)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
     
    uint64_t totalMilliseconds = interval*1000 ; 
    
    return totalMilliseconds;
}

/**
 *****************************************************************
 * @brief Qpp Update Data Rate.
 *****************************************************************
 */
- (void)qppUpdateDataRateAveraged:(NSNotification *)_noti{
    NSDate *  currentTime = [NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    
    [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
    
    curTimeMs = [self getDateTimeTOMilliSeconds : currentTime];
    
    uint64_t deltaTime = curTimeMs - preTimeMs;
    
    if(deltaTime == 0) /// overflow
        return;
    
    /// NSLog(@"deltaTime %llu", deltaTime);
    
#if 1
    dataReceived += [(NSData *)[_noti object] length]; /// * 255;
    
    float qppCurDataRate = (dataReceived * 1000 / deltaTime);
#else
    /// float qppCurDataRate = (dataReceived * 1000 / deltaTime);
    float qppCurDataRate = (255 * 20 * 1000 / deltaTime);
#endif

    _qppDataRateAvgLbl.text = [NSString stringWithFormat:@"%d", (int)qppCurDataRate];
    
    if(qppCurDataRate <= 0)
        return;
    
    // min max
    if(qppDataRateMin > (qppCurDataRate ))
    {
        qppDataRateMin  = qppCurDataRate ;
    }
    // max
    if(qppDataRateMax < qppCurDataRate)
    {
        qppDataRateMax  = qppCurDataRate;
    }
}

- (IBAction)qppDataRateAvgReset:(id)sender{
    [self qppDataRateAveragedReset];
    
    [self qppWrDataReset];
}

-(void)qppDataRateAveragedReset{
    dataReceived = 0;
    
    _qppDataRateAvgLbl.text = @"0";
    
    NSDate *  qppRefTime = [NSDate date];
    
    preTimeMs = [self getDateTimeTOMilliSeconds : qppRefTime];
}

-(void)qppWrDataReset{
    [self qppReset];
    devInfo.pkgIdx=0;
}

/**
 *****************************************************************
 * @brief Qpp Update Data Rate.
 *****************************************************************
 */
- (void)qppUpdateDataRateDynamic:(NSNotification *)_noti{
    
    NSDate *  currentTime = [NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    
    [dateformatter setDateFormat:@"HH:mm:ss.SSSS"];
    
    curTimeMs = [self getDateTimeTOMilliSeconds : currentTime];
    
    uint64_t deltaTime = curTimeMs - dynRefTimeMs;
    
    if(deltaTime == 0) /// overflow
        return;
    
    /// to dynamic data rate.
    float qppDataRateDyn = (255 * [(NSData *)[_noti object] length] * 1000 / deltaTime);
    dynRefTimeMs = curTimeMs;
    
    _qppDataRateDynLbl.text = [NSString stringWithFormat:@"%d", (int)qppDataRateDyn];
    
}

#pragma mark -
#pragma mark the method to settle softinput hide UITextField 
- (void)keyboardWillShow:(NSNotification *)noti
{
    float height = 216.0;
    CGRect frame = self.view.frame;
    frame.size = CGSizeMake(frame.size.width, frame.size.height - height);
    
    [UIView beginAnimations:@"Curl"context:nil]; // start Animation
    [UIView setAnimationDuration:0.30];
    [UIView setAnimationDelegate:self];
    [self.view setFrame:frame];
    [UIView commitAnimations];
}
#pragma text input
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // When the user presses return, take focus away from the text field so that the keyboard is dismissed.
    NSTimeInterval animationDuration = 0.30f;
    
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    CGRect rect = CGRectMake(0.0f, 20.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.view.frame = rect;
    [UIView commitAnimations];
    
    if (textField == self.inIntervalBtwPkg) {
        [textField resignFirstResponder];
    }
    
    if (textField == self.indata2send) {
        [textField resignFirstResponder];
    }
    
    return YES;
}


/// touch anywhere in panel to close keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.inIntervalBtwPkg resignFirstResponder];
    [self.indata2send resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    /// NSLog(@"%s",__func__);
    int inPut=0;
    if(textField==self.inIntervalBtwPkg){
        inPut=[[Utils sharedInst] decStrToDec:textField.text withStrMin:0 withStrMax:10];
        
        devInfo.intervalBtwPkg=((float)inPut)/1000.000;
    }
    
    if(textField==self.indata2send){
        devInfo.data2Send=[[NSMutableData alloc] initWithData: [[Utils sharedInst] hexStrToBytes: textField.text withStrMin:0 withStrMax:TEXT_EDITED_LENGTH_MAX]];
    }
    
    fEdited = true;
    /// NSLog(@"%f | %@",devInfo.intervalBtwPkg,devInfo.da ta2Send);
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"%s",__func__);
    
    CGRect frame = textField.frame;
    int offset = frame.origin.y + 32 - (self.view.frame.size.height - 216.0);//keyboard height : 216
    NSTimeInterval animationDuration = 0.30f;
    
    [UIView beginAnimations:@"ResizeForKeyBoard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    if(offset > 0)
    {
        CGRect rect = CGRectMake(0.0f, -offset,width,height);
        self.view.frame = rect;
    }

    [UIView commitAnimations];
    
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    /// NSLog(@"%s textField.text:%@",__func__,textField.text);
    int inPut=0;
    if(textField==self.inIntervalBtwPkg){
        inPut=[[Utils sharedInst] decStrToDec:textField.text withStrMin:0 withStrMax:10];
        
        devInfo.intervalBtwPkg=((float)inPut)/1000.000;
    }
    
    if(textField==self.indata2send){
        devInfo.data2Send=[[NSMutableData alloc] initWithData: [[Utils sharedInst] hexStrToBytes: textField.text withStrMin:0 withStrMax:TEXT_EDITED_LENGTH_MAX]];
    }
    
    fEdited = true;
    
    return YES;
}

#pragma mark -
-(void)subSetVersion{
//    NSDictionary *bundleDict = [[NSBundle mainBundle] infoDictionary];
//    _lblVersion.text = [NSString stringWithFormat:@"%@", [bundleDict objectForKey:@"CFBundleVersion"]];
    
    NSDictionary *dictBundle = [[NSBundle mainBundle] infoDictionary];
    
    _lblVersion.text = [NSString stringWithFormat:@"Ver:%@", [dictBundle objectForKey:@"CFBundleShortVersionString"]];
}



#pragma mark -
#pragma mark touch backgroud to close softkeyboard 
-(IBAction)backgroundTap:(id)sender
{
    // When the user presses return, take focus away from the text field so that the keyboard is dismissed.
    NSTimeInterval animationDuration = 0.30f;
    
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    
//    CGRect rect = CGRectMake(0.0f, 20.0f, self.view.frame.size.width, self.view.frame.size.height);// ui drawed!
    CGRect rect = CGRectMake(0.0f, 0.0f, self.view.frame.size.width,
                             self.view.frame.size.height);
    
    self.view.frame = rect;
    
    [UIView commitAnimations];
     
    [indata2send resignFirstResponder];
    
    [inIntervalBtwPkg resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    
    return YES;
}

- (IBAction)btnHelp:(id)sender {
  //  [self presentViewController: helpVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/**
 *****************************************************************
 * @brief Qpp convert CBUUID to UUID.
 *****************************************************************
 */
-(NSString *) CBUUIDToUUID : (CBUUID *) UUID {
    
    NSString *strUUID = [NSString stringWithFormat:@"%s",[[UUID.data description] cStringUsingEncoding : NSStringEncodingConversionAllowLossy]];
    
    return strUUID;
}

- (IBAction)toggleIndicate:(id)sender {
    if(!devInfo.fQppEnableStatus){
        return;
    }
    
    if([self.btnToggleNtf.titleLabel.text isEqualToString:@"Stop"]){
        [self.btnToggleNtf setTitle:@"Start" forState : UIControlStateNormal];
        [qppApi qppEnableNotify : devInfo.qppPeri
                    withNtfChar : devInfo.aQppNtfChar
                     withEnable : NO];
    }
    else if([self.btnToggleNtf.titleLabel.text isEqualToString:@"Start"]){
        [self.btnToggleNtf setTitle:@"Stop" forState : UIControlStateNormal];
        
        [self qppDataRateAveragedReset];
        
        [qppApi qppEnableNotify : devInfo.qppPeri
                    withNtfChar : devInfo.aQppNtfChar
                     withEnable : YES];
    }
}

-(int)selectPkgLengMax:(int)curLength withNewLength:(int)newLength{
    if(newLength>=curLength)
        return newLength;
    
    return curLength;
}
@end
