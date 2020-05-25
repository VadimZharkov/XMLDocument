//
//  XMLDocument.swift
//
//  Created by Vadim Zharkov on 20/03/15.
//  Copyright (c) 2015 Vadim Zharkov. All rights reserved.
//

import Foundation

public typealias XMLAttributes = [String: String]

public final class XMLElement: Sequence {
    public typealias Iterator = AnyIterator<XMLElement>
    
    public var name: String = ""
    public var attributes: XMLAttributes?
    public var value: String?

    public lazy var children: [XMLElement] = [XMLElement]()

    fileprivate weak var parent: XMLElement?

    var level: Int {
        var count = 0
        var element = self
        while let parent = element.parent {
            count += 1
            element = parent
        }
        return count
    }
  
    var indentation: String {
        var indent = ""
        let count = self.level
        for _ in 0..<count {
            indent += "\t"
        }
        return indent
    }
  
    public init(_ name: String, attributes: XMLAttributes? = nil, value: String? = nil) {
        self.name = name
        self.attributes = attributes
        self.value = value
    }
  
    public convenience init (_ name: String, value: String) {
        self.init(name, attributes: nil, value: value)
    }
  
    @discardableResult
    public func appendChild(_ child: XMLElement) -> XMLElement {
        child.parent = self
        children.append(child)
        return child
    }
  
    @discardableResult
    public func appendChild(_ name: String, attributes: XMLAttributes? = nil, value: String? = nil) -> XMLElement {
        let child = XMLElement(name, attributes: attributes, value: value)
        return appendChild(child)
    }

    public subscript(key: String) -> XMLElement? {
        return children.filter { $0.name == key }.first
    }

    public func makeIterator() -> Iterator {
        var index = 0
        return AnyIterator {
            if index < self.children.count {
                index += 1
                return self.children[index]
            }
            return nil
        }
    }

    public func toInt() -> Int? {
        return value != nil ? Int(value!) : nil
    }

    public func toString() -> String? {
        return value
    }
    
    public func toXMLString(_ indent: Bool = true) -> String {
        var xml = ""
    
        if indent && self.level > 0 { xml += self.indentation }
        xml += "<\(self.name)"
    
        if let attributes = self.attributes {
            if attributes.count > 0 {
                for (attribute, value) in attributes {
                    xml += " \(attribute)=\"\(value)\""
                }
            }
        }
        if self.value == nil && self.children.count == 0 {
            xml += " />"
        }
        else {
            if self.children.count > 0 {
                xml += ">"
                if indent { xml += "\n"}
                for child in self.children {
                    xml += "\(child.toXMLString(indent))"
                    if indent { xml += "\n"}
                }
                if indent && self.level > 0 { xml += self.indentation }
                xml += "</\(name)>"
            }
            else {
                xml += ">\(self.value!)</\(self.name)>"
            }
        }
        return xml
    }
}

public struct XMLDeclaration {
    public let version: Double?
    public let encoding: String?
    public let standalone: String?

    public init(version: Double? = nil, encoding: String? = nil, standalone: String? = nil) {
        self.version = version
        self.encoding = encoding
        self.standalone = standalone
    }
    
    public func toString() -> String {
        var xml = ""
        if self.version != nil || self.encoding != nil || self.encoding != nil {
            xml += "<?xml"
            if let version = self.version {
                xml += " version=\"\(version)\""
            }
            if let encoding = self.encoding {
                xml += " encoding=\"\(encoding)\""
            }
            if let standalone = standalone {
                xml += " standalone=\"\(standalone)\""
            }
            xml += "?>"
        }
        return xml
    }
}

public final class XMLDocument {
    public var declaration: XMLDeclaration?
    public var root: XMLElement?

    public init(declaration: XMLDeclaration? = nil, root: XMLElement? = nil) {
        self.root = root
        self.declaration = declaration
    }
  
    public convenience init(version: Double, encoding: String, root: XMLElement) {
        self.init(declaration: XMLDeclaration(version: version, encoding: encoding, standalone: nil), root: root)
    }
  
    public convenience init(version: Double, encoding: String, name: String, attributes: XMLAttributes? = nil) {
        let declaration = XMLDeclaration(version: version, encoding: encoding, standalone: nil)
        let root = XMLElement(name, attributes: attributes, value: nil)
        self.init(declaration: declaration, root: root)
    }

    public convenience init(_ name: String, attributes: XMLAttributes? = nil) {
        let root = XMLElement(name, attributes: attributes, value: nil)
        self.init(declaration: nil, root: root)
    }
  
    public func toXMLString(indent: Bool = true) -> String {
        var xml =  ""
        if let declaration = self.declaration {
            xml += declaration.toString()
            if indent { xml += "\n"}
        }
        if let root = self.root {
            xml += root.toXMLString(indent)
        }
        return xml
    }
    
    public func toUTF8Data() -> Data? {
        return toXMLString(indent: false).data(using: String.Encoding.utf8)
    }
}

public final class XMLBuilder {
    fileprivate let document = XMLDocument()
    fileprivate var current: XMLElement?
    
    fileprivate func add(_ element: XMLElement, block: (() -> ())? = nil) {
        if document.root == nil {
            document.root = element
            current = element
        }
        else if let _ = current {
            _ = current!.appendChild(element)
            if let _ = block {
                current = element
            }
        }
        if let block = block {
            block()
            current = current?.parent
        }
    }
    
    public func declaration(_ version: Double = 1.0, encoding: String? = nil, standalone: String? = nil) {
        document.declaration = XMLDeclaration(version: version, encoding: encoding, standalone: standalone)
    }
    
    public func element(_ name: String, block: (() -> ())? = nil) {
        let element = XMLElement(name)
        add(element, block: block)
    }
    
    public func element(_ name: String, attributes: XMLAttributes, block: (() -> ())? = nil) {
        let element = XMLElement(name, attributes: attributes)
        add(element, block: block)
    }
    
    public func element(_ name: String, attributes: XMLAttributes, value: String) {
        let element = XMLElement(name, attributes: attributes, value: value)
        add(element)
    }
    
    public func element(_ name: String, value: String) {
        let element = XMLElement(name, attributes: nil, value: value)
        add(element)
    }
}

public extension XMLDocument {
    static func build(_ block: (_ builder: XMLBuilder) -> ()) -> XMLDocument {
        let builder = XMLBuilder()
        block(builder)
        return builder.document
    }
}

public enum XMLParserError: Error, CustomDebugStringConvertible {
    case unknown

    public var debugDescription: String {
        return "Unknown error has occurred."
    }
}

public class XMLDocumentParser: NSObject {
    private let data: Data
    
    fileprivate var current: (parent: XMLElement?, element: XMLElement?, value: String?) = (parent: nil, element: nil, value: nil)
   
    fileprivate let document = XMLDocument()
    fileprivate var error: Error?
    
    public init(data: Data) {
        self.data = data
        
        super.init()
    }
    
    public static func parse(_ data: Data) throws -> XMLDocument {
        let parser = XMLDocumentParser(data: data)
        try parser.parse()
        
        return parser.document
    }
    
    public func parse() throws {
        let parser = Foundation.XMLParser(data: data)
        parser.shouldProcessNamespaces = false
        parser.delegate = self
        
        let success = parser.parse()
        guard success else {
            throw error ?? XMLParserError.unknown
        }
    }
}

extension XMLDocumentParser: XMLParserDelegate {
    public func parser(_ parser:Foundation.XMLParser,
                       didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                       attributes attributeDict: [String : String] = [:]) {
        current.value = String()
        current.element = XMLElement(elementName, attributes: attributeDict)
        if document.root == nil {
            document.root = current.element
        }
        current.parent?.appendChild(current.element!)
        current.parent = current.element
    }

    public func parser(_ parser: Foundation.XMLParser, foundCharacters string: String) {
        current.value! += string
        let newValue = current.value!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        current.element?.value = newValue.isEmpty ? nil : newValue
    }

    public func parser(_ parser: Foundation.XMLParser,
                       didEndElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?) {
        current.parent = current.parent?.parent
        current.element = nil
    }
    
    public func parser(_ parser: Foundation.XMLParser, parseErrorOccurred parseError: Error) {
        error = parseError
    }
}

public extension XMLDocument {
    static func parse(_ data: Data) throws -> XMLDocument {
        return try XMLDocumentParser.parse(data)
    }
}
