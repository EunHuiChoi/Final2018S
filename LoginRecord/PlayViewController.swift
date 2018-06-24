//
//  ViewController.swift
//  BasicAudioPlayer
//
//  Created by SWUCOMPUTER on 2018. 5. 29..
//  Copyright © 2018년 SWUCOMPUTER. All rights reserved.
//

import UIKit
import AVFoundation

class PlayViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet var pvProgressPlay: UIProgressView!
    @IBOutlet var currentTime: UILabel!
    @IBOutlet var endTime: UILabel!
    @IBOutlet var buttonPause: UIButton!
    @IBOutlet var buttonPlay: UIButton!
    @IBOutlet var buttonStop: UIButton!
    @IBOutlet var sliderVol: UISlider!
    
    var audioPlayer : AVAudioPlayer!
    var audioFile : URL!
    let MAX_VOLUME : Float = 10.0
    var progressTimer : Timer!
    var audioRecorder : AVAudioRecorder!
    var isRecodeMode = false
    
    let timePlaySelector: Selector = #selector(PlayViewController.updatePlayTime)
    
    @objc func updatePlayTime() {
        currentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectAudioFile()
    }
    
    func initPlay() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        sliderVol.maximumValue = MAX_VOLUME
        sliderVol.value = 1.0
        pvProgressPlay.progress = 0
        
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        audioPlayer.volume = sliderVol.value
        endTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        currentTime.text = convertNSTimeInterval2String(0)
        
        setPlayButtons(true, pause: false, stop: false)
    }
    
    func setPlayButtons(_ play: Bool, pause: Bool, stop: Bool) {
        buttonPlay.isEnabled = play
        buttonPause.isEnabled = pause
        buttonStop.isEnabled = stop
    }
    
    func convertNSTimeInterval2String(_ time: TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let stringTime = String(format: "%02d:%02d", min, sec)
        return stringTime
    }
    
    @IBAction func buttonPlayAudio(_ sender: UIButton) {
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: true)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlaySelector, userInfo: nil, repeats: true)
    }
    
    @IBAction func buttonPauseAudio(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: false)
    }
    
    @IBAction func buttonStopAudio(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        currentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate()
    }
    
    @IBAction func chagneVolum(_ sender: UISlider) {
        audioPlayer.volume = sliderVol.value
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate()
        setPlayButtons(true, pause: false, stop: false)
    }
    
    func selectAudioFile() {
        audioFile = Bundle.main.url(forResource: "together", withExtension: "mp3")
    }
}


