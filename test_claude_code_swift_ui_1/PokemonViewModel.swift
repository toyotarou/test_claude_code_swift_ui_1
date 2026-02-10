//
//  PokemonViewModel.swift
//  test_claude_code_swift_ui_1
//
//  Created by Claude on 2026/02/10.
//

import Foundation
import Observation

@Observable
class PokemonViewModel {
    var pokemons: [Pokemon] = []
    var allPokemonByNum: [String: Pokemon] = [:]
    var isLoading = false
    var errorMessage: String?

    func fetchPokemons() async {
        isLoading = true
        errorMessage = nil

        do {
            let url = URL(string: "https://raw.githubusercontent.com/Biuni/PokemonGO-Pokedex/master/pokedex.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(PokemonResponse.self, from: data)
            allPokemonByNum = Dictionary(uniqueKeysWithValues: response.pokemon.map { ($0.num, $0) })
            pokemons = response.pokemon.filter { $0.prevEvolution == nil }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func evolutionChain(for pokemon: Pokemon) -> [Pokemon] {
        var chain = [pokemon]
        if let nextEvolution = pokemon.nextEvolution {
            for evo in nextEvolution {
                if let found = allPokemonByNum[evo.num] {
                    chain.append(found)
                }
            }
        }
        return chain
    }
}
