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

// get list of available inputSources
guard let inputSourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
    exit(1)
}

// Scan japanese/roman IntputSources
for inputSource in inputSourceList {
    let raw = TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID) //Optional<UnsafeMutableRawPointer>
    let mode = unsafeBitCast(raw, to: NSString.self) as String

    if mode == "com.apple.inputmethod.Japanese" {
        japaneseSource = inputSource
    } else if mode == "com.apple.inputmethod.Japanese.Katakana" {
        katakanaSource = inputSource
    } else if mode == "com.apple.inputmethod.Roman" {
        romanSource = inputSource
    }
}

// Check nil
if japaneseSource == nil { japaneseSource = romanSource }
if katakanaSource == nil { katakanaSource = japaneseSource }

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
    
    else if requestID == "Q" { exit(0) }
}

RunLoop.current.run()
