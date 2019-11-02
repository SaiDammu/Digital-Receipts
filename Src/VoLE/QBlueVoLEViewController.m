//
//  QBlueVoLEViewController.m
//  bleDevMonitor
//
//  Created by Derek on 12/05/13.
//  Copyright (c) 2012 QN Inc. All rights reserved.
//
//Orbital

#import "QBlueClient.h"
#import "QBlueDefine.h"

#import "TableViewAlert.h"
#import "CustomAlertView.h"

#import "QBlueVoLEViewController.h"

#import <QuartzCore/CoreAnimation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>

#import "GraphView1.h"
#import "GraphView2.h"

#import "Constants.h"

#import "QppApi.h"
#import "DevicesCtrl.h"
#import "QppPublic.h"

#define VOLE_TIMER_STEP               (1.0) //was 5.0
#define VOLE_SCAN_DEV_TIMEOUT         1  //was 10
#define VOLE_DIDCONN_DEV_TIMEOUT      50
#define VOLE_RESUME_TIMEOUT           50
volatile int startcounting = 3;
volatile int initialcount = 0;
//double num[5] = {0.9677, -3.8708, 5.8062, -3.8708, 0.9677};
//double den[5] = {1.0000, -3.9343, 5.8051, -3.8072, 0.9364};

//volatile double RegX[5];
//volatile double RegY[5];
//volatile float CenterTap;

@interface QBlueVoLEViewController () {
    uint32_t received_data_length;
    NSDate *refDate;
    NSDate *intDate;
    NSString *fname;
    uint8_t  voleScanDevTimeoutCount;
    NSTimer *voleScanDevTimeoutTimer;
    
    uint8_t  voleDidConnDevTimeoutCount;
    NSTimer *voleDidConnDevTimeoutTimer;
    uint16_t numm;
    NSString *numms;
    NSString *nummst;
#if QPP_LOG_FILE
    NSString *_fileLog;
    NSFileHandle *_fileHdl;
    
    NSData  *readerBuf;  //
#endif
    
    NSMutableData  *writeBuf;  //
    
    uint8_t _prev_type;
    
    uint8_t qppWrData[512];
    
       QppApi *qppApi;
    DevicesCtrl *devInfo;
}

@property (strong, nonatomic) NSTimer *voleScanDevTimeoutTimer;
@property (strong, nonatomic) NSTimer *voleDidConnDevTimeoutTimer;

@end

@implementation QBlueVoLEViewController

@synthesize voleScanDevTimeoutTimer;
@synthesize voleDidConnDevTimeoutTimer;
@synthesize myGraph=_myGraph;


+ (QBlueVoLEViewController *)sharedInstance
{
    static QBlueVoLEViewController *_sharedInstance = nil;
    if (_sharedInstance == nil) {
        _sharedInstance = [[QBlueVoLEViewController alloc] init];
    }
    
    return _sharedInstance;
}

-(id)init {
    
    return self;
}

-(void)WriteToStringFile:(NSMutableString *)textToWrite{
    
    NSError *err;
    
    
    
    BOOL ok = [textToWrite writeToFile:@"/test.dat" atomically:YES encoding:NSUnicodeStringEncoding error:&err];
    
    if (!ok) {
        NSLog(@"Error writing file at %@\n%@",
              @"/users/davidschie/documents/test.dat", [err localizedFailureReason]);
    }
}

-(NSArray *)ReadTextFromFile:(NSMutableString *)textToRead{
    
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *fileInDocumentsPath = [documentsPath stringByAppendingPathComponent:@"Z005.txt"];
    NSString *myfile = [NSString stringWithContentsOfFile: fileInDocumentsPath encoding: NSUTF8StringEncoding error: &error];
    
    return [myfile componentsSeparatedByString:@"\n"];
}


- (void) voleStopScanDevTimeout
{
    voleScanDevTimeoutCount = 0;
    
    [voleScanDevTimeoutTimer invalidate];
    
    [self.voleScanDevActInd stopAnimating];
}

- (void) voleScanDevTimeoutRsp{
    
    if(voleScanDevTimeoutCount < VOLE_SCAN_DEV_TIMEOUT)
    {
        voleScanDevTimeoutCount++;
        
        [self updateScanCountDown: TRUE withCount:(VOLE_SCAN_DEV_TIMEOUT - voleScanDevTimeoutCount)];
        
        return;
    }
    
    [self updateScanCountDown: FALSE withCount : 0];
    
    [self voleStopScanDevTimeout];
    
    bleDevMonitor *dev = [bleDevMonitor sharedInstance];
    
    // create the alert
    NSArray *otaDevList = [dev discoveredPeripherals];
    
    if([otaDevList count])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName : voleScanPeriEndNoti object:nil];
    }
    else
    {
        /// to scan a device timeout.
        CustomAlertView *voleScanDevAlert = [[CustomAlertView alloc] initWithTitle : ALERT_NODEVICE_TITLE
                                                                           message : @"No Device Around!"
                                                                          delegate : nil
                                                                 cancelButtonTitle : nil/*@"Cancel" */
                                                                 otherButtonTitles : @"OK", nil];
        [voleScanDevAlert show];
    }
}

- (void) voleStartScanActInd
{
    [self.voleScanDevActInd startAnimating];
    
    voleScanDevTimeoutCount = 0;
    
    voleScanDevTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval : 1.0 target:self selector:@selector(voleScanDevTimeoutRsp) userInfo:nil repeats : YES];
}

- (IBAction)voleScanPeri:(id)sender {
    bleDevMonitor *dev = [bleDevMonitor sharedInstance];
    
    BOOL isConnected = dev.isConnected;
    
    if (isConnected) {
        [[bleDevMonitor sharedInstance] disconnect];
    }
    else {
        self.receivedDataLabel.text = @"0";
        self.dataRateLabel.text = @"0";
        
        dev.connectionDelegate = self;
        
        [self voleStartScanActInd];
        
        _voleScanCountDnLbl.text = [NSString stringWithFormat:@"%d", VOLE_SCAN_DEV_TIMEOUT];
        
        [dev startScan];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    devInfo = [[DevicesCtrl alloc] init];
    
    devInfo.intervalBtwPkg=0.03f;
    devInfo.fQppWrRepeat = false;
    devInfo.lengOfPkg2Send=20;
    
    [self refreshData2BeSent:devInfo];
    
    [self refreshQppDataToSend:devInfo ];

    
    qBleClient *dev = [qBleClient sharedInstance];
     [dev startScan];

    
    
    
    sleep(2);
    refDate = [NSDate date];
    fname = [NSString stringWithFormat:@"ppg[%d][%@].txt",received_data_length,refDate];
    //Dave
    numm=0;
    numms=@"";
    nummst=@"";
    self.ArrayOfValues = [[NSMutableArray alloc] init];
    self.ArrayOfValues1 = [[NSMutableArray alloc] init];
    self.ArrayOfValuesBase = [[NSMutableArray alloc] init];
    
    self.ArrayOfValuesGolay = [[NSMutableArray alloc] init];
    self.ledfilter = [[NSMutableArray alloc] init];
    self.beatdifference = [[NSMutableArray alloc] init];
    
    _myGraph.delegate = self;
    float p;
    [self.myGraph reloadGraph];
    for (int i=0; i < 1000; i++)
    {
        p=1*sin(0.5*i)+100;
        [self.ArrayOfValues1 addObject:[NSNumber numberWithFloat:(p)]]; // Random values for the graph
        [self.ArrayOfValues addObject:[NSNumber numberWithFloat:(p)]]; // Random values for the graph
        
    }
    
    
    _RespGraph.delegate = self;
    [self.RespGraph reloadGraph];
    // Do any additional setup after loading the view from its nib.
    self.title = @"VoLE Demo";
    self.temperature.text=@" ";
    [self.VoLEVersion setText:[NSString stringWithFormat: @"Ver %1.1f", QBLUE_VOLE_VERSION]];
    
    [self.connectButton setTitle:@"Scan" forState:UIControlStateNormal];
    self.connStatusLabel.text = @"><";
    
    
    /*[[@"123457" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:@"/tmp/test2.txt" atomically:NO];
     NSString *myfile = [NSString stringWithContentsOfFile:@"/tmp/test2.txt"
     encoding:NSASCIIStringEncoding
     error:NULL];
     NSLog(@"Our file contains this: %@", myfile);*/
    // Documents path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    // Destination path
    NSString *fileInDocumentsPath = [documentsPath stringByAppendingPathComponent:@"ecg.txt"];
    
    // Origin path
    NSString *fileInBundlePath = [[NSBundle mainBundle] pathForResource:@"ecg" ofType:@"txt"];
    
    // File manager for copying
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager copyItemAtPath:fileInBundlePath toPath:fileInDocumentsPath error:&error];
    [[@"1234578" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileInDocumentsPath atomically:NO];
    //[[@"123457" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileInDocumentsPath atomically:NO];
    [fileManager copyItemAtPath:fileInDocumentsPath toPath:fileInBundlePath error:&error];
    NSString *my1file = [NSString stringWithContentsOfFile: fileInDocumentsPath encoding: NSUTF8StringEncoding error: &error];
    NSLog(@"Our file contains this: %@", my1file);
    
    
    NSFileHandle *file;
    NSMutableData *data;
    
    const char *bytestring = "black dog";
    
    data = [NSMutableData dataWithBytes:bytestring
                                 length:strlen(bytestring)];
    
    file = [NSFileHandle fileHandleForUpdatingAtPath:
            fileInDocumentsPath];
    
    if (file == nil)
        NSLog(@"Failed to open file");
    
    [file seekToFileOffset: 5];
    [file writeData: data];
    [file closeFile];
    NSString *my2file = [NSString stringWithContentsOfFile: fileInDocumentsPath encoding: NSUTF8StringEncoding error: &error];
    NSLog(@"Our file contains this: %@", my2file);
    [fileManager copyItemAtPath:fileInDocumentsPath toPath:fileInBundlePath error:&error];
    [self voleResetVC];
    
    [self volePlayerReset ];
    
    [bleDevMonitor sharedInstance].updateDelegate = self;
    
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshConnectBtns) name:voleDidDisconnectNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voleUpdateDidConnDev) name:voleDidConnectNoti object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voleDisplayPeripherals) name:voleScanPeriEndNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voleSelOnePeripheralRsp:) name:voleSelOnePeripheralNoti object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppSelOnePeripheralRsp:) name : qppSelOnePeripheralNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didQppEnableConfirmForAppRsp:) name: didQppEnableConfirmForAppNoti object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qppUpdateDataRateAveraged:) name:qppSelOnePeripheralNoti object:nil];
    
#if QPP_LOG_FILE
    _fileLog = nil; // zfq
#endif
    
    [self qppDataRateAveragedReset];
          
    
    NSString * periString = @"";
   //   CBPeripheral *peri = [CBPeripheral new];
   // [peri writeValue:[periString dataUsingEncoding:NSUTF8StringEncoding] forDescriptor:[CBDescriptor new]];



           qppApi = [QppApi sharedInstance];
        [qppApi qppEnableNotify : devInfo.qppPeri
                               withNtfChar : devInfo.aQppNtfChar
                                withEnable : YES];
     
    
   
    
    
}

-(void)refreshData2BeSent:(DevicesCtrl *)_devCtrl{
    for(int i=0; i<_devCtrl.lengOfPkg2Send;i++){
        qppWrData[i]=i;
    }
    
    _devCtrl.data2Send=[[NSMutableData alloc] initWithBytes:qppWrData length:_devCtrl.lengOfPkg2Send];
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


- (void)qppSelOnePeripheralRsp :(NSNotification *)noti{
      devInfo.qppPeri=[noti object];
}
- (void)qppUpdateDataRateAveraged:(NSNotification *)_noti{
    
    NSLog(@"asdf");
    
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


-(void)qppDataRateAveragedReset{
   // dataReceived = 0;
    
   // _qppDataRateAvgLbl.text = @"0";
    
   // NSDate *  qppRefTime = [NSDate date];
    
    //preTimeMs = [self getDateTimeTOMilliSeconds : qppRefTime];
}

- (int)numberOfPointsInGraph {
    return (int)[self.ArrayOfValues count];
}

- (float)valueForIndex:(NSInteger)index {
    return [[self.ArrayOfValues objectAtIndex:index] floatValue];
}

- (int)numberOfPointsInGraph1 {
    return (int)[self.ArrayOfValues1 count];
}

- (float)valueForIndex1:(NSInteger)index {
    return [[self.ArrayOfValues1 objectAtIndex:index] floatValue];
}


- (void)refreshConnectBtns {
    BOOL isConnected = [bleDevMonitor sharedInstance].isConnected;
    
    NSLog(@"\n func : %s\n", __func__);
    
    if (isConnected) {
        [self.connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        
        
        
        NSString *dev_name = [[bleDevMonitor sharedInstance] devName];
        if (dev_name) {
            self.devNameLabel.text = dev_name;
            NSLog(@"Device Name is %@", dev_name);
        }
        self.connStatusLabel.text = @"<>";
        received_data_length = 0;
        refDate = [NSDate date];
        NSLog(@"refDate %@", refDate.description);
        
#if QPP_LOG_FILE
        NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        
        //NSString *_filePath= [documentsDirectory stringByAppendingPathComponent:@"log.txt"];
        NSString *_filePath= [documentsDirectory stringByAppendingPathComponent:@"testAudio.caf"];
        
        BOOL r = [[NSFileManager defaultManager] createFileAtPath:_filePath contents:nil attributes:nil];
        
        _fileHdl = [NSFileHandle fileHandleForUpdatingAtPath:_filePath];
        
        if (r == NO || _fileHdl == nil)
        {
            NSLog(@"File Open Error!\n");
        }
        
        _fileLog = [[NSString alloc] init];
        
#endif
        // device side should send the first type be 1 every time the link be created
        _prev_type = 0;
    }
    else
    {
        [self.connectButton setTitle:@"Scan" forState:UIControlStateNormal];
        
        
        self.connStatusLabel.text = @"><";
        self.devNameLabel.text = @"No Device";
        
#if QPP_LOG_FILE
        
        NSLog(@"_fileHdl %@\n",_fileHdl);
        
        [_fileHdl seekToEndOfFile];
        
        [_fileHdl writeData: writeBuf];
        
        [_fileHdl closeFile];
        
        // clean writeBuf
        
        writeBuf = [NSMutableData alloc] ;
        
        _fileLog = nil;
        
#endif
    }
}

#pragma mark - RECEIVED_DATA_LENGTH

- (void)bleDevMonitor:(bleDevMonitor *)client didUpdateReceivedData:(NSData *)data
{
    uint16_t length = data.length;
    
#if QPP_DATA_CHECK
    // check the received data
    const uint8_t *reportData = [data bytes];
    
    uint8_t type = reportData[0];
    if ((uint8_t)(type - _prev_type) != 1)
    {
        NSLog(@"Error: %d:%d", _prev_type, type);
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"QPP Alert View"
                                                    message:@"Received data check failed!"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil, nil];
        [av show];
    }
    _prev_type = type;
#endif
    
    // data rate
    uint16_t data_rate;
    static uint32_t length_interval = 0;
    static bool data_rate_history = NO;
    
    
    if (received_data_length == 0)
    {
        refDate = [NSDate date];
        data_rate = 0;
        length_interval = 0;
        data_rate_history = NO;
    }
    else
    {
#if UPDATE_DATA_RATE_IN_TIME
        length_interval += length;
        if (length_interval <= 20)
        {
            refDate = [NSDate date];
            intDate = [[NSDate date]initWithTimeInterval:UPDATE_DATA_RATE_INTERVAL sinceDate:refDate];
            data_rate = 0;
        }
        else
        {
            NSDate *curDate = [NSDate date];
            if ([curDate compare: intDate] != NSOrderedAscending)
            {
                NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:refDate];
                data_rate = (length_interval-20)/interval;
                // NSLog(@"data length = %d, date rate = %d", length_interval, data_rate);
                length_interval = 0;
                data_rate_history = YES;
            }
            else
            {
                if (data_rate_history == NO)
                {
                    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:refDate];
                    data_rate = (length_interval-20)/interval;
                }
                else
                {
                    data_rate = 0;
                }
            }
        }
#else
        NSTimeInterval interval;
        interval = [[NSDate date] timeIntervalSinceDate:refDate];
        data_rate = (received_data_length-20)/interval;
#endif
    }
    // total length
    received_data_length += length;
    
    if (length && received_data_length) {
        // total length display
        self.receivedDataLabel.text = [NSString stringWithFormat:@"%d", received_data_length];
        // data rate display
        if (data_rate != 0)
        {
            self.dataRateLabel.text = [NSString stringWithFormat:@"%d", data_rate];
        }
        //self.temperature.text = [NSString stringWithFormat:@"%d", 80];
//        NSString* myString;
        // myString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        uint16_t number2[10];
        
        uint16_t *number = (uint16_t*)data.bytes;// [data bytes];
//        int16_t temp;
        int8_t ia=0;
        int8_t ib=0;
        int8_t i=0;
        uint16_t latest;
        
        static int start = 0;
        static int countcheck = 0;
        static int printbeat = 0;
        static int fileCount = 0;
        static double RegX[41];
        static double RegX1[41];
        
        double CenterTap;
        double CenterTap1; /// first derivative
                
        
        while(i<([data length]/2))
        {
           // number2[i]=number[i];
            number2[i] = (0x3FFF & number[i]);
            i++;
        }
        
        i=0;ia=0;ib=0;
        int A = 0, B = 65000;
        int a = 75, b = 125;
        int newvalue;
        int currentvalue;
        static float timestamp = 0.0;
        if(start == 0)
        {
            for(int j=0;j<41;j++)
            {
                RegX[j]=0;
                RegX1[j]=0;
            }
            start = 1;
        }
        
        
        for (i=0; i<[data length]/2; i++)
        {
            /* Store it in a file */
            [self.ArrayOfValuesBase addObject:[NSNumber numberWithInteger:(number[i])]];
            numm=[(NSNumber *)[self.ArrayOfValuesBase objectAtIndex:(fileCount)] intValue];
            numms = [NSString stringWithFormat:@"%d\n", numm];
            nummst = [nummst stringByAppendingString:numms];
            fileCount++;
            if(fileCount>=240)
            {
                
                NSFileHandle *file;
                // Documents path
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0];
                // Destination path
                NSString *fileInDocumentsPath = [documentsPath stringByAppendingPathComponent:fname];
                NSData* writeData = [nummst dataUsingEncoding:NSUTF8StringEncoding];
                
              //  NSString* tempString;
              //  tempString = [[NSString alloc] initWithData:writeData encoding:NSASCIIStringEncoding];
                if (![[NSFileManager defaultManager] fileExistsAtPath:fileInDocumentsPath]) {
                    [[NSFileManager defaultManager] createFileAtPath:fileInDocumentsPath contents:nil attributes:nil];
                }
                
                
                file = [NSFileHandle fileHandleForUpdatingAtPath:fileInDocumentsPath];
                [file seekToEndOfFile];
                [file writeData: writeData];
                [file closeFile];
                [self.ArrayOfValuesBase removeAllObjects];  //empty storage array
                numm=0;
                numms=@"";
                nummst=@"";
                fileCount=0;
            }
            
            int count_leddata;
            
            int data = number2[i];
            float signal;
            signal = (float) data;
            // Shift the register values.
            for(int k=40; k>0; k--)
            {
                RegX[k] = RegX[k-1];
                RegX1[k] = RegX1[k-1];
            }
            
            // numerator
            CenterTap = 0.0;
            CenterTap1 = 0.0;
            RegX[0] = signal;
            RegX1[0] = signal;
            for(int k=0; k<=40; k++)
            {
                CenterTap += fil[k] * RegX[k];
                CenterTap1 += der[k] * RegX1[k];
            }
            
            [self.ledfilter addObject:[NSNumber numberWithInteger:((int)(CenterTap))]];
            if(CenterTap1 < 0)
                CenterTap1= CenterTap1 * -1;
            [self.ArrayOfValuesGolay addObject:[NSNumber numberWithInteger:((int)(CenterTap1))]];
            count_leddata = (int)[self.ledfilter count];
            if(count_leddata>=90) // 61
            {
                A = 66000;
                B = 0;
                for(int i=0; i<=89;i++)     // till 40
                {
                    currentvalue = [(NSNumber *)[self.ledfilter objectAtIndex:(i)] intValue];
                    if(currentvalue > B)
                    {
                        B = currentvalue;       // maximum
                        
                    }
                    if(currentvalue < A)
                    {
                        A = currentvalue;      // minimum
                    }
                }
                if(B-A <= 20) //30// 10      // if it is actual value change it to 80
                {
                    a = 98;
                    b = 102;
                }
                else
                {
                    a = 65;
                    b = 135;
                }
                latest = [(NSNumber *)[self.ledfilter objectAtIndex:(29)] intValue];
                newvalue = a + (latest - A)*(b-a)/(B-A);
                newvalue = b - newvalue + a;
                
                [self.ArrayOfValues1 removeObjectAtIndex:0];
                [self.ArrayOfValues1 addObject:[NSNumber numberWithInteger:(newvalue)]];
                
                latest = [(NSNumber *)[self.ArrayOfValuesGolay objectAtIndex:(29)] intValue];
                newvalue = (latest + 20)*4;
                [self.ArrayOfValues removeObjectAtIndex:0];
                [self.ArrayOfValues addObject:[NSNumber numberWithInteger:(newvalue)]]; //accelerometer plot
                
                [self.ledfilter removeObjectAtIndex:0];
                [self.ArrayOfValuesGolay removeObjectAtIndex:0];
                
                
                countcheck = countcheck+1;
                int startindex =0;
                int betweenindex=0;
                int endindex = 0;
                int beatdiffindex=0;
                float meandiff=0.0;
                double sum_deviation = 0.0;
                int temp;
                int countbeats = 0;
                static int heartrate = 0;
                
                /* count beats */
                if(countcheck >=1000) // 80
                {
                    countcheck = 1; //250
                    timestamp = timestamp+8;
                    int k=50;
                    while(950-k-30 > 10)  // 78
                    {
                        int numb1 = [(NSNumber *)[self.ArrayOfValues1 objectAtIndex:(950-k-30)] intValue];
                        int numb2 = [(NSNumber *)[self.ArrayOfValues1 objectAtIndex:(950-k)] intValue];
                        int numb3 = [(NSNumber *)[self.ArrayOfValues1 objectAtIndex:(950-k+30)] intValue];
                        if (numb2 > numb3 && numb2 > numb1 && numb2 - numb3 > 15 && numb2 - numb1 > 15 && numb2 < 250 && numb2 > 0)
                        {
                            countbeats = countbeats + 1;
                            if (startindex == 0)
                            {
                                startindex = k;
                            }
                            else
                            {
                                betweenindex = k;
                                beatdiffindex = betweenindex - endindex;
                                [self.beatdifference addObject:[NSNumber numberWithInteger:(beatdiffindex)]];
                                meandiff += beatdiffindex;
                            }
                            endindex = k;
                            k=k+70;
                        }
                        else
                        {
                            k=k+10;
                        }
                    }
                    if (countbeats >= 7)
                    {
                        meandiff = meandiff/(125*(countbeats-1));
                        for(int i=0;i<countbeats-1;i++)
                        {
                            temp = [(NSNumber *)[self.beatdifference objectAtIndex:(i)] intValue];
                            sum_deviation += (temp/125 - meandiff) * (temp/125-meandiff);
                        }
                        sum_deviation = sum_deviation*1000/(countbeats-1);  // 1000 (ms)
                        sum_deviation = sqrt(sum_deviation);
                        countbeats = (countbeats-1)*125*60/(endindex-startindex);
                        if(printbeat == 0)
                        {
                            heartrate = countbeats;
                            printbeat = 1;
                        }
                        else
                        {
                            heartrate = (0.3*heartrate + 0.7*countbeats);
                        }
                        
                        self.temperature.text=[NSString stringWithFormat:@"%d", heartrate];//(int)(sum_deviation)]; // heartrate
                        
                    }
                    [self.beatdifference removeAllObjects];
                    countbeats = 0;
                }
                /* count beats end */
                
            }
            
        }
        
        
    }
    
    
    
    _myGraph.delegate = self;
    _RespGraph.delegate = self;
    
    [self.myGraph reloadGraph];
    [self.RespGraph reloadGraph];
#if QPP_LOG_FILE
    // write data to log file
    [writeBuf appendBytes:[data bytes] length:20 ];
#endif
    
}

- (void)viewDidUnload {
    [self setReceivedDataLabel:nil];
    [self setDevNameLabel:nil];
    [self setConnStatusLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    
    return NO;
}

- (IBAction)_FileButton:(id)sender {
    NSLog(@"here");
    fname = [NSString stringWithFormat:@"ecg[%d][%@].txt",received_data_length,refDate];
    
}

/*
 Hex 2 NSData.
 */
-(NSString *)hexData2NSString:(NSData *)toConvertData : (int16_t)strLenght
{
    ///// 将16进制数据转化成Byte 数组
    NSString *hexString = @" "; //16进制字符串
    
    const uint8_t *arrData = [toConvertData bytes];
    
    ///3ds key的Byte 数组， 128位
    for(int i=0; i < strLenght; i++)
    {
        
        unichar hex_char1 = arrData[i]>>4; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1+48);   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1+55); //// A 的Ascll - 65
        else
            int_ch1 = (hex_char1+87); //// a 的Ascll - 97
        
        // hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%x",int_ch1]];
        hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%x", hex_char1]];
        
        unichar hex_char2 = arrData[i]&0x0f; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2+48); //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch2 = hex_char2+55; //// A 的Ascll - 65
        else
            int_ch2 = hex_char2+87; //// a 的Ascll - 97
        
        hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%x",hex_char2]];
        
        i++;
        
        //hexString = [hexString stringByAppendingString:[NSString stringWithFormat:@"%x",arrData[i]]];
        
        //  NSLog(@"hexString:%@",hexString);
    }
    
    // NSData *newData = [[NSData alloc] initWithBytes:bytes length:strLenght];
    // NSLog(@"newData=%@",newData);
    
    
    // NSData 2 NSString.
    // NSString *testString = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
    
    return hexString;
}

- (NSString *)toGetFileName{
    // create file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // get the path
    // arg:NSDocumentDirectory: to get the path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // change to the path to be access
    [fileManager changeCurrentDirectoryPath:[documentsDirectory stringByExpandingTildeInPath]];
    
    // to get file's path
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"testAudio.caf"];
    
    return filePath;
}

#pragma mark - bleDevMonitorDelegate

/// display vole peripheral list
- (void)voleDisplayPeripherals //:(CBPeripheral *)aPeripheral
{
    [self.voleScanDevActInd stopAnimating];
    
    // create the alert
    NSArray *volePeriList = [[bleDevMonitor sharedInstance] discoveredPeripherals ];// [[otaFirmwareFile sharedInstance] enumBinFiles];
    
    self.voleDisplayDevicesVC = [TableViewAlert tableAlertWithTitle:@"Choose a Peripheral..." cancelButtonTitle:@"Cancel" numberOfRows:^NSInteger (NSInteger section)
                                 {
                                     return [volePeriList count];
                                 }
                                 
                                                           andCells:^UITableViewCell* (TableViewAlert *anAlert, NSIndexPath *indexPath)
                                 {
                                     static NSString *CellIdentifier = @"CellIdentifier";
                                     UITableViewCell *cell = [anAlert.table dequeueReusableCellWithIdentifier:CellIdentifier];
                                     
                                     if (cell == nil)
                                         cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                                     
                                     //cell.textLabel.text = [[volePeriList objectAtIndex:indexPath.row] name];
                                     NSString *temp=[[NSUserDefaults standardUserDefaults] valueForKey:@"localName"];
                                     cell.textLabel.text=temp;
                                     
                                     return cell;
                                 }];
    
    // Setting custom alert height
    self.voleDisplayDevicesVC.height = 250;
    
    // configure actions to perform
    [self.voleDisplayDevicesVC configureSelectionBlock:^(NSIndexPath *selectedIndex){
        self.devNameLabel.text = [[volePeriList objectAtIndex:selectedIndex.row] name];
        
        NSDictionary *dictPeri = [NSDictionary dictionaryWithObject : [volePeriList objectAtIndex:selectedIndex.row] forKey:@"selectedDevice"];
        
        [[NSNotificationCenter defaultCenter]postNotificationName: voleSelOnePeripheralNoti object:nil userInfo:dictPeri];
        
    } andCompletionBlock:^{
        self.devNameLabel.text = @"No Device! \n";
    }];
    
    // show the alert
    [self.voleDisplayDevicesVC show];
}

/// connect act ind.
- (void) voleStartDidConnActInd
{
    [self.voleDidConnDevActInd startAnimating];
    
    // voleDidConnDevTimeoutCount = 0;
    
    voleDidConnDevTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval : VOLE_DIDCONN_DEV_TIMEOUT/* VOLE_TIMER_STEP */ target:self selector:@selector(voleDidConnDevTimeoutRsp) userInfo:nil repeats : NO];
}

- (void)voleSelOnePeripheralRsp :(NSNotification *)notifyFromPeripheral
{
    NSLog(@"%s", __func__);
    
    CBPeripheral *selectedPeri = [notifyFromPeripheral.userInfo objectForKey:@"selectedDevice"];
    
    NSLog(@"testPeri = %@ \n", selectedPeri);
    
    /// to conect the peripheral
    bleDevMonitor *dev = [bleDevMonitor sharedInstance];
    [dev stopScan];
    
    [self voleStartDidConnActInd];
    
    [dev connectPeripheral : selectedPeri];
}

- (void) voleDidConnDevTimeoutRsp{
    
    // voleDidConnDevTimeoutCount++;
    
    // if(voleDidConnDevTimeoutCount > VOLE_DIDCONN_DEV_TIMEOUT)
    {
        [self voleStopDidConnDevTimeout];
        
        /// to scan a device timeout.
        CustomAlertView *voleDidConnDevAlert = [[CustomAlertView alloc] initWithTitle:@"Warning!"
                                                                              message:@"Connection Failed!"
                                                                             delegate:nil
                                                                    cancelButtonTitle:nil/*@"Cancel" */
                                                                    otherButtonTitles:@"OK", nil];
        [voleDidConnDevAlert show];
    }
}

- (void) voleStopDidConnDevTimeout
{
    voleDidConnDevTimeoutCount = 0;
    [voleDidConnDevTimeoutTimer invalidate];
    [self.voleDidConnDevActInd stopAnimating];
}

- (void)voleResetVC{
    //    received_data_length = 0;
    
    _voleScanDevActInd.hidesWhenStopped = YES;
    _voleDidConnDevActInd.hidesWhenStopped = YES;
    
    [self.voleScanDevActInd stopAnimating];
    [self.voleDidConnDevActInd stopAnimating];
    
    // _voleLoadFileBtn.hidden = YES;
    
    /// data rate
    // volePreTimeMs = 0l;
    // voleCurTimeMs = 0l;
    
    voleScanDevTimeoutCount = 0;
    [voleScanDevTimeoutTimer invalidate];
    
    voleDidConnDevTimeoutCount = 0;
    [voleDidConnDevTimeoutTimer invalidate];
    
}

-(void) volePlayerReset
{
    writeBuf = [NSMutableData alloc] ;
    
    received_data_length = 0;
}

- (void)updateScanCountDown : (BOOL)flag withCount : (uint8_t)ScanCountDn
{
    if(flag)
    {
        _voleScanCountDnLbl.text = [NSString stringWithFormat:@"%d", ScanCountDn];
        _voleScanCountDnLbl.hidden = NO;
        _voleScanCountDnUnitLbl.hidden = NO;
    }
    else
    {
        _voleScanCountDnLbl.text = @"0";
        _voleScanCountDnLbl.hidden = YES;
        _voleScanCountDnUnitLbl.hidden = YES;
    }
}

- (void) voleUpdateDidConnDev
{
    NSLog(@"method: %s", __func__);
    
    [self voleStopDidConnDevTimeout];
    [self refreshConnectBtns];
}

- (void)didQppReceiveData:(CBPeripheral *)aPeripheral withCharUUID:(CBUUID *)qppUUIDForNotifyChar withData:(NSData *)qppData {
    NSLog(@"qpp rec data %@",qppData);
}

@end
