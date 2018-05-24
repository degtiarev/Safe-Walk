//
//  ViewController.swift
//  Safe Walk
//
//  Created by Aleksei Degtiarev on 05/05/2018.
//  Copyright © 2018 Aleksei Degtiarev. All rights reserved.
//

import UIKit
import CoreMotion
import CoreML
import AudioToolbox.AudioServices

class ViewController: UIViewController {
    
    
    // For motion getting
    let motion = CMMotionManager()
    var motionUpdateTimer = Timer()
    let currentFrequency: Int = 60
    
    
    // Arrays for prediction
    var gyroXData = [Double]()
    var accXData = [Double]()
    
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startGettingData()
    }
    
    func startGettingData() {
        
        // Make sure the motion hardware is available.
        if self.motion.isAccelerometerAvailable, self.motion.isGyroAvailable, self.motion.isMagnetometerAvailable {
            
            self.motion.accelerometerUpdateInterval = 1.0 / Double (currentFrequency)
            self.motion.gyroUpdateInterval = 1.0 / Double (currentFrequency)
            self.motion.magnetometerUpdateInterval = 1.0 / Double (currentFrequency)
            
            self.motion.startAccelerometerUpdates()
            self.motion.startGyroUpdates()
            self.motion.startMagnetometerUpdates()
            
            // Configure a timer to fetch the data.
            self.motionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/Double (currentFrequency), repeats: true, block: { (timer1) in
                // Get the motion data.
                if let dataAcc = self.motion.accelerometerData, let dataGyro = self.motion.gyroData {
                    
                    let AccX = dataAcc.acceleration.x
                    let GyroX = dataGyro.rotationRate.x
                    
                    self.addData(gyroXValue: AccX, accYValue: GyroX)
                    let data = self.accXData + self.gyroXData
                    
                    if (data.count == 24) {
                        
                        guard let mlMultiArray = try? MLMultiArray(shape:[24], dataType:MLMultiArrayDataType.double) else {
                            fatalError("Unexpected runtime error. MLMultiArray")
                        }
                        
                        for (index, element) in data.enumerated() {
                            mlMultiArray[index] = NSNumber(value: element)
                        }
                        
                        
                        if let result = try? Classifier().makePrediction(mlMultiArray) {
                            print (result!)
                            
                            if result == MovementType.Safe {
                                self.statusLabel.text = "Safe"
                            } else if result == MovementType.RelativelySafe {
                                self.statusLabel.text = "Relatively Safe"
                            } else if result == MovementType.Unsafe {
                                self.statusLabel.text = "Unsafe"
                                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                            }
                            
                        }
                        
                        
                    }
                    
                }
            }
            )}
    }
    
    
    
    func stopGettingData() {
        motionUpdateTimer.invalidate()
        motionUpdateTimer = Timer()
        self.motion.stopGyroUpdates()
        self.motion.stopAccelerometerUpdates()
        self.motion.stopMagnetometerUpdates()
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
    
    func addData(gyroXValue: Double, accYValue: Double) {
        
        if gyroXData.count == 12 {
            // data.removeAll()
            // gyroXData.removeLast()
            gyroXData.removeFirst()
        }
        // gyroXData.insert(gyroXValue, at: 0)
        gyroXData.append(gyroXValue)
        
        
        if accXData.count == 12 {
            // data.removeAll()
            // accYData.removeLast()
            accXData.removeFirst()
        }
        // accYData.insert(accYValue, at: 0)
        accXData.append(accYValue)
    }
}




