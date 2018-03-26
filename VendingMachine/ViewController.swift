//
//  ViewController.swift
//  VendingMachine
//
//  Created by Pasan Premaratne on 1/19/16.
//  Edited by Kevin Bui on 9/18/16
//  Copyright © 2016 Treehouse. All rights reserved.
//

import UIKit

private let reuseIdentifier = "vendingItem"
private let screenWidth = UIScreen.mainScreen().bounds.width

// UICollectionViewDataSource: What goes in collection view, UICollectionViewDelegate: Modify its behavior

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    let vendingMachine: VendingMachineType
    var currentSelection: VendingSelection?
    var quantity: Double = 1.0
    
    // required initializer for a view controller
    required init?(coder aDecoder: NSCoder) {
        do {
            let dictionary = try PlistConverter.dictionaryFromFile("VendingInventory", ofType: "plist")
            let inventory = try InventoryUnarchiver.vendingInventoryFromDictionary(dictionary)
            self.vendingMachine = VendingMachine(inventory: inventory)
        } catch let error {
           fatalError("\(error)") // Crashes the app completely
        }
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCollectionViewCells()
        // print(vendingMachine.inventory) // To see if everything works out
        setupViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupViews() {
        updateQuantityLabel()
        updateBalanceLabel()
    }
    
    // MARK: - UICollectionView 

    func setupCollectionViewCells() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        let padding: CGFloat = 10
        layout.itemSize = CGSize(width: (screenWidth / 3) - padding, height: (screenWidth / 3) - padding)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    // Tells collection view to return 12 cells
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vendingMachine.selection.count
    }
    
    //cellForItem takes cell from collectionView, looks at passing data,
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VendingItemCell
        
        let item = vendingMachine.selection[indexPath.row]
        cell.iconView.image = item.icon()
        
        return cell
    }
    
    // When button is tapped, knows item tapped with indexPath
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        updateCellBackgroundColor(indexPath, selected: true)
        
        // print(vendingMachine.selection[indexPath.row]) // Prints index of button tapped
        currentSelection = vendingMachine.selection[indexPath.row]
        updateTotalPriceLabel()
        reset()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        updateCellBackgroundColor(indexPath, selected: false)
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        updateCellBackgroundColor(indexPath, selected: true)
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        updateCellBackgroundColor(indexPath, selected: false)
    }
    
    func updateCellBackgroundColor(indexPath: NSIndexPath, selected: Bool) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
            cell.contentView.backgroundColor = selected ? UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0) : UIColor.clearColor()
        }
    }
    
    // MARK: - Helper Methods
    
    @IBAction func purchase() {
        // Quick way to unwrap an optional
        if let currentSelection = currentSelection {
            do {
                try vendingMachine.vend(currentSelection, quantity: quantity)
                // balanceLabel.text = "$\(vendingMachine.amountDeposited)"
                updateBalanceLabel()
                
            } catch VendingMachineError.OutOfStock {
                showAlert("Out of Stock")
            } catch VendingMachineError.InvalidSelection {
                showAlert("Invalid Selection")
            } catch VendingMachineError.InsufficientFunds(required: let amount) {
                showAlert("Insufficient Funds", message: "Additional $\(amount) needed to complete purchase")
            } catch let error {
                fatalError("\(error)")  // This intentionally crash app if none other error above occured
            }
        } else {
            // FIXME: Alert user to no selection
        }
    }
    
    @IBAction func updateQuantity(sender: UIStepper) {
        // (UIStepper -> Void)
        quantity = sender.value
        updateTotalPriceLabel()
        updateQuantityLabel()
    }
    
    func updateTotalPriceLabel() {
        if let currentSelection = currentSelection, let item = vendingMachine.itemForCurrentSelection(currentSelection) {
            totalLabel.text = "$\(item.price * quantity)"
        }
    }
    
    func updateQuantityLabel() {
        quantityLabel.text = "\(quantity)"
    }
    
    func updateBalanceLabel() {
        balanceLabel.text = "$\(vendingMachine.amountDeposited)"
    }
    
    func reset() {
        quantity = 1
        updateTotalPriceLabel()
        updateQuantityLabel()
    }
    
    func showAlert(title: String, message: String? = nil, style: UIAlertControllerStyle = .Alert) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style) //Alert
        
        let okayAction = UIAlertAction(title: "Ok", style: .Default, handler: dismissAlert) // OK button on alert
        
        alertController.addAction(okayAction) // implements the two constant
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func dismissAlert(sender: UIAlertAction) {
        reset() // When button  is alerted, reset vending machine
    }
    @IBAction func depositFunds() {
        
        vendingMachine.deposit(5.00)
        updateBalanceLabel()
    }
}

