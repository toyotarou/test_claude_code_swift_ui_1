//
//  Pokemon.swift
//  test_claude_code_swift_ui_1
//
//  Created by Claude on 2026/02/10.
//

import Foundation

struct PokemonEvolution: Codable, Sendable {
    let num: String
    let name: String
}

struct Pokemon: Codable, Identifiable, Sendable {
    let id: Int
    let num: String
    let name: String
    let img: String
    let type: [String]
    let height: String
    let weight: String
    let candy: String?
    let candyCount: Int?
    let egg: String
    let spawnChance: Double
    let avgSpawns: Double
    let spawnTime: String
    let multipliers: [Double]?
    let weaknesses: [String]
    let prevEvolution: [PokemonEvolution]?
    let nextEvolution: [PokemonEvolution]?

    enum CodingKeys: String, CodingKey {
        case id, num, name, img, type, height, weight, candy, egg, weaknesses, multipliers
        case candyCount = "candy_count"
        case spawnChance = "spawn_chance"
        case avgSpawns = "avg_spawns"
        case spawnTime = "spawn_time"
        case prevEvolution = "prev_evolution"
        case nextEvolution = "next_evolution"
    }

    var imageURL: URL? {
        URL(string: img.replacingOccurrences(of: "http://", with: "https://"))
    }
}

struct PokemonResponse: Codable, Sendable {
    let pokemon: [Pokemon]
}
