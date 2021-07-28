//
//  ViewController.swift
//  starscreamSwift
//
//  Created by ITD02 on 28/07/2021.
//

import UIKit
import Starscream

class ViewController: UIViewController {
    
    var socket: WebSocket!
    var isConnected = false
//    var server = WebSocketServer()
    private let serverUrl = "http://localhost:5000/ws"  // /chat or /chatLongPolling or /chatWebSockets
    private let dispatchQueue = DispatchQueue(label: "hubsamplephone.queue.dispatcheueuq")
    
    private var name = ""
    private var messages: [String] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var msgTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let alert = UIAlertController(title: "Enter your Name", message:"", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField() { textField in textField.placeholder = "Name"}
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            self.name = alert.textFields?.first?.text ?? "John Doe"

            var request = URLRequest(url: URL(string: self.serverUrl)!)
            request.timeoutInterval = 5
            self.socket = WebSocket(request: request)
            self.socket.delegate = self
            self.socket.connect()
        }
        alert.addAction(OKAction)
        self.present(alert, animated: true)
    }
    
    @IBAction func stopWebSocketTouch(_ sender: Any) {
        if isConnected {
            print("disconnect")
            socket.disconnect()
        } else {
            print("connect")
            socket.connect()
        }
    }
    
    @IBAction func passMsgTouch(_ sender: Any) {
        let message = msgTextField.text
        if message != "" {
            socket.write(string: "\(self.name): \(message ?? "")")
            msgTextField.text = ""
        }
    }
    
    private func appendMessage(message: String) {
        self.dispatchQueue.sync {
            self.messages.append(message)
        }
        
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .automatic)
        self.tableView.endUpdates()
        self.tableView.scrollToRow(at: IndexPath(item: messages.count-1, section: 0), at: .bottom, animated: true)
    }
}

extension ViewController: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
            self.navigationItem.title = "i am \(self.name)"
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
            self.appendMessage(message: string)
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
//            handleError(error)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = -1
        dispatchQueue.sync {
            count = self.messages.count
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        let row = indexPath.row
        cell.chatLabel.text = messages[row]
        return cell
    }
}

