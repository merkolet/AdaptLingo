//
//  AuthUITests.swift
//  AdaptLingoUITests
//
//  Created by Sergey on 15.04.2026.
//

import XCTest

final class AuthUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SKIP_ONBOARDING"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Тест 1: Экран аутентификации отображается

    func testAuthScreenIsDisplayed() {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
    }

    // MARK: - Тест 2: Кнопка «Войти» недоступна с пустыми полями

    func testLoginButtonDisabledWithEmptyFields() {
        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.waitForExistence(timeout: 5))
        XCTAssertFalse(loginButton.isEnabled)
    }

    // MARK: - Тест 3: Кнопка «Войти» активируется при заполнении полей

    func testLoginButtonEnabledWithValidInput() {
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")

        let passwordField = app.secureTextFields["Пароль"]
        passwordField.tap()
        passwordField.typeText("password123")

        let loginButton = app.buttons["Войти"]
        XCTAssertTrue(loginButton.isEnabled)
    }

    // MARK: - Тест 4: Переход на экран регистрации

    func testTapRegisterButtonShowsSignUp() {
        let registerButton = app.buttons["Зарегистрироваться"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: 5))
        registerButton.tap()

        let nameField = app.textFields["Имя пользователя"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
    }

    // MARK: - Тест 5: Переход на экран сброса пароля

    func testForgotPasswordButtonShowsReset() {
        let forgotButton = app.buttons["Забыли пароль?"]
        XCTAssertTrue(forgotButton.waitForExistence(timeout: 5))
        forgotButton.tap()

        let emailResetField = app.textFields["Email"]
        XCTAssertTrue(emailResetField.waitForExistence(timeout: 5))
    }

    // MARK: - Тест 6: Ошибка при неверных учётных данных

    func testLoginWithInvalidCredentialsShowsError() {
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("wrong@example.com")

        let passwordField = app.secureTextFields["Пароль"]
        passwordField.tap()
        passwordField.typeText("wrongpass")

        app.buttons["Войти"].tap()

        // Ожидаем появления текста ошибки
        let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Invalid'")).firstMatch
        XCTAssertTrue(errorText.waitForExistence(timeout: 10))
    }
}
