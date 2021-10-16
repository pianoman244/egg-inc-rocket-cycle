//
//  RocketTank.swift
//  Egg Fueling App
//
//  Created by Nathan Chasse on 7/30/21.
//

import Foundation

protocol RocketTankDelegate {
    func updateRocketTankUI(rocketTank: RocketTank)
}

class RocketTank {
    var fuels: [Fuel] = []
    var fuelCapacities: [Int]
    var delegate: TankBrain?
    
    init(fuelNames: [EggCode], fuelCapacities: [Int]) {
        for name in fuelNames {
            self.fuels.append(Fuel(amount: 0, name: name))
        }
        self.fuelCapacities = fuelCapacities
    }
    
    func fillWith(amounts: [Int]) {
        for i in (0..<amounts.count) {
            if amounts[i] <= (fuelCapacities[i] - fuels[i].amount) {
                fuels[i].amount += amounts[i]
            } else {
                fuels[i].amount = fuelCapacities[i]
            }
        }
        
        delegate?.updateRocketTankUI(rocketTank: self)
    }
    
    func fillTank(id: Int) {
        fuels[id].amount = fuelCapacities[id]
    }
    
    func canLaunch() -> Bool {
        for i in (0..<fuels.count) {
            if fuels[i].amount != fuelCapacities[i] {
                return false
            }
        }
        
        return true
    }
    func launch() {
        for i in (0..<fuels.count) {
            fuels[i].amount = 0
        }
        
        delegate?.updateRocketTankUI(rocketTank: self)
    }
}
