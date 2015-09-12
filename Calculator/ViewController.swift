//
//  ViewController.swift
//  Calculator
//
//  Created by Simon on 4/19/15.
//  Copyright (c) 2015 Simon Stiefel. All rights reserved.
//

import UIKit

// This is the main view controller representing the main UI.

class ViewController: UIViewController, CalculatorBrainDelegate
{
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var expressionLabel: UILabel!
    @IBOutlet weak var undoButton: UIButton!
    
    private var displayNumberFormatter = NSNumberFormatter()
    
    // Tracks whether the user is in the middle of typing a number
    private var userIsInTheMiddleOfTypingANumber = false
    {
        didSet {
            updateUndoButton()
        }
    }
    
    // Temporary variable that holds the user-entered number (while userIsInTheMiddleOfTypingANumber is true)
    // Once the number has been fully entered, it is pushed onto the stack
    private var userTypedNumber: String?
    
    // Model that does all the computation
    private var brain = CalculatorBrain()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
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
                // Allow only one decimal point
                if digit == "." && typedNumber.rangeOfString(".", options: [], range: nil, locale: nil) != nil {
                    return
                }
                
                // Append user typed number
                userTypedNumber = typedNumber + digit
            }
        } else {
            // User started entering a number
            userTypedNumber = digit
            userIsInTheMiddleOfTypingANumber = true
        }
        
        // Update display
        displayStringValue = userTypedNumber
    }
    
    @IBAction func operate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            // Commit user-entered before performing operation
            enter()
        }
        
        if let operation = sender.currentTitle {
            let evaluationResult = brain.performOperation(operation)
            showEvaluationResult(evaluationResult)
        }
    }
    
    @IBAction func enter() {
        if let newOperandStringValue = userTypedNumber {
            // Convert user-entered number (string) to double and push onto stack
            if let newOperandValue = NSNumberFormatter().numberFromString(newOperandStringValue)?.doubleValue {
                let evaluationResult = brain.pushOperand(newOperandValue)
                showEvaluationResult(evaluationResult)
            }
        }
        
        // Reset user-entering state
        userIsInTheMiddleOfTypingANumber = false
        userTypedNumber = nil
    }
    
    // This method acts as both "backspace" and "undo" action depending on whether the user is in the middle of entering a number
    @IBAction func backspace(sender: AnyObject) {
        if userIsInTheMiddleOfTypingANumber {
            // Backspace
            if let typedNumber = userTypedNumber {
                if typedNumber.characters.count > 1 {
                    // Remove least significant digit from user-entered number
                    userTypedNumber = String(typedNumber.characters.dropLast())
                } else {
                    // Reset user-entered number to 0 and reset state
                    userTypedNumber = "0"
                    userIsInTheMiddleOfTypingANumber = false
                }
                
                // Update display
                displayStringValue = userTypedNumber
            }
            
        } else {
            // Undo
            let evaluationResult = brain.popOperationOrOperand()
            showEvaluationResult(evaluationResult)
        }
    }
    
    @IBAction func negate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            // If the user is in the middle of entering a number we can just negate that number
            if let typedNumber = userTypedNumber {
                let isNegative = typedNumber.hasPrefix("-")
                if isNegative {
                    // Remove "-"
                    userTypedNumber = typedNumber.stringByReplacingOccurrencesOfString("-", withString: "", options: .LiteralSearch, range: nil)
                } else {
                    // Prepend "-"
                    userTypedNumber = "-" + typedNumber
                }
                
                // Update display
                displayStringValue = userTypedNumber
            }
        } else {
            // If the user is NOT entering a number we push the negate operation onto the stack
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
            // Set value for "M"
            brain.variableValues["M"] = currentValue
            
            // Re-evaluate stack and update display
            let evaluationResult = brain.evaluate()
            showEvaluationResult(evaluationResult)
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    @IBAction func pushM() {
        // Push variable "M"
        brain.pushOperand("M")
        
        // Re-evaulate stack and update display
        let evaluationResult = brain.evaluate()
        showEvaluationResult(evaluationResult)
    }
    
    private func showEvaluationResult(evaluationResult: EvaluationResult){
        switch evaluationResult {
        case .Result(let result):
            displayValue = result
        case .Error(let errorCode):
            let errorMessage = errorMessageForErrorCode(errorCode)
            displayStringValue = errorMessage
        }
    }
    
    private func errorMessageForErrorCode(errorCode: ErrorCode) -> String {
        let errorMessage: String
        switch errorCode {
        case .EmptyStack:
            errorMessage = NSLocalizedString("EmptyStack", comment: "Empty stack")
        case .DivisionByZero:
            errorMessage = NSLocalizedString("DivisionByZero", comment: "Division by Zero")
        case .SquareRootOfNegativeNumber:
            errorMessage = NSLocalizedString("SquareRootOfNegNumber", comment: "Square Root of Neg Number")
        case .NotEnoughOperands:
            errorMessage = NSLocalizedString("NotEnoughOperands", comment: "Not Enough Operands")
        case .VariableNotSet:
            errorMessage = NSLocalizedString("VariableNotSet", comment: "Variable Not Set")
        }
        
        return errorMessage
    }
    
    // String value for display
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
    
    // Double value for display
    var displayValue: Double? {
        get {
            var doubleValue : Double? = nil
            if let displayText = display.text {
                // Convert string to number
                if let numberFromDisplayText = NSNumberFormatter().numberFromString(displayText) {
                    doubleValue = numberFromDisplayText.doubleValue
                }
            }

            return doubleValue
        }
        set {
            var displayValueString = "0"
            if let doubleValue = newValue {
                // Convert double to formatted string
                displayValueString = displayNumberFormatter.stringFromNumber(doubleValue)!
            }
            
            // Update display
            display.text = displayValueString
        }
    }
    
    // Update the expression label
    private func updateExpressionLabel() {
        if var historyString = brain.description {
            if (brain.didFinishOperation()) {
                // If there are no "left-overs" on the stack, append "="
                historyString = historyString + " ="
            }

            expressionLabel.text = historyString
        } else {
            // Reset label
            expressionLabel.text = ""
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
        updateExpressionLabel()
    }
}
