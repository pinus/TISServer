//
//  main.swift
//  TISServer
//
//  Created by pns
//

import Carbon

var japaneseSource: TISInputSource?
var katakanaSource: TISInputSource?
var romanSource: TISInputSource?
var abcSource: TISInputSource?
var usSource: TISInputSource?
var usExtendedSource: TISInputSource?

// get list of available inputSources
guard let inputSourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
    exit(1)
}

// Scan japanese/roman IntputSources
for inputSource in inputSourceList {
    var raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID) //Optional<UnsafeMutableRawPointer>
    let mode = unsafeBitCast(raw, to: NSString.self) as String
    raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID)
    let id = unsafeBitCast(raw, to: NSString.self) as String

    //print(inputSource)
    if mode == "com.apple.inputmethod.Japanese" {
        japaneseSource = inputSource
    } else if mode == "com.apple.inputmethod.Japanese.Katakana" {
        katakanaSource = inputSource
    } else if mode == "com.apple.inputmethod.Roman" {
        romanSource = inputSource
    }
    if id == "com.apple.keylayout.ABC" {
        abcSource = inputSource
    } else if id == "com.apple.keylayout.US" {
        usSource = inputSource
    } else if id == "com.apple.keylayout.USExtended" {
        usExtendedSource = inputSource
    }
}

// Select InputSource if changed
func select(_ inputSource: TISInputSource?) {
    let raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelected)
    let isSelected = Unmanaged<AnyObject>.fromOpaque(raw!).takeUnretainedValue() as! Bool
    if !isSelected { TISSelectInputSource(inputSource) } // else { print ("Already selected") }
    print("OK")
    fflush(stdout)
}

// readLine in background to follow manual change
func readLineInBackground(completion: @escaping (String) -> Void) {
    DispatchQueue.global().async {
        while true {
            if let input = readLine() {
                completion(input)
            }
        }
    }
}

// call from main thread
readLineInBackground { input in
    let requestID = input.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if requestID == "J" { select(japaneseSource) }
    else if requestID == "R" { select(romanSource) }
    else if requestID == "K" { select(katakanaSource) }
    else if requestID == "A" { select(abcSource) }
    else if requestID == "U" { select(usSource) }
    else if requestID == "X" { select(usExtendedSource) }

    else if requestID == "Q" { exit(0) }
}

RunLoop.current.run()
