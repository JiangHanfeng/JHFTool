//
//  JHFCancelableTask.swift
//  JHFTool
//
//  Created by 蒋函锋 on 2024/1/24.
//

import Foundation

public class JHFCancelableTask : NSObject {
    public typealias Excutable = (_ isCanceled: Bool) -> ()
    
    @discardableResult public static func delay(_ time: TimeInterval, at queue: dispatch_queue_t, task: @escaping () -> ()) -> Excutable? {
        var closure: (() -> Void)? = task
        var result: Excutable?
        let delayClosure: Excutable = { isCancelled in
            defer {
                closure = nil
                result = nil
            }
            guard let closure, !isCancelled else {
                return
            }
            queue.async(execute: closure)
        }
        result = delayClosure
        queue.asyncAfter(deadline: .now() + time) {
            if let result {
                result(false)
            }
        }
        return result
    }
}
