import SmokeHTTP1
import SmokeOperationsHTTP1Server
import Logging

struct IsuconContext {
    let logger: Logger
}

extension IsuconContext {
    struct OperationInput: Codable, OperationHTTP1InputProtocol, Validatable {
        func validate() throws {
            
        }
        
        static func compose(queryDecodableProvider: () throws -> String, pathDecodableProvider: () throws -> String, bodyDecodableProvider: () throws -> String, headersDecodableProvider: () throws -> String) throws -> IsuconContext.OperationInput {
            return .init()
        }
        
        typealias QueryType = String
        
        typealias PathType = String
        
        typealias BodyType = String
        
        typealias HeadersType = String
        
        
    }
    struct OperationOutput: Codable, OperationHTTP1OutputProtocol, Validatable {
        func validate() throws {
            
        }
        
        var bodyEncodable: String? { return nil }
        var additionalHeadersEncodable: String? { return nil }
        
        typealias BodyType = String
        
        typealias AdditionalHeadersType = String
        
        
    }
    func handleTheOperation(input: OperationInput) throws -> OperationOutput {
        return OperationOutput()
    }
}


import SmokeOperationsHTTP1
import SmokeOperations

enum MyApplicationErrors: String, CustomStringConvertible, Error {
    case unknownResource
    var description: String { String(describing: self) }
}

public enum MyOperations: String, Hashable, CustomStringConvertible, OperationIdentity {
    case theOperation = "TheOperation"

    public var description: String {
        return rawValue
    }

    public var operationPath: String {
        switch self {
        case .theOperation:
            return "/theOperation"
        }
    }
}

extension MyOperations {
    static func addToSmokeServer<SelectorType: SmokeHTTP1HandlerSelector>(selector: inout SelectorType)
            where SelectorType.ContextType == IsuconContext,
                  SelectorType.OperationIdentifer == MyOperations {
        
        let allowedErrorsForTheOperation: [(MyApplicationErrors, Int)] = [(.unknownResource, 404)]
        selector.addHandlerForOperationProvider(.theOperation, httpMethod: .GET,
                                                operationProvider: IsuconContext.handleTheOperation, allowedErrors: allowedErrorsForTheOperation)
    }
}

SmokeHTTP1Server.runAsOperationServer { (<#EventLoopGroup#>) -> SmokeServerStaticContextInitializer in
    <#code#>
}
