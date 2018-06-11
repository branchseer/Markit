//
//  MarkitNamespaceHandler.swift
//  Markit
//
//  Created by patr0nus on 2018/5/29.
//

import Foundation

let kMarkitObjectClassName = "Markit"
fileprivate let kMarkitObjectTopObjectsPropertyName = "topObjects"
fileprivate let kNamePropertyName = "name"
fileprivate let kIDPropertyName = "id"
fileprivate let kStringType = "String"

let kReferenceClassName = "Reference"
let kReferenceExpressionName = "expression"
//fileprivate let kReferenceExpressionType = "ReferenceExpression"

//fileprivate struct ReferenceExpression {
//    enum Target {
//        case objectWithID(_: String)
//        case inputObject
//    }
//    let expressionString: String
//    let target: Target
//    let keyPath: String?
//
//    init(expressionString: String) throws  {
//        self.expressionString = expressionString
//        let components = expressionString.split(separator: ".", maxSplits: 2)
//        if components.isEmpty {
//            throw ReferenceError.invalidExpressionString(expressionString)
//        }
//        self.target = components[0] == "#" ? .inputObject: .objectWithID(String(components[0]))
//        self.keyPath = components.count == 2 ? String(components[1]): nil
//    }
//}

public enum ReferenceError: Swift.Error {
    case invalidExpressionString(_: String)
    case targetNoFound(expression: String)
    case nsobjectRequiredForKeyPath(expression: String)
}

class MarkitNamespaceHandler: NamespaceHandler {
    required init(urlParams: [URLQueryItem]?) {
        
    }
    
    func contextCreator() -> ContextCreator {
        return {
            MarkitObject(connector: $0)
        }
    }
    
    func objectConstructor(ofClass className: String, propertyNames: Set<String>) throws -> (ObjectConstructor, propertyNamesForConstructor: Set<String>) {
        if className == kMarkitObjectClassName {
            return ({ context, _ in
                return context!
            }, [])
        }
        
        if className == kReferenceClassName {
            if !propertyNames.contains(kReferenceExpressionName) {
                throw Compiler.Error.missingRequiredProperty(name: kReferenceExpressionName, className: className)
            }
            return ({ context, parameters in
                let markitContext = context as! MarkitObject
                let expression = parameters[kReferenceExpressionName] as! String
                
                if (expression.first == "#") {
                    return markitContext.connector.value(named: String(expression.dropFirst()))
                }
                else {
                    return markitContext.objectsByID.value(forKeyPath: expression)
                }
                
                
            }, [kReferenceExpressionName])
        }
        
        throw Compiler.Error.noSuchClassName(className)
    }
    
    func object(ofClass className: String, literal: String) throws -> Object {
        if className == kStringType {
            return literal
        }
//        if className == kReferenceExpressionType {
//            return try ReferenceExpression(expressionString: literal)
//        }
        
        fatalError("Invalid literal \(literal) for class \(className).")
    }
    
    func objectConstructedCallback(forClass className: String) -> ObjectLifecycleCallback? {
        return nil
    }
    
    func type(ofProperty propertyName: String, inClass className: String) throws -> PropertyType {
        if className == kMarkitObjectClassName && propertyName == kMarkitObjectTopObjectsPropertyName {
            return .array(elementClassName: nil)
        }
        if className == kReferenceClassName && propertyName == kReferenceExpressionName {
            return .singleValue(className: kStringType)
        }
        
        if propertyName == kNamePropertyName || propertyName == kIDPropertyName {
            return .singleValue(className: kStringType)
        }
        throw Compiler.Error.propertyNotFound(name: propertyName, className: className)
    }
    
    func propertySetter(ofProperty propertyName: String, inClass className: String) -> PropertySetterFunction {
        if className == kMarkitObjectClassName && propertyName == kMarkitObjectTopObjectsPropertyName {
            return { ctx, object, propertyValue in
                (object as! MarkitObject).topObjects = propertyValue as! [Any]
            }
        }
        
        if propertyName == kNamePropertyName {
            return { ctx, object, name in
                let markit = ctx as! MarkitObject
                let name = name as! String
                
                markit.connector.setValue(object, withName: name)
//                (ctx as! MarkitObject).owner.setValue(object, forKeyPath: name as! String)
//                (ctx as! MarkitObject).objectsByName[name as! String] = object
            }
        }
        
        if propertyName == kIDPropertyName {
            return { ctx, object, name in
                (ctx as! MarkitObject).objectsByID[name as! String] = object
            }
        }
        
        fatalError("No property \(propertyName) in class \(className).")
    }
    
    func property(_ lp: String, mustBeAssignedBeforeProperty rp: String) -> Bool {
        return false
    }
    
    func contentPropertyName(ofClass className: String) throws -> String? {
        if className == kMarkitObjectClassName {
            return kMarkitObjectTopObjectsPropertyName
        }
        throw Compiler.Error.noSuchClassName(className)
    }
    
    func objectBuiltCallback(forClass className: String) -> ObjectLifecycleCallback? {
        return nil
    }
}
