//
//  main.swift
//  TISServer
//
//  Created by pns
//

let VERSION = "1.4"

import Carbon

var japaneseSource: TISInputSource?
var katakanaSource: TISInputSource?
var romanSource: TISInputSource?
var abcSource: TISInputSource?
var usSource: TISInputSource?
var usExtendedSource: TISInputSource?

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
// current input source does not update in response to manual input source changes
func select(_ inputSource: TISInputSource?) {
    // select through TIS
//    if let raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelected) {
//        let isSelected = Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue() as! Bool
//        if !isSelected {
//            TISSelectInputSource(inputSource)
//        } //else { print ("Already selected") }
//    }
    let selected = TISCopyCurrentKeyboardInputSource().takeUnretainedValue()
    if selected != inputSource {
        TISSelectInputSource(inputSource)
    } //else { print ("Already selected") }

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
RunLoop.main.run()


/*
 com.apple.keylayout.Russian: 'Russian'
 com.apple.keylayout.US: 'U.S.'
 com.apple.keylayout.ABC: 'ABC'
 com.apple.keylayout.USExtended: 'ABC – Extended'
 com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese: 'Hiragana'
 com.apple.inputmethod.Kotoeri.RomajiTyping: 'Japanese – Romaji'
 com.justsystems.inputmethod.atok35.Roman: '英字　　（ATOK）'
 com.justsystems.inputmethod.atok35.Japanese.Katakana: 'カタカナ（ATOK）'
 com.justsystems.inputmethod.atok35.Japanese.FullWidthRoman: '全角英字（ATOK）'
 com.justsystems.inputmethod.atok35.Japanese: 'ひらがな（ATOK）'
 com.justsystems.inputmethod.atok35.Japanese.HalfWidthEiji: '半角英字（ATOK）'
 com.justsystems.inputmethod.atok35: 'ATOK'
 */

//import AppKit
//
//var japaneseId: String?
//var katakanaId: String?
//var romanId: String?
//var abcId: String?
//var usId: String?
//var usExtendedId: String?
//var atokId: String?
//var kotoeriId: String?
//let txtView = NSTextInputContext.init(client: NSTextView.init())
//
//func scanInputSources() {
//    guard let sources = txtView.keyboardInputSources else {
//        print("No keyboard input sources available.")
//        return
//    }
//    for source in sources {
//        if source == "com.apple.keylayout.ABC" { abcId = source }
//        else if source == "com.apple.keylayout.US" { usId = source }
//        else if source == "com.apple.keylayout.USExtended" { usExtendedId = source }
//        else if source.contains("justsystem") {
//            if source.hasSuffix(".Japanese") { atokId = source }
//            else if source.hasSuffix(".Roman") { romanId = source }
//            else if source.hasSuffix(".Katakana") { katakanaId = source }
//        } else if source.contains("Kotoeri") {
//            if source.hasSuffix(".Japanese") { kotoeriId = source }
//        }
//    }
//    if atokId != nil { japaneseId = atokId }
//    else if kotoeriId != nil { japaneseId = kotoeriId; romanId = usId }
//}
//
//// Select InputSource if changed
//func select(_ inputSource: String?) {
//    // select through NSTextView
//    // ** selectedKeyboardInputSource does not update in response to manual input source changes **
//    //guard let target = inputSource else { return }
//    //let selected = txtView.selectedKeyboardInputSource
//    //if target != selected {
//    //    txtView.selectedKeyboardInputSource = target
//    //} // else { print("Already selected") }
//
//    if let target = inputSource {
//        txtView.selectedKeyboardInputSource = target
//    }
//
//    print("OK")
//    fflush(stdout)
//}
//
//scanInputSources()
//
//DispatchQueue.main.async {
//    while true {
//        if let input = readLine() {
//            let requestID = input.trimmingCharacters(in: .whitespacesAndNewlines)
//            
//            if requestID == "J" { select(japaneseId) }
//            else if requestID == "R" { select(romanId) }
//            else if requestID == "K" { select(katakanaId) }
//            else if requestID == "A" { select(abcId) }
//            else if requestID == "U" { select(usId) }
//            else if requestID == "X" { select(usExtendedId) }
//            else if requestID == "Q" { exit(0) }
//            else if requestID == "?" { print(VERSION); fflush(stdout) }
//        }
//    }
//}
//
//RunLoop.current.run()
