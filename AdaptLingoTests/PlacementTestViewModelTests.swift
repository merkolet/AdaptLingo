//
//  PlacementTestViewModelTests.swift
//  AdaptLingoTests
//
//  Created by Sergey on 15.04.2026.
//

import XCTest
@testable import AdaptLingo

@MainActor
final class PlacementTestViewModelTests: XCTestCase {

    var sut: PlacementTestViewModel!

    override func setUp() {
        super.setUp()
        sut = PlacementTestViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Начальное состояние

    func testInitialStateValues() {
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertNil(sut.selectedAnswerIndex)
        XCTAssertEqual(sut.score, 0)
        XCTAssertFalse(sut.isCompleted)
        XCTAssertEqual(sut.assignedLevel, "A1")
    }

    // MARK: - answerState

    func testAnswerStateNormalWhenNothingSelected() {
        sut.selectedAnswerIndex = nil
        XCTAssertEqual(sut.answerState(for: 0), .normal)
        XCTAssertEqual(sut.answerState(for: 2), .normal)
    }

    func testAnswerStateSelectedForChosenIndex() {
        sut.selectAnswer(2)
        XCTAssertEqual(sut.answerState(for: 2), .selected)
        XCTAssertEqual(sut.answerState(for: 0), .normal)
    }

    // MARK: - progress

    func testProgressWithNoQuestions() {
        XCTAssertEqual(sut.progress, 0.0)
    }

    // MARK: - scoreBasedLevel

    func testScoreBasedLevelA1() {
        let level = callScoreBasedLevel(score: 0, total: 15)
        XCTAssertEqual(level, "A1")
    }

    func testScoreBasedLevelB1() {
        let level = callScoreBasedLevel(score: 9, total: 15)
        XCTAssertEqual(level, "B1")
    }

    func testScoreBasedLevelC1() {
        let level = callScoreBasedLevel(score: 15, total: 15)
        XCTAssertEqual(level, "C1")
    }

    // MARK: - Helpers

    private func callScoreBasedLevel(score: Int, total: Int) -> String {
        let pct = total > 0 ? Double(score) / Double(total) : 0
        switch pct {
        case 0.93...: return "C1"
        case 0.73...: return "B2"
        case 0.53...: return "B1"
        case 0.33...: return "A2"
        default:  return "A1"
        }
    }
}
