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
 OCR "あ ひらがな（ATOK）", "ア カタカナ（ATOK）", "A 英字 （ATOK）", "us U.S.", "Q ABC", "At ABC- 拡張"
 */

import Vision
import ScreenCaptureKit
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
var textRequest: VNRecognizeTextRequest?
let ocrRegion = OCRRegion()

func log(_ message: String) {
    logger.log("\(message, privacy: .public)")
}

/// 画面上の特定の矩形範囲をキャプチャして OCR 結果を返す
func capturedString(filter: SCContentFilter, config: SCStreamConfiguration) async throws -> String {
    // 画面をキャプチャ
    let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    
    // Vision フレームワークによる OCR リクエスト
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([textRequest!])
    
    // 結果の取得
    guard let observations = textRequest!.results else { return "" }
    let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
    return recognizedStrings.joined(separator: " ")
}

/// Menuextra Clock UserDefaults の設定値
struct MenuextraClockSettings: Equatable {
    var isAnalog: Int
    var showSeconds: Int
    var showDate: Int
    var showDayOfWeek: Int
}

/// OCR 区画を menuextra clock の状態に応じて決め, filter, config を作る
class OCRRegion {
    let inputMenuWidth = 150.0
    let menuBarHeight = 28.0
    let domain = "com.apple.menuextra.clock"
    var settings = MenuextraClockSettings(isAnalog: -1, showSeconds: -1, showDate: -1, showDayOfWeek: -1)
    var captureFilter: SCContentFilter?
    var captureConfig: SCStreamConfiguration?

    func update() async throws {
        // UserDefaults のチェック
        if let analog = UserDefaults.standard.persistentDomain(forName: domain)?["IsAnalog"] as? Int,
           let showSeconds = UserDefaults.standard.persistentDomain(forName: domain)?["ShowSeconds"] as? Int,
           let showDate = UserDefaults.standard.persistentDomain(forName: domain)?["ShowDate"] as? Int,
           let showDayOfWeek = UserDefaults.standard.persistentDomain(forName: domain)?["ShowDayOfWeek"] as? Int {
            // updatecheck
            let newSetting = MenuextraClockSettings(isAnalog: analog, showSeconds: showSeconds, showDate: showDate, showDayOfWeek: showDayOfWeek)
            if settings == newSetting { return }
            
            log("Menuextra Clock setting updated.")
            settings = newSetting
                        
            var inputMenuOffset = 200.0
            if analog == 0 { // digital
                if showSeconds == 0 { inputMenuOffset -= 23.0 }
                if showDate == 2 { // hide date
                    if showDayOfWeek == 0 { inputMenuOffset -= 87.0 }
                    else { inputMenuOffset -= 76.0 }
                } else { // show date
                    if showDayOfWeek == 0 { inputMenuOffset -= 21.0 }
                }
            } else { inputMenuOffset -= 125.0 } // analog

            let content = try await SCShareableContent.current
            guard let display = content.displays.first else { return }
            let x = CGFloat(display.width) - inputMenuWidth - inputMenuOffset
            let rect = CGRect(x: x, y: 0.0, width: inputMenuWidth, height: menuBarHeight)
            
            captureFilter = SCContentFilter(display: display, excludingWindows: [])
            
            let config = SCStreamConfiguration()
            config.width = Int(rect.width)
            config.height = Int(rect.height)
            config.sourceRect = rect
            config.showsCursor = false
            
            captureConfig = config
        }
    }
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

    Task {
        // 入力メニューが表示される場所の矩形範囲を決める
        try await ocrRegion.update()
        
        // OCR 設定
        let request: VNRecognizeTextRequest = {
            let request = VNRecognizeTextRequest()
            request.customWords = ["ひらがな", "カタカナ", "英字", "拡張", "ABC", "U.S." ]
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["ja-JP", "en-US"]
            return request
        }()
        textRequest = request
    }
}

/// Select InputSource if changed
func select(_ target: String?) {
    Task {
        let clock = ContinuousClock()
        let asyncDuration = try await clock.measure {
            try await ocrRegion.update()
            
            guard let filter = ocrRegion.captureFilter,
                  let config = ocrRegion.captureConfig else { return }
            let captured = try await capturedString(filter: filter, config: config)
            log("capture = \(captured)")

            var selected: String?
            if captured.contains("ひら") {
                selected = japaneseId
            } else if captured.contains("カタ") {
                selected = katakanaId
            } else if captured.contains("英字") {
                selected = romanId
            } else if captured.contains("U.S.") {
                selected = usId
            } else if captured.contains("拡張") {
                selected = usExtendedId
            } else if captured.contains("ABC") {
                selected = abcId
            } else {
                selected = txtView.selectedKeyboardInputSource
            }
            
            if target != selected {
                log("to \(target!) from \(selected!) ")
                txtView.selectedKeyboardInputSource = target!
            } else { log("Already selected") }
            
        }
        log("duration: \(asyncDuration)")
    }
    print("OK")
    fflush(stdout)
}


initialize()

DispatchQueue.main.async {
    while true {
        if let input = readLine() {
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

RunLoop.main.run()
