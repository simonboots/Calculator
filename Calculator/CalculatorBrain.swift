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
    private enum Op: Printable {
        case Operand(Double)
        case ConstantOperand(String, Double)
        case VariableOperand(String)
        case UnaryOperation(String, Double -> Double)
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
    
    private var opStack = [Op]()
    private var knownOps = [String:Op]()
    private var opsPrecedences = [String:Int]()
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
        
        opsPrecedences["×"] = 1
        opsPrecedences["÷"] = 1
        opsPrecedences["+"] = 2
        opsPrecedences["−"] = 2
        
        descriptionNumberFormatter = NSNumberFormatter()
        descriptionNumberFormatter.numberStyle = .DecimalStyle
    }
    
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
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
                
            case .BinaryOperation(_, let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
            }
        }
        
        return (nil, ops)
    }
    
    var history: [String] {
        get {
            return opStack.map { $0.description }
        }
    }
    
    var description: String? {
        get {
            var remainingOps = opStack
            var descriptions = [String]()
            var foundDescription = false
            
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
            
            return (descriptions.reverse() as NSArray).componentsJoinedByString(",")
        }
    }
    
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
                let operandDescription = buildDescription(remainingOps)
                if let operand = operandDescription.resultString {
                    return ("\(symbol)(\(operand))", operandDescription.remainingOps, nil)
                }
                
            case .BinaryOperation(let symbol, _):
                let op1Description = buildDescription(remainingOps)
                var op1String = (op1Description.resultString != nil) ? op1Description.resultString! : "?"
                    
                let op2Description2 = buildDescription(op1Description.remainingOps)
                var op2String = (op2Description2.resultString != nil) ? op2Description2.resultString! : "?"
                
                let selfPrecedence = opsPrecedences[symbol]!
                
                if let op1Precedence = op1Description.precedence {
                    if (op1Precedence > selfPrecedence) {
                        op1String = "(\(op1String))"
                    }
                }
                
                if let op2Precedence = op2Description2.precedence {
                    if (op2Precedence > selfPrecedence) {
                        op2String = "(\(op2String))"
                    }
                }
                
                return ("\(op2String)\(symbol)\(op1String)", op2Description2.remainingOps, opsPrecedences[symbol])
            }
        }

        return (nil, ops, nil)
    }
    
    var variableValues = [String:Double]()
    
    func reset() {
        opStack.removeAll(keepCapacity: false)
    }
    
    func resetVariables() {
        variableValues.removeAll(keepCapacity: false)
    }
    
    func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        println("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.VariableOperand(symbol))
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
    
        return evaluate()
    }
    
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
}