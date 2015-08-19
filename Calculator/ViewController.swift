//
//  ViewController.swift
//  Calculator
//
//  Created by Simon on 4/19/15.
//  Copyright (c) 2015 Simon Stiefel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CalculatorBrainDelegate
{
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var historyLabel: UILabel!
    @IBOutlet weak var undoButton: UIButton!
    
    private var displayNumberFormatter = NSNumberFormatter()
    var userIsInTheMiddleOfTypingANumber = false
    {
        didSet {
            updateUndoButton()
        }
    }
    var userTypedNumber: String?
    var brain = CalculatorBrain()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        brain.delegate = self
        displayNumberFormatter.numberStyle = .DecimalStyle
    }
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleOfTypingANumber {
            if let typedNumber = userTypedNumber {
                // Handle decimal point (only allow one)
                if digit == "." && typedNumber.rangeOfString(".", options: nil, range: nil, locale: nil) != nil {
                    return
                }
                
                userTypedNumber = typedNumber + digit
            }
        } else {
            userTypedNumber = digit
            userIsInTheMiddleOfTypingANumber = true
        }
        
        displayStringValue = userTypedNumber
    }
    
    @IBAction func operate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        
        if let operation = sender.currentTitle {
            displayValue = brain.performOperation(operation)
        }
    }
    
    @IBAction func enter() {
        if let newOperandStringValue = userTypedNumber {
            if let newOperandValue = NSNumberFormatter().numberFromString(newOperandStringValue)?.doubleValue {
                displayValue = brain.pushOperand(newOperandValue)
            }
        }
        
        userIsInTheMiddleOfTypingANumber = false
        userTypedNumber = nil
    }
    
    @IBAction func backspace(sender: AnyObject) {
        
        if userIsInTheMiddleOfTypingANumber {
            if let typedNumber = userTypedNumber {
                if count(typedNumber) > 1 {
                    userTypedNumber = dropLast(typedNumber)
                } else {
                    userTypedNumber = "0"
                    userIsInTheMiddleOfTypingANumber = false
                }
                
                displayStringValue = userTypedNumber
            }
            
        } else {
            displayValue = brain.popOperationOrOperand()
        }
    }
    
    @IBAction func negate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            if let typedNumber = userTypedNumber {
                let isNegative = typedNumber.hasPrefix("-")
                if isNegative {
                    userTypedNumber = typedNumber.stringByReplacingOccurrencesOfString("-", withString: "", options: .LiteralSearch, range: nil)
                } else {
                    userTypedNumber = "-" + typedNumber
                }
                
                displayStringValue = userTypedNumber
            }
        } else {
            operate(sender)
        }
    }
    
    @IBAction func reset(sender: AnyObject) {
        brain.reset()
        brain.resetVariables()
        displayValue = 0
        userIsInTheMiddleOfTypingANumber = false
        userTypedNumber = nil
    }
    
    @IBAction func storeM() {
        if let currentValue = displayValue {
            brain.variableValues["M"] = currentValue
            displayValue = brain.evaluate()
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    @IBAction func pushM() {
        brain.pushOperand("M")
        displayValue = brain.evaluate()
    }
    
    var displayStringValue: String? {
        get {
            return display.text
        }
        
        set {
            var stringValue = "0"
            if let newStringValue = newValue {
                stringValue = newStringValue
            }
            
            display.text = stringValue
        }
    }
    
    var displayValue: Double? {
        get {
            var doubleValue : Double? = nil
            if let displayText = display.text {
                if let numberFromDisplayText = NSNumberFormatter().numberFromString(displayText) {
                    doubleValue = numberFromDisplayText.doubleValue
                }
            }

            return doubleValue
        }
        set {
            var displayValueString = "0"
            if let doubleValue = newValue {
                displayValueString = displayNumberFormatter.stringFromNumber(doubleValue)!
            }
            
            display.text = displayValueString
        }
    }
    
    private func updateHistory() {
        if var historyString = brain.description {
            if (brain.didFinishOperation()) {
                historyString = historyString + " ="
            }

            historyLabel.text = historyString
        } else {
            historyLabel.text = ""
        }
    }
    
    private func updateUndoButton() {
        if userIsInTheMiddleOfTypingANumber {
            // Show Backspace
            undoButton.setTitle("⬅︎", forState: .Normal)
        } else {
            // Show Undo
            undoButton.setTitle("↺", forState: .Normal)
        }
    }
    
    // MARK: CalculatorBrainDelegate Methods
    
    func calculatorBrainDidUpdateStack(brain: CalculatorBrain) {
        updateHistory()
    }
}
