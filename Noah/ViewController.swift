//
//  ViewController.swift
//  Noah
//
//  Created by Edward Arenberg on 3/12/18.
//  Copyright © 2018 Edward Arenberg. All rights reserved.
//

import UIKit
import ArcGIS
import Speech

extension ViewController : SFSpeechRecognizerDelegate {
    
}

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: AGSSceneView!
    @IBOutlet weak var menuButton: UIButton! {
        didSet {
            menuButton.layer.cornerRadius = 24
            menuButton.layer.masksToBounds = true
        }
    }
    @IBAction func menuHit(_ sender: UIButton) {
    }
    
    @IBOutlet weak var cameraButton: UIButton! {
        didSet {
            cameraButton.layer.cornerRadius = 24
            cameraButton.layer.masksToBounds = true
        }
    }
    @IBAction func cameraHit(_ sender: UIButton) {
    }
    
    @IBOutlet weak var noahIV: UIImageView! {
        didSet {
            noahIV.layer.cornerRadius = 40
            noahIV.layer.masksToBounds = true
        }
    }
    @IBAction func noahTapped(_ sender: UITapGestureRecognizer) {
        let utterance = AVSpeechUtterance(string: "Zoom in so I can get a better view.")
//        print(AVSpeechSynthesisVoice.speechVoices())
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")

        self.synthesizer.speak(utterance)
    }
    
    @IBOutlet weak var microphoneButton: UIButton!
    @IBAction func microphoneTouchDown(_ sender: UIButton) {
        startRecording()
    }
    @IBAction func microphoneTouchUp(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        } else {
        }
    }
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()

    
    var portal : AGSPortal!
    
    func getLayer() {
        
        self.portal = AGSPortal(url: URL(string: "https://www.arcgis.com")!, loginRequired: false)
        self.portal.credential = AGSCredential(user: "theUser", password: "thePassword")
        self.portal.load() {[weak self] (error) in
            if let error = error {
                print(error)
                return
            }
            // check the portal item loaded and print the modified date
            if self?.portal.loadStatus == AGSLoadStatus.loaded {
                let fullName = self?.portal.user?.fullName
                print(fullName!)
            }
        }
    }
    
    func addLayer() {
        
        var drapedGraphicsOverlay: AGSGraphicsOverlay!
        var absoluteGraphicsOverlay: AGSGraphicsOverlay!
        var relativeGraphicsOverlay: AGSGraphicsOverlay!
        // create a draped graphics overlay
        drapedGraphicsOverlay = AGSGraphicsOverlay()
        drapedGraphicsOverlay.sceneProperties?.surfacePlacement = AGSSurfacePlacement.draped
        sceneView.graphicsOverlays.add(drapedGraphicsOverlay)
        // create a absolute graphics overlay
        absoluteGraphicsOverlay = AGSGraphicsOverlay()
        absoluteGraphicsOverlay.sceneProperties?.surfacePlacement = AGSSurfacePlacement.absolute
        sceneView.graphicsOverlays.add(absoluteGraphicsOverlay)
        // create a relative graphics overlay
        relativeGraphicsOverlay = AGSGraphicsOverlay()
        relativeGraphicsOverlay.sceneProperties?.surfacePlacement = AGSSurfacePlacement.relative
        sceneView.graphicsOverlays.add(relativeGraphicsOverlay)
        //create a point and marker symbols
        let point = AGSPointMake3D(-75.19, 39.94, 1000, 0, sceneView.spatialReference)
        let redMarker = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        let blueMarker = AGSSimpleMarkerSymbol(style: .circle, color: .blue, size: 10)
        let greenMarker = AGSSimpleMarkerSymbol(style: .circle, color: .green, size: 10)
        //create the graphics
        let drapedGraphic = AGSGraphic(geometry: point, symbol: redMarker)
        let absoluteGraphic = AGSGraphic(geometry: point, symbol: blueMarker)
        let relativeGraphic = AGSGraphic(geometry: point, symbol: greenMarker)
        //add the graphics in the overlays
        drapedGraphicsOverlay.graphics.add(drapedGraphic)
        absoluteGraphicsOverlay.graphics.add(absoluteGraphic)
        relativeGraphicsOverlay.graphics.add(relativeGraphic)
        //set the camera to look at the points
        let camera = AGSCamera(latitude: 39.94, longitude: -75.19, altitude: 1600, heading: 0, pitch: 70, roll: 0)
//        let camera = AGSCamera(latitude: 53.02, longitude: -4.04, altitude: 1600, heading: 0, pitch: 70, roll: 0)
        sceneView.setViewpointCamera(camera)
        sceneView.currentViewpointCamera()

        let sphereSymbol = AGSSimpleMarkerSceneSymbol(style: .sphere, color: .red, height: 1000, width: 1000, depth: 1000, anchorPosition: .center)
        //create a point
//        let pt = AGSPointMake3D(-4.04, 53.16, 1000, 0, self.sceneView.spatialReference)
        let pt = AGSPointMake3D(-75.19, 39.94, 1000, 0, self.sceneView.spatialReference)
        //create a graohic
        let graphic = AGSGraphic(geometry: pt, symbol: sphereSymbol)
        //add the graphic to the relative graphics overlay
        relativeGraphicsOverlay.graphics.add(graphic)

        /*
        var mapLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer")!)

        scene.basemap?.operationalLayers.addObject(mapLayer)
         */

        /*
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer")!)
        scene.basemap?.baseLayers.add(tiledLayer)
         */
        
        /*
        var basemap:AGSBasemap
        let map = AGSMap()
        var tiledLayer = AGSArcGISTiledLayer(URL: NSURL(string: "https://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer")!)
        basemap = AGSBasemap(baseLayer: tiledLayer)
        map.basemap = basemap
         */

        
        // AGSArcGISVectorTiledLayer   .tpk , .vtpk
        /*
        let l = AGSArcGISTiledLayer(url: URL(string:"")!)
        
        let mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/MapServer/layers/0")!)
        sceneView.graphicsOverlays.add(mapImageLayer)
         */

        /*
        let theMapImageLayerURL = URL(string:"")!
        let baseTimeImageLayer = AGSArcGISMapImageLayer(url: theMapImageLayerURL)

        self.map.basemap = AGSBasemap.topographic()
        self.map.operationalLayers.add(baseTimeImageLayer)
        self.map.operationalLayers.add(offsetTileImageLayer)
        self.mapView.map = map
        */
    }
    
    func getPublic() {
        self.portal = AGSPortal(url: URL(string: "https://www.arcgis.com")!, loginRequired: false)
        self.portal.load() {[weak self] (error) in
            if let error = error {
                print(error)
            }
            // check the portal item loaded and print the modified date
            if self?.portal.loadStatus == AGSLoadStatus.loaded {
                if let portalName = self?.portal.portalInfo?.portalName {
                    print(portalName)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //Assign the scene to the scene view
        sceneView.scene = scene
        speechRecognizer?.delegate = self
        //Set the current viewpoint of the camera
//        let camera = AGSCamera(latitude: 48.38, longitude: -4.493, altitude: 100, heading: 320, pitch: 70, roll: 0)
        let camera = AGSCamera(latitude: 39.94, longitude: -75.19, altitude: 1600, heading: 320, pitch: 70, roll: 0)
        sceneView.setViewpointCamera(camera)
        sceneView.isAttributionTextVisible = false
        sceneView.currentViewpointCamera()
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            DispatchQueue.main.async {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }

//        addLayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with:[.mixWithOthers,.defaultToSpeaker,.allowBluetooth])
        } catch {
            print(error)
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    // MARK: - Speech
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            //            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
//        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                let text = result?.bestTranscription.formattedString
                print(text)
                isFinal = (result?.isFinal)!
                
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if let text = result?.bestTranscription.formattedString {
                    
                    self.processText(text: text)
                    
                } else {
                    let utterance = AVSpeechUtterance(string: "Say again?")
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
                    self.synthesizer.speak(utterance)
                }
                
            }
        })
        
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
//            self.recognitionRequest?.append(buffer)
//        }
//
//        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
    }
    
    func processText(text:String) {
        let str = text.lowercased()
        
        let sa = str.components(separatedBy: " ")
        if sa.contains("done") || sa.contains("exit") {

            return
        } else if sa.contains("down") {
            
            let cam = sceneView.currentViewpointCamera()
            let z = cam.location.z
            let newCam = cam.elevate(withDeltaAltitude: -z/2)
            sceneView.setViewpointCamera(newCam, duration: 1.5, completion: nil)

        } else if sa.contains("up") {
            
            let cam = sceneView.currentViewpointCamera()
            let z = cam.location.z
            let newCam = cam.elevate(withDeltaAltitude: z)
            sceneView.setViewpointCamera(newCam, duration: 1.5, completion: nil)
            
        } else if sa.contains("help") {
            let utterance = AVSpeechUtterance(string: "Try saying things like down, up, report, or reset")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            self.synthesizer.speak(utterance)
            return
        }
        
    }


}

