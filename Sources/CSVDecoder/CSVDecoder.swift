
//
//  CSVDecoder2.swift
//  CSVDecoder
//
//  Created by Jaap on 06/02/2019.
//

import Foundation
import CSVReader

public class CSVDecoder {
    public enum DateDecodingStrategy {
        case deferredToDate
        case secondsSince1970
        case millisecondsSince1970
        @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
        case iso8601
        case formatted(DateFormatter)
        case custom((_ value: String) throws -> Date)
    }
    
    public enum DataDecodingStrategy {
        case deferredToData
        case base64
        case custom((_ value: String) throws -> Data)
    }
    
    public enum NonConformingFloatDecodingStrategy {
        case `throw`
        case convertFromString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    public enum KeyDecodingStrategy {
        case useDefaultKeys
        case convertFromSnakeCase
        case custom((_ codingPath: [CodingKey]) -> CodingKey)
    }
    
    fileprivate struct _Options {
        let dateDecodingStrategy: DateDecodingStrategy
        let dataDecodingStrategy: DataDecodingStrategy
        let nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy
        let keyDecodingStrategy: KeyDecodingStrategy
    }
    
    open var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate
    open var dataDecodingStrategy: DataDecodingStrategy = .base64
    open var nonConformingFloatDecodingStrategy: NonConformingFloatDecodingStrategy = .throw
    open var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys
    
    
    fileprivate var options: _Options {
        return _Options(
            dateDecodingStrategy: dateDecodingStrategy,
            dataDecodingStrategy: dataDecodingStrategy,
            nonConformingFloatDecodingStrategy: nonConformingFloatDecodingStrategy,
            keyDecodingStrategy: keyDecodingStrategy)
    }
    
    public init() {}
    
    open func decode<T: Decodable>(_ type: T.Type, using reader: CSVReader) throws -> T {
        let decoder = _CSVDecoder(referencing: reader, options: self.options)
        return try T(from: decoder)
    }
    
    open func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        fatalError("Needs work")
    }
}

fileprivate class _CSVDecoder: Decoder {
    var reader: CSVReader
    
    var options: CSVDecoder._Options
    
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    init(referencing reader: CSVReader, options: CSVDecoder._Options) {
        self.reader = reader
        self.options = options
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let container = _CSVKeyedDecodingContainer<Key>(referencing: self)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        // not supported
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "CSV file format does not support unkeyed decoding"))
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

fileprivate struct _CSVKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var decoder: _CSVDecoder
    
    var codingPath: [CodingKey]
    
    var allKeys: [Key] {
        guard let headers = self.decoder.reader.headers else {
            return []
        }
        return headers.compactMap { Key(stringValue: $0) }
    }
    
    init(referencing decoder: _CSVDecoder) {
        self.decoder = decoder
        
        // To be implemented
//        switch decoder.options.keyDecodingStrategy {
//        case .useDefaultKeys:
//            break
//        case .convertFromSnakeCase:
//
//
//        case .custom(let converter):
//
//        }
        
        self.codingPath = decoder.codingPath
    }
    
    func contains(_ key: Key) -> Bool {
        return allKeys.contains(where: { k in
            return k.stringValue == key.stringValue
        })
    }
    
    func value(for key: Key) throws -> String {
        guard self.contains(key) else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\(key.stringValue))"))
        }
        
        return self.decoder.reader[key.stringValue]!
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        return try value(for: key).isEmpty
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        let value = try self.value(for: key)
        
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let result = try self.decoder.unbox(value, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found nil instead."))
        }
        return result
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        // not supported
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "CSV file format does not support decoding of nested types"))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        // not supported
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "CSV file format does not support decoding of nested types"))
    }
    
    func superDecoder() throws -> Decoder {
        // not supported
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "CSV file format does not support decoding of nested types"))
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        // not supported
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "CSV file format does not support decoding of nested types"))
    }
}

extension _CSVDecoder: SingleValueDecodingContainer {
    var value: String {
        let key = self.codingPath.last!
        return self.reader[key.stringValue]!
    }
    
    func expectNonNil<T>(_ type: T.Type) throws {
        guard !self.decodeNil() else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found nil value instead."))
        }
    }
    
    func decodeNil() -> Bool {
        return self.value.isEmpty
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try expectNonNil(type)
        return try self.unbox(self.value, as: type)!
    }
}

extension _CSVDecoder {
    func unbox<T: Decodable>(_ value: String, as type: T.Type) throws -> T? {
        if value.isEmpty { return nil }
        
        switch type {
        case is Bool.Type:
            guard let bool = Bool(value) else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            }
            return bool as? T
            
        case is String.Type:
            return value as? T
            
        case is Double.Type:
            if let double = Double(value) {
                return double as? T
            }
            
            switch self.options.nonConformingFloatDecodingStrategy {
            case .throw:
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            case .convertFromString(let posInfString, let negInfString, let nanString):
                switch value {
                case posInfString:
                    return Double.infinity as? T
                case negInfString:
                    return -Double.infinity as? T
                case nanString:
                    return Double.nan as? T
                default:
                    throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
                }
            }
            
        case is Float.Type:
            guard let double = try unbox(value, as: Double.self) else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: Double.self, reality: value)
            }
            guard abs(double) <= Double(Float.greatestFiniteMagnitude) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed number does not fit in \(type)"))
            }
            
            return Float(double) as? T
            
            // Int, Int8, Int16, Int32, Int64,
        // UInt, UInt8, UInt16, UInt32, UInt64
        case let integerType as IntegerRadixInitializable.Type:
            guard let intValue = integerType.init(value, radix: 10) else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            }
            return intValue as? T
            
        case is Date.Type:
            switch self.options.dateDecodingStrategy {
            case .deferredToDate:
                return try Date(from: self) as? T
            case .secondsSince1970:
                let double = try self.unbox(value, as: Double.self)!
                return Date(timeIntervalSince1970: double) as? T
            case .millisecondsSince1970:
                let double = try self.unbox(value, as: Double.self)!
                return Date(timeIntervalSince1970: double / 1000.0) as? T
            case .iso8601:
                if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                    guard let date = _iso8601Formatter.date(from: value) else {
                        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                    }
                    
                    return date as? T
                } else {
                    fatalError("ISO8601DateFormatter is unavailable on this platform.")
                }
            case .formatted(let formatter):
                guard let date = formatter.date(from: value) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Date string does not match format expected by formatter."))
                }
                
                return date as? T
            case .custom(let closure):
                return try closure(value) as? T
            }
            
        case is Data.Type:
            switch self.options.dataDecodingStrategy {
            case .deferredToData:
                return try Data(from: self) as? T
            case .base64:
                guard let data = Data(base64Encoded: value) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
                }
                return data as? T
            case .custom(let closure):
                return try closure(value) as? T
            }
            
        case is URL.Type:
            guard let urlString = try self.unbox(value, as: String.self) else {
                return nil
            }
            
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid URL string."))
            }
            
            return url as? T
            
        case is Decimal.Type:
            guard let decimal = Decimal(string: value) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid Decimal string."))
            }
            
            return decimal as? T
            
        default:
            return try T(from: self)
        }
    }
}

extension DecodingError {
    fileprivate static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: String) -> DecodingError {
        let description = "Expected to decode \(expectation) but found string type containing (\(reality.isEmpty ? "a nil value" : reality)) instead."
        return .typeMismatch(expectation, DecodingError.Context(codingPath: path, debugDescription: description))
    }
}

fileprivate protocol IntegerRadixInitializable {
    init?(_ value: String, radix: Int)
}

extension Int: IntegerRadixInitializable {}
extension Int8: IntegerRadixInitializable {}
extension Int16: IntegerRadixInitializable {}
extension Int32: IntegerRadixInitializable {}
extension Int64: IntegerRadixInitializable {}

extension UInt: IntegerRadixInitializable {}
extension UInt8: IntegerRadixInitializable {}
extension UInt16: IntegerRadixInitializable {}
extension UInt32: IntegerRadixInitializable {}
extension UInt64: IntegerRadixInitializable {}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
fileprivate var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
