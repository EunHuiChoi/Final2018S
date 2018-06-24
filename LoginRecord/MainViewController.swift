//
//  MainViewController.swift
//  LoginRecord
//
//  Created by SWUCOMPUTER on 2018. 6. 17..
//  Copyright © 2018년 SWUCOMPUTER. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    @IBOutlet var myRecordTableView: UITableView!
    var fetchedArray: [FolderData] = Array()
    var selectedData: FolderData?
    
    @IBAction func addFolderButton(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "새로운 폴더", message: "이 폴더의 이름을 입력하십시오.", preferredStyle: .alert)
        let save = UIAlertAction(title: "Save", style: .default) {
            (save) in
            let name = alert.textFields![0].text!
            let urlString: String = "http://condi.swu.ac.kr/student/W11iphone/insertFolder.php"
            guard let requestURL = URL(string: urlString) else { return }
            var request = URLRequest(url: requestURL)
            request.httpMethod = "POST"
            
            let appDelegate = UIApplication.shared.delegate as!AppDelegate
            appDelegate.foldername = name
            
            guard let userID = appDelegate.ID  else { return }
            let restString: String = "id=" + userID + "&name=" + name
            
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
            self.fetchedArray = []
            self.downloadDataFromServer()
            self.myRecordTableView.reloadData()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
            (cancel) in
        }
        alert.addAction(cancel)
        alert.addAction(save)
        
        alert.addTextField {
            (myTextField) in
            myTextField.placeholder = "폴더 이름"
            
            /*if (myTextField.text?.isEmpty)! {
                save.isEnabled = false
            }
            else {
                save.isEnabled = true
            }*/
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func buttonLogout(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title:"로그아웃 하시겠습니까?",message: "",preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            let urlString: String = "http://condi.swu.ac.kr/student/W11iphone/logout.php"
            guard let requestURL = URL(string: urlString) else { return }
            var request = URLRequest(url: requestURL)
            request.httpMethod = "POST"
            let session = URLSession.shared
            let task = session.dataTask(with: request) { (responseData, response, responseError) in
                guard responseError == nil else { return }
            }
            task.resume()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginView = storyboard.instantiateViewController(withIdentifier: "LoginView")
            self.present(loginView, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationItem.leftBarButtonItem = self.editButtonItem
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let name = appDelegate.userName {
            self.title = name + "'s Record" }
        fetchedArray = []
        self.downloadDataFromServer()
    }
    
    func downloadDataFromServer() -> Void {
        let urlString: String = "http://condi.swu.ac.kr/student/W11iphone/folderTable.php"
        guard let requestURL = URL(string: urlString) else { return }
        var request = URLRequest(url: requestURL)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        request.httpMethod = "POST"
        guard let userID = appDelegate.ID else { return }
        //guard let folderName = appDelegate.foldername else { return }
        print(userID)
        let restString: String = "id=" + userID
        request.httpBody = restString.data(using: .utf8)
        print(restString)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            guard responseError == nil else { print("Error: calling POST"); return; }
            guard let receivedData = responseData else { print("Error: not receiving Data"); return; }
            let response = response as! HTTPURLResponse
            
            if !(200...299 ~= response.statusCode) { print("HTTP response Error!"); return }
            do {
                if let jsonData = try JSONSerialization.jsonObject(with: receivedData, options:.allowFragments) as? [[String: Any]] {
                    for i in 0...jsonData.count-1 {
                        let newData: FolderData = FolderData()
                        var jsonElement = jsonData[i]
                        newData.folders = jsonElement["folders"] as! String
                        newData.id = jsonElement["id"] as! String
                        newData.name = jsonElement["name"] as! String
                        self.fetchedArray.append(newData)
                        print(self.fetchedArray)
                    }
                    DispatchQueue.main.async {
                        self.myRecordTableView.reloadData()
                    }
                }
            } catch {
                print("Error:\(error)")
            }
        }
        task.resume()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedArray.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Decoder Folder"
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.myRecordTableView.dequeueReusableCell(withIdentifier: "Folder Cell", for: indexPath)
        let item = fetchedArray[indexPath.row]
        cell.textLabel?.text = item.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
        }
        else if editingStyle == .insert {
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toListView" {
            if let destination = segue.destination as? ListTableViewController {
                if let selectedIndex = self.myRecordTableView.indexPathsForSelectedRows?.first?.row {
                    let appDelegate = UIApplication.shared.delegate as!AppDelegate
                    let data = fetchedArray[selectedIndex]
                    appDelegate.userName = data.name
                    destination.title = appDelegate.userName
                }
            }
        }
    }
    
}
