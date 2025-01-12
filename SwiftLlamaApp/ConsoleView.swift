//
//  ConsoleView.swift
//  SwiftLlamaApp
//
//  Created by Amit Samant on 12/01/25.
//

import SwiftUI

struct ConsoleView: View {
    @ObservedObject var vm: OutputListener = OutputListener()
    var body: some View {
        GroupBox {
            ScrollView {
                ScrollViewReader { reader in
                    ForEach(vm.logs, id: \.description) { log in
                        GroupBox {
                            Text(log.composedMessage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .onChange(of: vm.logs) { oldValue, newValue in
                        if let last = vm.logs.last {
                            withAnimation {
                                reader.scrollTo(last.description, anchor: .bottom)
                                
                            }
                        }
                        
                    }
                }
                
            }
            .defaultScrollAnchor(.bottom)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ConsoleView()
}
