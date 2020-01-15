//
//  HRMViewController.swift
//  VoLE Demo
//
//  Created by Sai Seshu Sarath Chandra Dammu on 12/17/19.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

import UIKit
import CoreBluetooth
import CorePlot
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class HRMViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, ScannerDelegate, CPTPlotDataSource, CPTPlotSpaceDelegate {

    //MARK: - Properties
    var bluetoothManager                : CBCentralManager?
    var hrValues                        : NSMutableArray?
    var xValues                         : NSMutableArray?
    var plotXMaxRange                   : Int?
    var plotXMinRange                   : Int?
    var plotYMaxRange                   : Int?
    var plotYMinRange                   : Int?
    var plotXInterval                   : Int?
    var plotYInterval                   : Int?
    var isBluetoothOn                   : Bool?
    var isDeviceConnected               : Bool?
    var isBackButtonPressed             : Bool?
    var batteryServiceUUID              : CBUUID!
    var batteryLevelCharacteristicUUID  : CBUUID!
    var hrServiceUUID                   : CBUUID!
    var hrMeasurementCharacteristicUUID : CBUUID!
    var hrLocationCharacteristicUUID    : CBUUID!
    var linePlot                        : CPTScatterPlot?
    var graph                           : CPTGraph?
    var peripheral                      : CBPeripheral?
    var scanButton                      : UIBarButtonItem!
    
    @objc var enableTwoGraphs:Bool = Bool()
    
    
    //MARK: - UIVIewController Outlets
  //  @IBOutlet weak var verticalLabel: UILabel!
  //  @IBOutlet weak var battery: UIButton!
    @IBOutlet weak var deviceName: UILabel!
  //  @IBOutlet weak var connectionButton: UIButton!
    //@IBOutlet weak var hrLocation: UILabel!
    @IBOutlet weak var hrValue: UILabel!
    @IBOutlet weak var graphView: CPTGraphHostingView!
    
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    @IBOutlet weak var topSpace: UIView!
    @IBOutlet weak var titleHeight: NSLayoutConstraint!
    @IBOutlet weak var graphBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var bpmView: NSLayoutConstraint!
    
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    //MARK: - UIVIewController Actions
     @IBAction func connectionButtonTapped(_ sender: AnyObject) {
        print("connect tapped")
        if peripheral != nil{
            bluetoothManager?.cancelPeripheralConnection(peripheral!)
        }
         
        let scannerVC = ScannerViewController()
        if let id = hrServiceUUID{
            scannerVC.filterUUID = id
        }
        scannerVC.delegate = self
        self.present(scannerVC, animated: true, completion: nil)
       // self.navigationController?.pushViewController(scannerVC, animated: true)
       // scannerVC.filterUUID = hrServiceUUID self.navigationController?.pushViewController(scannerVC, animated: true)
        
    }
    
    @IBAction func aboutButtonTapped(_ sender: AnyObject) {
        print("about button")
       // self.showAbout(message: AppUtilities.getHelpTextForService(service: .hrm))
    }
    
    
    //MARK: - UIViewController delegate
    //required init?(coder aDecoder: NSCoder) {
      
  //      super.init(coder: aDecoder)
  //  }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Rotate the vertical label
           self.deviceName.textColor = .black
        
        //embed vc
       /* self.titleHeight.constant = 0
        self.bpmView.constant = 0
        self.graphBottomSpace.constant = 350
        */
        scanButton = UIBarButtonItem(title: "Scan", style: .plain, target: self, action: #selector(self.scanButtonAction)) // action:#selector(Class.MethodName) for swift 3
        self.navigationItem.rightBarButtonItem  = scanButton
        
        
        hrServiceUUID = CBUUID(string: ServiceIdentifiers.hrsServiceUUIDString)
        hrMeasurementCharacteristicUUID  = CBUUID(string: ServiceIdentifiers.hrsHeartRateCharacteristicUUIDString)
        hrLocationCharacteristicUUID     = CBUUID(string: ServiceIdentifiers.hrsSensorLocationCharacteristicUUIDString)
        batteryServiceUUID               = CBUUID(string: ServiceIdentifiers.batteryServiceUUIDString)
        batteryLevelCharacteristicUUID   = CBUUID(string: ServiceIdentifiers.batteryLevelCharacteristicUUIDString)
        
       // verticalLabel.transform = CGAffineTransform(translationX: -(verticalLabel.frame.width/2) + (verticalLabel.frame.height / 2), y: 0.0).rotated(by: -.pi / 2)
        isBluetoothOn           = false
        isDeviceConnected       = false
        isBackButtonPressed     = false
        peripheral              = nil
        
        hrValues = NSMutableArray()
        xValues  = NSMutableArray()
        
        initLinePlot()
        
        //Embedd qpp
        if enableTwoGraphs{
            self.deviceName.text = ""
            //okay, lets stop this work , open resume
            self.topMargin.constant = 300.0
            self.bottomSpace.constant = 30.0
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(containerView)
            
            let controller = QBlueVoLEViewController(nibName: "QBlueVoLEViewController", bundle: .main)
            
            controller.willMove(toParent: self)
            self.view.addSubview(controller.view)
            self.addChild(controller)
            controller.didMove(toParent: self)
            containerView.addSubview(controller.view)
            controller.view.frame = CGRect(x: 0, y: 64, width: self.view.frame.size.width-90, height: 240)
            
            controller.view.clipsToBounds = true
      
            
        }
        
        
    }
  
    //objc to swift
    @objc func connectHRM(_ aPeripheral:CBPeripheral){
        print("hrm connect")
        
        // bluetoothManager = aManager;
        bluetoothManager!.delegate = self;
        
        // The sensor has been selected, connect to it
        peripheral = aPeripheral;
        aPeripheral.delegate = self;
        let options = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey as NSCopying)
        bluetoothManager!.connect(aPeripheral, options: options as? [String : AnyObject])
        bluetoothManager?.cancelPeripheralConnection(aPeripheral)
    }
    
    
    @objc func scanButtonAction(){

        if peripheral != nil
        {
            bluetoothManager?.cancelPeripheralConnection(peripheral!)
        }
         
        let scannerVC = ScannerViewController()
        if let id = hrServiceUUID{
            scannerVC.filterUUID = id
        }
        scannerVC.delegate = self
        self.present(scannerVC, animated: true, completion: nil)
       // self.navigationController?.pushViewController(scannerVC, animated: true)
       // scannerVC.filterUUID = hrServiceUUID self.navigationController?.pushViewController(scannerVC, animated: true)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if peripheral != nil && isBackButtonPressed == true
        {
            bluetoothManager?.cancelPeripheralConnection(peripheral!)
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DisconnectQpp"), object: nil, userInfo: nil)
            
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isBackButtonPressed = true
    }

    //MARK: - CTPPlot Implementation
    
    func initLinePlot() {
        //Initialize and display Graph (x and y axis lines)
        graph = CPTXYGraph(frame: graphView.bounds)
        self.graphView.hostedGraph = self.graph;
        
        //apply styling to Graph
        graph?.apply(CPTTheme(named: CPTThemeName.plainWhiteTheme))
        
        //set graph backgound area transparent
        graph?.fill = CPTFill(color: CPTColor.clear())
        graph?.plotAreaFrame?.fill = CPTFill(color: CPTColor.clear())
        graph?.plotAreaFrame?.fill = CPTFill(color: CPTColor.clear())
        
        //This removes top and right lines of graph
        graph?.plotAreaFrame?.borderLineStyle = CPTLineStyle(style: nil)
        //This shows x and y axis labels from 0 to 1
        graph?.plotAreaFrame?.masksToBorder = false
        
        // set padding for graph from Left and Bottom
        graph?.paddingBottom = 30;
        graph?.paddingLeft = 50;
        graph?.paddingRight = 0;
        graph?.paddingTop = 0;
        
        //Define x and y axis range
        // x-axis from 0 to 100
        // y-axis from 0 to 300
        let plotSpace = graph?.defaultPlotSpace
        plotSpace?.allowsUserInteraction = false
        plotSpace?.delegate = self;
        self.resetPlotRange()
        
        let axisSet = graph?.axisSet as! CPTXYAxisSet;
        
        let axisLabelFormatter = NumberFormatter()
        axisLabelFormatter.generatesDecimalNumbers = false
        axisLabelFormatter.numberStyle = NumberFormatter.Style.decimal
        
        
        //Define x-axis properties
        //x-axis intermediate interval 2
        let xAxis = axisSet.xAxis
        xAxis?.majorIntervalLength = plotXInterval as NSNumber?
        xAxis?.minorTicksPerInterval = 4;
        xAxis?.minorTickLength = 5;
        xAxis?.majorTickLength = 7;
        xAxis?.title = "Time (s)"
        xAxis?.titleOffset = 25;
        xAxis?.labelFormatter = axisLabelFormatter
        
        //Define y-axis properties
        let yAxis = axisSet.yAxis
        yAxis?.majorIntervalLength = plotYInterval as NSNumber?
        yAxis?.minorTicksPerInterval = 4
        yAxis?.minorTickLength = 5
        yAxis?.majorTickLength = 7
        yAxis?.title = "BPM"
        yAxis?.titleOffset = 30
        yAxis?.labelFormatter = axisLabelFormatter
        
        
        //Define line plot and set line properties
        linePlot = CPTScatterPlot()
        linePlot?.dataSource = self
        graph?.add(linePlot!, to: plotSpace)
        
        //set line plot style
        let lineStyle = linePlot?.dataLineStyle!.mutableCopy() as! CPTMutableLineStyle
        lineStyle.lineWidth = 2
        lineStyle.lineColor = CPTColor.black()
        linePlot!.dataLineStyle = lineStyle;
     
       
        
        let symbolLineStyle = CPTMutableLineStyle(style: lineStyle)
        symbolLineStyle.lineColor = CPTColor.black()
        let symbol = CPTPlotSymbol.ellipse()
        symbol.fill = CPTFill(color: CPTColor.black())
        symbol.lineStyle = symbolLineStyle
        symbol.size = CGSize(width: 3.0, height: 3.0)
        linePlot?.plotSymbol = symbol;
        
        //set graph grid lines
        let gridLineStyle = CPTMutableLineStyle()
        gridLineStyle.lineColor = CPTColor.gray()
        gridLineStyle.lineWidth = 0.5
        xAxis?.majorGridLineStyle = gridLineStyle
        yAxis?.majorGridLineStyle = gridLineStyle
    }
    
    func resetPlotRange() {
        plotXMaxRange = 20
        plotXMinRange = 0
        plotYMaxRange = 310
        plotYMinRange = 0
        plotXInterval = 20
        plotYInterval = 50
         
        let plotSpace = graph?.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: NSNumber(value: plotXMinRange!), length: NSNumber(value: plotXMaxRange!))
        plotSpace.yRange = CPTPlotRange(location: NSNumber(value: plotYMinRange!), length: NSNumber(value: plotYMaxRange!))
    }
    
    func clearUI() {
       // deviceName.text = "DEFAULT HRM";
       // battery.setTitle("N/A", for: .normal)
       // battery.tag = 0;
        //hrLocation.text = "n/a";
        hrValue.text = "-";
        
        // Clear and reset the graph
        hrValues?.removeAllObjects()
        xValues?.removeAllObjects()
        resetPlotRange()
        graph?.reloadData()
    }
    
    func addHRvalueToGraph(data value: Int) {
        // In this method the new value is added to hrValues array
        hrValues?.add(NSDecimalNumber(value: value as Int))
        
        // Also, we save the time when the data was received
        // 'Last' and 'previous' values are timestamps of those values. We calculate them to know whether we should automatically scroll the graph
        var lastValue : NSDecimalNumber
        var firstValue : NSDecimalNumber
        
        if xValues?.count > 0 {
            lastValue  = xValues?.lastObject as! NSDecimalNumber
            firstValue = xValues?.firstObject as! NSDecimalNumber
        }else{
            lastValue  = 0
            firstValue = 0
        }
        
        let previous : Double = lastValue.subtracting(firstValue).doubleValue
        xValues?.add(HRMViewController.longUnixEpoch())
        lastValue  = xValues?.lastObject as! NSDecimalNumber
        firstValue = xValues?.firstObject as! NSDecimalNumber
        let last : Double = lastValue.subtracting(firstValue).doubleValue
        
        // Here we calculate the max value visible on the graph
        let plotSpace = graph!.defaultPlotSpace as! CPTXYPlotSpace
        let max = plotSpace.xRange.locationDouble + plotSpace.xRange.lengthDouble
        
        if last > max && previous <= max {
            let location = Int(last) - plotXMaxRange! + 1
            plotSpace.xRange = CPTPlotRange(location: NSNumber(value: (location)), length: NSNumber(value: plotXMaxRange!))
        }
        
        // Rescale Y axis to display higher values
        if value >= plotYMaxRange {
            while (value >= plotYMaxRange)
            {
                plotYMaxRange = plotYMaxRange! + 50
            }
            
            plotSpace.yRange = CPTPlotRange(location: NSNumber(value: plotYMinRange!), length: NSNumber(value: plotYMaxRange!))
        }
        graph?.reloadData()
    }
    
    //MARK: - ScannerDelegate
    func centralManagerDidSelectPeripheral(withManager aManager: CBCentralManager, andPeripheral aPeripheral: CBPeripheral){
        // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
        bluetoothManager = aManager;
        bluetoothManager!.delegate = self;
        
        // The sensor has been selected, connect to it
        peripheral = aPeripheral;
        aPeripheral.delegate = self;
        let options = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBConnectPeripheralOptionNotifyOnNotificationKey as NSCopying)
        bluetoothManager!.connect(aPeripheral, options: options as? [String : AnyObject])
    }
    

    //MARK: - CPTPlotDataSource
    
    func numberOfRecords(for plot :CPTPlot) -> UInt {
        return UInt(hrValues!.count)
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        let fieldVal = NSInteger(fieldEnum)
        let scatterPlotField = CPTScatterPlotField(rawValue: fieldVal)
        switch scatterPlotField! {
        case .X:
            // The xValues stores timestamps. To show them starting from 0 we have to subtract the first one.
            return (xValues?.object(at: Int(idx)) as! NSDecimalNumber).subtracting(xValues?.firstObject as! NSDecimalNumber)
        case .Y:
            return hrValues?.object(at: Int(idx)) as AnyObject?
        default:
            return nil
        }
    }

    //MARK: - CPRPlotSpaceDelegate
    func plotSpace(_ space: CPTPlotSpace, shouldScaleBy interactionScale: CGFloat, aboutPoint interactionPoint: CGPoint) -> Bool {
        return false
    }

    func plotSpace(_ space: CPTPlotSpace, willDisplaceBy proposedDisplacementVector: CGPoint) -> CGPoint {
        return CGPoint(x: proposedDisplacementVector.x, y: 0)
    }
    
    func plotSpace(_ space: CPTPlotSpace, willChangePlotRangeTo newRange: CPTPlotRange, for coordinate: CPTCoordinate) -> CPTPlotRange? {
        // The Y range does not change here
        if coordinate == CPTCoordinate.Y {
            return newRange;
        }

        // Adjust axis on scrolling
        let axisSet = space.graph?.axisSet as! CPTXYAxisSet
        
        if newRange.location.intValue >= plotXMinRange! {
            // Adjust axis to keep them in view at the left and bottom;
            // adjust scale-labels to match the scroll.
            axisSet.yAxis!.orthogonalPosition = NSNumber(value: newRange.locationDouble - Double(plotXMinRange!))
            return newRange
        }
        axisSet.yAxis!.orthogonalPosition = 0
        return CPTPlotRange(location: NSNumber(value: plotXMinRange!), length: NSNumber(value: plotXMaxRange!))
    }
    
    //MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            print("Bluetooth powered off")
        } else {
            print("Bluetooth powered on")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async {
           // self.deviceName.text = peripheral.name
            self.deviceName.textColor = .black
            self.scanButton.title = "DISCONNECT"
            self.hrValues?.removeAllObjects()
            self.xValues?.removeAllObjects()
            self.resetPlotRange()
        
            if UIApplication.instancesRespond(to: #selector(UIApplication.registerUserNotificationSettings(_:))){
                UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
            }
            NotificationCenter.default.addObserver(self, selector: #selector(HRMViewController.appDidEnterBackgroundCallback), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(HRMViewController.appDidBecomeActiveCallback), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        
        // Peripheral has connected. Discover required services
        
        if let id1 = hrServiceUUID,let id2 = batteryServiceUUID{
            peripheral.discoverServices([id1, id2])
        }
   
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async {
            AppUtilities.showAlert(title: "Error", andMessage: "Connecting to peripheral failed. Try again", from: self)
            self.scanButton.title = "CONNCECT"
            self.peripheral = nil
            self.clearUI()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Scanner uses other queue to send events. We must edit UI in the main queue
        DispatchQueue.main.async {
            self.scanButton.title = "CONNCECT"
            self.peripheral = nil;
            self.clearUI()
            
            if AppUtilities.isApplicationInactive() {
                let name = peripheral.name ?? "Peripheral"
                AppUtilities.showBackgroundNotification(message: "\(name) is disconnected.")
            }
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
    }
    
    //MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("An error occured while discovering services: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        for aService : CBService in peripheral.services! {
            
            if let id1 = hrServiceUUID, let id2 = batteryServiceUUID{
                
                if aService.uuid.isEqual(id1){
                    print("HRM Service found")
                    peripheral.discoverCharacteristics(nil, for: aService)
                } else if aService.uuid.isEqual(id2) {
                  print("Battery service found")
                    peripheral.discoverCharacteristics(nil, for: aService)
                }
                
            }
            
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error occurred while discovering characteristic: \(error!.localizedDescription)")
            bluetoothManager!.cancelPeripheralConnection(peripheral)
            return
        }
        
        if let id1 = hrServiceUUID, let id2 = batteryServiceUUID{
            if service.uuid.isEqual(id1) {
                
                if let id3 = hrMeasurementCharacteristicUUID,let id4 = hrLocationCharacteristicUUID{
                    
                    for aCharactersistic : CBCharacteristic in service.characteristics! {
                        if aCharactersistic.uuid.isEqual(id3) {
                            print("Heart rate measurement characteristic found")
                            peripheral.setNotifyValue(true, for: aCharactersistic)
                        }else if aCharactersistic.uuid.isEqual(id4) {
                            print("Heart rate sensor location characteristic found")
                            peripheral.readValue(for: aCharactersistic)
                        }
                    }
                    
                }
                
                  
              } else if service.uuid.isEqual(id2) {
                  for aCharacteristic : CBCharacteristic in service.characteristics! {
                      if aCharacteristic.uuid.isEqual(batteryLevelCharacteristicUUID) {
                          print("Battery level characteristic found")
                          peripheral.readValue(for: aCharacteristic)
                      }
                  }
              }
        }
        
  
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error occurred while updating characteristic value: \(error!.localizedDescription)")
            return
        
        }
        
        
        DispatchQueue.main.async {
            
            if let id1 = self.hrMeasurementCharacteristicUUID, let id2 = self.hrLocationCharacteristicUUID, let id3 = self.batteryLevelCharacteristicUUID{
                if characteristic.uuid.isEqual(id1) {
                    
                    if self.enableTwoGraphs{
                        let valuesArray = self.decodeRRValue(withData: characteristic.value!)
                        
                        for value in valuesArray {
                            self.addHRvalueToGraph(data: Int(value))
                            self.hrValue.text = "RR : \(value)"
                           // print("value \(Int(value))")
                        }
                        
                    }else{
                        let valuesArray = self.decodeHRValue(withData: characteristic.value!)
                        
                        let value = self.decodeHRValue(withData: characteristic.value!)
                        self.addHRvalueToGraph(data: Int(value))
                        self.hrValue.text = "\(value)"
                        
                    }
                    

                    
                    
                    //print("\(self.hrValue.text)")
                    self.hrValue.textColor = .black
                } else if characteristic.uuid.isEqual(id2) {
                    //self.hrLocation.text = self.decodeHRLocation(withData: characteristic.value!)
                } else if characteristic.uuid.isEqual(id3) {
                    let data = characteristic.value as NSData?
                    let array : UnsafePointer<UInt8> = (data?.bytes)!.assumingMemoryBound(to: UInt8.self)
                    let batteryLevel : UInt8 = array[0]
                    let text = "\(batteryLevel)%"
                   // self.battery.setTitle(text, for: UIControl.State.disabled)
                    
                   /* if self.battery.tag == 0 {
                        if characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue > 0 {
                            self.battery.tag = 1 // Mark that we have enabled notifications
                            peripheral.setNotifyValue(true, for: characteristic)
                        }
                    } */
                }
            }
            
      
        }
    }
    
    //MARK: - UIApplicationDelegate callbacks
    @objc func appDidEnterBackgroundCallback() {
        let name = peripheral?.name ?? "peripheral"
        AppUtilities.showBackgroundNotification(message: "You are still connected to \(name). It will collect data also in background.")
    }
    
    @objc func appDidBecomeActiveCallback() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    //MARK: - Segue management
  /*  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
        return identifier != "scan" || peripheral == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scan" {
            // Set this contoller as scanner delegate
          
        }
    }
    */
    //MARK: - Helpers
    static func longUnixEpoch() -> NSDecimalNumber {
        return NSDecimalNumber(value: Date().timeIntervalSince1970 as Double)
    }

    func decodeRRValue(withData data: Data) -> Array<Int> {
        let count = data.count / MemoryLayout<UInt8>.size
        var array = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&array, length:count * MemoryLayout<UInt8>.size)
        
        var bpmValue : Int = 0;
        if ((array[0] & 0x01) == 0) {
            bpmValue = Int(array[1])
        } else {
            //Convert Endianess from Little to Big
            bpmValue = Int(UInt16(array[2] * 0xFF) + UInt16(array[1]))
        }
        print("BPM:\(bpmValue)")
        
        let characters = Array(data.hexString)
        let rr1Hex = "\(characters[14])\(characters[15])\(characters[12])\(characters[13])"
        let rr2Hex = "\(characters[10])\(characters[11])\(characters[08])\(characters[09])"
        
        let rr1String = Int(rr1Hex, radix: 16)!
        let rr2String = Int(rr2Hex, radix: 16)!
        
        let rrArray = [rr1String,rr2String]
        
        return rrArray
    }
    
    func decodeHRValue(withData data: Data) -> Int {
           let count = data.count / MemoryLayout<UInt8>.size
           var array = [UInt8](repeating: 0, count: count)
           (data as NSData).getBytes(&array, length:count * MemoryLayout<UInt8>.size)
           
           var bpmValue : Int = 0;
           if ((array[0] & 0x01) == 0) {
               bpmValue = Int(array[1])
           } else {
               //Convert Endianess from Little to Big
               bpmValue = Int(UInt16(array[2] * 0xFF) + UInt16(array[1]))
           }
           return bpmValue
       }
    
    
    func decodeHRLocation(withData data:Data) -> String {
        let location = (data as NSData).bytes.bindMemory(to: UInt16.self, capacity: data.count)
        switch (location[0]) {
            case 0:
                return "Other"
            case 1:
                return "Chest"
            case 2:
                return "Wrist"
            case 3:
                return "Finger"
            case 4:
                return "Hand";
            case 5:
                return "Ear Lobe"
            case 6:
                return "Foot"
            default:
                return "Invalid";
        }
    }
}
