//
//  ViewController.swift
//  BLE_center
//
//  Created by Jake Lin on 2017/7/13.
//  Copyright © 2017年 Jake Lin. All rights reserved.
//
//

import UIKit
import CoreBluetooth




class ViewController: UIViewController, UITextFieldDelegate, CBPeripheralDelegate, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    var mCentralManager: CBCentralManager! //centralManager物件
    var selectedPeripheral: CBPeripheral? //所選定連線的peripheral
    var btPeripherals: [CBPeripheral] = [] //存放找到的藍牙peripheral端
    var btRSSIs: [NSNumber] = [] //存放屬性： 訊號強度
    var btConnectable: [Int] = [] //存放屬性： 是否可連線
    var charDictionary = [String: CBCharacteristic]() //存放所找到的特徵值

    
    @IBOutlet weak var logWindow: UITextView!
    
    @IBOutlet weak var scanView: UIView! //掃描視窗
    @IBOutlet weak var characteristicField: UITextField! //輸入特徵值欄位
    @IBOutlet weak var manualField: UITextField! //存放輸入資料
    @IBOutlet weak var senddataField: UITextField! //送出資料欄位
    @IBOutlet weak var BTtableView: UITableView! //tableView
    
    @IBOutlet weak var btNameLabel: UILabel!
    
    var flag = 0
    
    
    @IBAction func scanBtn(_ sender: Any) {
        
        
        
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(ViewController.stopScan), userInfo: nil, repeats: false)
        //按下button, 計時5秒鐘～時間到停止掃描
        
        mCentralManager.scanForPeripherals(withServices: nil, options: nil)
        
        scanView.isHidden = false
        scanView.bringSubview(toFront: view)
        
    }
    
    @IBAction func cancelBtn(_ sender: Any) {
        
        scanView.isHidden = true
        
        
    }
    
    
    @IBAction func readBtn(_ sender: Any) {
        
        
        if let characteristic = charDictionary[characteristicField.text!.uppercased()] {
            print("read")
            logD(message: "read data, characteristic: \(characteristicField.text)")
            
            selectedPeripheral?.readValue(for: characteristic)
            
        }
    }
    
    @IBAction func notifyBtn(_ sender: Any) {
        
        if let characteristic = charDictionary[characteristicField.text!.uppercased()] {
            print("nofify")
            logD(message: "set notify, characteristic: \(characteristicField.text) ")
            selectedPeripheral?.setNotifyValue(true, for: characteristic)
        }

        
    }
    
    @IBAction func writeAndNotify(_ sender: Any) {
        
        
        
        if let characteristic = charDictionary[characteristicField.text!.uppercased()]  {
            print("set notify and write")
            
            logD(message: "set notify, characteristic: \(characteristicField.text) ")
            selectedPeripheral?.setNotifyValue(true, for: characteristic)
            //送出notify
            
            //let value: [UInt8] = [0x51, 0x26, 0x00, 0x00, 0x00, 0x00, 0xA3, 0x1A]
            //let data = Data(bytes:value)
            //直接送出ByteArray
            
            
            let hexString = stringToBytes(senddataField.text!.uppercased())
            
            let data2 = Data(bytes:hexString!)
            //將String轉換為ByteArray格式
            
            do {
                try sendData(data: data2 as Data, uuidString: characteristicField.text!.uppercased())
            } catch {
                print(error)
                logD(message: error as! String)
            }
            //送出資料

        }
        
        
        
    }
    
    
    @IBAction func writeBtn(_ sender: Any) {
     
        if characteristicField.text != nil {
            
            //let value: [UInt8] = [0xFD, 0xFD, 0xFA, 0x05, 0x0D, 0x0A]
            //let data = Data(bytes:value)
            //直接送出ByteArray
            
            let hexString = stringToBytes(senddataField.text!.uppercased())
            let data2 = Data(bytes:hexString!)
            //String轉ByteArray
            
            do {
                try sendData(data: data2 as Data, uuidString: characteristicField.text!.uppercased())
            } catch {
                print(error)
            }
            //送出資料
            
        }

    }
    
    
    @IBAction func clearLogBtn(_ sender: Any) {
        
        logWindow.text = ""
        
    }
    
    override func viewDidLoad() {

        
        logWindow.isEditable = false
        
        characteristicField.delegate = self
        manualField.delegate = self
        senddataField.delegate = self
        
        BTtableView.delegate = self
        BTtableView.dataSource = self
        
        scanView.isHidden = true

        mCentralManager = CBCentralManager(delegate: self, queue: nil, options:[CBCentralManagerOptionShowPowerAlertKey: true])

        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        //logD(message: "DidUpdateState")
        print("DidUpdateState")
        //檢查central本身的狀態
        
        switch central.state {
        case .unknown:
            logD(message: "State_Unknown")
            
        case .resetting:
            logD(message: "State_Resetting")
            
        case .unsupported:
            logD(message: "State_Unsupported")
            
        case .unauthorized:
            logD(message: "State_Unauthorized")
            
        case .poweredOff:
            logD(message: "State_PoweredOff")
            
        case .poweredOn:
            logD(message: "State_PoweredOn")
            
            
        }
        

        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //logD(message: "didDiscover peripheral")
        print("didDiscover peripheral")
        
        print (peripheral.name)
        
        if peripheral.name != nil {
            
            logD(message: peripheral.name!)
            logD(message: peripheral.identifier.uuidString)
            logD(message: peripheral.description)
            
        }
        //檢查是否掃到重複的peripheral
        let temp = btPeripherals.filter { (pl) -> Bool in
            return pl.identifier.uuidString == peripheral.identifier.uuidString
        }
        //filter的範例可參考 https://hugolu.gitbooks.io/learn-swift/content/Advanced/HighOrderFunctions.html
        
        if temp.count == 0 {
            
            //print("enter temp.count")
            btPeripherals.append(peripheral)
            //將新掃到的peripherals存放到陣列,以供tableView使用
            btRSSIs.append(RSSI)
            btConnectable.append(Int((advertisementData[CBAdvertisementDataIsConnectable]! as AnyObject).description)!)
            //存放"RSSI值"和"是否可連線"
        }
        //http://shenyun23-4.blogspot.tw/2015/10/ios-corebluetooth-swift-2-ble-1.html
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("did connect")
        
        peripheral.discoverServices(nil)
        scanView.isHidden = true
        
        }
    
    func  peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    
        print("didcover services")
        //print(peripheral.services)
        
        
        for service in peripheral.services! {
    
            print("service found: \(service.uuid.uuidString)")
            logD(message: "service found: \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: service)
           //指定找到的服務,繼續往下搜尋特徵值
        }

        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            
            print("characteristics found : \(uuidString)")
            logD(message: "characteristics found : \(uuidString)")
            
            print(characteristic.properties)
            logD(message: "properties rawvalue: \(characteristic.properties.rawValue)")
            //print(characteristic.properties.intersection.(<#T##CBCharacteristicProperties#>))

            print(getProperties(rawvalue: characteristic.properties.rawValue))
            logD(message: "properties: \(getProperties(rawvalue: characteristic.properties.rawValue))")
            //將特徵值屬性rawValue帶入function中運算
        }
        //print(charDictionary)
        
        
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        
        print("didUpdateValue")
        print (characteristic.uuid.uuidString)


       
        if characteristic.value != nil{
            
            let data = characteristic.value! as NSData
            let dataString : String = data.description
            
            print(dataString)
            logD(message: "got data: \(dataString)")
            
            if characteristic.uuid.uuidString == "FFF1" && data.length == 8{
                
                let data = characteristic.value! as NSData
                let dataString : String = data.description
                
                dataAnalysis2(data: dataString)
            }
            
        }
        
        /*
        if characteristic.uuid.uuidString == "00001524-1212-EFDE-1523-785FEABCD123" {
            
            print("自定義")
            
            
            let data = characteristic.value! as NSData
            let dataS : String = data.description
            
            print(dataS)
            print(dataS.lengthOfBytes(using: .utf8))
            print(data.length)
            
        }*/
        
        
        
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("連線中斷")
        logD(message: "連線中斷")

    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("藍牙連線失敗")
        logD(message: "藍牙連線失敗")
    }

    
    func logD(message: String){
        
        logWindow.text = logWindow.text + "\(message)\n"
        
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
        
    }
    
    func stopScan() {
        
        mCentralManager.stopScan()
        BTtableView.reloadData()
        logD(message: "*~停止掃描裝置")
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //if btPeripherals.count == 0 && scaned == true {
        
        /*
        if btPeripherals.count == 0 {
            print("device not found or bluetooth not opened")
            
            let alertController = UIAlertController(
                
                title: "沒找到任何裝置",
                message: "沒找到啦",
                
                preferredStyle: .alert
                
            )
            
            let okAction = UIAlertAction(title: "確定", style: .default){
                (action) in
                
            }
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)

        }*/
 
        return btPeripherals.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BTtableViewCell", for: indexPath) as! BTTableViewCell
        
        
        print("cell for row at")
        
        if btPeripherals[indexPath.row].name == nil {
            cell.BTdeviceLabel.text = "no Name"
        }else{
            print(btPeripherals[indexPath.row].name)
            cell.BTdeviceLabel.text = btPeripherals[indexPath.row].name
            
        }
        
        print(btPeripherals[indexPath.row].identifier.uuidString)
        cell.BTidLabel.text = btPeripherals[indexPath.row].identifier.uuidString
        
        if indexPath.row != flag {
            cell.accessoryType = .none
        }
        
        //scanView.isHidden = false
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("didselectRowAt")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BTtableViewCell", for: indexPath) as! BTTableViewCell
        
        
        print("You tapped cell number \(indexPath.row).")
        
        cell.accessoryType = .checkmark
        flag = indexPath.row
        BTtableView.reloadData()
        
        selectedPeripheral = btPeripherals[indexPath.row]
        selectedPeripheral?.delegate = self
        

        scanView.isHidden = true
        tableView.deselectRow(at: indexPath, animated: true)
        mCentralManager.connect(selectedPeripheral!, options: nil)
        btNameLabel.text = selectedPeripheral?.name
        //連線所選擇的peripheral
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
    }
    
    
    func sendData(data: Data, uuidString: String) throws {
        
        print("send data")
        
        guard let characteristic = charDictionary[uuidString] else {
            
            throw SendDataError.CharacteristicNotFound
            //保證收到的特徵值有在搜尋到的陣列裡面,若沒有則拋出錯誤
        }
        
        if uuidString == characteristicField.text?.uppercased() {
            
            selectedPeripheral?.writeValue(
                data,
                for: characteristic,
                type: .withResponse
            )
        
        }
        
        
    }
    
    
    func stringToBytes(_ string: String) -> [UInt8]? {
        //https://stackoverflow.com/questions/42731023/how-do-i-convert-hexstring-to-bytearray-in-swift-3
        
        let length = string.characters.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    
    func getProperties(rawvalue: UInt) -> [String] {
        
        //https://github.com/Pluto-Y/Swift-LightBlue/blob/master/Source/CBCharacteristic%2BLightBlue.swift
        
        let properties = rawvalue
        let broadcast = CBCharacteristicProperties.broadcast.rawValue
        let read = CBCharacteristicProperties.read.rawValue
        let writeWithoutResponse = CBCharacteristicProperties.writeWithoutResponse.rawValue
        let write = CBCharacteristicProperties.write.rawValue
        let notify = CBCharacteristicProperties.notify.rawValue
        let indicate = CBCharacteristicProperties.indicate.rawValue
        let authenticatedSignedWrites = CBCharacteristicProperties.authenticatedSignedWrites.rawValue
        let extendedProperties = CBCharacteristicProperties.extendedProperties.rawValue
        let notifyEncryptionRequired = CBCharacteristicProperties.notifyEncryptionRequired.rawValue
        let indicateEncryptionRequired = CBCharacteristicProperties.indicateEncryptionRequired.rawValue
        var resultProperties = [String]()
        if properties & broadcast > 0 {
            resultProperties.append("Broadcast")
        }
        if properties & read > 0 {
            resultProperties.append("Read")
        }
        if properties & write > 0 {
            resultProperties.append("Write")
        }
        if properties & writeWithoutResponse > 0 {
            resultProperties.append("Write Without Response")
        }
        
        if properties & notify > 0 {
            resultProperties.append("Notify")
        }
        if properties & indicate > 0 {
            resultProperties.append("Indicate")
        }
        if properties & authenticatedSignedWrites > 0 {
            resultProperties.append("Authenticated Signed Writes")
        }
        if properties & extendedProperties > 0 {
            resultProperties.append("Extended Properties")
        }
        if properties & notifyEncryptionRequired > 0 {
            resultProperties.append("Notify Encryption Required")
        }
        if properties & indicateEncryptionRequired > 0 {
            resultProperties.append("Indicate Encryption Required")
        }
        return resultProperties
    }

    func dataAnalysis2(data: String){
        
        //print(data)
        //fdfdfd05 0d0a error
        
        //fdfdfc75 4d3e0d0a  //117 77 62
        
        //if data.lengthOfBytes(using: <#T##String.Encoding#>)
        
        
        //解析收縮壓 systolic
        let systolicSta = data.index(data.startIndex, offsetBy: 7)
        let systolicEnd = data.index(data.startIndex, offsetBy: 9)
        let rangeSystolic = systolicSta..<systolicEnd
        print(rangeSystolic)
        //解析舒張壓 diastolic
        let diastolicSta = data.index(data.startIndex, offsetBy: 10)
        let diastolicEnd = data.index(data.startIndex, offsetBy: 12)
        let rangeDiastolic = diastolicSta..<diastolicEnd
        print(rangeDiastolic)
        
        //解析心跳
        let heartSta = data.index(data.startIndex, offsetBy: 12)
        let heartEnd = data.index(data.startIndex, offsetBy: 14)
        let rangeHeart = heartSta..<heartEnd
        print(rangeHeart)
        
        let sysValue = UInt8(data.substring(with: rangeSystolic), radix: 16)
        //print("收縮壓")
        //print(sysValue)
        
        let diaValue = UInt8(data.substring(with: rangeDiastolic), radix: 16)
        //print("舒張壓")
        //print(diaValue)
        
        let heartValue = UInt8(data.substring(with: rangeHeart), radix: 16)
        //print("心跳")
        //print(heartValue)
        
        print("收縮壓：\(sysValue) 舒張壓：\(diaValue) 心跳：\(heartValue)")
        
        
        if let sysValueString = sysValue {
            print(sysValueString.description)
            logD(message: "收縮壓： \(sysValueString.description)")
        }
        
        if let diaValueString = diaValue {
            print(diaValueString.description)
            logD(message: "舒張壓： \(diaValueString.description)")
        }
        
        if let heaValueString = heartValue {
            print(heaValueString.description)
            logD(message: "脈搏： \(heaValueString.description)")
        }
        
        
    }


}


enum SendDataError: Error {
    case CharacteristicNotFound
    
}



