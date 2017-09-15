//
//  CustomAudioPlayer.swift
//  AudioPlayerDemo
//
//  Created by Nayem BJIT on 9/15/17.
//  Copyright © 2017 Nayem BJIT. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

import Foundation
import AVFoundation
import MediaPlayer

let AudioPlayerOnTrackChangedNotification = "AudioPlayerOnTrackChangedNotification"
let AudioPlayerOnPlaybackStateChangedNotification = "AudioPlayerOnPlaybackStateChangedNotification"

public struct PlaybackItem {
    let fileURL: URL
    let trackName: String
    let albumName: String
    let artistName: String
    let albumImageName: String
}

extension PlaybackItem: Equatable {}
public func ==(lhs: PlaybackItem, rhs: PlaybackItem) -> Bool {
    return lhs.fileURL.absoluteString == rhs.fileURL.absoluteString
}

open class CustomAudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    //MARK: - Vars
    
    var audioPlayer: AVAudioPlayer?
    open var playbackItems: [PlaybackItem]?
    open var currentPlaybackItem: PlaybackItem?
    open var nextPlaybackItem: PlaybackItem? {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let nextItemIndex = playbackItems.index(of: currentPlaybackItem)! + 1
        if nextItemIndex >= playbackItems.count { return nil }
        
        return playbackItems[nextItemIndex]
    }
    open var previousPlaybackItem: PlaybackItem? {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return nil }
        
        let previousItemIndex = playbackItems.index(of: currentPlaybackItem)! - 1
        if previousItemIndex < 0 { return nil }
        
        return playbackItems[previousItemIndex]
    }
    var nowPlayingInfo: [String : Any]?
    
    open var currentTime: TimeInterval? {
        return self.audioPlayer?.currentTime
    }
    
    open var duration: TimeInterval? {
        return self.audioPlayer?.duration
    }
    
    open var isPlaying: Bool {
        return self.audioPlayer?.isPlaying ?? false
    }
    
    //MARK: - Dependencies
    
    private let audioSession: AVAudioSession
    private let commandCenter: MPRemoteCommandCenter
    private let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    private let notificationCenter: NotificationCenter
    
    //MARK: - Init
    
//    typealias AudioPlayerDependencies = (audioSession: AVAudioSession, commandCenter: MPRemoteCommandCenter, nowPlayingInfoCenter: MPNowPlayingInfoCenter, notificationCenter: NotificationCenter)
    
    init(audioSession: AVAudioSession, commandCenter: MPRemoteCommandCenter, nowPlayingInfoCenter: MPNowPlayingInfoCenter, notificationCenter: NotificationCenter) {
        self.audioSession = audioSession
        self.commandCenter = commandCenter
        self.nowPlayingInfoCenter = nowPlayingInfoCenter
        self.notificationCenter = notificationCenter
        
        super.init()
        
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        
        
        self.configureCommandCenter()
    }
    
    //MARK: - Playback Commands
    
    open func play(items: [PlaybackItem], firstItem: PlaybackItem? = nil) {
        self.playbackItems = items
        
        if items.count == 0 {
            self.endPlayback()
            return
        }
        
        let playbackItem = firstItem ?? self.playbackItems!.first!
        
        self.play(playbackItem: playbackItem)
    }
    
    func play(playbackItem: PlaybackItem) {
        guard let audioPlayer = try? AVAudioPlayer(contentsOf: playbackItem.fileURL) else {
            self.endPlayback()
            return
        }
        
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
        self.audioPlayer = audioPlayer
        
        self.currentPlaybackItem = playbackItem
        
        self.updateNowPlayingInfoForCurrentPlaybackItem()
        self.updateCommandCenter()
        
        self.notifyOnTrackChanged()
    }
    
    open func togglePlayPause() {
        if self.isPlaying {
            self.pause()
        }
        else {
            self.play()
        }
    }
    
    open func play() {
        self.audioPlayer?.play()
        self.updateNowPlayingInfoElapsedTime()
        self.notifyOnPlaybackStateChanged()
    }
    
    open func pause() {
        self.audioPlayer?.pause()
        self.updateNowPlayingInfoElapsedTime()
        self.notifyOnPlaybackStateChanged()
    }
    
    open func nextTrack() {
        guard let nextPlaybackItem = self.nextPlaybackItem else { return }
        self.play(playbackItem: nextPlaybackItem)
        self.updateCommandCenter()
    }
    
    open func previousTrack() {
        guard let previousPlaybackItem = self.previousPlaybackItem else { return }
        self.play(playbackItem: previousPlaybackItem)
        self.updateCommandCenter()
    }
    
    open func seekTo(timeInterval: TimeInterval) {
        self.audioPlayer?.currentTime = timeInterval
        self.updateNowPlayingInfoElapsedTime()
    }
    
    //MARK: - Command Center
    
    func updateCommandCenter() {
        guard let playbackItems = self.playbackItems, let currentPlaybackItem = self.currentPlaybackItem else { return }
        
        self.commandCenter.previousTrackCommand.isEnabled = currentPlaybackItem != playbackItems.first!
        self.commandCenter.nextTrackCommand.isEnabled = currentPlaybackItem != playbackItems.last!
    }
    
    func configureCommandCenter() {
        self.commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.play()
            return .success
        })
        
        self.commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.pause()
            return .success
        })
        
        self.commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.nextTrack()
            return .success
        })
        
        self.commandCenter.previousTrackCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.previousTrack()
            return .success
        })
        
    }
    
    //MARK: - Now Playing Info
    
    func updateNowPlayingInfoForCurrentPlaybackItem() {
        guard let audioPlayer = self.audioPlayer, let currentPlaybackItem = self.currentPlaybackItem else {
            self.configure(nowPlayingInfo: nil)
            return
        }
        
        var nowPlayingInfo = [MPMediaItemPropertyTitle: currentPlaybackItem.trackName,
                              MPMediaItemPropertyAlbumTitle: currentPlaybackItem.albumName,
                              MPMediaItemPropertyArtist: currentPlaybackItem.artistName,
                              MPMediaItemPropertyPlaybackDuration: audioPlayer.duration,
                              MPNowPlayingInfoPropertyPlaybackRate: NSNumber(value: 1.0 as Float)] as [String : Any]
        
        if let image = UIImage(named: currentPlaybackItem.albumImageName) {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
        }
        
        self.configure(nowPlayingInfo: nowPlayingInfo)
        
        self.updateNowPlayingInfoElapsedTime()
    }
    
    func updateNowPlayingInfoElapsedTime() {
        guard var nowPlayingInfo = self.nowPlayingInfo, let audioPlayer = self.audioPlayer else { return }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: audioPlayer.currentTime as Double);
        
        self.configure(nowPlayingInfo: nowPlayingInfo)
    }
    
    func configure(nowPlayingInfo: [String: Any]?) {
        self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        self.nowPlayingInfo = nowPlayingInfo
    }
    
    //MARK: - AVAudioPlayerDelegate
    
    open func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if self.nextPlaybackItem == nil {
            self.endPlayback()
        }
        else {
            self.nextTrack()
        }
    }
    
    func endPlayback() {
        self.currentPlaybackItem = nil
        self.audioPlayer = nil
        
        self.updateNowPlayingInfoForCurrentPlaybackItem()
        self.notifyOnTrackChanged()
    }
    
    open func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        self.notifyOnPlaybackStateChanged()
    }
    
    open func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        if AVAudioSessionInterruptionOptions(rawValue: UInt(flags)) == .shouldResume {
            self.play()
        }
    }
    
    //MARK: - Convenience
    
    func notifyOnPlaybackStateChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: AudioPlayerOnPlaybackStateChangedNotification), object: self)
    }
    
    func notifyOnTrackChanged() {
        self.notificationCenter.post(name: Notification.Name(rawValue: AudioPlayerOnTrackChangedNotification), object: self)
    }
    
    //MARK: -
    
}
