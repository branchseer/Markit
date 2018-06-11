//
//  CaseConverter.swift
//  Markit
//
//  Created by patr0nus on 2018/6/6.
//

import Foundation

fileprivate func caseLiteralConvertorFunction<T>(type: T.Type, cases: [String: T], fallbackConvertor: ((String) throws-> T)? = nil) -> ClassExtension.LiteralConvertor<T> {
    return {
        if let result = cases[$0] {
            return result
        }
        if let fallbackConvertor = fallbackConvertor {
            return try fallbackConvertor($0)
        }
        throw Compiler.Error.invalidLiteral($0, className: String(describing: type))
    }
}

extension ClassExtension {
    static func caseLiteralConvertor<T>(type: T.Type, cases: [String: T], fallbackConvertor: ((String) throws-> T)? = nil) -> ClassExtension {
        return ClassExtension.literalConvertor(caseLiteralConvertorFunction(type: type, cases: cases, fallbackConvertor: fallbackConvertor))
    }
    static func caseRawValueLiteralConvertor<T: RawRepresentable>(type: T.Type, cases: [String: T], fallbackConvertor: ((String) throws-> T)? = nil) -> ClassExtension {
        let caseConvertor = caseLiteralConvertorFunction(type: type, cases: cases, fallbackConvertor: fallbackConvertor)
        return ClassExtension.literalConvertor {
            try caseConvertor($0).rawValue
        }
    }    
}
