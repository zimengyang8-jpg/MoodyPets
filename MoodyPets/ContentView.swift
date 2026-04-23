//
//  ContentView.swift
//  MoodyPets
//
//  Created by Zimeng Yang on 4/19/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var user = Auth.auth().currentUser
    
    var body: some View {
        Group {
            if user != nil {
                NavigationStack {
                    HomeView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            Auth.auth().addStateDidChangeListener { _, newUser in
                user = newUser
            }
        }
    }
}

#Preview {
    ContentView()
}
