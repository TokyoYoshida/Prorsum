import Foundation
import Dispatch

private let _operationQ = createOperationQueue()

func swiftPanic(error: Error){
    fatalError("\(error)")
}

public func go(_ routine: @autoclosure @escaping (Void) -> Void){
    _go(routine)
}

public func go(_ routine: @escaping (Void) -> Void){
    _go(routine)
}

public func gomain(_ routine: @escaping (Void) -> Void){
    OperationQueue.main.addOperation(routine)
}

private func _go(_ routine: @escaping (Void) -> Void){
    let operation = BlockOperation()
    
    operation.addExecutionBlock {
        routine()
    }
    
    _operationQ.addOperation(operation)
}

public func runLoop(){
    RunLoop.main.run()
}

private func createOperationQueue() -> OperationQueue {
    let operationQ = OperationQueue()
    if let _maxProcs = ProcessInfo.processInfo.environment["PRORSUMMAXPROCS"], let maxProcs = Int(_maxProcs) {
        operationQ.maxConcurrentOperationCount = maxProcs
    }
    
    return operationQ
}
