# XMLDocument

This package contains a simple XMLDocument class with Parser and Builder.

## Usage

Building:
```swift
let xml = XMLDocument.build { x in
       x.declaration()
       x.element("Autodiscover", attributes: ["xmlns":"http://schemas.microsoft.com/exchange/autodiscover/mobilesync/requestschema/2006"]) {
           x.element("Request") {
               x.element("EMailAddress", value: username)
               x.element("AcceptableResponseSchema", value: "http://schemas.microsoft.com/exchange/autodiscover/mobilesync/responseschema/2006")
           }
       }
```
Parsing:
```swift
let doc = try XMLDocument.parse(data)
```
Navigation:
```swift       
let address = xml.root?["Request"]?["EMailAddress"]
```
