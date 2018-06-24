//
//  ViewController.swift
//  AudioPlayer
//
//  Created by SWUCOMPUTER on 2018. 5. 11..
//  Copyright © 2018년 SWUCOMPUTER. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class TempRecordViewController: UIViewController, AVAudioRecorderDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var recordingSession:AVAudioSession!
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    var numberOfRecords : Int = 0
    var temFile : [NSManagedObject] = []
    
    @IBOutlet var buttonLabel: UIButton!
    @IBOutlet var myTableView: UITableView!
    
    @IBAction func record(_ sender: UIButton) {
        if audioRecorder == nil {
            numberOfRecords += 1
            let filename = getDirectory().appendingPathComponent("\(numberOfRecords).m4a")
            
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            do {
                audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
                
                let context = getContext()
                let entity = NSEntityDescription.entity(forEntityName: "TemDirect", in: context)
                let object = NSManagedObject(entity: entity!, insertInto: context)
                
                let alert = UIAlertController(title: "새로운 녹음", message: "이 녹음의 이름을 입력하십시오.", preferredStyle: .alert)
                let save = UIAlertAction(title: "Save", style: .default) {
                    (save) in
                    //녹음 파일 이름과 URL 클라이언트 DB저장
                    object.setValue(alert.textFields?[0].text, forKey: "temName")
                    object.setValue("\(self.numberOfRecords).m4a", forKey: "temFile")
                    print(filename)
                    do {
                        try context.save()
                        print("saved!")
                    } catch let error as NSError {
                        print("Could not save \(error), \(error.userInfo)")
                    }
                    
                    self.audioRecorder.delegate = self
                    self.audioRecorder.record()
                    
                    self.buttonLabel.setImage(#imageLiteral(resourceName: "stop.png"), for: UIControlState())
                    
                }
                let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
                    (cancel) in
                    context.delete(object)
                }
                alert.addAction(cancel)
                alert.addAction(save)
                alert.addTextField {
                    (myTextField) in
                    myTextField.placeholder = "녹음 이름"
                }
                present(alert, animated: true, completion: nil)
                
            }
            catch {
            }
        }
        else {
            audioRecorder.stop()
            audioRecorder = nil
            
            buttonLabel.setImage(#imageLiteral(resourceName: "recordPress.png"), for: UIControlState())
            
            let context = self.getContext()
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TemDirect")
            do {
                temFile = try context.fetch(fetchRequest)
                
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
            myTableView.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordingSession = AVAudioSession.sharedInstance()

        let context = self.getContext()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TemDirect")
        do {
            temFile = try context.fetch(fetchRequest)
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        numberOfRecords = temFile.count
        /*
         위 코드에 대한 설명 : 시뮬레이터를 종료한 후, 다시 실행해서 녹음을 진행해도 이전에 녹음했던 것들과 녹음 경로가 겹치지 않게 해주는 역할을 한다.
         그러나 이는 tableview cell을 삭제하지 않았을 경우에만 해당된다. cell을 삭제하게 되면 cell의 수가 줄어들게 되고, 이는 시뮬레이터를 종료 후,
         다시 실행할 때 녹음경로가 겹치게 되어 녹음본끼리 상충하게 되는 결과를 불러온다. 이러한 오류의 해결방법은 옵셔널 바인딩을 통해 로컬디비에 저장된 마지막
         '숫자.m4a'값을 numbersOfRecords에 대입하면 된다. (따라서 원래는 temFile 어트리뷰트를 String이 아닌 Int 타입으로 정의하는 것이 맞다.)
         if let number: Int = object.value(forKey: "temFile") as? Int {
            numberOfRecords = number
         }
         그러나 로컬디비의 마지막 데이터를 불러오는 것에 실패하였다.
         따라서 녹음경로를 겹치게 하지 않으려면 셀을 삭제할때 마지막 셀만 삭제하거나, 전부 다 삭제해야 경로가 겹치지 않는다.
         */
        
        print(numberOfRecords)
        
        AVAudioSession.sharedInstance().requestRecordPermission {
            (hasPermission) in
            if hasPermission {
                print ("ACCEPTED")
            }
        }
    }
    
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return temFile.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Direct cell", for: indexPath)
        let temBig = temFile[indexPath.row]
        cell.textLabel?.text = temBig.value(forKey: "temName") as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //numberOfRecords += 1
            let context = getContext()
            context.delete(temFile[indexPath.row])
            do {
                try context.save()
                print("delete file")
            } catch let error as NSError {
                print("Could not delete \(error), \(error.userInfo)")
            }
            temFile.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        else if editingStyle == .insert {
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pathUrl = temFile[indexPath.row].value(forKey: "temFile") as! String
        let path = getDirectory().appendingPathComponent(pathUrl)
        
        print(pathUrl)
        print(path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.play()
        }
        catch {
            
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "temporary file"
    }
}


