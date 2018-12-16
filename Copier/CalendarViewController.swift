//
//  CalendarViewController.swift
//  Copier
//
//  Created by Will Bishop on 18/8/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import Cocoa
import EventKit
import HotKey
import SwiftyChrono

class CalendarViewController: NSViewController, NSTextFieldDelegate {
    
    private var eventStore = EKEventStore()
    private var input = NSTextField()
    private var hotKey: HotKey? {
        didSet {
            guard let hotKey = hotKey else {
                print("Unregistered")
                return
            }
            
            print("Registered")
            
            hotKey.keyDownHandler = { [weak self] in
                if self?.createAlert() ?? false{
                    self?.createEvent()
                }
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    func register(_ sender: Any?) {
        hotKey = HotKey(keyCombo: KeyCombo(key: .c, modifiers: [.command, .shift]))
    }
    
    @objc func createAlert() -> Bool{
        let alert = NSAlert()
        alert.messageText = "Create Quick Event"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        input = NSTextField(frame: NSRect(x: 0, y: 0, width: 290, height: 20))
        input.placeholderString = "Movie at 7 pm on Friday"
        input.delegate = self
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        return alert.runModal() == .alertFirstButtonReturn
        
    }
    func createEvent(){
        let chrono = Chrono()
        guard let event = chrono.parse(text: input.stringValue).first else {return}
        let eventTitle = input.stringValue.replacingOccurrences(of: event.text, with: "")
        let start = event.start.date
        let end = event.end?.date ?? Calendar.current.date(byAdding: .hour, value: 1, to: event.start.date)
        self.createEvent(withTitle: eventTitle, startDate: start, endDate: end)
    }
    func createEvent(withTitle eventName: String, startDate start: Date, endDate end: Date? = nil){
        
       
        eventStore.requestAccess(to: .event) { (granted, error) in
            
            if (granted) && (error == nil) {
                print("granted \(granted)")
                print("error \(error)")
                
                let event = EKEvent(eventStore: self.eventStore)
                
                event.title = eventName
                event.startDate = start
                event.endDate = end
                event.calendar = self.eventStore.defaultCalendarForNewEvents
                do {
                    try self.eventStore.save(event, span: .thisEvent, commit: true)
                } catch let error as NSError {
                    print("failed to save event with error : \(error)")
                }
                event.calendar.refresh()

                print("Saved Event")
            }
            else{
                
                print("failed to save event with error : \(error) or access not granted")
            }
        }
    }
}

extension CalendarViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> CalendarViewController {
        //1.
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        //2.
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "CalendarViewController")
        //3.
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? CalendarViewController else {
            fatalError("Why cant i find CalendarViewController? - Check Main.storyboard")
        }
        viewcontroller.register(self)
        viewcontroller.eventStore.requestAccess(to: .event, completion: { (granted, error) in
            print(granted)
        })
        return viewcontroller
    }
}
