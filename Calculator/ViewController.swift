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
    
    var userIsInTheMiddleOfTypingANumber = false
    var brain = CalculatorBrain()

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
            if let result = brain.performOperation(operation) {
                displayValue = result
            } else {
                displayValue = 0
            }
        }
        
        updateHistory()
    }
    
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        if let result = brain.pushOperand(displayValue) {
            displayValue = result
        } else {
            displayValue = 0            
        }
        
        updateHistory()
    }
    
    @IBAction func reset(sender: AnyObject) {
        brain.reset()
        displayValue = 0
        userIsInTheMiddleOfTypingANumber = false
        updateHistory()
    }
    
    var displayValue: Double {
        get {
            return NSNumberFormatter().numberFromString(display.text!)!.doubleValue
        }
        set {
            display.text = "\(newValue)"
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    private func updateHistory() {
        var historyStrings = brain.history
        var historyString = (historyStrings as NSArray).componentsJoinedByString("\n");
        historyLabel.text = historyString
    }
}
