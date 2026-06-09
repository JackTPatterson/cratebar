import Foundation

struct ProcessResult {
    let exitCode: Int32
    let output: String
}

enum ProcessRunner {
    /// Run an executable to completion, streaming combined stdout/stderr lines to `onLine`.
    /// Returns the exit code and the full captured output.
    @discardableResult
    static func run(
        _ executable: String,
        _ arguments: [String],
        onLine: (@Sendable (String) -> Void)? = nil
    ) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            let collected = OutputBox()
            let handle = pipe.fileHandleForReading
            handle.readabilityHandler = { fh in
                let data = fh.availableData
                guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
                collected.append(chunk)
                if let onLine {
                    chunk.split(whereSeparator: { $0 == "\n" || $0 == "\r" })
                        .forEach { onLine(String($0)) }
                }
            }

            process.terminationHandler = { proc in
                handle.readabilityHandler = nil
                // Drain anything left in the pipe.
                let remaining = handle.readDataToEndOfFile()
                if !remaining.isEmpty, let s = String(data: remaining, encoding: .utf8) {
                    collected.append(s)
                }
                continuation.resume(returning: ProcessResult(
                    exitCode: proc.terminationStatus,
                    output: collected.value
                ))
            }

            do {
                try process.run()
            } catch {
                handle.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}

/// Thread-safe accumulator for streamed process output.
private final class OutputBox: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""

    func append(_ s: String) {
        lock.lock(); defer { lock.unlock() }
        buffer += s
    }

    var value: String {
        lock.lock(); defer { lock.unlock() }
        return buffer
    }
}
