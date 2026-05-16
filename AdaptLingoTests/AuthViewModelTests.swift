//
//  AuthViewModelTests.swift
//  AdaptLingoTests
//
//  Created by Sergey on 15.04.2026.
//

import XCTest
@testable import AdaptLingo

@MainActor
final class AuthViewModelTests: XCTestCase {

    var sut: AuthViewModel!

    override func setUp() {
        super.setUp()
        sut = AuthViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - isFormValid

    func testFormInvalidWhenEmailEmpty() {
        sut.email = ""
        sut.password = "password123"
        XCTAssertFalse(sut.isFormValid)
    }

    func testFormInvalidWhenPasswordEmpty() {
        sut.email = "test@example.com"
        sut.password = ""
        XCTAssertFalse(sut.isFormValid)
    }

    func testFormInvalidWhenEmailMalformed() {
        sut.email = "notanemail"
        sut.password = "password123"
        XCTAssertFalse(sut.isFormValid)
    }

    func testFormValidWithCorrectCredentials() {
        sut.email = "user@example.com"
        sut.password = "securePass1"
        XCTAssertTrue(sut.isFormValid)
    }

    // MARK: - clearLoginSuccess

    func testClearLoginSuccessResetsFlag() {
        sut.clearLoginSuccess()
        XCTAssertFalse(sut.loginSucceeded)
    }

    // MARK: - Initial state

    func testInitialStateIsIdle() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.loginSucceeded)
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
    }
}
