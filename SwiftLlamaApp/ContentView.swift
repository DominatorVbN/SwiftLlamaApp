//
//  ContentView.swift
//  SwiftLlamaApp
//
//  Created by Amit Samant on 12/01/25.
//

import LLaMAServer
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    @EnvironmentObject var serverProvider: ServerProvider
    
    /// Number of threads to use during generation. Optional.
    @State private var threads: Int?
    
    /// Number of threads to use during batch and prompt processing. Optional.
    @State private var threadsBatch: Int?
    
    /// Number of threads in the HTTP server pool to process requests. Optional.
    @State private var threadsHTTP: Int?
    
    /// Specify a remote HTTP URL to download the model file. Optional.
    @State private var modelURL: String?
    
    /// Set an alias for the model. This alias will be returned in API responses. Optional.
    @State private var alias: String?
    
    /// Set the size of the prompt context. Defaults to 2048 for optimal performance.
    @State private var ctxSize: Int = 4096
    
    /// When compiled with appropriate support, this option allows offloading some layers to the GPU for computation. Optional.
    @State private var nGPULayers: Int?
    
    /// When using multiple GPUs, this controls which GPU is used for small tensors. Optional.
    @State private var mainGPU: Int?
    
    /// Controls how large tensors should be split across all GPUs. The split is a comma-separated list of values. Optional.
    @State private var tensorSplit: String?
    
    /// Set the batch size for prompt processing. Default is 512.
    @State private var batchSize: Int?
    
    /// Use 32-bit floats instead of 16-bit floats for memory key+value. Not recommended. Defaults to false.
    @State private var memoryF32: Bool = false
    
    /// Lock the model in memory, preventing it from being swapped out. Optional.
    @State private var mlock: Bool = false
    
    /// Do not memory-map the model. By default, models are mapped into memory. Optional.
    @State private var noMmap: Bool = false
    
    /// Attempt optimizations that help on some NUMA systems. Optional.
    @State private var numa: String?
    
    /// Apply a LoRA (Low-Rank Adaptation) adapter to the model. This allows adaptation of the pretrained model to specific tasks or domains. Optional.
    @State private var lora: String?
    
    /// Optional model to use as a base for the layers modified by the LoRA adapter. Used in conjunction with the `--lora` flag. Optional.
    @State private var loraBase: String?
    
    /// Server read/write timeout in seconds. Defaults to 600.
    @State private var timeout: Int = 600
    
    /// Set the hostname or IP address to listen on. Default is `127.0.0.1`.
    @State private var host: String?
    
    /// Set the port to listen on. Default is 8080.
    @State private var port: Int = 8080
    
    /// Path from which to serve static files. Optional.
    @State private var path: String?
    
    /// Set API keys for request authorization. Requests must have the Authorization header set with the API key as a Bearer token. Optional.
    @State private var apiKey: [String]?
    
    /// Path to a file containing API keys delimited by new lines. Requests must include one of the keys for access. Optional.
    @State private var apiKeyFile: String?
    
    /// Enable embedding extraction. Defaults to disabled.
    @State private var embedding: Bool = false
    
    /// Set the number of slots for process requests. Default is 1.
    @State private var parallel: Int?
    
    /// Enable continuous batching (a.k.a dynamic batching). Defaults to disabled.
    @State private var contBatching: Bool = false
    
    /// Set a file to load "a system prompt" (initial prompt of all slots), useful for chat applications. Optional.
    @State private var systemPromptFile: String?
    
    /// Path to a multimodal projector file for LLaVA. Optional.
    @State private var mmproj: String?
    
    /// Set the group attention factor to extend context size through self-extend. Optional.
    @State private var grpAttnN: Int?
    
    /// Set the group attention width to extend context size through self-extend. Optional.
    @State private var grpAttnW: Int?
    
    /// Set the maximum tokens to predict. Optional.
    @State private var nPredict: Int?
    
    /// To disable slots state monitoring endpoint. Slots state may contain user data, including prompts. Defaults to false.
    @State private var slotsEndpointDisable: Bool = false
    
    /// Enable Prometheus `/metrics` compatible endpoint. Defaults to disabled.
    @State private var metrics: Bool = false
    
    /// Set a custom Jinja chat template. This parameter accepts a string, not a file name. Optional.
    @State private var chatTemplate: String?
    
    /// Output logs to stdout only. By default, logs are enabled. Optional.
    @State private var logDisable: Bool = false
    
    /// Define the log output format: json or text. Default is json. Optional.
    @State private var logFormat: String?
    
    @State private var isFilePickerPresented: Bool = false
    @State private var modelFileURL: URL?
    
    @State private var isAlertPresented: Bool = false
    @State private var alertMessage: String?
    
    @State private var isServerRunning: Bool = false
    
    @State private var isSectionExpanded: Bool = false
    
    var body: some View {
        ScrollView {
            Form {
                LabeledContent("Selected Model") {
                    HStack {
                        if let modelFileURL {
                            Text("\(modelFileURL.lastPathComponent)")
                        }
                        Button("Select GGUF Model") {
                            isFilePickerPresented = true
                        }
                    }
                    .fileImporter(isPresented: $isFilePickerPresented, allowedContentTypes: [UTType(importedAs: "gguf")]) { result in
                        switch result {
                        case .success(let success):
                            self.modelFileURL = success
                        case .failure(let failure):
                            self.alertMessage = failure.localizedDescription
                            self.isAlertPresented = true
                        }
                    }
                }
                
                DisclosureGroup("More settings", isExpanded: $isSectionExpanded) {
                    Form {
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Threads", value: $threads, format: .number)
                                    .labelsHidden()
                                Text("Number of threads to use during generation.").font(.caption2)
                            }
                        } label: {
                            Text("Thread (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Threads Batch", value: $threadsBatch, format: .number)
                                    .labelsHidden()
                                Text("Number of threads to use during batch and prompt processing.").font(.caption2)
                            }
                        } label: {
                            Text("Threads Batch (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Threads HTTP", value: $threadsHTTP, format: .number)
                                    .labelsHidden()
                                Text("Number of threads in the HTTP server pool to process requests.").font(.caption2)
                            }
                        } label: {
                            Text("Threads HTTP (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Model URL", text: $modelURL.bound)
                                    .labelsHidden()
                                Text("Specify a remote HTTP URL to download the model file.").font(.caption2)
                            }
                        } label: {
                            Text("Model URL (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Alias", text: $alias.bound)
                                    .labelsHidden()
                                Text("Set an alias for the model. This alias will be returned in API responses.").font(.caption2)
                            }
                        } label: {
                            Text("Alias (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Context Size", value: $ctxSize, format: .number)
                                    .labelsHidden()
                                Text("Set the size of the prompt context. Defaults to 2048 for optimal performance.").font(.caption2)
                            }
                        } label: {
                            Text("Context Size")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("GPU Layers", value: $nGPULayers, format: .number)
                                    .labelsHidden()
                                Text("Allows offloading some layers to the GPU for computation.").font(.caption2)
                            }
                        } label: {
                            Text("GPU Layers (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Main GPU", value: $mainGPU, format: .number)
                                    .labelsHidden()
                                Text("Controls which GPU is used for small tensors.").font(.caption2)
                            }
                        } label: {
                            Text("Main GPU (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Tensor Split", text: $tensorSplit.bound)
                                    .labelsHidden()
                                Text("Controls how large tensors should be split across all GPUs.").font(.caption2)
                            }
                        } label: {
                            Text("Tensor Split (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Batch Size", value: $batchSize, format: .number)
                                    .labelsHidden()
                                Text("Set the batch size for prompt processing. Default is 512.").font(.caption2)
                            }
                        } label: {
                            Text("Batch Size (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                Toggle("Memory F32", isOn: $memoryF32)
                                    .labelsHidden()
                                Text("Use 32-bit floats instead of 16-bit floats for memory key+value. Not recommended.").font(.caption2)
                            }
                        } label: {
                            Text("Memory F32")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                Toggle("Mlock", isOn: $mlock)
                                    .labelsHidden()
                                Text("Lock the model in memory, preventing it from being swapped out.").font(.caption2)
                            }
                        } label: {
                            Text("Mlock (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                Toggle("No Mmap", isOn: $noMmap)
                                    .labelsHidden()
                                Text("Do not memory-map the model. By default, models are mapped into memory.").font(.caption2)
                            }
                        } label: {
                            Text("No Mmap (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("NUMA", text: $numa.bound)
                                    .labelsHidden()
                                Text("Attempt optimizations that help on some NUMA systems.").font(.caption2)
                            }
                        } label: {
                            Text("NUMA (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("LoRA", text: $lora.bound)
                                    .labelsHidden()
                                Text("Apply a LoRA (Low-Rank Adaptation) adapter to the model.").font(.caption2)
                            }
                        } label: {
                            Text("LoRA (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("LoRA Base", text: $loraBase.bound)
                                    .labelsHidden()
                                Text("Optional model to use as a base for the layers modified by the LoRA adapter.").font(.caption2)
                            }
                        } label: {
                            Text("LoRA Base (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Timeout", value: $timeout, format: .number)
                                    .labelsHidden()
                                Text("Server read/write timeout in seconds. Defaults to 600.").font(.caption2)
                            }
                        } label: {
                            Text("Timeout")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Host", text: $host.bound)
                                    .labelsHidden()
                                Text("Set the hostname or IP address to listen on. Default is `127.0.0.1`.").font(.caption2)
                            }
                        } label: {
                            Text("Host (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Port", value: $port, format: .number)
                                    .labelsHidden()
                                Text("Set the port to listen on. Default is 8080.").font(.caption2)
                            }
                        } label: {
                            Text("Port")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Path", text: $path.bound)
                                    .labelsHidden()
                                Text("Path from which to serve static files.").font(.caption2)
                            }
                        } label: {
                            Text("Path (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("API Key", text: $apiKey.bound)
                                    .labelsHidden()
                                Text("Set API keys comma saperated for request authorization. Requests must have the Authorization header set with the API key as a Bearer token.").font(.caption2)
                            }
                        } label: {
                            Text("API Key (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("API Key File", text: $apiKeyFile.bound)
                                    .labelsHidden()
                                Text("Path to a file containing API keys delimited by new lines. Requests must include one of the keys for access.").font(.caption2)
                            }
                        } label: {
                            Text("API Key File (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                Toggle("Embedding", isOn: $embedding)
                                    .labelsHidden()
                                Text("Enable embedding extraction. Defaults to disabled.").font(.caption2)
                            }
                        } label: {
                            Text("Embedding")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Parallel", value: $parallel, format: .number)
                                    .labelsHidden()
                                Text("Set the number of slots for process requests. Default is 1.").font(.caption2)
                            }
                        } label: {
                            Text("Parallel (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                Toggle("Continuous Batching", isOn: $contBatching)
                                    .labelsHidden()
                                Text("Enable continuous batching (a.k.a dynamic batching). Defaults to disabled.").font(.caption2)
                            }
                        } label: {
                            Text("Continuous Batching")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("System Prompt File", text: $systemPromptFile.bound)
                                    .labelsHidden()
                                Text("Set a file to load 'a system prompt' (initial prompt of all slots), useful for chat applications.").font(.caption2)
                            }
                        } label: {
                            Text("System Prompt File (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Multimodal Projector File", text: $mmproj.bound)
                                    .labelsHidden()
                                Text("Path to a multimodal projector file for LLaVA.").font(.caption2)
                            }
                        } label: {
                            Text("Multimodal Projector File (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Group Attention Factor", value: $grpAttnN, format: .number)
                                    .labelsHidden()
                                Text("Set the group attention factor to extend context size through self-extend.").font(.caption2)
                            }
                        } label: {
                            Text("Group Attention Factor (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Group Attention Width", value: $grpAttnW, format: .number)
                                    .labelsHidden()
                                Text("Set the group attention width to extend context size through self-extend.").font(.caption2)
                            }
                        } label: {
                            Text("Group Attention Width (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Max Tokens to Predict", value: $nPredict, format: .number)
                                    .labelsHidden()
                                Text("Set the maximum tokens to predict.").font(.caption2)
                            }
                        } label: {
                            Text("Max Tokens to Predict (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                Toggle("Disable Slots Endpoint", isOn: $slotsEndpointDisable)
                                    .labelsHidden()
                                Text("To disable slots state monitoring endpoint. Slots state may contain user data, including prompts.").font(.caption2)
                            }
                        } label: {
                            Text("Disable Slots Endpoint")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                Toggle("Enable Metrics", isOn: $metrics)
                                    .labelsHidden()
                                Text("Enable Prometheus `/metrics` compatible endpoint. Defaults to disabled.").font(.caption2)
                            }
                        } label: {
                            Text("Enable Metrics")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Chat Template", text: $chatTemplate.bound)
                                    .labelsHidden()
                                Text("Set a custom Jinja chat template. This parameter accepts a string, not a file name.").font(.caption2)
                            }
                        } label: {
                            Text("Chat Template (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                Toggle("Disable Logs", isOn: $logDisable)
                                    .labelsHidden()
                                Text("Output logs to stdout only. By default, logs are enabled.").font(.caption2)
                            }
                        } label: {
                            Text("Disable Logs (Optional)")
                        }
                        
                        LabeledContent {
                            VStack(alignment: .leading) {
                                TextField("Log Format", text: $logFormat.bound)
                                    .labelsHidden()
                                Text("Define the log output format: json or text. Default is json.").font(.caption2)
                            }
                        } label: {
                            Text("Log Format (Optional)")
                        }
                    }
                }
                if isServerRunning {
                    Button("Stop server") {
                        serverProvider.server.stopServer()
                    }
                }
                Button(isServerRunning ? "Re-start LLAMA Server" : "Start LLAMA server") {
                    startServer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(modelFileURL == nil)
            }
            .padding()
        }
        .frame(maxWidth: 500, alignment: .leading)
        .alert(self.alertMessage ?? "Error", isPresented: $isAlertPresented) {
            Button("OK", role: .cancel) { }
        }
        .navigationTitle("SwiftLlama")
        .onAppear(perform: pollServerStatus)
    }
    
    func startServer() {
        guard let modelFileURL else { return }
        _ = modelFileURL.startAccessingSecurityScopedResource()
        let serverConfig = ServerConfig(
            modelPath: modelFileURL.path(),
            threads: threads,
            threadsBatch: threadsBatch,
            threadsHTTP: threadsHTTP,
            modelURL: modelURL,
            alias: alias,
            ctxSize: ctxSize,
            nGPULayers: nGPULayers,
            mainGPU: mainGPU,
            tensorSplit: tensorSplit,
            batchSize: batchSize,
            memoryF32: memoryF32,
            mlock: mlock,
            noMmap: noMmap,
            numa: numa,
            lora: lora,
            loraBase: loraBase,
            timeout: timeout,
            host: host,
            port: port,
            path: path,
            apiKey: apiKey,
            apiKeyFile: apiKeyFile,
            embedding: embedding,
            parallel: parallel,
            contBatching: contBatching,
            systemPromptFile: systemPromptFile,
            mmproj: mmproj,
            grpAttnN: grpAttnN,
            grpAttnW: grpAttnW,
            nPredict: nPredict,
            slotsEndpointDisable: slotsEndpointDisable,
            metrics: metrics,
            chatTemplate: chatTemplate,
            logDisable: logDisable,
            logFormat: logFormat
        )
        let config = LLaMAConfig(serverConfig: serverConfig)
        do {
            if serverProvider.server.isServerRunning {
                try serverProvider.server.restartServer(with: config)
            } else {
                try serverProvider.server.startServer(with: config)
            }
        } catch {
            self.alertMessage = error.localizedDescription
            self.isAlertPresented = true
        }
    }
    
    func pollServerStatus() {
        Task {
            while true {
                try? await Task.sleep(for: .seconds(1))
                isServerRunning = serverProvider.server.isServerRunning
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 300)
}

extension Binding where Value == String? {
    var bound: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

extension Binding where Value == [String]? {
    var bound: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue?.joined(separator: ", ") ?? "" },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0.components(separatedBy: ", ") }
        )
    }
}
