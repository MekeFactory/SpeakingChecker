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
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    private var speechRecognizer: SFSpeechRecognizer!
    private var recognitionTask: SFSpeechRecognitionTask!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest!
    private let audioEngine = AVAudioEngine()
    private var talker = AVSpeechSynthesizer()
    
    // 録音モード
    enum Mode {
        case none
        case recording
        case stopping
    }
    private var mode = Mode.none
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            do {
                try self.startRecording()
                setMode(.recording)
            } catch {
                print("ERROR")
            }
        case .recording:
            stopRecording()
            setMode(.stopping)
        default:
            break
        }
    }
    
    private func startRecording() throws {
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
                print(result.isFinal.description + ":" + result.bestTranscription.formattedString)
                if (self.mode == .recording) {
                    let str = result.bestTranscription.formattedString
                    self.label.text = str

                    // TODO:単語判定
                    if str.uppercased() == "HELLO" {
                        self.label.textColor = UIColor.red
                    }
                    self.stopRecording()
                }
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.setMode(.none)
            }
        }
        
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
            startButton.setTitle("開始", for: .normal)
            startButton.backgroundColor = UIColor.blue
        case .recording:
            label.text = ""
            label.textColor = UIColor.black
            startButton.setTitle("録音中", for: .normal)
            startButton.backgroundColor = UIColor.red
        default:
            break
        }
    }
    
    @IBAction func onSpeak(_ sender: Any) {
        let utterance = AVSpeechUtterance(string: "hello")
        utterance.voice = AVSpeechSynthesisVoice(language: "en")
        talker.speak(utterance)
    }
}
