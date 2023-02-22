//
//  ViewController.swift
//  sheetsAPI_test
//
//  Created by Ben Schwartz on 5/2/20.
//  Copyright © 2020 Ben Schwartz. All rights reserved.
//

//
//MARK: sample sheet : https://docs.google.com/spreadsheets/d/18v632hMyxOtgWEe9IgI-xhe_oVzNQXpKU41NyxjzKfs/edit#gid=0

//MARK: links -> https://stackoverflow.com/questions/31776114/how-show-activityindicator-in-swift
// https://www.hackingwithswift.com/example-code/uikit/how-to-use-uiactivityindicatorview-to-show-a-spinner-when-work-is-happening

import UIKit

class ViewController: UIViewController, URLSessionDelegate {

    @IBOutlet weak var status_lbl: UILabel!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var buffer: UIActivityIndicatorView!
    @IBOutlet weak var jsonLink_lbl: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var topView: UIView!
    var urlString : String = ""
    
    private var items : [[String:Any]] = [[:]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
    }
}
extension ViewController : UITextFieldDelegate {
    
    @IBAction func loadTouched(_ sender: Any) {
        fetchData()
    }

    @IBAction func printTouched(_ sender: Any) {
        if items.count > 2 {
            textView.text = getDictText(from: items)
        }
        else { jsonLink_lbl.text = "no data found" }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        fetchData()
        textField.resignFirstResponder()
        return false
    }
    @IBAction func editingChanged(_ sender: Any) {
        urlString = urlField.text!
        urlField.resignFirstResponder()
    }
    @IBAction func clearTouched(_ sender: Any) {
        reset()
    }
}

private extension ViewController {

    func initialize() {
        status_lbl.text = "waiting for input..."
        buffer.isHidden = true
        buffer.hidesWhenStopped = true
        jsonLink_lbl.adjustsFontSizeToFitWidth = true;
        urlField.delegate = self
    }
    
    func fetchData() {
        buffer.startAnimating()
        status_lbl.text = "generating json..."
        let success = generateJSON()
        if success {
            status_lbl.text = "load successful (items : \(items.count))"
            jsonLink_lbl.text = getJsonURL(sheetsURL: urlField.text!)
        }
        else {
            status_lbl.text = "load failed"
        }
        buffer.stopAnimating()
    }
    
    func reset() {
        status_lbl.text = ""
        urlField.text = ""
        if(!buffer.isHidden) {
            print("not hidden")
            buffer.isHidden = true
        }
        jsonLink_lbl.text = ""
        textView.text = ""
        urlString = ""
        items = []
    }
    
    func getDictText(from dict: [[String:Any]]) -> String {
        var text = ""
        var count = 0
        for row in items {
            count += 1
            text += "\(count) : "
            text += row.description
            text += "\n"
        }
        return text
    }
}
//MARK: json loading
extension ViewController {
    
    func generateJSON() -> Bool{
        
        items = []
        
        let semaphore = DispatchSemaphore(value: 0) // https://medium.com/@roykronenfeld/semaphores-in-swift-e296ea80f860

        if urlString.contains("docs.google.com/spreadsheets/d/") && urlString.count > 80 {
            if let jsonURL = getJsonURL(sheetsURL: urlString) {
                if let url = URL(string: jsonURL) {
                    URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
                        if let data = data {
                          self.loadData(with: data) { dictArray in
                                print("success")
                                self.items = dictArray
                            }
                        }
                    semaphore.signal()
                    }.resume()
                }
            }
            semaphore.wait()
        }
        return self.items.count > 1
    }
    
    func loadData(with data: Data, completion: ([[String:Any]]) -> () ) {
        //i could try doing this straight to array of dictionaries, but its hard
        var dictArray : [[String : Any]] = [[:]]
        do {
            if let myDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let myArray = myDict["rows"] as? [[String:Any]] {
                    dictArray = myArray
                }
            }
        }
        catch {
            print("there was an error \(error)")
        }
        completion(dictArray)
    }
    
    func getJsonURL(sheetsURL : String) -> String? {
        let adjustedURL = sheetsURL[sheetsURL.firstIndex(of: "d")!...]
        let array = adjustedURL.components(separatedBy: "/")
        if array.count < 4 { return nil }
        var count = 3
        var sheetID = ""
        while sheetID.count < 3 {
            sheetID = array[count]
            count += 1
        }
        let jsonURL = "http://gsx2json.com/api?id=\(sheetID)&columns=false"
        return jsonURL
    }
}


