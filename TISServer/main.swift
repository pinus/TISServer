//
//  main.swift
//  TISServer
//
//  Created by pns
//

import Carbon
import AppKit

let VERSION = "1.2"

var japaneseSource: TISInputSource?
var katakanaSource: TISInputSource?
var romanSource: TISInputSource?
var abcSource: TISInputSource?
var usSource: TISInputSource?
var usExtendedSource: TISInputSource?
//let txtView = NSTextInputContext.init(client: NSTextView.init())

func scanInputSources() {
    // get list of available inputSources
    guard let inputSourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
        exit(1)
    }

    // Scan japanese/roman IntputSources
    for inputSource in inputSourceList {
        //
        // lookup by id: com.apple.keylayout {.US, .USExtended, .ABC, ... }
        //
        if let raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {  //Optional<UnsafeMutableRawPointer>
            let id = Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
            if id == "com.apple.keylayout.ABC" {
                abcSource = inputSource
            } else if id == "com.apple.keylayout.US" {
                usSource = inputSource
            } else if id == "com.apple.keylayout.USExtended" {
                usExtendedSource = inputSource
            }
        }
        //
        // lookup by mode: com.apple.inputmethod { .Roman, .Japanese, .Japanese.Katakana }
        // corresponding id = com.justsystems.inputmethod.atok35 {.Roman, .Japanese, .Japanese.Katakana }
        //
        if let raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID) {
            let mode = Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
            if mode == "com.apple.inputmethod.Japanese" {
                japaneseSource = inputSource
            } else if mode == "com.apple.inputmethod.Japanese.Katakana" {
                katakanaSource = inputSource
            } else if mode == "com.apple.inputmethod.Roman" {
                romanSource = inputSource
            }
        }
        //print("\(id) : \(mode)")
    }
}

// Select InputSource if changed
func select(_ inputSource: TISInputSource?) {
    // select through TIS
    if let raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelected) {
        let isSelected = Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue() as! Bool
        if !isSelected {
            TISSelectInputSource(inputSource)
        } //else { print ("Already selected") }
    }

    // select through NSTextView
//    if !Thread.isMainThread {
//        DispatchQueue.main.async { select(inputSource) }
//        return
//    }
//
//    if let raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) {
//        let id = Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
//        let selected = txtView.selectedKeyboardInputSource
//        if id != selected {
//            txtView.selectedKeyboardInputSource = id
//        } // else { print("Already selected") }
//    }

    print("OK")
    fflush(stdout)
}

scanInputSources()
DispatchQueue.main.async {
    while true {
        if let input = readLine() {
            let requestID = input.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if requestID == "J" { select(japaneseSource) }
            else if requestID == "R" { select(romanSource) }
            else if requestID == "K" { select(katakanaSource) }
            else if requestID == "A" { select(abcSource) }
            else if requestID == "U" { select(usSource) }
            else if requestID == "X" { select(usExtendedSource) }
            else if requestID == "Q" { exit(0) }
            else if requestID == "?" { print(VERSION); fflush(stdout) }
        }
    }
}

RunLoop.current.run()
