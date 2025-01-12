//
//  SwiftLlamaAppApp.swift
//  SwiftLlamaApp
//
//  Created by Amit Samant on 12/01/25.
//

import SwiftUI
import LLaMAServer

class ServerProvider: ObservableObject {
    let server: LLaMAServer
    
    init() {
        self.server = LLaMAServer()
    }
}

enum ViewTypes: String, CaseIterable {
    var id: String { self.rawValue }
    case configurator
}

struct Sidebar: View {
    @Binding var selectedView: ViewTypes?
    
    var body: some View {
        List(ViewTypes.allCases, id: \.self, selection: $selectedView) { view in
            Text(view.rawValue.capitalized).tag(view)
        }
        .listStyle(.sidebar)
    }
}

@main
struct SwiftLlamaAppApp: App {
    @State var selectedView: ViewTypes? = .configurator
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                Sidebar(selectedView: $selectedView)
            } content: {
                ContentView()
                    .environmentObject(ServerProvider())
            } detail: {
                ConsoleView()
                    .navigationSplitViewColumnWidth(200)
            }
        }
    }
}

