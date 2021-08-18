//
//  XCTestCase+MemoryLeakTracking.swift
//  
//
//  Created by Boyce Estes on 8/18/21.
//

import XCTest


extension XCTestCase {

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {

        // Teardown block allows us to do something at the end of a test. We place it in
        // this test case instead of in a tearDown method because we only want to test this
        // when the instance is in memory.
        addTeardownBlock { [weak instance] in
            // We make sut weak here because we do not want to keep it in memory
            // if it is not already in memory. If we didn't make it weak, functions that
            // do not have retain cycles from the load method (like
            // test_init_doesNotRequestDataFromURL) will fail this test.
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
