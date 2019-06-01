//
//  ViewController.swift
//  SocketStreamSwift
//
//  Created by daisukenagata on 06/02/2019.
//  Copyright (c) 2019 daisukenagata. All rights reserved.
//

import UIKit
import SocketStreamSwift

extension ViewController: SocketStreamDelegate {
    func receivedMessage(message: Message) {
        indexCount.append(message.message)
        table.reloadData()
    }
}

extension ViewController: MessageInputDelegate {
    func sendMessage(message: String) { extensionString.sendMessage(message: message) }
}

extension ViewController: SocketToHost {
    var host: String {
        get { return "localhost" }
    }
    var hostNumber: UInt32 {
        get { return 8000 }
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

class ViewController: UIViewController,UITextFieldDelegate {

    private var table: UITableView
    private var indexCount: [String]
    private  var extensionString: SocketStream
    @IBOutlet weak var enterField: UITextField!


    init() {
        self.table = UITableView()
        self.indexCount = [String]()
        self.extensionString = SocketStream()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.table = UITableView()
        self.indexCount = [String]()
        self.extensionString = SocketStream()
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
        extensionString.socket = self
        extensionString.delegate = self
        extensionString.networkAccept()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        sendMessage(message: textField.text!)
        return true
    }

}
