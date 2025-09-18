//
//  NetworkTestView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 15/09/2025.
//

import SwiftUI

struct NetworkTestView: View {
    @StateObject private var mistralService = MistralService()
    @State private var isRunningTest = false
    @State private var testResults = ""
    @State private var showResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Netwerk Diagnostiek")
                    .font(.title)
                    .padding()
                
                Text("Test of de Mistral AI API verbinding werkt en controleer voor quota problemen.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: runDiagnostics) {
                    HStack {
                        if isRunningTest {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isRunningTest ? "API verbinding testen..." : "Test Mistral API")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isRunningTest)
                .padding(.horizontal)
                
                if showResults {
                    ScrollView {
                        Text(testResults)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("API Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func runDiagnostics() {
        isRunningTest = true
        testResults = ""
        showResults = false
        
        Task {
            // Run simple connection test
            let result = await mistralService.performSimpleConnectionTest()
            
            await MainActor.run {
                testResults = """
                \(result.message)
                
                \(result.details)
                """
                showResults = true
                isRunningTest = false
            }
        }
    }
}

struct NetworkTestView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkTestView()
    }
}