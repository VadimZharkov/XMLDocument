import XCTest
@testable import XMLDocument

final class XMLDocumentTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(XMLDocument().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
