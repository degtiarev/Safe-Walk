//
//  Classifier.swift
//  Safe Walk WatchKit Extension
//
//  Created by Aleksei Degtiarev on 06/05/2018.
//  Copyright © 2018 Aleksei Degtiarev. All rights reserved.
//

import Foundation
import CoreML

enum MovementType {
    case Safe
    case RelativelySafe
    case Unsafe
}

enum WatchClassifierError : Error {
    case RuntimeError(String)
}

class WatchClassifier: NSObject {
    let model = WatchUserActivityType()
    
    private func predict(_ input: MLMultiArray) -> MLMultiArray {
        guard let modelPrediction = try? model.prediction(input: input) else {
            fatalError("Unable to make prediction")
        }
        return modelPrediction.output
    }
    
    public func makePrediction(_ onInputData: MLMultiArray) throws -> MovementType? {
        let modelPrediction: MLMultiArray?
        
        modelPrediction = self.predict(onInputData)
        
        guard let predictedClassSafe =  (modelPrediction?[0])?.doubleValue,
            let predictedClassRelativelySafe = modelPrediction?[1].doubleValue,
            let predictedClassUnsafe = modelPrediction?[2].doubleValue
            else {
                throw WatchClassifierError.RuntimeError("Predicted values are invalid")
        }
        
        let largest = max(predictedClassSafe, predictedClassRelativelySafe, predictedClassUnsafe)
        
        print("Result: \(predictedClassSafe), \(predictedClassRelativelySafe). \(predictedClassUnsafe)")
        
        if largest == predictedClassSafe {
            return MovementType.Safe
        } else if largest == predictedClassRelativelySafe {
            return MovementType.RelativelySafe
        } else if largest == predictedClassUnsafe {
            return MovementType.Unsafe
        } else {
            return nil
        }
    }
}
