import XCTest
@testable import RockCrabData

final class YouTubeRequestTests: XCTestCase {
    func testChannelListRequestIncludesIOSBundleIdentifierHeader() throws {
        let request = try HTTPRequestList.ChannelListRequest(
            key: "test-key",
            channelId: "test-channel",
            maxResults: 10,
            pageToken: nil
        ).asURLRequest()

        XCTAssertEqual(
            request.value(forHTTPHeaderField: "X-Ios-Bundle-Identifier"),
            Bundle.main.bundleIdentifier
        )
    }

    func testChannelInfoRequestIncludesIOSBundleIdentifierHeader() throws {
        let request = try HTTPRequestList.ChannelInfoRequest(key: "test-key").asURLRequest()

        XCTAssertEqual(
            request.value(forHTTPHeaderField: "X-Ios-Bundle-Identifier"),
            Bundle.main.bundleIdentifier
        )
    }
}
