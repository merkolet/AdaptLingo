//
//  ProfileUITests.swift
//  AdaptLingoUITests
//
//  Created by Sergey on 15.04.2026.
//

import XCTest

final class ProfileUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SKIP_ONBOARDING", "MOCK_AUTH"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Тест 1: Экран профиля содержит ключевые элементы

    func testProfileScreenContainsKeyElements() {
        navigateToProfile()

        XCTAssertTrue(app.staticTexts["Тема оформления"].waitForExistence(timeout: 5)
            || app.staticTexts["Профиль"].waitForExistence(timeout: 5))
    }

    // MARK: - Тест 2: Кнопка выхода присутствует

    func testLogoutButtonExists() {
        navigateToProfile()

        let logoutButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Выйти' OR label CONTAINS 'Выход'")).firstMatch
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
    }

    // MARK: - Тест 3: Переключение темы

    func testThemeSwitchExists() {
        navigateToProfile()

        let themeToggle = app.switches.firstMatch
        XCTAssertTrue(themeToggle.waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func navigateToProfile() {
        let profileTab = app.tabBars.buttons["Профиль"]
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
        }
    }
}
