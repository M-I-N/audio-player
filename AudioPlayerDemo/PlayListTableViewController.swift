//
//  PlayListTableViewController.swift
//  AudioPlayerDemo
//
//  Created by Nayem BJIT on 9/15/17.
//  Copyright © 2017 Nayem BJIT. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class PlayListTableViewController: UITableViewController {
    
    let audioSession = AVAudioSession.sharedInstance()
    let commandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let notificationCenter = NotificationCenter.default
    let bundle = Bundle.main
    
    lazy var myPlayer: CustomAudioPlayer = {
        return CustomAudioPlayer(audioSession: self.audioSession, commandCenter: self.commandCenter, nowPlayingInfoCenter: self.nowPlayingInfoCenter, notificationCenter: self.notificationCenter)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playbackItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let playbackItem = playbackItems[indexPath.row]
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlayListTableViewCell
//        cell.player = myPlayer
//        cell.playbackItem = playbackItem
        
        let cell = PlayListTableViewCell(player: myPlayer, playbackItem: playbackItem, reuseIdentifier: "Cell")

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        let selectedCell = tableView.cellForRow(at: indexPath)
        let otherCells = tableView.visibleCells.filter {$0 != selectedCell}
        
        let selectedPlaybackItem = playbackItems[indexPath.row]
        
        // Tapping on the cell as previously tapped will stop the playback
        if myPlayer.currentPlaybackItem == selectedPlaybackItem {
            myPlayer.endPlayback()
//            selectedCell?.accessoryType = .none
        } else {
            // If not currently playing, player will play the list
            myPlayer.play(items: playbackItems, firstItem: selectedPlaybackItem)
//            selectedCell?.accessoryType = .checkmark
//            otherCells.forEach{ $0.accessoryType = .none }
        }
        */
        myPlayer.play(items: playbackItems, firstItem: playbackItems[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Notifications
    
    func configureNotifications() {
        notificationCenter.addObserver(self, selector: #selector(onTrackAndPlaybackStateChange), name: NSNotification.Name(rawValue: AudioPlayerOnTrackChangedNotification), object: nil)
        notificationCenter.addObserver(self, selector: #selector(onTrackAndPlaybackStateChange), name: NSNotification.Name(rawValue: AudioPlayerOnPlaybackStateChangedNotification), object: nil)
    }
    
    func onTrackAndPlaybackStateChange() {
//        self.updatePlayerButton(animated: true)
        self.tableView.reloadData()
    }
    
    // MARK:- Playlist Items
    lazy var playbackItems: [PlaybackItem] = {
        let playbackItem1 = PlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "Best Coast - The Only Place (The Only Place)", ofType: "mp3")!),
                                           trackName: "The Only Place",
                                           albumName: "The Only Place",
                                           artistName: "Best Coast",
                                           albumImageName: "Best Coast - The Only Place (The Only Place)")
        
        let playbackItem2 = PlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "Future Islands - Before the Bridge (On the Water)", ofType: "mp3")!),
                                           trackName: "Before the Bridge",
                                           albumName: "On the Water",
                                           artistName: "Future Islands",
                                           albumImageName: "Future Islands - Before the Bridge (On the Water).jpg")
        
        let playbackItem3 = PlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "Motorama - Alps (Alps)", ofType: "mp3")!),
                                           trackName: "Alps",
                                           albumName: "Alps",
                                           artistName: "Motorama",
                                           albumImageName: "Motorama - Alps (Alps)")
        
        let playbackItem4 = PlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "Nils Frahm - You (Screws Reworked)", ofType: "mp3")!),
                                           trackName: "You",
                                           albumName: "Screws Reworked",
                                           artistName: "Nils Frahm",
                                           albumImageName: "Nils Frahm - You (Screws Reworked)")
        
        let playbackItem5 = PlaybackItem(fileURL: URL(fileURLWithPath: self.bundle.path(forResource: "The Soul's Release - Catching Fireflies (Where the Trees Are Painted White)", ofType: "mp3")!),
                                           trackName: "Catching Fireflies",
                                           albumName: "Where the Trees Are Painted White",
                                           artistName: "The Soul's Release",
                                           albumImageName: "The Soul's Release - Catching Fireflies (Where the Trees Are Painted White).jpg")
        
        let playbackItems = [playbackItem1, playbackItem2, playbackItem3, playbackItem4, playbackItem5]
        
        return playbackItems
    }()

}
