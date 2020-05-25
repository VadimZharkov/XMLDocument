import XCTest
@testable import XMLDocument

final class XMLDocumentTests: XCTestCase {
    static var allTests = [
        ("testXMLDocumentIsBuilt", testXMLDocumentIsBuilt),
        ("testXMLDocumentIsParsed", testXMLDocumentIsParsed),
        ("testXMLDocumentNavigation", testXMLDocumentNavigation),
    ]
    
    func testXMLDocumentIsBuilt() {
        let etalon = "<?xml version=\"1.0\"?><Autodiscover xmlns=\"http://schemas.microsoft.com/exchange/autodiscover/mobilesync/requestschema/2006\"><Request><EMailAddress>blabla@outlook.com</EMailAddress><AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/mobilesync/responseschema/2006</AcceptableResponseSchema></Request></Autodiscover>"
        let username = "blabla@outlook.com"
        let xml = XMLDocument.build { x in
            x.declaration()
            x.element("Autodiscover", attributes: ["xmlns":"http://schemas.microsoft.com/exchange/autodiscover/mobilesync/requestschema/2006"]) {
                x.element("Request") {
                    x.element("EMailAddress", value: username)
                    x.element("AcceptableResponseSchema", value: "http://schemas.microsoft.com/exchange/autodiscover/mobilesync/responseschema/2006")
                }
            }
        }
        XCTAssertEqual(etalon, xml.toXMLString(indent: false))
    }
    
    func testXMLDocumentIsParsed() {
        let etalon = "<Autodiscover xmlns=\"http://schemas.microsoft.com/exchange/autodiscover/mobilesync/requestschema/2006\"><Request><EMailAddress>blabla@outlook.com</EMailAddress><AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/mobilesync/responseschema/2006</AcceptableResponseSchema></Request></Autodiscover>"
        let data = etalon.data(using: .utf8)
        do {
            let doc = try XMLDocument.parse(data!)
            let xml = doc.toXMLString(indent: false)
            
            XCTAssertEqual(etalon, xml)
        }
        catch {
            XCTFail("Error: \(error)")
        }
    }
    
    func testXMLDocumentNavigation() {
        let username = "blabla@outlook.com"
        let xml = XMLDocument.build { x in
              x.declaration()
              x.element("Autodiscover", attributes: ["xmlns":"http://schemas.microsoft.com/exchange/autodiscover/mobilesync/requestschema/2006"]) {
                  x.element("Request") {
                      x.element("EMailAddress", value: username)
                      x.element("AcceptableResponseSchema", value: "http://schemas.microsoft.com/exchange/autodiscover/mobilesync/responseschema/2006")
                  }
              }
          }

        let email = xml.root?["Request"]?["EMailAddress"]
        XCTAssertEqual(email?.name, "EMailAddress")
        XCTAssertEqual(email?.value, username)
    }
}
