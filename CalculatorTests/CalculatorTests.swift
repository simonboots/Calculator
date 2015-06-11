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
        XCTAssertEqual(description!, "cos(3.0)", "Unexpected description")
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
        XCTAssertEqual(description!, "cos((1.0+2.0)÷(3.0+4.0))", "Unexpected description")
    }
    
    func testMissingOperand() {
        let brain = CalculatorBrain()
        
        brain.pushOperand(1.0)
        brain.performOperation("+")
        
        let description = brain.description
        XCTAssertEqual(description!, "?+1.0", "Unexpected description")
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
        
        XCTAssertEqual(description!, "√(1.0+2.0),cos(π)", "Unexpected description")
        
    }
}
