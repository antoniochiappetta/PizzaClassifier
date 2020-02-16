//
//  PizzTypes.swift
//  PizzaClassifier
//
//  Created by Antonio Chiappetta on 12/02/2020.
//  Copyright © 2020 Antonio Chiappetta. All rights reserved.
//

import Vision

enum PizzaType: String {
    
    // MARK: - Cases
    
    case margherita = "margherita"
    case marinara = "marinara"
    case diavola = "diavola"
    case capricciosa = "capricciosa"
    case quattroFormaggi = "quattro-formaggi"
    
    // MARK: - Initialization
    
    init(withObservation observation: VNClassificationObservation) {
        self = PizzaType(rawValue: observation.identifier)!
    }
    
    // MARK: - Ingredients
    
    func getIngredients() -> Set<Ingredient> {
        switch self {
        case .margherita:
            return [Ingredient.tomato, Ingredient.mozzarella, Ingredient.basil]
        case .marinara:
            return [Ingredient.tomato, Ingredient.origan, Ingredient.garlic]
        case .diavola:
            return [Ingredient.tomato, Ingredient.mozzarella, Ingredient.salame]
        case .capricciosa:
            return [Ingredient.tomato, Ingredient.mozzarella, Ingredient.artichokes, Ingredient.olives, Ingredient.Ham, Ingredient.Mushrooms]
        case .quattroFormaggi:
            return [Ingredient.mozzarella, Ingredient.parmeasan, Ingredient.blueCheese, Ingredient.provola]
        }
    }
    
}
