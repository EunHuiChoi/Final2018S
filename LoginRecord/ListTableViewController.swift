//
//  ListTableViewController.swift
//  LoginRecord
//
//  Created by SWUCOMPUTER on 2018. 6. 17..
//  Copyright © 2018년 SWUCOMPUTER. All rights reserved.
//

import UIKit

class ListTableViewController: UITableViewController {
    
    var fetchedArray: [RecordData] = Array()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let name = self.title {
            appDelegate.foldername = name
            //print(appDelegate.foldername)
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchedArray = []
        self.downloadDataFromServer()
    }
    
    func downloadDataFromServer() -> Void {
        let urlString: String = "http://condi.swu.ac.kr/student/W11iphone/recordTable.php"
        guard let requestURL = URL(string: urlString) else { return }
        var request = URLRequest(url: requestURL)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        request.httpMethod = "POST"
        guard let folderName = appDelegate.foldername else { return }
        print(folderName)
        let restString: String = "foldername=" + folderName
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
                        let newData: RecordData = RecordData()
                        var jsonElement = jsonData[i]
                        newData.recordBrief = jsonElement["recordBrief"] as! String
                        newData.id = jsonElement["id"] as! String
                        newData.foldername = jsonElement["foldername"] as! String
                        newData.title = jsonElement["title"] as! String
                        newData.subtitle = jsonElement["subtitle"] as! String
                        newData.memo = jsonElement["description"] as! String
                        newData.date = jsonElement["date"] as! String
                        self.fetchedArray.append(newData)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } catch {
                print("\(error)")
            }
        }
        task.resume()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return fetchedArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "List Cell", for: indexPath)
        
        let item = fetchedArray[indexPath.row]
        print(item)
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.date
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toRecordView" {
            if let destination = segue.destination as? RecordViewController {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if let name = self.title {
                    appDelegate.foldername = name
                    //print(appDelegate.foldername)
                    destination.folderName = appDelegate.foldername
                }
            }
        }
    }

}
