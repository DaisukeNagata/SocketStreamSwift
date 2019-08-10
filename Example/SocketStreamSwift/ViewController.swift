//
//  ViewController.swift
//  SocketStreamSwift
//
//  Created by daisukenagata on 06/02/2019.
//  Copyright (c) 2019 daisukenagata. All rights reserved.
//

import UIKit
import SocketStreamSwift

class ViewController: UIViewController {

    private var url = "wss://nrsiaemeja.execute-api.ap-northeast-1.amazonaws.com/Prod"
    private var port = 443
    private var indexCount = [String]()

    private lazy var table: UITableView = {
        let table = UITableView()
        table.dataSource = self
        table.frame = view.frame
        table.separatorStyle = .none
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(table)
        return table
    }()

    private lazy var socketStream: SocketStream = {
       let e = SocketStream(url: URL(string:url)!, hostNumber: UInt32(port))
        e.delegate = self
        e.unConnected = self
        return e
    }()

    @IBOutlet weak var enterField: UITextField! {
        didSet {
            enterField.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        socketStream.networkAccept()
        table.frame.origin.y = enterField.frame.origin.y + enterField.frame.height + UIApplication.shared.statusBarFrame.height
    }

}

// MARK: MessageInputDelegate
extension ViewController: MessageInputDelegate {
    func sendMessage(message: String) { socketStream.sendMessage(message) }
}

// MARK: SocketStreamDelegate
extension ViewController: SocketStreamDelegate {
    func receivedMessage(message: Message) {

        indexCount.append(message.message)
        table.reloadData()
    }
}

// MARK: EroorUnconnected
extension ViewController: ErrorUnconnected {
    func errorOccurred() {
        print("errorOccurred")
    }
}

// MARK: textFieldShouldReturn
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if port == 443 {
            let p:[String:Any] = ["message":"sendmessage","data":"\(textField.text ?? "" )"]
            let dd = try! JSONSerialization.data(withJSONObject: p, options: .prettyPrinted)
            socketStream.dequeueWrite(dd)
        } else {
            sendMessage(message: textField.text!)
        }
        return true
    }
}

// MARK: UITableViewDataSource
extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return indexCount.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.textAlignment = .right
        cell.textLabel?.text = indexCount[indexPath.row]
        return cell
    }
}
