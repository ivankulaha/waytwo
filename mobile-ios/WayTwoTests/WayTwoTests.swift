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

    // MARK: - APIClient 401 retry

    func testFetchProfile_on401_forcesRefreshAndRetriesOnce() async throws {
        URLProtocolStub.responses = [
            (401, Data()),
            (200, try JSONEncoder().encode(makeRemoteProfile(
                userId: "user-a",
                displayName: "Alex",
                gender: "male",
                onboardingCompletedAt: nil
            )))
        ]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.com/api/v1")!,
            logger: AppLogger(),
            session: URLSession(configuration: configuration)
        )
        let tokenSource = FakeTokenSource(initialToken: "stale-token", refreshedToken: "fresh-token")

        let profile = try await apiClient.fetchProfile(tokenSource: tokenSource)

        XCTAssertEqual(profile.userId, "user-a")
        XCTAssertEqual(URLProtocolStub.capturedAuthorizationHeaders, ["Bearer stale-token", "Bearer fresh-token"])
        XCTAssertEqual(tokenSource.forceRefreshCallCount, 1)
    }

    func testFetchProfile_secondUnauthorized_throws() async {
        URLProtocolStub.responses = [
            (401, Data()),
            (401, Data())
        ]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.com/api/v1")!,
            logger: AppLogger(),
            session: URLSession(configuration: configuration)
        )
        let tokenSource = FakeTokenSource(initialToken: "stale-token", refreshedToken: "still-invalid-token")

        do {
            _ = try await apiClient.fetchProfile(tokenSource: tokenSource)
            XCTFail("Expected the second 401 to throw")
        } catch {
            XCTAssertEqual(tokenSource.forceRefreshCallCount, 1)
        }
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

private final class FakeTokenSource: TokenSource {
    private let initialToken: String
    private let refreshedToken: String
    private(set) var forceRefreshCallCount = 0

    init(initialToken: String, refreshedToken: String) {
        self.initialToken = initialToken
        self.refreshedToken = refreshedToken
    }

    func currentAccessToken() async throws -> String {
        initialToken
    }

    func forceRefresh() async throws -> String {
        forceRefreshCallCount += 1
        return refreshedToken
    }
}

/// Stubs `URLProtocol` to serve queued `(statusCode, body)` responses in
/// order and record each request's `Authorization` header, without hitting
/// the network.
private final class URLProtocolStub: URLProtocol {
    static var responses: [(statusCode: Int, body: Data)] = []
    static var capturedAuthorizationHeaders: [String] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let header = request.value(forHTTPHeaderField: "Authorization") {
            Self.capturedAuthorizationHeaders.append(header)
        }
        guard !Self.responses.isEmpty else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let next = Self.responses.removeFirst()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: next.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: next.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
