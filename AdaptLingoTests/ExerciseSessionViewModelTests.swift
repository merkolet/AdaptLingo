//
//  ExerciseSessionViewModelTests.swift
//  AdaptLingoTests
//
//  Created by Sergey on 15.04.2026.
//

import XCTest
@testable import AdaptLingo

@MainActor
final class ExerciseSessionViewModelTests: XCTestCase {

    var sut: ExerciseSessionViewModel!

    override func setUp() {
        super.setUp()
        sut = ExerciseSessionViewModel(exerciseType: .multipleChoice)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Начальное состояние

    func testInitialState() {
        XCTAssertTrue(sut.exercises.isEmpty)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertNil(sut.selectedAnswer)
        XCTAssertFalse(sut.isAnswerRevealed)
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.loadError)
        XCTAssertFalse(sut.sessionComplete)
        XCTAssertEqual(sut.score, 0)
    }

    // MARK: - Прогресс

    func testProgressIsZeroWhenEmpty() {
        XCTAssertEqual(sut.progress, 0.0)
    }

    func testProgressCalculation() {
        sut.exercises = makeDummyExercises(count: 4)
        sut.currentIndex = 2
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.001)
    }

    // MARK: - xpEarned

    func testXPEarnedIsScoreTimesTen() {
        sut.exercises = makeDummyExercises(count: 5)
        sut.exercises[0].isCorrect = true
        sut.exercises[1].isCorrect = true
        sut.exercises[2].isCorrect = true
      
        sut.score = 3
        XCTAssertEqual(sut.xpEarned, 30)
    }

    // MARK: - wrongExercises

    func testWrongExercisesFiltersIncorrect() {
        sut.exercises = makeDummyExercises(count: 3)
        sut.exercises[0].isCorrect = false
        sut.exercises[1].isCorrect = true
        sut.exercises[2].isCorrect = false
        XCTAssertEqual(sut.wrongExercises.count, 2)
    }

    // MARK: - isLastQuestion

    func testIsLastQuestion() {
        sut.exercises = makeDummyExercises(count: 3)
        sut.currentIndex = 2
        XCTAssertTrue(sut.isLastQuestion)
    }

    func testIsNotLastQuestion() {
        sut.exercises = makeDummyExercises(count: 3)
        sut.currentIndex = 1
        XCTAssertFalse(sut.isLastQuestion)
    }

    // MARK: - selectAnswer

    func testSelectCorrectAnswerIncrementsScore() {
        sut.exercises = makeDummyExercises(count: 1)
        sut.selectAnswer("am")
        XCTAssertEqual(sut.score, 1)
        XCTAssertTrue(sut.isAnswerRevealed)
    }

    func testSelectWrongAnswerDoesNotIncrementScore() {
        sut.exercises = makeDummyExercises(count: 1)
        sut.selectAnswer("is")
        XCTAssertEqual(sut.score, 0)
        XCTAssertTrue(sut.isAnswerRevealed)
    }

    func testSelectAnswerAfterRevealedIsIgnored() {
        sut.exercises = makeDummyExercises(count: 1)
        sut.selectAnswer("am")
        let scoreAfterFirst = sut.score
        sut.selectAnswer("be")
        XCTAssertEqual(sut.score, scoreAfterFirst)
    }

    // MARK: - optionState

    func testOptionStateNormalBeforeAnswer() {
        sut.exercises = makeDummyExercises(count: 1)
        XCTAssertEqual(sut.optionState(for: "am"), .normal)
    }

    func testOptionStateCorrectAfterAnswer() {
        sut.exercises = makeDummyExercises(count: 1)
        sut.selectAnswer("is")
        XCTAssertEqual(sut.optionState(for: "am"), .correct)
        XCTAssertEqual(sut.optionState(for: "is"), .wrong)
    }

    // MARK: - retry

    func testRetryResetsState() {
        sut.exercises = makeDummyExercises(count: 2)
        sut.score = 1
        sut.currentIndex = 1
        sut.sessionComplete = true
        sut.retry()
        XCTAssertEqual(sut.score, 0)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertFalse(sut.sessionComplete)
    }

    // MARK: - Helpers

    private func makeDummyExercises(count: Int) -> [Exercise] {
        (0..<count).map { i in
            Exercise(
                id: UUID(),
                type: .multipleChoice,
                difficulty: "A1",
                instruction: "Выбери вариант:",
                question: "I ___ a student \(i).",
                options: ["is", "are", "am", "be"],
                correctAnswer: "am",
                explanation: "Test explanation",
                userAnswer: nil,
                isCorrect: nil
            )
        }
    }
}
