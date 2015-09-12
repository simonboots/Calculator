//
//  CalculatorTests.swift
//  CalculatorTests
//
//  Created by Simon on 4/19/15.
//  Copyright (c) 2015 Simon Stiefel. All rights reserved.
//

import UIKit
import XCTest

class CalculatorTests: XCTestCase {
    
    func testVariableOperand() {
        let brain = CalculatorBrain()
        brain.variableValues["x"] = 4
        
        brain.pushOperand(3)
        brain.pushOperand("x")
        let result = brain.performOperation("+")
        
        switch result {
        case .Result(let resultValue):
            XCTAssertEqual(resultValue, Double(7), "Unexpected result")
        case .Error(let errorCode):
            XCTAssertTrue(false, "Unexpected error code: \(errorCode)")
        }

    }
    
    func testUnaryOperandDescription() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(3)
        brain.performOperation("cos")
        
        let description = brain.description
        XCTAssertEqual(description!, "cos(3)", "Unexpected description")
    }
    
    func testMultipleOperations() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(1)
        brain.pushOperand(2)
        brain.performOperation("+")
        
        brain.pushOperand(3)
        brain.pushOperand(4)
        brain.performOperation("+")

        brain.performOperation("÷")
        brain.performOperation("cos")
        
        let description = brain.description
        XCTAssertEqual(description!, "cos((1+2)÷(3+4))", "Unexpected description")
    }
    
    func testMissingOperand() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(1)
        brain.performOperation("+")
        
        let description = brain.description
        XCTAssertEqual(description!, "?+1", "Unexpected description")
    }
    
    func testMultipleCompleteExpressions() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(1)
        brain.pushOperand(2)
        brain.performOperation("+")
        
        brain.performOperation("√")
        
        brain.performOperation("π")
        brain.performOperation("cos")
        
        let description = brain.description
        
        XCTAssertEqual(description!, "√(1+2),cos(π)", "Unexpected description")
    }
    
    func testMVariable() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(7)
        brain.pushOperand("M")
        brain.performOperation("+")
        var evaluationResult = brain.performOperation("√")
        
        switch evaluationResult {
        case .Error(let errorCode):
            XCTAssertEqual(errorCode, ErrorCode.VariableNotSet, "Unexpected error code \(errorCode)")
        case .Result(let result):
            XCTAssertTrue(false, "Unexpeced result: \(result)")
        }
        
        brain.variableValues["M"] = 9
        
        evaluationResult = brain.evaluate()
        
        switch evaluationResult {
        case .Error(_):
            XCTAssertTrue(false, "Unexpected Result")
        case .Result(let result):
            XCTAssertEqual(result, Double(4), "Unexpected Result")
        }
        
        brain.pushOperand(14)
        evaluationResult = brain.performOperation("+")
        
        switch evaluationResult {
        case .Error(_):
            XCTAssertTrue(false, "Unexpected Result")
        case .Result(let result):
            XCTAssertEqual(result, Double(18), "Unexpected Result")
        }
    }
    
    func testEmptyStackError() {
        let brain = CalculatorBrain()
        
        let evaluationResult = brain.evaluate()
        
        switch evaluationResult {
        case .Error(let errorCode):
            XCTAssertEqual(errorCode, ErrorCode.EmptyStack, "Unexpected error code")
        case .Result(_):
            XCTAssertTrue(false, "Unexpected Result")
        }
    }
    
    func testDivisionByZeroError() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(7)
        brain.pushOperand(0)
        let evaluationResult = brain.performOperation("÷")
        
        switch evaluationResult {
        case .Error(let errorCode):
            XCTAssertEqual(errorCode, ErrorCode.DivisionByZero, "Unexpected error code")
        case .Result(_):
            XCTAssertTrue(false, "Unexpected Result")
        }
    }
    
    func testSquareRootOfNegativeNumberError() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(2);
        brain.performOperation("±")
        let evaluationResult = brain.performOperation("√")
        
        switch evaluationResult {
        case .Error(let errorCode):
            XCTAssertEqual(errorCode, ErrorCode.SquareRootOfNegativeNumber, "Unexpected error code")
        case .Result(_):
            XCTAssertTrue(false, "Unexpected Result")
        }
    }
    
    func testNotEnoughOperandsError() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(2)
        let evaluationResult = brain.performOperation("÷")
        
        switch evaluationResult {
        case .Error(let errorCode):
            XCTAssertEqual(errorCode, ErrorCode.NotEnoughOperands, "Unexpected error code")
        case .Result(_):
            XCTAssertTrue(false, "Unexpected Result")
        }
    }
    
    func testVariableNotSetError() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(2)
        brain.pushOperand("X")
        let evaluationResult = brain.performOperation("+")
        
        switch evaluationResult {
        case .Error(let errorCode):
            XCTAssertEqual(errorCode, ErrorCode.VariableNotSet, "Unexpected error code")
        case .Result(_):
            XCTAssertTrue(false, "Unexpected Result")
        }
    }
    
    func testMultipleErrorOrder() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(2)
        brain.pushOperand("X")
        // Trigger .VariableNotSet error
        brain.performOperation("+")
        
        // Trigger .NotEnoughOperands error
        var evaluationResult = brain.performOperation("÷")
        
        // Expecting .VariableNotSet error
        switch evaluationResult {
        case .Error(let errorCode):
            XCTAssertEqual(errorCode, ErrorCode.VariableNotSet, "Unexpected error code")
        case .Result(_):
            XCTAssertTrue(false, "Unexpected Result")
        }

        // Fix .VariableNotSet error
        brain.variableValues["X"] = 4
        
        evaluationResult = brain.evaluate()
        
        // Expecting .NotEnoughOperands error
        switch evaluationResult {
        case .Error(let errorCode):
            XCTAssertEqual(errorCode, ErrorCode.NotEnoughOperands, "Unexpected error code")
        case .Result(_):
            XCTAssertTrue(false, "Unexpected Result")
        }
    }
}
