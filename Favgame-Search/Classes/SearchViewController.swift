//
//  SearchViewController.swift
//  Favgame
//
//  Created by deri indrawan on 29/12/22.
//

import UIKit
import Combine
import SkeletonView

class SearchViewController: UIViewController {
  
  // MARK: - Properties
  var searchGameUseCase: SearchGameUseCase?
  private var cancellables: Set<AnyCancellable> = []
  private var gameList: [Game]?
  
  private let searchTextField: UITextField = {
    let textField = UITextField()
    textField.placeholder = "Find your favorite game..."
    textField.backgroundColor = UIColor(rgb: Constant.twilightColor)
    textField.layer.borderWidth = 2
    textField.layer.borderColor = UIColor(rgb: Constant.rumColor).cgColor
    textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
    textField.leftViewMode = .always
    textField.keyboardType = .default
    textField.autocorrectionType = .no
    textField.autocapitalizationType = .none
    return textField
  }()
  
  private let searchButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
    button.backgroundColor = UIColor(rgb: Constant.eastBayColor)
    button.tintColor = UIColor(rgb: Constant.twilightColor)
    button.layer.borderColor = UIColor(rgb: Constant.rumColor).cgColor
    button.layer.borderWidth = 2
    button.layer.cornerRadius = 8
    return button
  }()
  
  private let searchTableView: UITableView = {
    let table = UITableView(frame: .zero, style: .plain)
    table.backgroundColor = UIColor(rgb: Constant.rhinoColor)
    table.isSkeletonable = true
    table.showsVerticalScrollIndicator = false
    table.register(GameTableViewCell.self, forCellReuseIdentifier: GameTableViewCell.identifier)
    return table
  }()
  
  // MARK: - Life Cycle
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.tabBarController?.tabBar.isHidden = false
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(rgb: Constant.rhinoColor)
    navigationItem.title = "Search"
    let textAttributes = [
      NSAttributedString.Key.foregroundColor: UIColor.white,
      NSAttributedString.Key.font: Constant.fontBold
    ]
    navigationController?.navigationBar.titleTextAttributes = textAttributes
    navigationController?.navigationBar.tintColor = UIColor(rgb: Constant.rhinoColor)
    setupUI()
  }
  
  // MARK: - Selector
  @objc private func searchButtonTapped() {
    let alert = UIAlertController(title: "Alert", message: "Keyword must contain at least three characters.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
    
    if let query = searchTextField.text?.replacingOccurrences(of: " ", with: "") {
      if query.trimmingCharacters(in: .whitespaces).count >= 3 {
        searchGame(with: query)
      } else {
        self.present(alert, animated: true)
      }
    } else {
      self.present(alert, animated: true)
    }
  }
  
  // MARK: - Helper
  private func setupUI() {
    view.addSubview(searchTextField)
    searchTextField.anchor(
      top: view.safeAreaLayoutGuide.topAnchor,
      leading: view.leadingAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      height: 60
    )
    
    view.addSubview(searchButton)
    searchButton.anchor(
      top: view.safeAreaLayoutGuide.topAnchor,
      leading: searchTextField.trailingAnchor,
      trailing: view.trailingAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      paddingRight: 8,
      width: 60,
      height: 60
    )
    searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    
    view.addSubview(searchTableView)
    searchTableView.anchor(
      top: searchTextField.bottomAnchor,
      leading: view.leadingAnchor,
      bottom: view.safeAreaLayoutGuide.bottomAnchor,
      trailing: view.trailingAnchor,
      paddingTop: 8,
      paddingLeft: 8,
      paddingRight: 8
    )
    searchTableView.dataSource = self
    searchTableView.delegate = self
  }
  
  private func searchGame(with query: String) {
    searchTableView.showSkeleton(usingColor: .gray, transition: .crossDissolve(0.25))
    searchGameUseCase?.execute(with: query)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure:
          let alert = UIAlertController(title: "Alert", message: String(describing: completion), preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          self.present(alert, animated: true)
        case .finished:
          self.searchTableView.backgroundView = nil
          self.searchTableView.hideSkeleton(reloadDataAfter: true)
        }
      }, receiveValue: { [weak self] gameList in
        self?.gameList = gameList
      })
      .store(in: &cancellables)
  }
  
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if ((gameList?.isEmpty) != false) {
      let message = "This page is empty.\nFind your favorite game."
      self.searchTableView.setEmptyMessage(message)
    } else {
      self.searchTableView.restore()
    }
    return gameList?.count ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: GameTableViewCell.identifier, for: indexPath) as? GameTableViewCell else {
      return UITableViewCell()
    }
    cell.layer.cornerRadius = 8
    
    guard let result = gameList else {
      return UITableViewCell()
    }
    let game = result[indexPath.row]
    cell.configure(with: game)
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 120
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let game = gameList else { return }
    let selectedGameId = game[indexPath.row].id
    
    let detailVC = Injection().container.resolve(DetailViewController.self)
    guard let detailVC = detailVC else { return }
    detailVC.configure(withGameId: selectedGameId)
    
    let nav = UINavigationController(rootViewController: detailVC)
    nav.modalPresentationStyle = .fullScreen
    
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(rgb: Constant.rhinoColor)
    nav.navigationBar.standardAppearance = appearance
    nav.navigationBar.scrollEdgeAppearance = nav.navigationBar.standardAppearance
    nav.navigationBar.tintColor = .white
    present(nav, animated: true)
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let verticalPadding: CGFloat = 8
    
    let maskLayer = CALayer()
    maskLayer.cornerRadius = 8
    maskLayer.backgroundColor = UIColor.black.cgColor
    maskLayer.frame = CGRect(x: cell.bounds.origin.x, y: cell.bounds.origin.y, width: cell.bounds.width, height: cell.bounds.height).insetBy(dx: 0, dy: verticalPadding/2)
    cell.layer.mask = maskLayer
  }
}
