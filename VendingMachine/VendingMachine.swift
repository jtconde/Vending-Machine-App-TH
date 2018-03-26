//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by Kevin Bui on 5/20/16.
//  Edited by Kevin Bui on 9/18/16
//  Copyright © 2016 Treehouse. All rights reserved.
//

import Foundation
import UIKit

// Protocols

protocol VendingMachineType {
    
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: ItemType] { get set }
    var amountDeposited: Double { get set }
    
    init(inventory: [VendingSelection: ItemType])
    func vend(selection: VendingSelection, quantity: Double) throws
    func deposit(amount: Double)
    func itemForCurrentSelection(selection: VendingSelection) -> ItemType?
}

protocol ItemType {
    var price: Double { get }
    var quantity: Double { get set }
}

// Error Types

enum InventoryError: ErrorType {
    case InvalidResource
    case ConversionError
    case InvalidKey
}

enum VendingMachineError: ErrorType {
    case InvalidSelection
    case OutOfStock
    case InsufficientFunds(required: Double) // Associated value
}


// Helper Classes

class PlistConverter {
    class func dictionaryFromFile(resource: String, ofType type: String) throws -> [String : AnyObject] {
        
        guard let path = NSBundle.mainBundle().pathForResource(resource, ofType: type) else {
            throw InventoryError.InvalidResource
        }
        
        guard let dictionary = NSDictionary(contentsOfFile: path),
        let castDictionary = dictionary as? [String : AnyObject] else {
            throw InventoryError.ConversionError
        }
        
        return castDictionary
    }
}

class InventoryUnarchiver {
    class func vendingInventoryFromDictionary(dictionary: [String : AnyObject]) throws -> [VendingSelection : ItemType] {
        
        var inventory: [VendingSelection : ItemType] = [:] // [:] empty dictionary
        
        for (key, value) in dictionary {
            if let itemDict = value as? [String : Double],
            let price = itemDict["price"], let quantity = itemDict["quantity"] {
                
                let item = VendingItem(price: price, quantity: quantity)
                
                guard let key = VendingSelection(rawValue: key) else {
                    throw InventoryError.InvalidKey
                }
                
                inventory.updateValue(item, forKey: key)
            }
        }
        
        return inventory
    }
}



// Concrete Types

enum VendingSelection: String {
    case Soda
    case DietSoda
    case Chips
    case Cookie
    case Sandwich
    case Wrap
    case CandyBar
    case PopTart
    case Water
    case FruitJuice
    case SportsDrink
    case Gum
    
    // instance method return UIImage
    func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue) {
            return image
        } else {
            return UIImage(named: "Default")!
        }
    }
}

struct VendingItem: ItemType {
    let price: Double
    var quantity: Double
}

class VendingMachine: VendingMachineType {
    
    let selection: [VendingSelection] = [.Soda, .DietSoda, .Chips, .Cookie, .Sandwich, .Wrap, .CandyBar, .PopTart, .Water, .FruitJuice, .SportsDrink, .Gum]
    var inventory: [VendingSelection: ItemType]
    var amountDeposited: Double = 10.0
    
    required init(inventory : [VendingSelection: ItemType]){
        self.inventory = inventory
    }
    
    // Checks if valid item, and if enough in stock
    func vend(selection: VendingSelection, quantity: Double) throws {
        
        guard var item = inventory[selection] else {
            throw VendingMachineError.InvalidSelection
        }
        
        guard item.quantity > 0 else {
            throw VendingMachineError.OutOfStock
        }
        
        item.quantity -= quantity
        inventory.updateValue(item, forKey: selection)
        
        let totalPrice = item.price * quantity
        
        if amountDeposited >= totalPrice {
            amountDeposited -= totalPrice // Deduct amountDep from totalPrice
        } else {
            
            // If not enough money, calculate how much is needed and display by throwing error
            let amountRequired = totalPrice - amountDeposited
            throw VendingMachineError.InsufficientFunds(required: amountRequired)
        }
    }
    
    func itemForCurrentSelection(selection: VendingSelection) -> ItemType? {
        return inventory[selection]
    }
    
    // Checks if enough cash
    func deposit(amount: Double) {
        amountDeposited += amount
    }

}