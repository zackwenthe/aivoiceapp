import Foundation
import Foundation
import OSLog

@Observable
@MainActor
final class ModelManager {
    enum DownloadState: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded
        case error(message: String)
        
        static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
            switch (lhs, rhs) {
            case (.notDownloaded, .notDownloaded):
                return true
            case (.downloading(let p1), .downloading(let p2)):
                return p1 == p2
            case (.downloaded, .downloaded):
                return true
            case (.error(let m1), .error(let m2)):
                return m1 == m2
            default:
                return false
            }
        }
    }
    
    var downloadStates: [String: DownloadState] = [:]
    var selectedModelID: String? {
        didSet {
            if let id = selectedModelID {
                UserDefaults.standard.set(id, forKey: UserDefaults.Keys.selectedLLMModel)
            }
        }
    }
    
    private let modelsDirectory: URL
    nonisolated private let downloadDelegate: ModelDownloadDelegate
    nonisolated private let urlSession: URLSession
    
    init() {
        // Set up models directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        modelsDirectory = appSupport.appendingPathComponent("Dictate/Models", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        
        // Set up download delegate (must be created before urlSession)
        let delegate = ModelDownloadDelegate()
        downloadDelegate = delegate
        
        // Configure URLSession with delegate
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // 5 minutes
        config.timeoutIntervalForResource = 3600 // 1 hour for large downloads
        urlSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        // Set the manager reference after initialization
        delegate.manager = self
        
        // Load saved selection
        selectedModelID = UserDefaults.standard.string(forKey: UserDefaults.Keys.selectedLLMModel)
        
        // Check which models are already downloaded
        updateDownloadStates()
    }
    
    private func updateDownloadStates() {
        for model in ModelInfo.availableModels {
            // MLX models are stored as directories containing multiple files
            let modelDirectory = modelsDirectory.appendingPathComponent(model.id)
            let isDownloaded = FileManager.default.fileExists(atPath: modelDirectory.path) &&
                               isModelComplete(at: modelDirectory)
            
            downloadStates[model.id] = isDownloaded ? .downloaded : .notDownloaded
        }
    }
    
    /// Check if a model directory contains all required files
    private func isModelComplete(at directory: URL) -> Bool {
        let requiredFiles = ["config.json", "tokenizer.json", "tokenizer_config.json"]
        let hasWeights = FileManager.default.fileExists(atPath: directory.appendingPathComponent("model.safetensors").path) ||
                        FileManager.default.fileExists(atPath: directory.appendingPathComponent("weights.safetensors").path)
        
        let hasRequiredFiles = requiredFiles.allSatisfy { filename in
            FileManager.default.fileExists(atPath: directory.appendingPathComponent(filename).path)
        }
        
        return hasWeights && hasRequiredFiles
    }
    
    func downloadModel(_ model: ModelInfo) async {
        downloadStates[model.id] = .downloading(progress: 0.0)
        
        // Create model directory
        let modelDirectory = modelsDirectory.appendingPathComponent(model.id)
        
        // If directory already exists, remove it before downloading
        if FileManager.default.fileExists(atPath: modelDirectory.path) {
            try? FileManager.default.removeItem(at: modelDirectory)
        }
        
        do {
            // Create model directory
            try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
            
            // MLX models require multiple files
            let requiredFiles = [
                "config.json",
                "tokenizer.json",
                "tokenizer_config.json",
                model.fileName, // weights file (typically model.safetensors or weights.safetensors)
            ]
            
            // Optional files that may exist for some models
            let optionalFiles = [
                "special_tokens_map.json",
                "tokenizer_config.json",
                "generation_config.json"
            ]
            
            Logger.app.info("Downloading MLX model: \(model.name) (\(requiredFiles.count) files)")
            
            // Download required files
            for (index, fileName) in requiredFiles.enumerated() {
                let fileURL = modelDirectory.appendingPathComponent(fileName)
                let downloadURL = "https://huggingface.co/\(model.huggingFaceRepo)/resolve/main/\(fileName)"
                
                guard let url = URL(string: downloadURL) else {
                    throw DictateError.modelDownloadFailed("Invalid URL for \(fileName)")
                }
                
                Logger.app.debug("Downloading \(fileName) from \(downloadURL)")
                
                // Download individual file
                try await downloadFile(from: url, to: fileURL, modelID: model.id, fileIndex: index, totalFiles: requiredFiles.count)
            }
            
            // Try to download optional files (don't fail if they don't exist)
            for fileName in optionalFiles {
                let fileURL = modelDirectory.appendingPathComponent(fileName)
                let downloadURL = "https://huggingface.co/\(model.huggingFaceRepo)/resolve/main/\(fileName)"
                
                if let url = URL(string: downloadURL) {
                    try? await downloadFile(from: url, to: fileURL, modelID: model.id, fileIndex: requiredFiles.count, totalFiles: requiredFiles.count, optional: true)
                }
            }
            
            downloadStates[model.id] = .downloaded
            Logger.app.info("Model downloaded successfully: \(model.name)")
            
        } catch let error as DictateError {
            // Clean up partial download
            try? FileManager.default.removeItem(at: modelDirectory)
            Logger.app.error("Download failed: \(error.localizedDescription)")
            downloadStates[model.id] = .error(message: error.localizedDescription)
        } catch is CancellationError {
            // Clean up on cancellation
            try? FileManager.default.removeItem(at: modelDirectory)
            Logger.app.info("Download cancelled: \(model.name)")
            downloadStates[model.id] = .notDownloaded
        } catch {
            // Clean up on any other error
            try? FileManager.default.removeItem(at: modelDirectory)
            Logger.app.error("Download failed: \(error.localizedDescription)")
            downloadStates[model.id] = .error(message: "Download failed: \(error.localizedDescription)")
        }
    }
    
    private func downloadFile(from url: URL, to destination: URL, modelID: String, fileIndex: Int, totalFiles: Int, optional: Bool = false) async throws {
        let (tempURL, response) = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(URL, URLResponse), Error>) in
                let task = urlSession.downloadTask(with: url) { location, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let location = location, let response = response else {
                        continuation.resume(throwing: DictateError.modelDownloadFailed("No response received"))
                        return
                    }
                    
                    continuation.resume(returning: (location, response))
                }
                
                downloadDelegate.registerTask(task, for: modelID)
                task.resume()
            }
        } onCancel: {
            downloadDelegate.cancelDownload(for: modelID)
        }
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictateError.modelDownloadFailed("Invalid response")
        }
        
        // For optional files, silently skip if not found (404)
        if optional && httpResponse.statusCode == 404 {
            Logger.app.debug("Optional file not found (skipping): \(url.lastPathComponent)")
            return
        }
        
        guard httpResponse.statusCode == 200 else {
            throw DictateError.modelDownloadFailed("HTTP error: \(httpResponse.statusCode) for \(url.lastPathComponent)")
        }
        
        // Move downloaded file to final destination
        try FileManager.default.moveItem(at: tempURL, to: destination)
        
        // Update overall progress based on completed files
        let overallProgress = Double(fileIndex + 1) / Double(totalFiles)
        downloadStates[modelID] = .downloading(progress: overallProgress)
    }
    
    func cancelDownload(_ model: ModelInfo) {
        // Cancel any ongoing download for this model
        downloadDelegate.cancelDownload(for: model.id)
        downloadStates[model.id] = .notDownloaded
        
        // Clean up partial downloads
        let modelDirectory = modelsDirectory.appendingPathComponent(model.id)
        try? FileManager.default.removeItem(at: modelDirectory)
        
        Logger.app.info("Download cancelled: \(model.name)")
    }
    
    func deleteModel(_ model: ModelInfo) {
        let modelDirectory = modelsDirectory.appendingPathComponent(model.id)
        
        do {
            try FileManager.default.removeItem(at: modelDirectory)
            downloadStates[model.id] = .notDownloaded
            
            // If this was the selected model, clear the selection
            if selectedModelID == model.id {
                selectedModelID = nil
            }
            
            Logger.app.info("Model deleted: \(model.name)")
        } catch {
            Logger.app.error("Failed to delete model: \(error.localizedDescription)")
        }
    }
    
    nonisolated func updateProgress(for modelID: String, progress: Double) {
        Task { @MainActor in
            downloadStates[modelID] = .downloading(progress: progress)
        }
    }
    
    func loadSelectedModel(into styler: TextStyler) async {
        guard let modelID = selectedModelID,
              let model = ModelInfo.availableModels.first(where: { $0.id == modelID }) else {
            Logger.app.warning("No model selected")
            return
        }
        
        // MLX models are stored as directories, pass the directory path
        let modelDirectory = modelsDirectory.appendingPathComponent(model.id)
        
        guard FileManager.default.fileExists(atPath: modelDirectory.path) else {
            Logger.app.error("Model directory not found at path: \(modelDirectory.path)")
            return
        }
        
        await styler.loadModel(from: modelDirectory.path)
        
        if styler.isReady {
            Logger.app.info("Model loaded: \(model.name)")
        } else {
            Logger.app.error("Failed to load model: \(model.name)")
        }
    }
}

// MARK: - Download Delegate

private final class ModelDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    weak var manager: ModelManager?
    private var downloadTasks: [URLSessionTask: String] = [:] // Map task to model ID
    private let lock = NSLock()
    
    override init() {
        super.init()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        lock.lock()
        guard let modelID = downloadTasks[downloadTask] else {
            lock.unlock()
            return
        }
        lock.unlock()
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        manager?.updateProgress(for: modelID, progress: progress)
        
        Logger.app.debug("Download progress for \(modelID): \(Int(progress * 100))%")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // This is handled by the async download method
        Logger.app.debug("Download finished to temporary location: \(location.path)")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        downloadTasks.removeValue(forKey: task)
        lock.unlock()
        
        if let error = error {
            Logger.app.error("Download task completed with error: \(error.localizedDescription)")
        }
    }
    
    func registerTask(_ task: URLSessionTask, for modelID: String) {
        lock.lock()
        downloadTasks[task] = modelID
        lock.unlock()
    }
    
    func cancelDownload(for modelID: String) {
        lock.lock()
        let tasksToCancel = downloadTasks.filter { $0.value == modelID }.map { $0.key }
        lock.unlock()
        
        for task in tasksToCancel {
            task.cancel()
        }
    }
}

