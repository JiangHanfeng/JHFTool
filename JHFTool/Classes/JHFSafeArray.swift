//
//  JHFSafeArray.swift
//  JHFTool
//
//  Created by 蒋函锋 on 2024/1/23.
//

import Foundation

public class JHFSafeArray<Element> {
    fileprivate let queue = DispatchQueue(label: "com.JHFTool.JHFSafeArray", attributes: .concurrent)
    fileprivate var array: [Element] = []
    
    public init() {}
}

public extension JHFSafeArray {
    var all: [Element] {
        var results: [Element] = []
        queue.sync {
            results = array
        }
        return results
    }
    
    var first: Element? {
        var result: Element?
        queue.sync {
            result = array.first
        }
        return result
    }
    
    var last: Element? {
        var result: Element?
        queue.sync {
            result = array.last
        }
        return result
    }
    
    var count: Int {
        var result = 0
        queue.sync {
            result = array.count
        }
        return result
    }
    
    var isEmpty: Bool {
        return count == 0
    }
    
    var descrption: String {
        var result = ""
        queue.sync {
            result = array.description
        }
        return result
    }
}

// MARK: Read
public extension JHFSafeArray {
    func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        var result: Element?
        try queue.sync {
            result = try array.first(where: predicate)
        }
        return result
    }
    
    func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        var result: [Element] = []
        try queue.sync {
            result = try array.filter(isIncluded)
        }
        return result
    }
    
    func firstIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        var result: Int?
        try queue.sync {
            result = try array.firstIndex(where: predicate)
        }
        return result
    }
    
    func lastIndex(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        var result: Int?
        try queue.sync {
            result = try array.lastIndex(where: predicate)
        }
        return result
    }
    
    func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> [Element] {
        var result = [Element]()
        try queue.sync {
            result = try array.sorted(by: areInIncreasingOrder)
        }
        return result
    }
    
    @available(swift, deprecated: 4.1, renamed: "compactMap(_:)", message: "Please use compactMap(_:) for the case where closure returns an optional value")
    func flatMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        var result = [ElementOfResult]()
        try queue.sync {
            result = try array.flatMap(transform)
        }
        return result
    }
    
    func compactMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        var result = [ElementOfResult]()
        try queue.sync {
            result = try array.compactMap(transform)
        }
        return result
    }
    
    func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        var result: [T] = []
        try queue.sync {
            result = try array.map(transform)
        }
        return result
    }
    
    func forEach(_ body: (Element) throws -> Void) rethrows {
        try queue.sync {
            try array.forEach(body)
        }
    }
    
    func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        var result = false
        try queue.sync {
            result = try array.contains(where: predicate)
        }
        return result
    }
}

// MARK: Write
public extension JHFSafeArray {
    func append(_ newElement: Element, completion: ((_ newArray: [Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in            self?.array.append(newElement)
            var array = self?.array
            array == nil ? array = [] : nil
            DispatchQueue.main.async {
                completion?(array!)
            }
        }
    }
    
    func append(contentsOf: [Element], completion: ((_ newArray: [Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.array.append(contentsOf: contentsOf)
            var array = self?.array
            array == nil ? array = [] : nil
            DispatchQueue.main.async {
                completion?(array!)
            }
        }
    }
    
    func insert(_ newElement: Element, at index: Int, completion: ((_ newArray: [Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.array.insert(newElement, at: index)
            var array = self?.array
            array == nil ? array = [] : nil
            DispatchQueue.main.async {
                completion?(array!)
            }
        }
    }
    
    func insert(contentsOf: [Element], at index: Int, completion: ((_ newArray: [Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.array.insert(contentsOf: contentsOf, at: index)
            var array = self?.array
            array == nil ? array = [] : nil
            DispatchQueue.main.async {
                completion?(array!)
            }
        }
    }
    
    func remove(at index: Int, completion: ((Element?) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            let element = self?.array.remove(at: index)
            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }
    
    func remove(where predicate: @escaping (Element) -> Bool, completion: (([Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            var elements: [Element] = []
            var index = self?.array.firstIndex(where: predicate)
            while index != nil {
                if let element = self?.array[index!] {
                    elements.append(element)
                }
                self?.array.remove(at: index!)
                index = self?.array.firstIndex(where: predicate)
            }
            DispatchQueue.main.async {
                completion?(elements)
            }
        }
    }
    
    func removeAll(completion: (() -> Void)? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            self?.array.removeAll()
            completion?()
        }
    }
}

public extension JHFSafeArray {
    subscript(index: Int) -> Element? {
        get {
            var result: Element?
            queue.sync {
                guard array.count > index else {
                    fatalError("index of \(index) out of range 0..<\(array.count)")
                }
                result = array[index]
            }
            return result
        }
        
        set {
            guard let newValue else {
                return
            }
            queue.async(flags: .barrier) { [weak self] in
                self?.array[index] = newValue
            }
        }
    }
}

// MARK: for Equatable
public extension JHFSafeArray where Element: Equatable {
    func contains(_ element: Element) -> Bool {
        var result = false
        queue.sync {
            result = array.contains(element)
        }
        return result
    }
    
    func firstIndex(of element: Element) -> Int? {
        var result: Int?
        queue.sync {
            result = array.firstIndex(of: element)
        }
        return result
    }
}
