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

    // AWS RealURL "wss://9rqzvo5ac3.execute-api.ap-northeast-1.amazonaws.com/Prod", port = 443
    private var url = "wss://localhost"
    private var port = 8000
    private var table: UITableView
    private var indexCount: [String]
    private lazy var extensionString: SocketStream = {
       let e = SocketStream(url: URL(string:url)!, hostNumber: UInt32(port))
        return e
    }()

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
        extensionString.unConnected = self
        extensionString.networkAccept()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if port == 443 {
            let p:[String:Any] = ["message":"sendmessage","data":"\(textField.text ?? "" )"]
            let dd = try! JSONSerialization.data(withJSONObject: p, options: .prettyPrinted)
            extensionString.dequeueWrite(dd)
        } else {
           sendMessage(message: textField.text!)
        }
        return true
    }
    
}

// MARK: MessageInputDelegate
extension ViewController: MessageInputDelegate {
    func sendMessage(message: String) { extensionString.sendMessage(message) }
}

// MARK: SocketStreamDelegate
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

// MARK: EroorUnconnected
extension ViewController: ErrorUnconnected {
    func errorOccurred() {
        print("errorOccurred")
    }
}

