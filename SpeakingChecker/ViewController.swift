//
//  ViewController.swift
//  SpeakingChecker
//
//  Created by MekeFactory on 2019/06/18.
//  Copyright © 2019 MekeFactory. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var subject: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    private var speechRecognizer: SFSpeechRecognizer!
    private var recognitionTask: SFSpeechRecognitionTask!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest!
    private let audioEngine = AVAudioEngine()
    private var talker = AVSpeechSynthesizer()
    
    let words = [
        "hello",
        "natural",
        "early",
        "enough",
        "usual",
        "black",
        "sunny",
        "eleventh",
        "yellow",
        "first",
        "favorite",
        "new"
    ]
    var word: String!
    var index = 0
    
    // 録音状態
    enum Mode {
        case none
        case recording
        case stopping
    }
    private var mode = Mode.none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subject.text = words[index]
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                break
            default:
                self.startButton.isEnabled = false
            }
        }
        setMode(.none)
    }
    
    @IBAction func onStart(_ sender: Any) {
        switch mode {
        case .none:
            try! self.startRecording()
            setMode(.recording)
        case .recording:
            stopRecording()
            setMode(.stopping)
        default:
            break
        }
    }
    
    private func startRecording() throws {
        // AVAudioEngineによる録音中でも再生音量が小さくならない
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
        try audioSession.setMode(AVAudioSession.Mode.default)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)

        // タスクがあれば終了
        if let recTask = recognitionTask {
            recTask.cancel()
            self.recognitionTask = nil
        }
        
        // リクエスト作成
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recRequest = recognitionRequest else {
            fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
        }
        
        // リクエストをタスクにセット
        recRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recRequest) { result, error in
            var isFinal = false
            if let result = result {
                isFinal = result.isFinal
                if isFinal {
                    let str = result.bestTranscription.formattedString
                    self.label.text = str
                    
                    // 単語判定
                    if str.uppercased() == self.words[self.index].uppercased() {
                        self.label.textColor = UIColor.green
                    } else {
                        self.label.textColor = UIColor.red
                    }
                }
                self.stopRecording()
            }
            if error != nil || isFinal {
                // 終了処理
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.setMode(.none)
            }
        }
        
        // マイク
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(
        onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
    
    func setMode(_ mode:Mode){
        self.mode = mode
        switch mode {
        case .none:
            startButton.setTitle("Start", for: .normal)
            startButton.backgroundColor = UIColor.blue
        case .recording:
            label.text = ""
            label.textColor = UIColor.black
            startButton.setTitle("REC", for: .normal)
            startButton.backgroundColor = UIColor.red
        default:
            break
        }
    }
    
    @IBAction func onExample(_ sender: Any) {
        let utterance = AVSpeechUtterance(string: words[index])
        utterance.voice = AVSpeechSynthesisVoice(language: "en")
        talker.speak(utterance)
    }
    
    @IBAction func onNext(_ sender: Any) {
        if index >= words.count-1 {
            index = 0
        } else {
            index += 1
        }
        subject.text = words[index]
    }
}
