//
//  ContentView.swift
//  TaskGroups
//
//  Created by William Finnis on 03/08/2021.
//

import SwiftUI

struct Message: Decodable {
    let id: Int
    let from: String
    let message: String
}

struct User {
    let username: String
    let favorites: Set<Int>
    let messages: [Message]
}

enum FetchResult {
    case username(String)
    case favorites(Set<Int>)
    case messages([Message])
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .task(loadUser)
    }
    
    func loadUser() async {
        let user = await withThrowingTaskGroup(of: FetchResult.self) { group -> User in
            group.addTask {
                let url = URL(string: "https://hws.dev/username.json")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = String(decoding: data, as: UTF8.self)
                return .username(result)
            }
            
            group.addTask {
                let url = URL(string: "https://hws.dev/user-favorites.json")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode(Set<Int>.self, from: data)
                return .favorites(result)
            }
            
            group.addTask {
                let url = URL(string: "https://hws.dev/user-messages.json")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode([Message].self, from: data)
                return .messages(result)
            }
            
            var username = "Anonymous"
            var favorites = Set<Int>()
            var messages = [Message]()
            
            do {
                for try await value in group {
                    switch value {
                    case .username(let value):
                        username = value
                    case .favorites(let value):
                        favorites = value
                    case .messages(let value):
                        messages = value
                    }
                }
            } catch {
                print("Fetch at least partially failed; sending back what we have so far. \(error.localizedDescription)")
            }
            
            return User(username: username, favorites: favorites, messages: messages)
        }
        
        print("User \(user.username) has \(user.messages.count) messages and \(user.favorites.count) favorites.")
    }
}
