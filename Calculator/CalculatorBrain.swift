//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Simon on 4/19/15.
//  Copyright (c) 2015 Simon Stiefel. All rights reserved.
//

import Foundation

enum ErrorCode: Int, CustomStringConvertible {
    case EmptyStack
    case DivisionByZero
    case SquareRootOfNegativeNumber
    case NotEnoughOperands
    case VariableNotSet
    
    var description: String {
        return "E\(self.rawValue)"
    }
}

// Evaluation result can either be a double or an error string
enum EvaluationResult: CustomStringConvertible {
    case Result(Double)
    case Error(ErrorCode)
    
    var description: String {
        switch self {
        case .Result(let result):
            return "\(result)"
        case .Error(let errorCode):
            return errorCode.description
        }
    }
}

class CalculatorBrain
{
    typealias VariableOperandEvaluator = String -> Double
    typealias VariableOperandVerifier = (String -> ErrorCode?)?
    typealias UnaryOperationEvaluator = Double -> Double
    typealias UnaryOperationVerifier = (Double -> ErrorCode?)?
    typealias BinaryOperationEvaluator = (Double, Double) -> Double
    typealias BinaryOperationVerifier = ((Double, Double) -> ErrorCode?)?
    
    
    // Available operation types
    private enum Op: CustomStringConvertible {
        // Basic operand, e.g. 1.234
        case Operand(Double)
        
        // Constant operand, e.g. π
        case ConstantOperand(String, Double)
        
        // User-settable variable operand, e.g. M
        case VariableOperand(String, VariableOperandEvaluator, VariableOperandVerifier)
        
        // Unary operation, e.g. cos()
        case UnaryOperation(String, UnaryOperationEvaluator, UnaryOperationVerifier)
        
        // Binary operation, e.g. +
        case BinaryOperation(String, BinaryOperationEvaluator, BinaryOperationVerifier)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .ConstantOperand(let symbol, _):
                    return symbol
                case .VariableOperand(let symbol, _, _):
                    return symbol
                case .UnaryOperation(let symbol, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _):
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
        knownOps["×"] = Op.BinaryOperation("×", *, nil)
        knownOps["÷"] = Op.BinaryOperation("÷", { $1 / $0 }, { (divisor: Double, _) -> ErrorCode? in divisor == 0 ? .DivisionByZero : nil })
        knownOps["+"] = Op.BinaryOperation("+", + , nil)
        knownOps["−"] = Op.BinaryOperation("−", { $1 - $0 }, nil)
        knownOps["√"] = Op.UnaryOperation("√", sqrt, { $0 < 0 ? .SquareRootOfNegativeNumber : nil })
        knownOps["sin"] = Op.UnaryOperation("sin", sin, nil)
        knownOps["cos"] = Op.UnaryOperation("cos", cos, nil)
        knownOps["±"] = Op.UnaryOperation("±", { $0 * -1 }, nil)
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
    private func evaluate(ops: [Op]) -> (result: EvaluationResult, remainingOps: [Op])
    {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
            case .Operand(let operand):
                return (.Result(operand), remainingOps)
                
            case .ConstantOperand(_, let operand):
                return (.Result(operand), remainingOps)
                
            case .VariableOperand(let symbol, let evaluator, let verifier):
                if let error = verifier?(symbol) {
                    return (.Error(error), remainingOps)
                }
                
                let variableValue = evaluator(symbol)
                return (.Result(variableValue), remainingOps)
                
            case .UnaryOperation(_, let operation, let verifier):
                // Unary operation takes one parameter that we first need to evaluate based on the remaining ops
                let operandEvaluation = evaluate(remainingOps)
                
                switch operandEvaluation.result {
                case .Error(let errorCode):
                    if errorCode == .EmptyStack {
                        // Convert .EmptyStack error to .NotEnoughOperandsError
                        return (.Error(.NotEnoughOperands), operandEvaluation.remainingOps)
                    } else {
                        return (operandEvaluation.result, operandEvaluation.remainingOps)
                    }
                    
                case .Result(let evaluatedOperand):
                    // Found valid operand
                    if let error = verifier?(evaluatedOperand) {
                        return (.Error(error), remainingOps)
                    }
                    
                    return (.Result(operation(evaluatedOperand)), operandEvaluation.remainingOps)
                }
                
            
            case .BinaryOperation(_, let operation, let verifier):
                // Binary operation takes two parameters that we first need to evaluate based on the remaining ops
                // Evaluate operand 1
                let operand1Evaluation = evaluate(remainingOps)
                
                // Check operand1 evaluation for errors
                switch operand1Evaluation.result {
                case .Error(let errorCode):
                    if errorCode == .EmptyStack {
                        // Convert .EmptyStack error to .NotEnoughOperandsError
                        return (.Error(.NotEnoughOperands), operand1Evaluation.remainingOps)
                    } else {
                        return (operand1Evaluation.result, operand1Evaluation.remainingOps)
                    }
                    
                case .Result(let evaluatedOperand1):
                    // Found valid operand 1
                    // Evaluate operand 2
                    let operand2Evaluation = evaluate(operand1Evaluation.remainingOps)
                    
                    // Check operand2 evaluation for errors
                    switch operand2Evaluation.result {
                    case .Error(let errorCode):
                        if errorCode == .EmptyStack {
                            // Convert .EmptyStack error to .NotEnoughOperandsError
                            return (.Error(.NotEnoughOperands), operand2Evaluation.remainingOps)
                        } else {
                            return (operand2Evaluation.result, operand2Evaluation.remainingOps)
                        }
                        
                    case .Result(let evaluatedOperand2):
                        // Verify operands
                        if let error = verifier?(evaluatedOperand1, evaluatedOperand2) {
                            return (.Error(error), remainingOps)
                        }
                        
                        return (.Result(operation(evaluatedOperand1, evaluatedOperand2)), operand2Evaluation.remainingOps)
                    }
                }
            }
        }
        
        // ops is empty
        return (.Error(.EmptyStack), ops)
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
            repeat {
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
            return (Array(descriptions.reverse()) as NSArray).componentsJoinedByString(",")
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
                
            case .VariableOperand(let symbol, _, _):
                return (symbol, remainingOps, nil)
                
            case .UnaryOperation(let symbol, _, _):
                // Unary operation takes one parameter that we first need to build based on the remaining ops
                let operandDescription = buildDescription(remainingOps)
                if let operand = operandDescription.resultString {
                    // The expression is 'symbol(operand)'
                    // Remaining ops are the remaining ops from the operand evaluation
                    return ("\(symbol)(\(operand))", operandDescription.remainingOps, nil)
                } else {
                    return ("\(symbol)(?)", operandDescription.remainingOps, nil)
                }
                
            case .BinaryOperation(let symbol, _, _):
                // Binary operation takes two parameters that we first need to build based on the remaining ops
                let op1Description = buildDescription(remainingOps)
                var op1String = (op1Description.resultString != nil) ? op1Description.resultString! : "?"
                    
                let op2Description = buildDescription(op1Description.remainingOps)
                var op2String = (op2Description.resultString != nil) ? op2Description.resultString! : "?"
                
                let selfPrecedence = binaryOperationPrecendences[symbol]!
                
                // Wrap op1String in parenthesis if its precedence is greater than our operation's precendence
                if let op1Precedence = op1Description.precedence {
                    if (op1Precedence > selfPrecedence) {
                        op1String = "(\(op1String))"
                    }
                }

                // Wrap op2String in parenthesis if its precedence is greater than our operation's precendence
                if let op2Precedence = op2Description.precedence {
                    if (op2Precedence > selfPrecedence) {
                        op2String = "(\(op2String))"
                    }
                }
                
                // The expression is 'op2String operation op1String'
                // Remaining ops are the remaining ops from the second operand evaluation
                return ("\(op2String)\(symbol)\(op1String)", op2Description.remainingOps, selfPrecedence)
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
    func evaluate() -> EvaluationResult {
        let (result, remainder) = evaluate(opStack)
        print("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    
    // Evaluate opStack and return result or error code
    func evaluateAndReportErrors() -> EvaluationResult {
        let (result, _) = evaluate(opStack)
        return result
    }
    
    // Push operand onto opStack and return evaluated result
    func pushOperand(operand: Double) -> EvaluationResult {
        opStack.append(Op.Operand(operand))
        notifyStackChange()
        return evaluate()
    }

    // Push variable operand (string) onto opStack and return evaluated result
    func pushOperand(symbol: String) -> EvaluationResult {
        let evaluator: VariableOperandEvaluator = { self.variableValues[$0] ?? 0 }
        let verifier: VariableOperandVerifier = {
            self.variableValues[$0] == nil ? .VariableNotSet : nil
        }
        opStack.append(Op.VariableOperand(symbol, evaluator, verifier))
        notifyStackChange()
        return evaluate()
    }
    
    // Perform operation and return evaluated result
    func performOperation(symbol: String) -> EvaluationResult {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
            notifyStackChange()
        }
    
        return evaluate()
    }
    
    // Pop operation or operand from opStack
    func popOperationOrOperand() -> EvaluationResult {
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
            case .UnaryOperation(_, _, _):
                fallthrough
            case .BinaryOperation(_, _, _):
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