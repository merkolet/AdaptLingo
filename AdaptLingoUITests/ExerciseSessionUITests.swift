//
//  ExerciseSessionUITests.swift
//  AdaptLingoUITests
//
//  Created by Sergey on 15.04.2026.
//

import XCTest

final class ExerciseSessionUITests: XCTestCase {

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

    // MARK: - Тест 1: Экран выбора упражнений содержит все типы

    func testLessonsScreenShowsExerciseTypes() {
        navigateToLessons()

        XCTAssertTrue(app.staticTexts["Грамматика"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Пропуски"].exists || app.staticTexts["Заполни пропуск"].exists)
        XCTAssertTrue(app.staticTexts["Перевод"].exists)
    }

    // MARK: - Тест 2: Индикатор загрузки появляется при старте сессии

    func testLoadingIndicatorAppearsOnSessionStart() {
        navigateToLessons()

        let grammarCell = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Грамматика'")).firstMatch
        if grammarCell.waitForExistence(timeout: 5) {
            grammarCell.tap()
            let progressView = app.activityIndicators.firstMatch
            XCTAssertTrue(progressView.waitForExistence(timeout: 3))
        }
    }

    // MARK: - Тест 3: Прогресс-бар отображается в сессии

    func testProgressHeaderIsVisible() {
        navigateToLessons()

        let grammarCell = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Грамматика'")).firstMatch
        guard grammarCell.waitForExistence(timeout: 5) else { return }
        grammarCell.tap()

        // Ждём загрузки упражнений
        let progressText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/'")).firstMatch
        XCTAssertTrue(progressText.waitForExistence(timeout: 15))
    }

    // MARK: - Тест 4: Выбор ответа разблокирует кнопку «Далее»

    func testSelectingAnswerShowsNextButton() {
        navigateToLessons()

        let grammarCell = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Грамматика'")).firstMatch
        guard grammarCell.waitForExistence(timeout: 5) else { return }
        grammarCell.tap()

        // Ждём загрузки и выбираем первый вариант ответа
        let firstOption = app.buttons.element(boundBy: 0)
        guard firstOption.waitForExistence(timeout: 15) else { return }
        firstOption.tap()

        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Далее' OR label CONTAINS 'Завершить'")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func navigateToLessons() {
        let lessonsTab = app.tabBars.buttons["Уроки"]
        if lessonsTab.waitForExistence(timeout: 5) {
            lessonsTab.tap()
        }
    }
}
