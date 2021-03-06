//
//  AppDelegate.swift
//  Copier
//
//  Created by Will Bishop on 16/8/18.
//  Copyright © 2018 Will Bishop. All rights reserved.
//

import Cocoa
import HotKey
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let menu = NSMenu()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    var existingItems: [Data]?
    var existingTypes: [NSPasteboard.PasteboardType]?
    let popover = NSPopover()
    var eventMonitor: EventMonitor?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        if let button = statusItem.button, var image = NSImage(named: NSImage.Name(rawValue: "StatusBarButtonImage")){
            image.isTemplate = true
            button.image = image
          
            
            button.action = #selector(togglePopover(_:))
        }
        menu.addItem(NSMenuItem(title: "Record Hotkey", action: #selector(recordHotkey), keyEquivalent: "P"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Quotes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        popover.contentViewController = CalendarViewController.freshController()
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    func constructMenu() {
        menu.addItem(NSMenuItem(title: "Quit ", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.title = "Copier"
        statusItem.menu = menu
    }
    @objc func recordHotkey(){
        self.togglePopover(self)
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        eventMonitor?.start()

    }
    
    func closePopover(sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()

    }
}

