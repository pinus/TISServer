//
//  main.swift
//  TISServer
//
//  Created by pns
//

let VERSION = "2.0"

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

import AppKit
import OSLog

let logger = Logger(subsystem: "tis-server", category: "Service")

var japaneseId: String?
var katakanaId: String?
var romanId: String?
var abcId: String?
var usId: String?
var usExtendedId: String?
var atokId: String?
var kotoeriId: String?
let txtView = NSTextInputContext.init(client: NSTextView.init())

func log(_ message: String) {
    logger.log("\(message, privacy: .public)")
}

/// 初期設定
func initialize() {
    guard let sources = txtView.keyboardInputSources else {
        print("No keyboard input sources available.")
        return
    }
    for source in sources {
        if source == "com.apple.keylayout.ABC" { abcId = source }
        else if source == "com.apple.keylayout.US" { usId = source }
        else if source == "com.apple.keylayout.USExtended" { usExtendedId = source }
        else if source.contains("justsystem") {
            if source.hasSuffix(".Japanese") { atokId = source }
            else if source.hasSuffix(".Roman") { romanId = source }
            else if source.hasSuffix(".Katakana") { katakanaId = source }
        } else if source.contains("Kotoeri") {
            if source.hasSuffix(".Japanese") { kotoeriId = source }
        }
    }
    if atokId != nil { japaneseId = atokId }
    else if kotoeriId != nil { japaneseId = kotoeriId; romanId = usId }
}

/// Select InputSource if changed
func select(_ target: String?) {
    let selected = txtView.selectedKeyboardInputSource
    
    if target != selected {
        log("to \(target!) from \(selected!) ")
        txtView.selectedKeyboardInputSource = target!
    } else { log("Already selected") }
    
    print("OK")
    fflush(stdout)
}


initialize()

DispatchQueue.global().async {
    while true {
        if let input = readLine() {
            
            DispatchQueue.main.async {
                let requestID = input.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if requestID == "J" { select(japaneseId) }
                else if requestID == "R" { select(romanId) }
                else if requestID == "K" { select(katakanaId) }
                else if requestID == "A" { select(abcId) }
                else if requestID == "U" { select(usId) }
                else if requestID == "X" { select(usExtendedId) }
                else if requestID == "Q" { exit(0) }
                else if requestID == "?" { print(VERSION); fflush(stdout) }
            }
        }
    }
}

RunLoop.main.run()
