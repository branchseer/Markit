//
//  Utiles.swift
//  Markit
//
//  Created by patr0nus on 2018/5/18.
//

import Foundation

extension XMLElement {
    var namespace: String? {
        //        let namespaceNode = self.namespace(forPrefix: self.prefix ?? "") ?? self.resolveNamespace(forName: self.name ?? "")
        let namespaceNode = self.resolveNamespace(forName: self.name ?? "")
        return namespaceNode?.stringValue
    }
}
//
//extension Optional {
//    func unwrapOrThrow(error: @autoclosure () -> Error) throws -> Wrapped {
//        if let value = self {
//            return value
//        }
//        else {
//            throw error()
//        }
//    }
//}

extension XMLNode {
    var attrNamespace: String? {
        guard let parent = self.parent as? XMLElement else { return nil }
        //        let namespaceNode = parent.namespace(forPrefix: self.prefix ?? "") ?? parent.resolveNamespace(forName: self.name ?? "")
        let namespaceNode = parent.resolveNamespace(forName: self.name ?? "")
        return namespaceNode?.stringValue
    }
}


private extension StringProtocol {
    func dropLast(from character: Character) -> SubSequence? {
        guard let index = self.index(of: character) else { return nil }
        let chCount = self.distance(from: index, to: self.endIndex)
        return self.dropLast(chCount)
    }
}

private var selfAndAncestsorNamesCache = [String: [String]]()
private var propertyTypeCache = [String: String?]()

private let propertyAttributeTypeSurroundings = CharacterSet(charactersIn: "^{}@\"=")

extension String {
    var selfAndAncestorClassNames: [String] {
        if let result = selfAndAncestsorNamesCache[self] {
            return result
        }
        
        var result = [String]()
        var currentClass: AnyClass? = NSClassFromString(self)
        while let theCurrentClass = currentClass {
            result.append(NSStringFromClass(theCurrentClass))
            currentClass = theCurrentClass.superclass()
        }
        
        selfAndAncestsorNamesCache[self] = result
        
        return result
    }
    
    func typeString(ofProperty name: String) -> String? {
        let classNameAndPropertyString = "\(self)#\(name)"
        if let result = propertyTypeCache[classNameAndPropertyString] {
            return result
        }
        
        var result: String? = nil
        
        if let theClass = NSClassFromString(self),
            let objcProperty = class_getProperty(theClass, name),
            let cPropertyAttributes = property_getAttributes(objcProperty) {
            
            let propertyAttributes = String(cString: cPropertyAttributes).dropFirst()
            result = String(propertyAttributes.dropLast(from: ",") ?? propertyAttributes)
                .trimmingCharacters(in: propertyAttributeTypeSurroundings)
        }
        
        propertyTypeCache[classNameAndPropertyString] = result
        return result
    }
}

