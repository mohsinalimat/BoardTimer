//
//  ViewController.swift
//  BoardTimer
//
//  Created by Tiago Maia Lopes on 11/10/17.
//  Copyright © 2017 Tiago Maia Lopes. All rights reserved.
//

import UIKit

struct NotificationName {
  static let restartTimer = Notification.Name("restart_timer")
  static let newTimer = Notification.Name("new_timer")
}

class ViewController: UIViewController {

  // MARK: Properties
  
  let optionsSegueId = "show_options"
  
  @IBOutlet weak var blackWrapperView: XibView!
  @IBOutlet weak var whiteWrapperView: XibView!
  weak var blackTimerView: SingleTimerView!
  weak var whiteTimerView: SingleTimerView!
  var currentPlayerView: SingleTimerView {
    get {
      if playerManager.currentPlayer.color == .white {
        return whiteTimerView
      } else {
        return blackTimerView
      }
    }
  }
  
  @IBOutlet private var blackTimerDefaultHeight: NSLayoutConstraint!
  private var blackTimerIncreasedHeight: NSLayoutConstraint!
  private var blackTimerDecreasedHeight: NSLayoutConstraint!
  
  @IBOutlet var passGesture: UITapGestureRecognizer!
  private var playerManager: PlayerManager!
  
  // MARK: Life Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupManagers()
    setupObservers()
    setupTimerViews()
    refreshTimerViews()
  }
  
  // MARK: Setup
  
  func setupManagers(with configuration: TimerConfiguration? = nil) {
    // TODO: Determine the default timer.
    let configuration = configuration ?? TimerConfiguration.getDefaultConfigurations()[0]
    
    let timer = TimerManager()
    timer.delegate = self
    
    let whitePlayer = Player(color: .white,
                             configuration: configuration)
    let blackPlayer = Player(color: .black,
                             configuration: configuration)
    
    playerManager = PlayerManager(timer: timer,
                                  white: whitePlayer,
                                  black: blackPlayer)
    playerManager.delegate = self
  }
  
  func setupObservers() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(restartRequested(notification:)),
                                           name: NotificationName.restartTimer,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(newTimerRequested(notification:)),
                                           name: NotificationName.newTimer,
                                           object: nil)
  }
  
  func setupTimerViews() {
    blackTimerView = blackWrapperView.contentView as! SingleTimerView
    whiteTimerView = whiteWrapperView.contentView as! SingleTimerView
    
    blackTimerView.theme = .black
    whiteTimerView.theme = .white
    
    blackTimerView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
    
    blackTimerIncreasedHeight = blackTimerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8)
    blackTimerDecreasedHeight = blackTimerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2)
  }
  
  // MARK: Imperatives
  
  func animatePlayerChange() {
    let currentColor = playerManager.currentPlayer.color
    
    blackTimerDefaultHeight.isActive = false
    
    if currentColor == .black {
      blackTimerDecreasedHeight.isActive = false
      blackTimerIncreasedHeight.isActive = true
    } else {
      blackTimerIncreasedHeight.isActive = false
      blackTimerDecreasedHeight.isActive = true
    }
    
    UIView.animate(withDuration: 0.5) { [unowned self] in
      self.view.layoutIfNeeded()
    }
  }
  
  func getFormattedRemainingTime(for player: Player) -> String {
    let remainingTime = player.remainingTime
    let minutes = Int(remainingTime / 60)
    let seconds = Int(remainingTime.truncatingRemainder(dividingBy: 60))
    
    return "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
  }
  
  func refreshTimerViews() {
    whiteTimerView.setText(getFormattedRemainingTime(for: playerManager.whitePlayer))
    blackTimerView.setText(getFormattedRemainingTime(for: playerManager.blackPlayer))
  }
  
  // TODO: Return the correct configuration
  func restartTimer(with configuration: TimerConfiguration? = nil) {
    playerManager = nil
    setupManagers(with: configuration)
    refreshTimerViews()
  }
}

extension ViewController {
 
  // MARK: Actions
  
  @IBAction func didTap(_ sender: UITapGestureRecognizer) {
    if !playerManager.timer.isRunning() {
      playerManager.timer.start()
    } else {
      playerManager.toggleCurrentPlayer()
    }
  }
  
//  @IBAction func didDoubleTap(_ sender: UITapGestureRecognizer) {
//    if playerManager.timer.isRunning() {
//      playerManager.timer.pause()
//    } else {
//      playerManager.timer.start()
//    }
//  }
  
  @IBAction func didTapRefresh(_ sender: UIButton) {
    let alert = UIAlertController(title: "Reset",
                                  message: "Are you sure you want to reset the current timer?",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "reset", style: .destructive, handler: { [unowned self] _ in
      self.restartTimer()
    }))
    alert.addAction(UIAlertAction(title: "cancel", style: .cancel))
    
    present(alert, animated: true)
  }
  
  // MARK: Notification Actions
  
  @objc func restartRequested(notification: Notification) {
    restartTimer()
  }
  
  @objc func newTimerRequested(notification: Notification) {
    //    guard let config = notification.userInfo?["player_configuration"] as? PlayerConfiguration else { return }
    restartTimer()
  }

}

// MARK: Timer manager delegate

extension ViewController: TimerManagerDelegate {

  func timerHasStarted(manager: TimerManager) {
    animatePlayerChange()
  }

  func timerHasStopped(manager: TimerManager) {
    performSegue(withIdentifier: optionsSegueId,
                 sender: self)
  }

  func timerHasFired(manager: TimerManager) {
    playerManager.decreaseRemainingTime()
  }

}

// MARK: Player manager delegate

extension ViewController: PlayerManagerDelegate {
  
  func playerHasChanged(currentPlayer: Player) {
    refreshTimerViews()
    animatePlayerChange()
  }
  
  func playerTimeHasRanOver(player: Player) {
    playerManager.timer.pause()
    performSegue(withIdentifier: optionsSegueId, sender: self)
  }
  
  func playerTimeHasDecreased(player: Player) {
    refreshTimerViews()
  }
  
}

