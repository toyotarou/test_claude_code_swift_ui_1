//
//  ContentView.swift
//  test_claude_code_swift_ui_1
//
//  Created by 豊田英之 on 2026/02/10.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = PokemonViewModel()
    @State private var selectedPokemon: Pokemon?

    var body: some View {
        ZStack {
            NavigationStack {
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .tint(.white)
                            .foregroundStyle(.white)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Text(error)
                                .foregroundStyle(.red)
                            Button("Retry") {
                                Task {
                                    await viewModel.fetchPokemons()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.gray)
                        }
                    } else {
                        List(viewModel.pokemons) { pokemon in
                            PokemonRow(pokemon: pokemon)
                                .listRowBackground(Color(.systemGray6))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedPokemon = pokemon
                                    }
                                }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .navigationTitle("Pokedex")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
            .preferredColorScheme(.dark)
            .task {
                await viewModel.fetchPokemons()
            }

            // Dialog overlay
            if let pokemon = selectedPokemon {
                // Dimmed background - tap to dismiss
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedPokemon = nil
                        }
                    }

                // Dialog card
                EvolutionDialogView(
                    chain: viewModel.evolutionChain(for: pokemon)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
    }
}

// MARK: - List Row

struct PokemonRow: View {
    let pokemon: Pokemon

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: pokemon.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
                    .tint(.white)
            }
            .frame(width: 60, height: 60)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(pokemon.num)
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(pokemon.name)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Evolution Dialog View

struct EvolutionDialogView: View {
    let chain: [Pokemon]

    var body: some View {
        TabView {
            ForEach(chain) { pokemon in
                PokemonDetailPage(pokemon: pokemon)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.75)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }
}

// MARK: - Pokemon Detail Page

struct PokemonDetailPage: View {
    let pokemon: Pokemon

    var body: some View {
        VStack(spacing: 10) {
            // Image
            AsyncImage(url: pokemon.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
                    .tint(.white)
            }
            .frame(width: 120, height: 120)

            // Name & Number
            Text("#\(pokemon.num)")
                .font(.caption)
                .foregroundStyle(.gray)
            Text(pokemon.name)
                .font(.title2)
                .bold()
                .foregroundStyle(.white)

            // Type badges
            HStack(spacing: 8) {
                ForEach(pokemon.type, id: \.self) { type in
                    Text(type)
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(typeColor(type))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                StatCard(label: "Height", value: pokemon.height)
                StatCard(label: "Weight", value: pokemon.weight)
                StatCard(label: "Egg", value: pokemon.egg)
                StatCard(label: "Spawn Time", value: pokemon.spawnTime)
                StatCard(label: "Spawn Chance", value: String(format: "%.2f%%", pokemon.spawnChance))
                StatCard(label: "Avg Spawns", value: String(format: "%.0f", pokemon.avgSpawns))
            }
            .padding(.horizontal)

            // Candy
            if let candy = pokemon.candy {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.pink)
                        .font(.caption)
                    Text(candy)
                        .foregroundStyle(.white)
                    if let count = pokemon.candyCount {
                        Text("(\(count))")
                            .foregroundStyle(.gray)
                    }
                }
                .font(.caption)
            }

            // Weaknesses
            VStack(alignment: .leading, spacing: 6) {
                Text("Weaknesses")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.white)
                FlowLayout(spacing: 6) {
                    ForEach(pokemon.weaknesses, id: \.self) { weakness in
                        Text(weakness)
                            .font(.caption2)
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(typeColor(weakness).opacity(0.7))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top, 16)
    }

    func typeColor(_ type: String) -> Color {
        switch type {
        case "Grass": return .green
        case "Poison": return .purple
        case "Fire": return .orange
        case "Water": return .blue
        case "Bug": return Color(red: 0.6, green: 0.7, blue: 0.1)
        case "Normal": return .gray
        case "Electric": return .yellow
        case "Ground": return .brown
        case "Rock": return Color(red: 0.7, green: 0.6, blue: 0.4)
        case "Fairy": return .pink
        case "Fighting": return Color(red: 0.8, green: 0.2, blue: 0.2)
        case "Psychic": return Color(red: 1.0, green: 0.3, blue: 0.5)
        case "Ghost": return Color(red: 0.4, green: 0.3, blue: 0.6)
        case "Ice": return Color(red: 0.6, green: 0.85, blue: 0.9)
        case "Dragon": return Color(red: 0.4, green: 0.2, blue: 0.8)
        case "Flying": return Color(red: 0.5, green: 0.6, blue: 0.9)
        case "Steel": return Color(red: 0.6, green: 0.6, blue: 0.7)
        default: return .gray
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

#Preview {
    ContentView()
}
