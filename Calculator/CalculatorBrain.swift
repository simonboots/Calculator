//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Simon on 4/19/15.
//  Copyright (c) 2015 Simon Stiefel. All rights reserved.
//

import Foundation

class CalculatorBrain
{
    // Available operation types
    private enum Op: Printable {
        // Basic operand, e.g. 1.234
        case Operand(Double)
        
        // Constant operand, e.g. π
        case ConstantOperand(String, Double)
        
        // User-settable variable operand, e.g. M
        case VariableOperand(String)
        
        // Unary operation, e.g. cos()
        case UnaryOperation(String, Double -> Double)
        
        // Binary operation, e.g. +
        case BinaryOperation(String, (Double, Double) -> Double)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .ConstantOperand(let symbol, _):
                    return symbol
                case .VariableOperand(let symbol):
                    return symbol
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                }
            }
        }
    }
    
    weak var delegate: CalculatorBrainDelegate?
    
    // Operation and operand stack
    private var opStack = [Op]()
    
    // Array of known operations and operands
    private var knownOps = [String:Op]()
    
    // Binary operation precedence map
    private var binaryOperationPrecendences = [String:Int]()
    
    // Maps user-defined variables to their values
    var variableValues = [String:Double]()
    
    private var descriptionNumberFormatter: NSNumberFormatter
    
    init() {
        knownOps["×"] = Op.BinaryOperation("×", *)
        knownOps["÷"] = Op.BinaryOperation("÷") { $1 / $0 }
        knownOps["+"] = Op.BinaryOperation("+", +)
        knownOps["−"] = Op.BinaryOperation("−") { $1 - $0 }
        knownOps["√"] = Op.UnaryOperation("√", sqrt )
        knownOps["sin"] = Op.UnaryOperation("sin", sin)
        knownOps["cos"] = Op.UnaryOperation("cos", cos)
        knownOps["±"] = Op.UnaryOperation("±") { $0 * -1 }
        knownOps["π"] = Op.ConstantOperand("π", M_PI)
        
        // "×" and "÷" have higher precendence than "+" and "−"
        binaryOperationPrecendences["×"] = 1
        binaryOperationPrecendences["÷"] = 1
        binaryOperationPrecendences["+"] = 2
        binaryOperationPrecendences["−"] = 2
        
        descriptionNumberFormatter = NSNumberFormatter()
        descriptionNumberFormatter.numberStyle = .DecimalStyle
    }
    
    // Recursively evaluates the contents of ops
    // Returns optional result as Double and the remaining operations and operands that couldn't be evaluated
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op])
    {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
                
            case .ConstantOperand(_, let operand):
                return (operand, remainingOps)
                
            case .VariableOperand(let symbol):
                if let variableValue = variableValues[symbol] {
                    return (variableValue, remainingOps)
                }
                
            case .UnaryOperation(_, let operation):
                // Unary operation takes one parameter that we first need to evaluate based on the remaining ops
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    // Result is operation on operand
                    // Remaining ops are the remaining ops from the operand evaluation
                    return (operation(operand), operandEvaluation.remainingOps)
                }
                
            case .BinaryOperation(_, let operation):
                // Binary operation takes two parameters that we first need to evaluate based on the remaining ops
                let operand1Evaluation = evaluate(remainingOps)
                if let operand1 = operand1Evaluation.result {
                    let operand2Evaluation = evaluate(operand1Evaluation.remainingOps)
                    if let operand2 = operand2Evaluation.result {
                        // Result is operation on operand1 and operand2
                        // Remaining ops are the remaining ops from the second operand evaluation
                        return (operation(operand1, operand2), operand2Evaluation.remainingOps)
                    }
                }
            }
        }
        
        // ops is empty
        return (nil, ops)
    }
    
    // List of stack contents
    var history: [String] {
        get {
            return opStack.map { $0.description }
        }
    }
    
    // Returns a string that describes the current contents on the stack as an expression
    // If the contents of a stack cannot be converted to a single expression, multiple expressions are
    // concatenated with a comma.
    var description: String? {
        get {
            var remainingOps = opStack
            var descriptions = [String]()
            var foundDescription = false
            
            // Build expressions until all operations and operands in the stack are used
            do {
                let descriptionData = buildDescription(remainingOps)
                if let description = descriptionData.resultString {
                    descriptions.append(description)
                    foundDescription = true
                } else {
                    foundDescription = false
                }
            
                remainingOps = descriptionData.remainingOps
                
            } while (foundDescription)
            
            // Concatenate expressions with commas
            return (descriptions.reverse() as NSArray).componentsJoinedByString(",")
        }
    }
    
    // This method is similar to the evaluate() method above in that it recusively analyzes the stack
    // but instead of evaluating the operations and operands it builds a readable expression in the form of 'cos(1+(4*π))'
    private func buildDescription(ops: [Op]) -> (resultString: String?, remainingOps: [Op], precedence: Int?) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()

            switch op {
            case .Operand(let operand):
                return (descriptionNumberFormatter.stringFromNumber(operand), remainingOps, nil)
                
            case .ConstantOperand(let symbol, _):
                return (symbol, remainingOps, nil)
                
            case .VariableOperand(let symbol):
                return (symbol, remainingOps, nil)
                
            case .UnaryOperation(let symbol, _):
                // Unary operation takes one parameter that we first need to build based on the remaining ops
                let operandDescription = buildDescription(remainingOps)
                if let operand = operandDescription.resultString {
                    // The expression is 'symbol(operand)'
                    // Remaining ops are the remaining ops from the operand evaluation
                    return ("\(symbol)(\(operand))", operandDescription.remainingOps, nil)
                }
                
            case .BinaryOperation(let symbol, _):
                // Binary operation takes two parameters that we first need to build based on the remaining ops
                let op1Description = buildDescription(remainingOps)
                var op1String = (op1Description.resultString != nil) ? op1Description.resultString! : "?"
                    
                let op2Description2 = buildDescription(op1Description.remainingOps)
                var op2String = (op2Description2.resultString != nil) ? op2Description2.resultString! : "?"
                
                let selfPrecedence = binaryOperationPrecendences[symbol]!
                
                // Wrap op1String in parenthesis if its precedence is greater than our operation's precendence
                if let op1Precedence = op1Description.precedence {
                    if (op1Precedence > selfPrecedence) {
                        op1String = "(\(op1String))"
                    }
                }

                // Wrap op2String in parenthesis if its precedence is greater than our operation's precendence
                if let op2Precedence = op2Description2.precedence {
                    if (op2Precedence > selfPrecedence) {
                        op2String = "(\(op2String))"
                    }
                }
                
                // The expression is 'op2String operation op1String'
                // Remaining ops are the remaining ops from the second operand evaluation
                return ("\(op2String)\(symbol)\(op1String)", op2Description2.remainingOps, selfPrecedence)
            }
        }

        // Ops is empty
        return (nil, ops, nil)
    }
    
    // Reset the op stack
    func reset() {
        opStack.removeAll(keepCapacity: false)
        notifyStackChange()
    }
    
    // Reset user-defined variables
    func resetVariables() {
        variableValues.removeAll(keepCapacity: false)
    }
    
    // Evaluate opStack
    func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        println("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    
    // Push operand onto opStack and return evaluated result
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        notifyStackChange()
        return evaluate()
    }

    // Push variable operand (string) onto opStack and return evaluated result
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.VariableOperand(symbol))
        notifyStackChange()
        return evaluate()
    }
    
    // Perform operation and return evaluated result
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
            notifyStackChange()
        }
    
        return evaluate()
    }
    
    // Pop operation or operand from opStack
    func popOperationOrOperand() -> Double? {
        if opStack.count > 0 {
            opStack.removeLast()
            notifyStackChange()
        }
        
        return evaluate()
    }
    
    // Stack ends in an operation
    func didFinishOperation() -> Bool {
        if let lastOp = opStack.last {
            switch lastOp {
            case .UnaryOperation(_,_):
                fallthrough
            case .BinaryOperation(_,_):
                return true
            default:
                return false
            }
        }
        return false
    }
    
    // Notifies delegate about stack changes
    func notifyStackChange() {
        if let delegate = self.delegate {
            delegate.calculatorBrainDidUpdateStack(self)
        }
    }
}

protocol CalculatorBrainDelegate: class
{
    func calculatorBrainDidUpdateStack(brain: CalculatorBrain)
}