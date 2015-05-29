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
}
