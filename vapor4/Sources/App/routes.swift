import Vapor
import NIO
import MySQLKit
import Foundation

let initSh = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent() // App
    .deletingLastPathComponent() // Sources
    .deletingLastPathComponent() // vapor4
    .appendingPathComponent("isucon8-qualify")
    .appendingPathComponent("db")
    .appendingPathComponent("init.sh")

extension Process {
    @discardableResult
    static func exec(launchPath: String, arguments: [String]) async -> Int32 {
        return await withUnsafeContinuation { continuation in
            let initProcess = Process.launchedProcess(launchPath: initSh.path, arguments: [])
            initProcess.terminationHandler = { process in
                continuation.resume(returning: process.terminationStatus)
            }
        }
    }
}

func bootstrapDatabaseConnection(on eventLoopGroup: EventLoopGroup)
-> EventLoopGroupConnectionPool<MySQLConnectionSource> {
    let envs = ProcessInfo.processInfo.environment
    let configuration = MySQLConfiguration(
        hostname: envs["DB_HOST"]!,
        port: Int(envs["DB_PORT"]!)!,
        username: envs["DB_USER"]!,
        password: envs["DB_PASS"]!,
        database: envs["DB_DATABASE"]
    )
    let pools = EventLoopGroupConnectionPool(
        source: MySQLConnectionSource(configuration: configuration),
        on: eventLoopGroup
    )
    return pools
}

extension EventLoopGroupConnectionPool {
    public func withConnection<Result>(
        logger: Logger? = nil,
        on eventLoop: EventLoop? = nil,
        _ closure: @escaping (Source.Connection) async throws -> Result
    ) async throws -> Result {
        let future: EventLoopFuture<Result> = self.withConnection(logger: logger, on: eventLoop) { connection in
            let promise = connection.eventLoop.makePromise(of: Result.self)
            promise.completeWithAsync {
                try await closure(connection)
            }
            return promise.futureResult
        }
        return try await future.get()
    }
}

func routes(_ app: Application) throws {
    let pools = bootstrapDatabaseConnection(on: app.eventLoopGroup)
    defer { pools.shutdown() }

    // Serve "Public" directory
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.get("/") { req -> String in
        let events = try await pools.withConnection { conn in
            try await Database(connection: conn).getEvents(all: false)
        }
        return try renderIndexHtml(events: events, user: "user info")
    }
    app.post("/initialize") { _ async -> HTTPResponseStatus in
        await Process.exec(launchPath: initSh.path, arguments: [])
        return .ok
    }
}


