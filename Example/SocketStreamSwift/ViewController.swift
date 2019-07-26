//
//  ViewController.swift
//  SocketStreamSwift
//
//  Created by daisukenagata on 06/02/2019.
//  Copyright (c) 2019 daisukenagata. All rights reserved.
//

import UIKit
import SocketStreamSwift


class ViewController: UIViewController,UITextFieldDelegate {

    private var table: UITableView
    private var indexCount: [String]
    private var extensionString = SocketStream(url: URL(string:"wss://9rqzvo5ac3.execute-api.ap-northeast-1.amazonaws.com/Prod")!, hostNumber: UInt32(443))
    @IBOutlet weak var enterField: UITextField!


    init() {
        self.table = UITableView()
        self.indexCount = [String]()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.table = UITableView()
        self.indexCount = [String]()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        enterField.delegate = self
        table.dataSource = self
        table.frame = view.frame
        table.separatorStyle = .none
        table.frame.origin.y =
            enterField.frame.origin.y +
            enterField.frame.height +
            UIApplication.shared.statusBarFrame.height
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(table)
        extensionString.delegate = self
        extensionString.networkAccept()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let p:[String:Any] = ["message":"sendmessage","data":"\(textField.text ?? "" )"]
        let dd = try! JSONSerialization.data(withJSONObject: p, options: .prettyPrinted)
        extensionString.dequeueWrite(dd)
        return true
    }
    
}

extension ViewController: SocketStreamDelegate {
    func receivedMessage(message: Message) {
        
        indexCount.append(message.message)
        table.reloadData()
    }
}

extension ViewController: UITextViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return indexCount.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.textAlignment = .right
        cell.textLabel?.text = indexCount[indexPath.row]
        return cell
    }
}

extension String {
    func replacing() -> String {
        return self.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\0", with: "")
            .replacingOccurrences(of: "\\\\", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}
