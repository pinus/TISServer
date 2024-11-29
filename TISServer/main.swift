import Foundation
import Carbon

var japaneseSource: TISInputSource?
var katakanaSource: TISInputSource?
var romanSource: TISInputSource?
//var japaneseID = ""
//var katakanaID = ""
//var romanID = ""

// get list of available inputSources
guard let inputSourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
    exit(1)
}

// Scan japanese/roman IntputSource
for inputSource in inputSourceList {
    //let rawId = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID)
    //let id = unsafeBitCast(rawId, to: NSString.self) as String
    let rawMode = TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID)
    let mode = unsafeBitCast(rawMode, to: NSString.self) as String
    //print("id: \(id), mode: \(mode)")

    if mode == "com.apple.inputmethod.Japanese" {
        //japaneseID = id
        japaneseSource = inputSource
    } else if mode == "com.apple.inputmethod.Japanese.Katakana" {
        //katakanaID = id
        katakanaSource = inputSource
    } else if mode == "com.apple.inputmethod.Roman" {
        //romanID = id
        romanSource = inputSource
    }
}

// Check nil
if japaneseSource == nil { japaneseSource = romanSource }
if katakanaSource == nil { katakanaSource = japaneseSource }

// Change InputSource with stdin/stdout
while true {
    if let input = readLine() {
        let requestID = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if requestID == "J" { TISSelectInputSource(japaneseSource) }
        else if requestID == "R" { TISSelectInputSource(romanSource) }
        else if requestID == "K" { TISSelectInputSource(katakanaSource) }
        else if requestID == "EXIT" { exit(0) }
    }
}
