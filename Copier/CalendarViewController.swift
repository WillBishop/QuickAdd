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
    
    
    @IBOutlet weak var commandToggle: NSButton!
    @IBOutlet weak var shiftToggle: NSButton!
    @IBOutlet weak var optionToggle: NSButton!
    @IBOutlet weak var controlToggle: NSButton!
    @IBOutlet weak var actionKey: NSTextField!
    var enabledModifiers = NSEvent.ModifierFlags()
    var enabledActionKey: Key? = nil
    private var eventStore = EKEventStore()
    private var input = NSTextField()
    private var dateLabel = NSTextField()
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
        

        commandToggle.state = (UserDefaults.standard.bool(forKey: "commandEnabled") ? NSControl.StateValue.on : NSControl.StateValue.off)
        shiftToggle.state = (UserDefaults.standard.bool(forKey: "shiftEnabled") ? NSControl.StateValue.on : NSControl.StateValue.off)
        optionToggle.state = (UserDefaults.standard.bool(forKey: "optionEnabled") ? NSControl.StateValue.on : NSControl.StateValue.off)
        controlToggle.state = (UserDefaults.standard.bool(forKey: "controlEnabled") ? NSControl.StateValue.on : NSControl.StateValue.off)
        self.actionKey.stringValue = UserDefaults.standard.string(forKey: "actionKey") ?? "c"
        actionKey.delegate = self
        actionKey.tag = 1
        
    }
    func register(_ sender: Any?, keyCombo: KeyCombo) {
    
        hotKey = HotKey(keyCombo: keyCombo)
    }
    
    @objc func createAlert() -> Bool{
        let alert = NSAlert()
        alert.messageText = "Create Quick Event"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 290, height: 40))
        
        input = NSTextField(frame: NSRect(x: 0, y: 25, width: 290, height: 20))
        input.placeholderString = "Movie at 7 pm on Friday"
        input.delegate = self
        input.tag = 0
        
        dateLabel = NSTextField(frame: NSRect(x: 0, y: 0, width: 290, height: 20))
        dateLabel.isBordered = false
        dateLabel.backgroundColor = NSColor.clear
        dateLabel.placeholderString = ""
        dateLabel.isEditable = false
        dateLabel.isSelectable = false
        
        view.addSubview(dateLabel)
        view.addSubview(input)
        alert.accessoryView = view
        alert.window.initialFirstResponder = input
        return alert.runModal() == .alertFirstButtonReturn
        
    }
    override func controlTextDidChange(_ obj: Notification) {
        if let obj = obj.object as? NSTextField{
            switch obj.tag{
            case 0:
                self.parseRegularInput()
            case 1:
                self.changeActionKey()
            default:
                print()
            }
        }
        self.parseRegularInput()
        
    }
    func changeActionKey(){
        self.actionKey.stringValue = String(self.actionKey.stringValue.last ?? Character("c"))
        
        UserDefaults.standard.set(self.actionKey.stringValue, forKey: "actionKey")
        self.enabledActionKey = Key(string: String(self.actionKey.stringValue.last ?? Character("c")))
        if UserDefaults.standard.bool(forKey: "commandEnabled"){
            self.enabledModifiers.insert(.command)
        }
        if UserDefaults.standard.bool(forKey: "shiftEnabled"){
            self.enabledModifiers.insert(.shift)
            
        }
        if UserDefaults.standard.bool(forKey: "optionEnabled"){
            self.enabledModifiers.insert(.option)
            
        }
        if UserDefaults.standard.bool(forKey: "controlEnabled"){
            self.enabledModifiers.insert(.control)
            
        }
        let keyCombo = KeyCombo(key: enabledActionKey ?? .c, modifiers: enabledModifiers ?? [.command, .shift])
        self.register(self, keyCombo: keyCombo)

        
    }
    func parseRegularInput(){
        let inputString = input.stringValue.replacingOccurrences(of: "until", with: "to")
        guard let event = Chrono.casual.parse(text: inputString).first else {
            dateLabel.placeholderString = ""
            return
        }
        var eventTitle = input.stringValue.replacingOccurrences(of: event.text, with: "").condenseWhitespace()
        if input.stringValue.contains("until"){
            eventTitle = input.stringValue.replacingOccurrences(of: "until", with: "to").replacingOccurrences(of: event.text, with: "").condenseWhitespace()
        }
        let start = event.start.date
        let end = event.end?.date ?? Calendar.current.date(byAdding: .hour, value: 1, to: event.start.date)
        let hours = (end?.timeIntervalSince(start) ?? 3600) / 60 / 60
        let hoursString = forTrailingZero(temp: hours)
        let format = DateFormatter()
        format.dateFormat = "dd/MM/yyyy h:mma"
        var todayString = format.string(from: start) + " (\(hoursString) Hours)"
        if Calendar.current.isDateInToday(start){
            format.dateFormat = "h:mma"
            todayString = "at " + format.string(from: start) + " (\(hoursString) Hours)"
        } else if Calendar.current.isDateInTomorrow(start){
            format.dateFormat = "h:mma"
            todayString = "Tomorrow at " + format.string(from: start) + " (\(hoursString) Hours)"
        }
        
        dateLabel.placeholderString = "\"\(eventTitle)\", \(todayString)"
    }
    func forTrailingZero(temp: Double) -> String {
        var tempVar = String(format: "%g", temp)
        return tempVar
    }
    
    func createEvent(){
        let chrono = Chrono()
        guard let event = chrono.parse(text: input.stringValue.replacingOccurrences(of: "until", with: "to")).first else {return}
        let eventTitle = input.stringValue.replacingOccurrences(of: event.text.replacingOccurrences(of: "until", with: "to"), with: "")
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
    @IBAction func toggleModifierKey(_ sender: NSButton) {
        var shiftEnabled = shiftToggle.state == .on
        var controlEnabled = controlToggle.state == .on
        var optionEnabled = optionToggle.state == .on
        var commandEnabled = commandToggle.state == .on
        UserDefaults.standard.set(true, forKey: "customHotkey")
        
        UserDefaults.standard.set(shiftEnabled, forKey: "shiftEnabled")
        UserDefaults.standard.set(controlEnabled, forKey: "controlEnabled")
        UserDefaults.standard.set(optionEnabled, forKey: "optionEnabled")
        UserDefaults.standard.set(commandEnabled, forKey: "commandEnabled")
        if UserDefaults.standard.bool(forKey: "commandEnabled"){
            self.enabledModifiers.insert(.command)
        }
        if UserDefaults.standard.bool(forKey: "shiftEnabled"){
            self.enabledModifiers.insert(.shift)
            
        }
        if UserDefaults.standard.bool(forKey: "optionEnabled"){
            self.enabledModifiers.insert(.option)
            
        }
        if UserDefaults.standard.bool(forKey: "controlEnabled"){
            self.enabledModifiers.insert(.control)
            
        }
        let keyCombo = KeyCombo(key: enabledActionKey ?? .c, modifiers: enabledModifiers ?? [.command, .shift])
        self.register(self, keyCombo: keyCombo)
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
        
        viewcontroller.eventStore.requestAccess(to: .event, completion: { (granted, error) in
            print(granted)
        })
        viewcontroller.enabledActionKey = Key(string: UserDefaults.standard.string(forKey: "actionKey") ?? "c")
        
        
        if UserDefaults.standard.bool(forKey: "commandEnabled"){
            viewcontroller.enabledModifiers.insert(.command)
        }
        if UserDefaults.standard.bool(forKey: "shiftEnabled"){
            viewcontroller.enabledModifiers.insert(.shift)
            
        }
        if UserDefaults.standard.bool(forKey: "optionEnabled"){
            viewcontroller.enabledModifiers.insert(.option)
            
        }
        if UserDefaults.standard.bool(forKey: "controlEnabled"){
            viewcontroller.enabledModifiers.insert(.control)
            
        }
        let enabledActionKey = Key(string: UserDefaults.standard.string(forKey: "actionKey") ?? "c")
        let keyCombo = KeyCombo(key: enabledActionKey ?? .c, modifiers: viewcontroller.enabledModifiers ?? [.command, .shift])
        viewcontroller.register(self, keyCombo: keyCombo)
        return viewcontroller
    }
   
}

extension String {
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: NSCharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
