//
//  UserDefautls+Ext.swift
//  CoreMoose
//
//  Created by m x on 2023/12/23.
//
import Foundation



extension UserDefaults {
    var currentModelType: ModelType {
        get {
             let storedValue = string(forKey: "selectedModelType") ?? ModelType.LaMa.rawValue
            return ModelType(rawValue: storedValue) ?? .LaMa
        }
        set {
            set(newValue.rawValue, forKey: "selectedModelType")
        }
    }
    
    var hapticFeedbackOn: Bool {
        get {
            return bool(forKey: "hapticFeedbackOn")
        }
        set {
            set(newValue, forKey: "hapticFeedbackOn")
        }
    }
    
    var isPro: Bool {
        get {
            return bool(forKey: "isPro")
        }
    }
}
