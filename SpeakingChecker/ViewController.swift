//
//  ViewController.swift
//  SpeakingChecker
//
//  Created by MekeFactory on 2019/06/18.
//  Copyright © 2019 MekeFactory. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    
    private var speechRecognizer: SFSpeechRecognizer!
    private var recognitionTask: SFSpeechRecognitionTask!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest!
    private let audioEngine = AVAudioEngine()
    
    enum Mode {
        case none
        case recording
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
                self.button.isEnabled = false
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
            setMode(.none)
        }
    }
    
    private func startRecording() throws {
        if let recTask = recognitionTask {
            recTask.cancel()
            self.recognitionTask = nil
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recRequest = recognitionRequest else {
            fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recRequest) { result, error in
            var isFinal = false
            if let result = result {
                if (self.mode == .recording) {
                    self.label.text = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
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
            button.setTitle("開始", for: .normal)
            button.backgroundColor = UIColor.blue
        case .recording:
            button.setTitle("停止", for: .normal)
            button.backgroundColor = UIColor.red
        }
    }
}
