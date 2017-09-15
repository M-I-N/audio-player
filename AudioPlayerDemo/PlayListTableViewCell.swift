//
//  PlayListTableViewCell.swift
//  AudioPlayerDemo
//
//  Created by Nayem BJIT on 9/15/17.
//  Copyright © 2017 Nayem BJIT. All rights reserved.
//

import UIKit

class PlayListTableViewCell: UITableViewCell {
    
    //MARK: - Vars
    
    var playbackItem: PlaybackItem
    var barsImageView: UIImageView?
    
    //MARK: - Dependencies
    
    var player: CustomAudioPlayer
    
    //MARK: - Init
    
    init(player: CustomAudioPlayer, playbackItem: PlaybackItem, reuseIdentifier: String? = nil) {
        self.playbackItem = playbackItem
        self.player = player
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        self.updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    //MARK: - Update View
    
    func updateView() {
        self.imageView?.image = UIImage(named: self.playbackItem.albumImageName)
        self.textLabel?.text = "\(self.playbackItem.artistName) - \(self.playbackItem.trackName)"
        self.detailTextLabel?.text = "\(self.playbackItem.albumName)"
        
        self.updateAccessoryView()
    }
    
    func updateAccessoryView() {
        self.barsImageView?.removeFromSuperview()
        
        if self.playbackItem == self.player.currentPlaybackItem {
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            self.accessoryView = containerView
            
            let imageView = UIImageView(frame: CGRect(x: self.contentView.bounds.maxX + 5, y: self.contentView.bounds.midY - 10, width: 20, height: 20))
            
            imageView.contentMode = .scaleAspectFit
            self.addSubview(imageView)
            
            if self.player.isPlaying {
                var images = [UIImage]()
                for i in 1...9 {
                    images.append(UIImage(named: "equalizer\(i)")!)
                }
                
                imageView.animationImages = images
                imageView.animationDuration = 1
                imageView.startAnimating()
            }
            else {
                imageView.image = UIImage(named: "equalizer1")
            }
            
            self.barsImageView = imageView
        }
        else {
            self.accessoryView = nil
        }
    }
    
    //MARK: - Cell Selected/Highlighted
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.updateAccessoryView()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.updateAccessoryView()
    }
    
}
