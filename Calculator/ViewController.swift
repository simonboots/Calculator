//
//  ViewController.swift
//  Calculator
//
//  Created by Simon on 4/19/15.
//  Copyright (c) 2015 Simon Stiefel. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var historyLabel: UILabel!
    
    private var displayNumberFormatter = NSNumberFormatter()
    var userIsInTheMiddleOfTypingANumber = false
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
        displayNumberFormatter.numberStyle = .DecimalStyle
    }
    
    @IBAction func appendDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTypingANumber {
            // Handle decimal point (only allow one)
            if digit == "." && display.text!.rangeOfString(".", options: nil, range: nil, locale: nil) != nil {
                return
            }
            display.text = display.text! + digit
        } else {
            display.text = digit
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        
        if let operation = sender.currentTitle {
            displayValue = brain.performOperation(operation)
        }
        
        updateHistory()
    }
    
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        if let value = displayValue {
            displayValue = brain.pushOperand(value)
            updateHistory()
        }
    }
    
    @IBAction func backspace(sender: AnyObject) {
        var displayText = display.text!
        if count(displayText) > 1 {
            display.text = dropLast(displayText)
        } else {
            display.text = "0"
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    @IBAction func negate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            var displayText = display.text!
            let isNegative = displayText.hasPrefix("-")
            if isNegative {
                displayText = displayText.stringByReplacingOccurrencesOfString("-", withString: "", options: .LiteralSearch, range: nil)
            } else {
                displayText = "-" + displayText
            }
            
            display.text = displayText
        } else {
            operate(sender)
        }
    }
    
    @IBAction func reset(sender: AnyObject) {
        brain.reset()
        brain.resetVariables()
        displayValue = 0
        userIsInTheMiddleOfTypingANumber = false
        updateHistory()
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
        updateHistory()
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
            var displayValueString = "?"
            if let doubleValue = newValue {
                displayValueString = displayNumberFormatter.stringFromNumber(doubleValue)!
            }
            
            display.text = displayValueString
            userIsInTheMiddleOfTypingANumber = false
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
}
