//
//  InterfaceController.swift
//  Safe Walk WatchKit Extension
//
//  Created by Aleksei Degtiarev on 05/05/2018.
//  Copyright © 2018 Aleksei Degtiarev. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import HealthKit
import CoreML


class InterfaceController: WKInterfaceController {
    
    // Statuses
    enum Status {
        case waiting
        case working
    }
    
    var status: Status = Status.waiting {
        willSet(newStatus) {
            
            switch(newStatus) {
            case .waiting:
                waiting()
                break
                
            case .working:
                working()
                break
            }
        }
        didSet {
            
        }
    }
    
    // Outlets
    @IBOutlet var timer: WKInterfaceTimer!
    @IBOutlet var statusLabel: WKInterfaceLabel!
    
    
    // For motion getting
    let currentFrequency: Int = 60
    let motion = CMMotionManager()
    let queue = OperationQueue()
    
    
    // For background work
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    
    
    // Arrays for prediction
    var gyroXData = [Double]()
    var accYData = [Double]()
    
    
    // MARK - WKInterfaceController events
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Serial queue for sample handling and calculations.
        queue.maxConcurrentOperationCount = 1
        queue.name = "MotionManagerQueue"
        
        status = .waiting
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    
    // MARK - Control work of getting motion Data
    
    func startSafeMode() {
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .walking
        workoutConfiguration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        // Start the workout session and device motion updates.
        healthStore.start(session!)
        
        // Check motion availability
        if !motion.isDeviceMotionAvailable {
            print("Device Motion is not available.")
            return
        }
        
        motion.deviceMotionUpdateInterval = 1.0 / Double(currentFrequency)
        motion.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            
            if deviceMotion != nil {
                
                //                let currenTime = self.returnCurrentTime()
                let GyroX = deviceMotion!.rotationRate.x
                //                let GyroY = deviceMotion!.rotationRate.y
                //                let GyroZ = deviceMotion!.rotationRate.z
                
                //                let AccX = deviceMotion!.gravity.x + deviceMotion!.userAcceleration.x;
                let AccY = deviceMotion!.gravity.y + deviceMotion!.userAcceleration.y;
                //                let AccZ = deviceMotion!.gravity.z + deviceMotion!.userAcceleration.z;
                //                print ( "Time: \(currenTime) GyroX:\(GyroX), AccY:\(AccY)")
                //                print ( "Gyro: \(currenTime) \(GyroX), \(GyroY), \(GyroZ)")
                //                print ( "Acc : \(currenTime) \(AccX), \(AccY), \(AccZ)")
                
                //                print ("GyroX: \(GyroX)")
                //                print("Array Gyro: \(self.gyroXData)")
                //                print ("AccY: \(AccY)")
                //                print("Array Acc: \(self.gyroXData)")
                
                self.addData(gyroXValue: GyroX, accYValue: AccY)
                let data = self.gyroXData + self.accYData
                if data.count == 24 {
                    
                    guard let mlMultiArray = try? MLMultiArray(shape:[24], dataType:MLMultiArrayDataType.double) else {
                        fatalError("Unexpected runtime error. MLMultiArray")
                    }
                    
                    for (index, element) in data.enumerated() {
                        mlMultiArray[index] = NSNumber(value: element)
                    }
                    
                    
                    if let result = try? WatchClassifier().makePrediction(mlMultiArray) {
                        
                        print(result!)
                        
                        if result == MovementType.Safe {
                            WKInterfaceDevice.current().play(.click)
                        }
                        
                        
                    }
                    
                    
                }
                
            }
        }
    }
    
    func stopSafeMode() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }
        
        // Stop the device motion updates and workout session.
        motion.stopDeviceMotionUpdates()
        healthStore.end(session!)
        print("Ended health session")
        
        
        // Clear the workout session.
        session = nil
    }
    
    func returnCurrentTime() -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanoseconds = calendar.component(.nanosecond, from: date)
        
        let currentTime = "\(hour):\(minutes):\(seconds):\(nanoseconds)"
        
        return currentTime
    }
    
    
    
    // MARK - Action controlls
    
    @IBAction func startButtonPressed() {
        // check status
        if status == Status.working { return }
        
        startSafeMode()
        status = .working
    }
    
    @IBAction func stopButtonPressed() {
        // check status
        if status == Status.waiting { return }
        
        timer.stop()
        stopSafeMode()
        status = .waiting
    }
    
    
    
    // MARK - Update changing state
    
    func waiting() {
        statusLabel.setText("Off")
        timer.setDate(Date(timeIntervalSinceNow: 0.0))
        
    }
    
    
    func working() {
        statusLabel.setText("On")
        timer.setDate(Date(timeIntervalSinceNow: 0.0))
        timer.start()
    }
    
    
    func addData(gyroXValue: Double, accYValue: Double) {
        
        if gyroXData.count == 12 {
            // data.removeAll()
            // gyroXData.removeLast()
            gyroXData.removeFirst()
        }
        // gyroXData.insert(gyroXValue, at: 0)
        gyroXData.append(gyroXValue)
        
        
        if accYData.count == 12 {
            // data.removeAll()
            // accYData.removeLast()
            accYData.removeFirst()
        }
        // accYData.insert(accYValue, at: 0)
        accYData.append(accYValue)
    }
}
