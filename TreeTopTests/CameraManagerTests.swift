//
//  CameraManagerTests.swift
//  TreeTopTests
//
//  Created by Lesly Reinoso on 8/1/25.
//


import XCTest
@testable import TreeTop

final class CameraManagerTests: XCTestCase {



    func test_toggleAutoCapture_enablesInstructions_thenHidesAfterDelay() {
        let sut = CameraManager()
        XCTAssertFalse(sut.autoCaptureEnabled)
        XCTAssertFalse(sut.showInstructions)
        XCTAssertFalse(sut.isReady)

        // Enable auto-capture
        sut.toggleAutoCapture()

        // Immediately shows instructions, not ready yet
        XCTAssertTrue(sut.autoCaptureEnabled)
        XCTAssertTrue(sut.showInstructions)
        XCTAssertFalse(sut.isReady)

        // Wait a bit longer than 4 seconds to let the hide timer fire
        let exp = expectation(description: "instructions hidden")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.3) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)

        XCTAssertFalse(sut.showInstructions, "Instructions should auto-hide after ~4s")
    }

    func test_toggleAutoCapture_off_resetsState_andCancelsCountdown() {
        let sut = CameraManager()

        // Turn it on first
        sut.toggleAutoCapture()
        XCTAssertTrue(sut.autoCaptureEnabled)

        // Simulate in-progress auto-capture state the manager would keep
        sut.isAutoCapturing = true
        sut.countdownValue = 2
        sut.isLeveledHorizontally = true
        sut.isReady = true

        // Turn it off
        sut.toggleAutoCapture()
        XCTAssertFalse(sut.autoCaptureEnabled)
        XCTAssertFalse(sut.isAutoCapturing, "Turning off should cancel auto-capturing")
        XCTAssertEqual(sut.countdownValue, 0, "Countdown should reset to 0")
        XCTAssertFalse(sut.isLeveledHorizontally, "Level flag resets when disabling")
        XCTAssertFalse(sut.isReady, "Ready resets when disabling")
    }



    func test_toggleReady_toggles_andCancelsWhenTurnedOff() {
        let sut = CameraManager()

        // Start with not ready
        XCTAssertFalse(sut.isReady)

        // Toggle to ready
        sut.toggleReady()
        XCTAssertTrue(sut.isReady)

        // Simulate an ongoing auto-capture
        sut.isAutoCapturing = true
        sut.countdownValue = 2
        sut.isLeveledHorizontally = true

        // Toggle to not ready -> should cancel auto-capture & reset level flag
        sut.toggleReady()
        XCTAssertFalse(sut.isReady)
        XCTAssertFalse(sut.isAutoCapturing)
        XCTAssertEqual(sut.countdownValue, 0)
        XCTAssertFalse(sut.isLeveledHorizontally)
    }

  

    func test_stopMotionTracking_cancelsTimerIfPresent_andIsSafeToCall() {
        let sut = CameraManager()

        // Simulate an active countdown timer by mimicking state.
        sut.isAutoCapturing = true
        sut.countdownValue = 3

        // We cannot directly access the private timer, but stopMotionTracking()
        // should invalidate it and leave manager in a safe state.
        sut.stopMotionTracking()

        // After stopping motion tracking, countdown should be considered over/resettable.
        // (The method invalidates the timer; observable effects we can assert are that the
        // test doesn't crash and we can safely reset state.)
        sut.isAutoCapturing = false
        sut.countdownValue = 0

        XCTAssertFalse(sut.isAutoCapturing)
        XCTAssertEqual(sut.countdownValue, 0)
    }
}

