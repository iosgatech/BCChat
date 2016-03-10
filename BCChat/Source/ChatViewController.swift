//
//  ChatViewController.swift
//  BCChat
//
//  Created by Brian Wang on 3/9/16.
//  Copyright © 2016 BC. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON
import FBSDKShareKit
import FBSDKLoginKit
import FBSDKCoreKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var containerViewBottom: NSLayoutConstraint!
    var username:String = ""
    var root = Firebase(url: "https://bootcampchatapp.firebaseio.com")
    var token: FBSDKAccessToken!
    var authData:FAuthData!
    var messages:[String:Message] = [String:Message]() {
        didSet {
            sortedMessages = Array(messages.values) as [Message]
        }
    }
    
    var sortedMessages:[Message] = [] {
        didSet {
            self.sortedMessages.sortInPlace({ leftMessage, rightMessage in
                let leftDate = leftMessage.date
                let rightDate = rightMessage.date
                return leftDate < rightDate
            })
            reloadTable()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name"], tokenString:token.tokenString, version: nil, HTTPMethod:"GET")
        req.startWithCompletionHandler({ (connection, result, error:NSError!) -> Void in
            if let error = error {
                print("error \(error)")
            } else {
                print("name \(result["name"])")
                self.username = result["name"] as! String
            }
        })
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidAppear:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidDisappear", name: UIKeyboardWillHideNotification, object: nil)
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        let chatRoot = root.childByAppendingPath("chat")
        chatRoot.observeEventType(.ChildAdded, withBlock: {snapshot in
            print("\(snapshot)\n")
            var m = Message()
            m.username = snapshot.value!["username"] as! String
            m.message = snapshot.value!["message"] as! String
            m.date = snapshot.value!["date"] as! String
            self.sortedMessages.append(m)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendMessage(sender: UIButton) {
        if messageField.text == "" {
            shakeMessageFieldX()
            return
        }
        var newMessage = Message()
        newMessage.message = messageField.text!
        newMessage.username = self.username
        let chatRoot = root.childByAppendingPath("chat")
        let messageKeyRoot = chatRoot.childByAutoId()
        let messagePOST = [
            "username": newMessage.username,
            "date": newMessage.date,
            "message": newMessage.message
        ]
        messageKeyRoot.setValue(messagePOST)
        messageField.text = ""
    }
    
    
    //===========================================================================
    //MARK: - KEYBOARD
    //===========================================================================
    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        let touch = touches.first!.locationInView(self.view)
//        if CGRectContainsPoint(tableView.frame, touch) {
//            messageField.resignFirstResponder()
//        }
//        
//    }
    @IBAction func touchReceived(gesture:UITapGestureRecognizer) {
        let touch = gesture.locationInView(self.view)
        if !CGRectContainsPoint(containerView.frame, touch) {
            messageField.resignFirstResponder()
        }
        
    }
    
    
    func keyboardDidAppear(notification:NSNotification) {
        if let userInfo = notification.userInfo, frame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue {
            let height = frame().height
            UIView.animateWithDuration(0.3, animations: {
                self.containerViewBottom.constant = height
                self.view.layoutIfNeeded()
            })
            scrollToBottom()
        }
    }
    
    func keyboardDidDisappear() {
        UIView.animateWithDuration(0.3, animations: {
            self.containerViewBottom.constant = 0
            self.view.layoutIfNeeded()
        })
        scrollToBottom()
    }
}

extension ChatViewController {
    
//    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 1
//    }
    
//    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 0
//    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatTableViewCell
        let row = Int(indexPath.row)
        cell.usernameLabel.text = sortedMessages[row].username
        cell.dateLabel.text = sortedMessages[row].date
        cell.textView.text = sortedMessages[row].message
        return cell
    }
    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        //
//        
//    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedMessages.count
    }
    
    func reloadTable() {
        tableView.reloadData()
        scrollToBottom()
    }
    
    func shakeMessageFieldX() {
        let animations:[CGFloat] = [20.0, -20.0, 10.0, -10.0, 3.0, -3.0, 0.0]
        
        for i in 0..<animations.count {
//            let constant = animations[i]
            let frameOrigin = CGPointMake(self.messageField.frame.origin.x + animations[i], self.messageField.frame.origin.y)
            UIView.animateWithDuration(0.075, delay: 0.075 * Double(i), usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: [], animations: {
                self.messageField.frame.origin = frameOrigin
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
    }

    func scrollToBottom() {
        if sortedMessages.isEmpty {
            return
        }
        let indexPath = NSIndexPath(forItem: sortedMessages.count - 1, inSection: 0)
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        
    }
    
}

extension NSDate: Comparable { }

    public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
        return lhs.isEqualToDate(rhs)
    }

    public func <(lhs: NSDate, rhs: NSDate) -> Bool {
        return lhs.compare(rhs) == .OrderedAscending
    }