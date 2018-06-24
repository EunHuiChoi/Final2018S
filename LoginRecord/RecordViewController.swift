//
//  RecordViewController.swift
//  LoginRecord
//
//  Created by SWUCOMPUTER on 2018. 6. 17..
//  Copyright © 2018년 SWUCOMPUTER. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate, UIImagePickerControllerDelegate {

    @IBOutlet var recordTitle: UITextField!
    @IBOutlet var recordSub: UITextField!
    @IBOutlet var recordMemo: UITextView!
    //@IBOutlet var imageView: UIImageView!
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var pauseButton: UIButton!
    
    @IBOutlet var recordTime: UILabel!
    @IBOutlet var sliderVol: UISlider!
    
    var audioPlayer : AVAudioPlayer!
    var audioFile : URL!
    let MAX_VOLUME : Float = 10.0
    var audioRecorder : AVAudioRecorder!
    var progressTimer : Timer!
    var folderName : String!
    
    let timeRecordSelector: Selector = #selector(RecordViewController.updateRecordTime)
    let timePlaySelector: Selector = #selector(RecordViewController.updatePlayTime)
    
    @objc func updatePlayTime() {
        recordTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
    }
    @objc func updateRecordTime() {
        recordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }
    
    @IBAction func saveRecord(_ sender: UIBarButtonItem) {
        //입력확인
        let title = recordTitle.text!
        let subtitle = recordSub.text!
        let memo = recordMemo.text!
        if (title == "" || subtitle == "" || memo == "") {
            let alert = UIAlertController(title: "제목/설명을 입력하세요",
                                          message: "Save Failed", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                alert.dismiss(animated: true, completion: nil) }))
            self.present(alert, animated: true)
            return }
        //녹음파일 있는지 확인
        guard let myRecord = audioPlayer else {
            let alert = UIAlertController(title: "녹음파일이 없습니다.",message: "Save Failed", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true)
            return
        }
        
        //제목, 부제목, 메모장, 날짜, 아이디, 폴더이름 저장
        let urlString : String = "http://condi.swu.ac.kr/student/W11iphone/insertRecord.php"
        guard let requestURL = URL(string: urlString) else { return }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        
        //ID 폴더 이름 저장 - 나중에 맞는 정보만 뿌려야 하기 때문
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let userID = appDelegate.ID  else { return }
        guard let folderName = appDelegate.foldername else { return }
        print(userID)
        print(folderName)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let myDate = formatter.string(from: Date())
        print(myDate)
        
        var restString: String = "id=" + userID + "&foldername=" + folderName
        restString += "&title=" + title
        restString += "&subtitle=" + subtitle
        restString += "&description=" + memo
        restString += "&date=" + myDate
        request.httpBody = restString.data(using: .utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            guard responseError == nil else { return }
            guard let receivedData = responseData else { return }
            if let utf8Data = String(data: receivedData, encoding: .utf8) {
                print(utf8Data)
            }
        }
        task.resume()
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    //녹음시작
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if audioRecorder == nil {

            let recordSettings = [AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless as UInt32),
                                  AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                                  AVEncoderBitRateKey: 320000,
                                  AVNumberOfChannelsKey: 2,
                                  AVSampleRateKey: 44100.0] as [String : Any]
            
            do {
                audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
                audioRecorder.delegate = self
                audioRecorder.record()
                sender.setImage(#imageLiteral(resourceName: "stop.png"), for: UIControlState())
            } catch let error as NSError {
                print("Error-initRecord : \(error)")
            }
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        }
        else {
            audioRecorder.stop()
            progressTimer.invalidate()
            sender.setImage(#imageLiteral(resourceName: "recordPress.png"), for: UIControlState())
            setPlayButtons(true, pause: false)
            initPlay()
            //recordTime.text = convertNSTimeInterval2String(audioPlayer.duration)
            recordTime.text = convertNSTimeInterval2String(0)
            audioRecorder = nil
        }
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        audioPlayer.play()
        setPlayButtons(false, pause: true)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlaySelector, userInfo: nil, repeats: true)
    }
    
    //일시정지 버튼 왜인지 작동안함_추후확인요망
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false)
    }
    
    @IBAction func chagneVolum(_ sender: UISlider) {
        audioPlayer.volume = sliderVol.value
    }

    func initPlay() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        sliderVol.maximumValue = MAX_VOLUME
        sliderVol.value = 1.0
        
        audioPlayer.delegate = self
        audioPlayer.prepareToPlay()
        audioPlayer.volume = sliderVol.value
        //recordTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        //recordTime.text = convertNSTimeInterval2String(0)
        
        setPlayButtons(true, pause: false)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate()
        setPlayButtons(true, pause: false)
    }
    
    func convertNSTimeInterval2String(_ time: TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let stringTime = String(format: "%02d:%02d", min, sec)
        return stringTime
    }
    
    func setPlayButtons(_ play: Bool, pause: Bool) {
        playButton.isEnabled = play
        pauseButton.isEnabled = pause
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        recordMemo.becomeFirstResponder()
        return true
    }
    
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sliderVol.value = 1.0
        setPlayButtons(false, pause: false)
        
        //let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFile = getDirectory().appendingPathComponent("recordFile.m4a")
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("Error-setCategory: \(error)")
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Error-setActive: \(error)")
        }
        //audioRecorder.isMeteringEnabled = true
        //audioRecorder.prepareToRecord()
        recordTime.text = convertNSTimeInterval2String(0)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        folderName = appDelegate.foldername
        print(folderName)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
