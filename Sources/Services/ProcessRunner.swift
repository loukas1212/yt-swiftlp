// ProcessRunner and ProcessOutput are to launch and monitor the Process (YT-DLP)

import Foundation

struct ProcessOutput: Sendable {
    let status: Int32
    let output: String
    let errorText: String
}

enum ProcessRunner { // Run YT-DLP, Read stdout and stderr, waiting for end of execution

    static func run(
        executable: URL, 
        arguments: [String], 
        environment: [String: String]? = nil
    ) async throws -> ProcessOutput {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        if let environment { process.environment = environment }

        let stdout = Pipe()
        let stderr = Pipe()
        
        process.standardOutput = stdout
        process.standardError = stderr

        // Install/Create the Handler (Created before run(), so it never miss the Process() end)
        let (exitCodes, exitContinuation) = AsyncStream.makeStream(of: Int32.self)

        // The Handler to Terminate or see the Termination of the Process()
        process.terminationHandler = { finished in
            exitContinuation.yield(finished.terminationStatus)
            exitContinuation.finish() // Finish (Terminate) the Stream
        }

        do {
            try process.run()
        } catch {
            throw ToolError.launchFailed(error.localizedDescription)
        }

        // Never capture Process() or Pipe(), only FileHandle (Sendable) Type
        let outHandle = stdout.fileHandleForReading
        let errHandle = stderr.fileHandleForReading
        let outputTask = Task.detached { outHandle.readDataToEndOfFile() }
        let errorTask = Task.detached { errHandle.readDataToEndOfFile() }


        var status: Int32 = -1
        for await code in exitCodes { status = code }

        let output = String(decoding: await outputTask.value, as: UTF8.self) // Set "output" as the App Output
            .trimmingCharacters(in: .whitespacesAndNewlines) 
        let errorText = String(decoding: await errorTask.value, as: UTF8.self) // Set "errorText" as the potential App Error (stderr) output
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return ProcessOutput(status: status, output: output, errorText: errorText)
    }
}