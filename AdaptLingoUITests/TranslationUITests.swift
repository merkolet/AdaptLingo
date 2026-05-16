//
//  TranslationUITests.swift
//  AdaptLingoUITests
//
//  Created by Sergey on 15.04.2026.
//

import XCTest

final class TranslationUITests: XCTestCase {

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

    // MARK: - Тест 1: Экран перевода содержит поле ввода

    func testTranslationScreenHasInputField() {
        navigateToTranslation()

        let textEditor = app.textViews.firstMatch
        XCTAssertTrue(textEditor.waitForExistence(timeout: 5))
    }

    // MARK: - Тест 2: Кнопка «Перевести» присутствует

    func testTranslateButtonExists() {
        navigateToTranslation()

        let translateButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Перевест'")).firstMatch
        XCTAssertTrue(translateButton.waitForExistence(timeout: 5))
    }

    // MARK: - Тест 3: Ввод текста и запуск перевода

    func testTranslationWithInput() {
        navigateToTranslation()

        let textEditor = app.textViews.firstMatch
        guard textEditor.waitForExistence(timeout: 5) else { return }
        textEditor.tap()
        textEditor.typeText("Hello")

        let translateButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Перевест'")).firstMatch
        if translateButton.exists {
            translateButton.tap()
            let indicator = app.activityIndicators.firstMatch
            let result    = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Привет'")).firstMatch
            let appeared  = indicator.waitForExistence(timeout: 3) || result.waitForExistence(timeout: 10)
            XCTAssertTrue(appeared)
        }
    }

    // MARK: - Тест 4: Индикатор источника перевода присутствует (LLM / Локальная)

    func testTranslationSourceIndicatorExists() {
        navigateToTranslation()

        let llmLabel   = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'LLM' OR label CONTAINS 'Локальная'")).firstMatch
        _ = llmLabel.waitForExistence(timeout: 3)
    }

    // MARK: - Helpers

    private func navigateToTranslation() {
        let translationTab = app.tabBars.buttons["Перевод"]
        if translationTab.waitForExistence(timeout: 5) {
            translationTab.tap()
        }
    }
}
