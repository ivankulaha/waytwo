//
//  WayTwoTests.swift
//  WayTwoTests
//
//  Created by Ivan Kulaha on 27.04.2026.
//

import XCTest
@testable import WayTwo

final class WayTwoTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.reset()
    }

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

    func testPrepareProfileForUser_differentUser_wipesProfile() {
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("user-a")
        database.applyRemoteProfile(makeRemoteProfile(
            userId: "user-a",
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: "2026-01-01T00:00:00Z"
        ))

        database.prepareProfileForUser("user-b")

        let profile = database.getProfile()
        XCTAssertEqual(profile?.userId, "user-b")
        XCTAssertNil(profile?.displayName)
        XCTAssertNil(profile?.onboardingCompletedAt)
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
        URLProtocolStub.events = [
            .response(statusCode: 401, body: Data()),
            .response(statusCode: 200, body: try JSONEncoder().encode(makeRemoteProfile(
                userId: "user-a",
                displayName: "Alex",
                gender: "male",
                onboardingCompletedAt: nil
            )))
        ]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let apiClient = makeAPIClient(sessionConfiguration: configuration)
        let tokenSource = FakeTokenSource(initialToken: "stale-token", refreshedToken: "fresh-token")

        let profile = try await apiClient.fetchProfile(tokenSource: tokenSource)

        XCTAssertEqual(profile.userId, "user-a")
        XCTAssertEqual(URLProtocolStub.capturedAuthorizationHeaders, ["Bearer stale-token", "Bearer fresh-token"])
        XCTAssertEqual(tokenSource.forceRefreshCallCount, 1)
    }

    func testFetchProfile_retriesServerErrorsThenSucceeds() async throws {
        let body = try JSONEncoder().encode(makeRemoteProfile(
            userId: "user-a",
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: nil
        ))
        URLProtocolStub.events = [
            .response(statusCode: 500, body: Data()),
            .response(statusCode: 503, body: Data()),
            .response(statusCode: 200, body: body)
        ]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let apiClient = makeAPIClient(sessionConfiguration: configuration)

        let profile = try await apiClient.fetchProfile(
            tokenSource: FakeTokenSource(initialToken: "token", refreshedToken: "token")
        )

        XCTAssertEqual(profile.userId, "user-a")
        XCTAssertEqual(URLProtocolStub.requestCount, 3)
    }

    func testFetchProfile_clientError_doesNotRetry() async {
        URLProtocolStub.events = [
            .response(statusCode: 400, body: Data())
        ]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let apiClient = makeAPIClient(sessionConfiguration: configuration)

        do {
            _ = try await apiClient.fetchProfile(
                tokenSource: FakeTokenSource(initialToken: "token", refreshedToken: "token")
            )
            XCTFail("Expected a 400 to throw")
        } catch let error as APIError {
            guard case .http(let statusCode) = error, statusCode == 400 else {
                return XCTFail("expected http 400")
            }
            XCTAssertEqual(URLProtocolStub.requestCount, 1)
        } catch {
            XCTFail("expected APIError")
        }
    }

    // MARK: - ProfileSync network-first

    func testPushProfile_success_appliesRemoteAndDoesNotWritePatchFirst() async {
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("user-a")
        URLProtocolStub.events = [
            .response(statusCode: 200, body: try! JSONEncoder().encode(makeRemoteProfile(
                userId: "user-a",
                displayName: "RemoteName",
                gender: "male",
                onboardingCompletedAt: nil
            )))
        ]
        let sync = makeProfileSync(database: database)

        let result = await sync.pushProfile(patch: ProfilePatch(displayName: "LocalName"))

        guard case .success = result else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(database.getProfile()?.displayName, "RemoteName")
        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }

    func testPushProfile_retriesServerErrorsThenSucceeds() async {
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("user-a")
        let body = try! JSONEncoder().encode(makeRemoteProfile(
            userId: "user-a",
            displayName: "RemoteName",
            gender: "male",
            onboardingCompletedAt: nil
        ))
        URLProtocolStub.events = [
            .response(statusCode: 500, body: Data()),
            .response(statusCode: 503, body: Data()),
            .response(statusCode: 200, body: body)
        ]
        let sync = makeProfileSync(database: database)

        let result = await sync.pushProfile(patch: ProfilePatch(displayName: "LocalName"))

        guard case .success = result else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(database.getProfile()?.displayName, "RemoteName")
        XCTAssertEqual(URLProtocolStub.requestCount, 3)
    }

    func testPushProfile_clientError_doesNotRetryOrPersist() async {
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("user-a")
        URLProtocolStub.events = [
            .response(statusCode: 400, body: Data())
        ]
        let sync = makeProfileSync(database: database)

        let result = await sync.pushProfile(patch: ProfilePatch(displayName: "LocalName"))

        guard case .failure(.saveFailed) = result else {
            return XCTFail("expected saveFailed")
        }
        XCTAssertNil(database.getProfile()?.displayName)
        XCTAssertEqual(URLProtocolStub.requestCount, 1)
    }

    func testPushProfile_transportFailsAfterRetries_returnsSaveFailed() async {
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("user-a")
        URLProtocolStub.events = [
            .failure(URLError(.notConnectedToInternet)),
            .failure(URLError(.notConnectedToInternet)),
            .failure(URLError(.notConnectedToInternet))
        ]
        let sync = makeProfileSync(database: database)

        let result = await sync.pushProfile(patch: ProfilePatch(displayName: "LocalName"))

        guard case .failure(.saveFailed) = result else {
            return XCTFail("expected saveFailed")
        }
        XCTAssertNil(database.getProfile()?.displayName)
        XCTAssertEqual(URLProtocolStub.requestCount, 3)
    }

    func testCompleteOnboarding_patchesLookThenCompletes() async {
        let database = DatabaseClient(logger: AppLogger(), inMemory: true)
        database.prepareProfileForUser("user-a")
        let patched = makeRemoteProfile(
            userId: "user-a",
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: nil,
            colorId: "coral"
        )
        let completed = makeRemoteProfile(
            userId: "user-a",
            displayName: "Alex",
            gender: "male",
            onboardingCompletedAt: "2026-01-01T00:00:00Z",
            colorId: "coral"
        )
        URLProtocolStub.events = [
            .response(statusCode: 200, body: try! JSONEncoder().encode(patched)),
            .response(statusCode: 200, body: try! JSONEncoder().encode(completed))
        ]
        let sync = makeProfileSync(database: database)

        let result = await sync.completeOnboarding(look: ProfilePatch(colorId: "coral", photoPath: "/tmp/avatar.jpg"))

        guard case .success = result else {
            return XCTFail("expected success")
        }
        XCTAssertEqual(URLProtocolStub.capturedMethods, ["PATCH", "POST"])
        XCTAssertNotNil(database.getProfile()?.onboardingCompletedAt)
        XCTAssertEqual(database.getProfile()?.colorId, "coral")
    }

    func testFetchProfile_secondUnauthorized_throws() async {
        URLProtocolStub.events = [
            .response(statusCode: 401, body: Data()),
            .response(statusCode: 401, body: Data())
        ]
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let apiClient = makeAPIClient(sessionConfiguration: configuration)
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
        onboardingCompletedAt: String?,
        colorId: String? = nil
    ) -> APIClient.ProfileRow {
        APIClient.ProfileRow(
            userId: userId,
            displayName: displayName,
            gender: gender,
            dateOfBirth: nil,
            photoPath: nil,
            colorId: colorId,
            onboardingStep: 0,
            onboardingCompletedAt: onboardingCompletedAt,
            updatedAt: "2026-01-01T00:00:00Z"
        )
    }

    private func makeAPIClient(sessionConfiguration: URLSessionConfiguration) -> APIClient {
        APIClient(
            baseURL: URL(string: "https://example.com/api/v1")!,
            logger: AppLogger(),
            session: URLSession(configuration: sessionConfiguration),
            retryDelays: [0, 0, 0]
        )
    }

    private func makeProfileSync(database: DatabaseClient) -> ProfileSync {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return ProfileSync(
            database: database,
            apiClient: makeAPIClient(sessionConfiguration: configuration),
            tokenSource: FakeTokenSource(initialToken: "token", refreshedToken: "token"),
            logger: AppLogger()
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

/// Stubs `URLProtocol` to serve queued events in order and record each
/// request's method and `Authorization` header, without hitting the network.
private final class URLProtocolStub: URLProtocol {
    enum Event {
        case response(statusCode: Int, body: Data)
        case failure(Error)
    }

    static var events: [Event] = []
    static var capturedAuthorizationHeaders: [String] = []
    static var capturedMethods: [String] = []
    static var requestCount = 0

    static func reset() {
        events = []
        capturedAuthorizationHeaders = []
        capturedMethods = []
        requestCount = 0
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
        if let method = request.httpMethod {
            Self.capturedMethods.append(method)
        }
        if let header = request.value(forHTTPHeaderField: "Authorization") {
            Self.capturedAuthorizationHeaders.append(header)
        }
        guard !Self.events.isEmpty else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let next = Self.events.removeFirst()
        switch next {
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        case let .response(statusCode, body):
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
