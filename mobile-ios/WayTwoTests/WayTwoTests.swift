//
//  WayTwoTests.swift
//  WayTwoTests
//
//  Created by Ivan Kulaha on 27.04.2026.
//

import XCTest
@testable import WayTwo

final class WayTwoTests: XCTestCase {

    // MARK: - ProfileCompleteness

    func testHasFinishedOnboarding_blankProfile_isNotFinished() {
        XCTAssertFalse(ProfileCompleteness.hasFinishedOnboarding(
            displayName: nil,
            gender: nil,
            onboardingCompletedAt: nil
        ))
    }

    func testHasFinishedOnboarding_youFieldsPresentButNotCompleted_isNotFinished() {
        XCTAssertFalse(ProfileCompleteness.hasFinishedOnboarding(
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: nil
        ))
    }

    func testHasFinishedOnboarding_completedButBlankName_isNotFinished() {
        XCTAssertFalse(ProfileCompleteness.hasFinishedOnboarding(
            displayName: "   ",
            gender: "male",
            onboardingCompletedAt: "2026-01-01T00:00:00Z"
        ))
    }

    func testHasFinishedOnboarding_completedButMissingGender_isNotFinished() {
        XCTAssertFalse(ProfileCompleteness.hasFinishedOnboarding(
            displayName: "Alex",
            gender: nil,
            onboardingCompletedAt: "2026-01-01T00:00:00Z"
        ))
    }

    func testHasFinishedOnboarding_nameGenderAndCompletedAt_isFinished() {
        XCTAssertTrue(ProfileCompleteness.hasFinishedOnboarding(
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: "2026-01-01T00:00:00Z"
        ))
    }

    // MARK: - DatabaseClient.prepareProfileForUser

    func testPrepareProfileForUser_sameUser_keepsCompletedRow() {
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("user-a")
        database.applyRemoteProfile(makeRemoteProfile(
            userId: "user-a",
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: "2026-01-01T00:00:00Z"
        ))

        database.prepareProfileForUser("user-a")

        let profile = database.getProfile()
        XCTAssertEqual(profile?.userId, "user-a")
        XCTAssertNotNil(profile?.onboardingCompletedAt)
    }

    func testPrepareProfileForUser_differentUser_wipesProfileAndOutbox() {
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("user-a")
        database.applyRemoteProfile(makeRemoteProfile(
            userId: "user-a",
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: "2026-01-01T00:00:00Z"
        ))
        database.enqueueOutbox(operation: Outbox.Operation.completeOnboarding.rawValue, entityId: "onboarding", payload: "{}")

        database.prepareProfileForUser("user-b")

        let profile = database.getProfile()
        XCTAssertEqual(profile?.userId, "user-b")
        XCTAssertNil(profile?.displayName)
        XCTAssertNil(profile?.onboardingCompletedAt)
        XCTAssertTrue(database.fetchOutbox().isEmpty)
    }

    func testPrepareProfileForUser_unresolvedUserId_wipesLeftoverRow() {
        // Mirrors a pre-migration cache: every account used to share the
        // `"local"` row. An unresolved current user id must not inherit it.
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("local")
        database.applyRemoteProfile(makeRemoteProfile(
            userId: "local",
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: "2026-01-01T00:00:00Z"
        ))

        database.prepareProfileForUser(nil)

        let profile = database.getProfile()
        XCTAssertNil(profile?.displayName)
        XCTAssertNil(profile?.onboardingCompletedAt)
    }

    // MARK: - JWTAccessToken

    func testJWTAccessTokenSubject_decodesSubClaim() {
        // header {"alg":"HS256"} . payload {"sub":"user-123"} . signature (unverified, unused)
        let token = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.signature"
        XCTAssertEqual(JWTAccessToken.subject(token), "user-123")
    }

    func testJWTAccessTokenSubject_malformedToken_returnsNil() {
        XCTAssertNil(JWTAccessToken.subject("not-a-jwt"))
    }

    private func makeRemoteProfile(
        userId: String,
        displayName: String?,
        gender: String?,
        onboardingCompletedAt: String?
    ) -> APIClient.ProfileRow {
        APIClient.ProfileRow(
            userId: userId,
            displayName: displayName,
            gender: gender,
            dateOfBirth: nil,
            photoPath: nil,
            colorId: nil,
            onboardingStep: 0,
            onboardingCompletedAt: onboardingCompletedAt,
            updatedAt: "2026-01-01T00:00:00Z"
        )
    }
}
