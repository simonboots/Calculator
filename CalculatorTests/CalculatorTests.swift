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
        
        XCTAssertEqual(result!, Double(7), "Unexpected result")
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
        
        brain.pushOperand("π")
        brain.performOperation("cos")
        
        let description = brain.description
        
        XCTAssertEqual(description!, "√(1+2),cos(π)", "Unexpected description")
    }
    
    func testMVariable() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(7)
        brain.pushOperand("M")
        brain.performOperation("+")
        var result = brain.performOperation("√")
        
        XCTAssertNil(result, "Unexpected result")
        
        brain.variableValues["M"] = 9
        
        result = brain.evaluate()
        
        XCTAssertNotNil(result, "Unexpected Result")
        XCTAssertEqual(result!, Double(4), "Unexpected Result")
        
        brain.pushOperand(14)
        result = brain.performOperation("+")
        
        XCTAssertNotNil(result, "Unexpected Result")
        XCTAssertEqual(result!, Double(18), "Unexpected Result")
    }
}
