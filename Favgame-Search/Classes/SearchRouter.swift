//
//  SearchRouter.swift
//  Favgame
//
//  Created by deri indrawan on 01/01/23.
//

import Foundation
import Favgame_Core

public class SearchRouter {
  let container: Container = {
    let container = Injection().container
    
    container.register(SearchViewController.self) { resolver in
      let controller = SearchViewController()
      controller.searchGameUseCase = resolver.resolve(SearchGameUseCase.self)
      return controller
    }
    return container
  }()
}
