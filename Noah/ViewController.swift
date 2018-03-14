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
import AVFoundation
import CoreLocation
import MapKit
import CoreLocation
//import Parse
//import ParseLiveQuery

//let liveQueryClient: Client = ParseLiveQuery.Client(server: "wss://noah.back4app.io")


extension ViewController : SFSpeechRecognizerDelegate {
    
}

extension ViewController: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        speechRequest?.appendAudioSampleBuffer(sampleBuffer)
    }
    
}

/* Not using delegate
extension ViewController: SFSpeechRecognitionTaskDelegate {
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
 
        let best = recognitionResult.bestTranscription.formattedString
        print(best)
        processText(text: best)
 
    }
}
 */

extension ViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // hack to wait for audio to truely finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.resumeRecording()

            do {
                try self.startRecording()
            } catch (let e) {
//                print(e)
            }

        }
    }
}

class ViewController: UIViewController {
    
    enum AppMode { case ask, map }
    var appMode : AppMode = .ask
    var myIdent = ""
    let featureTable = AGSServiceFeatureTable(url: URL(string:"https://services2.arcgis.com/PmX3KsvHLzk1y5Hn/arcgis/rest/services/Philly_View_Sharing/FeatureServer/0")!)
    
    let edIdent = "885A6BE5-D314-4D06-8832-3B3EE3EEC1B7"
    let noahIdent = "4979E40D-4765-40D8-9204-2D0E0983EF6D"

    override func awakeFromNib() {
        super.awakeFromNib()
        if let ident = UserDefaults.standard.string(forKey: "Noah_Identity") {
            myIdent = ident
        } else {
            myIdent = UUID().uuidString
            UserDefaults.standard.set(myIdent, forKey: "Noah_Identity")
            UserDefaults.standard.synchronize()
        }
        print(myIdent)
    }
    
    func say(_ text:String) {
        stopRecording()
//        pauseRecording()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.delegate = self
        synthesizer.speak(utterance)
    }
    
    func playDone(sound:Int = 1322) {
        AudioServicesPlayAlertSound(SystemSoundID(UInt32(sound)))

//        audioOut()
//        donePlayer.play()
    }
    
    func showNoah(_ show:Bool = true) {
        UIView.animate(withDuration: 0.25) {
            self.noahIV.alpha = show ? 1 : 0
        }
    }
//    private var subscription: Subscription<PFObject>!

    @IBOutlet weak var heardLabel: UILabel!
    @IBOutlet weak var askIV: UIImageView!
    @IBAction func askIVTapped(_ sender: UITapGestureRecognizer) {
        restartRecording()
        doAsk()
    }
    func doAsk() {
        audioOut()
        say("Where would you like to go?")
    }
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?

    
    private var capture: AVCaptureSession?
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    func startRecognizer() {
        
        SFSpeechRecognizer.requestAuthorization {
            [unowned self] (authStatus) in
            switch authStatus {
            case .authorized:
                /*
                do {
                    try self.startRecording()
                } catch let error {
                    print("There was a problem starting recording: \(error.localizedDescription)")
                }
                 */
                break
            case .denied:
                print("Speech recognition authorization denied")
            case .restricted:
                print("Not available on this device")
            case .notDetermined:
                print("Not determined")
            }
        }
    }
    
    /*
    private func restartRecording() throws {
     
        audioEngine.prepare()
        try audioEngine.start()
        recognitionTask = speechRecognizer?.recognitionTask(with: request) {
            [unowned self]
            (result, _) in
            if let transcription = result?.bestTranscription {
                print(transcription)
                print(transcription.formattedString)
                self.processText(text: transcription.formattedString)
            }
        }
    }
     */
    
    private func audioIn() {
        do {
            //            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with:[.mixWithOthers,.defaultToSpeaker,.allowBluetooth])
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord, with:[.mixWithOthers,.defaultToSpeaker,.allowBluetooth])
            try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeMeasurement)
            try AVAudioSession.sharedInstance().setActive(true)
            microphoneButton.alpha = 1
        } catch {
//            print(error)
        }
    }
    private func audioOut() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with:[.mixWithOthers,.defaultToSpeaker,.allowBluetooth])
            try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
            try AVAudioSession.sharedInstance().setActive(true)
            microphoneButton.alpha = 0.5
        } catch {
//            print(error)
        }
    }
    
    private func startRecording() throws {
        print("TRY START RECORDING - \(audioEngine.isRunning)")
        
        audioIn()
        
        if audioEngine.isRunning && recognitionTask == nil {
            print("RETRY...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                try? self.startRecording()
            }
            return
        } else if audioEngine.isRunning { return }
        
//        if audioEngine.isRunning { return }
        print("START RECORDING")
        
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024,
                        format: recordingFormat) { [unowned self]
                            (buffer, _) in
                            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        recognitionTask = speechRecognizer?.recognitionTask(with: request) {
            [unowned self]
            (result, _) in
            if let transcription = result?.bestTranscription {
//                print(transcription)
                let text = transcription.formattedString
                print(text)
                DispatchQueue.main.async {
                    self.heardLabel.text = text
                }
                self.processText(text: text)
            }
        }
    }
    
    private func stopRecording(_ force:Bool = false) {
        print("STOP RECORDING...")
        twoWord = false
        if audioEngine.isRunning || force {
            request.endAudio()
            recognitionTask?.cancel()
            recognitionTask = nil

            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.inputNode.reset()
        }
        audioOut()
        print("...STOPPED")
    }
    
    private func restartRecording(play:Bool = false, sound:Int = 1322) {
        stopRecording()
        if play { playDone(sound: sound) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            try? self.startRecording()
        }
    }
    
    private func pauseRecording() {
        print("PAUSE RECORDING")
        request.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    /*
    private func resumeRecording() {
        print("RESUME RECORDING")
        
        audioIn()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) {
            [unowned self]
            (result, _) in
            if let transcription = result?.bestTranscription {
//                print(transcription)
                print(transcription.formattedString)
                self.processText(text: transcription.formattedString)
            }
        }
    }
     */
    

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var arscnView: ARSCNView!
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            sceneView.isARModeEnabled = true
        }
    }
    
    
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
        say("Zoom in so I can get a better view.")
    }
    
    @IBOutlet weak var microphoneButton: UIButton!
    @IBAction func microphoneTouchDown(_ sender: UIButton) {
    }
    @IBAction func microphoneTouchUp(_ sender: UIButton) {
        restartRecording()
    }
    
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
    
    func addDots() {
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
        
        /*
         let sphereSymbol = AGSSimpleMarkerSceneSymbol(style: .sphere, color: .red, height: 1000, width: 1000, depth: 1000, anchorPosition: .center)
         //create a point
         //        let pt = AGSPointMake3D(-4.04, 53.16, 1000, 0, self.sceneView.spatialReference)
         let pt = AGSPointMake3D(-75.19, 39.94, 1000, 0, self.sceneView.spatialReference)
         //create a graohic
         let graphic = AGSGraphic(geometry: pt, symbol: sphereSymbol)
         //add the graphic to the relative graphics overlay
         relativeGraphicsOverlay.graphics.add(graphic)
         */
    }
    
    enum Layer : String {
        case census = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer"
        case demographics = "https://services.arcgisonline.com/arcgis/rest/services/Demographics/USA_Median_Age/MapServer"
        case crime = "https://utility.arcgis.com/usrsvcs/servers/519f044648cd4d169117a4d2d39dca75/rest/services/USA_Crime/MapServer"
        case safety = "https://megacity.esri.com/ArcGIS/rest/services/Demographics/USA_CrimeIndex/MapServer"
    }
    
    func addLayer(_ layer:Layer) {
        spinner.startAnimating()
        showNoah(true)
        playDone()
        if layer == .crime {
            
//            let portal = AGSPortal(url: URL(string: "https://www.arcgis.com")!, loginRequired: false)
            // https://utility.arcgis.com/usrsvcs/servers/519f044648cd4d169117a4d2d39dca75/rest/services/USA_Crime/MapServer
            // 519f044648cd4d169117a4d2d39dca75
            // 9fb4d96077e24bcba72ba6cf1139c9cf
            let portalItem = AGSPortalItem(portal: self.portal, itemID: "519f044648cd4d169117a4d2d39dca75")
//            let item = AGSPortalItem(url: URL(string:"https://utility.arcgis.com/usrsvcs/servers/519f044648cd4d169117a4d2d39dca75/rest/services/USA_Crime/MapServer")!)
//            print(item?.serviceURL)
//            let params = AGSPortalQueryParameters()
            guard let url = portalItem.serviceURL else { return }
            let mapLayer = AGSArcGISMapImageLayer(url: url)
            mapLayer.opacity = 0.5

            mapLayer.load(completion: { error in
                self.spinner.stopAnimating()
//                print(mapLayer.loadError)
                if error != nil { print(error); return }
                scene.operationalLayers.add(mapLayer)

                /*
                let legend = mapLayer.fetchLegendInfos(completion: { infos, error in
                    //            ageLayer.showInLegend = true
                    print(infos)
                })
                 */
            })

//            scene.operationalLayers.add(mapLayer)


        } else {
            let mapLayer = AGSArcGISMapImageLayer(url: URL(string: layer.rawValue)!)
            mapLayer.opacity = 0.5
//            scene.operationalLayers.add(mapLayer)
            mapLayer.load(completion: { error in
                self.spinner.stopAnimating()
//                print(mapLayer.loadError)
                if error != nil { print(error); return }
                scene.operationalLayers.add(mapLayer)

                /*
                let legend = mapLayer.fetchLegendInfos(completion: { infos, error in
                    //            ageLayer.showInLegend = true
                    print(infos)
                })
                 */
            })
            
        }

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
    
    func doReset() {
        let removes = sceneView.graphicsOverlays.filter { $0 is AGSGraphicsOverlay }
        sceneView.graphicsOverlays.removeObjects(in: removes)
        scene.operationalLayers.removeAllObjects()

        arMotionDataSource.stop()
        
        audioOut()

        stopRecording(true)
        self.playDone()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            try? self.startRecording()
        }
    }
    
    @IBAction func longPressReset(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            doReset()
            let fpc : AGSFirstPersonCameraController = self.sceneView.cameraController as! AGSFirstPersonCameraController
            resetPhilly()
            arMotionDataSource.start { (error) in
                if let error = error { print("error: \(error.localizedDescription)")}
            }
        }
    }
    
    func setupPhilly() {
        //        let cameraSanDiego = AGSCamera(latitude: 32.707, longitude: -117.156, altitude: 100, heading: 180, pitch: 0, roll: 0)
        // Franklin Square:  39.955620 , -75.150497
        let cameraPhilly = AGSCamera(latitude: 39.955620, longitude: -75.150497,
                                     altitude: 1500,
                                     heading: 45,
                                     pitch: 0,
                                     roll: 0)
        let fpcController = AGSFirstPersonCameraController(initialPosition: cameraPhilly)
        arMotionDataSource = AGSARKitMotionDataSource(arscnView: arscnView)
        fpcController.motionDataSource = arMotionDataSource
        //        fpcController.motionDataSource = arMotionDataSource
        
        sceneView.cameraController = fpcController
        
        fpcController.translationFactor = 1000
        
        fpcController.frameRate = .quality  // .balanced
        
        let ft = AGSServiceFeatureTable(url: URL(string:"https://services2.arcgis.com/PmX3KsvHLzk1y5Hn/arcgis/rest/services/Philly_View_Sharing/FeatureServer/0")!)
        scene.operationalLayers.add(ft)
        
        arMotionDataSource.start { (error) in
            if let error = error { print("error: \(error.localizedDescription)")}
        }
        //        arMotionDataSource.start { (error) in
        //            print("motion data source started with error: " + "\(error?.localizedDescription ?? "no error")")
        //        }
        
        ft.load(completion: { error in
            let g = AGSPoint(x: 55, y: 42, spatialReference: ft.spatialReference)
            let f = ft.createFeature(attributes: [:], geometry: g)
            ft.add(f, completion: { error in
                ft.applyEdits(completion: { results, error in
                    
                })
            })
        })
        
        
        
    }
    func resetPhilly() {
        let cameraPhilly = AGSCamera(latitude: 39.955620, longitude: -75.150497,
                                     altitude: 1500,
                                     heading: 45,
                                     pitch: 0,
                                     roll: 0)
        
        let fpc : AGSFirstPersonCameraController = sceneView.cameraController as! AGSFirstPersonCameraController
        fpc.isFadingTransition = true
        fpc.translationFactor = 1000
        fpc.initialPosition = cameraPhilly
    }
    
    var doneSound = URL(fileURLWithPath: Bundle.main.path(forResource: "beep", ofType: "wav")!)
    var donePlayer : AVAudioPlayer!
    var alertSound = URL(fileURLWithPath: Bundle.main.path(forResource: "reveal", ofType: "wav")!)
    var alertPlayer : AVAudioPlayer!

    var arMotionDataSource : AGSARKitMotionDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        getPublic()

        alertPlayer = try! AVAudioPlayer(contentsOf: alertSound)
        alertPlayer.prepareToPlay()
        donePlayer = try! AVAudioPlayer(contentsOf: doneSound)
        donePlayer.prepareToPlay()
        
        showNoah(false)

        speechRecognizer?.delegate = self
        //Set the current viewpoint of the camera
//        let camera = AGSCamera(latitude: 48.38, longitude: -4.493, altitude: 100, heading: 320, pitch: 70, roll: 0)
        
        /*
        let camera = AGSCamera(latitude: 39.94, longitude: -75.19, altitude: 1600, heading: 320, pitch: 70, roll: 0)
        sceneView.setViewpointCamera(camera)
        sceneView.currentViewpointCamera()
         */
        
        sceneView.isAttributionTextVisible = false

//        setupPhilly()

        //Assign the scene to the scene view
        sceneView.scene = scene

        synthesizer.delegate = self
        

        /*n
        let mQuery = PFQuery(className: "Marker")
        mQuery.whereKey("To", equalTo: myIdent)

        subscription = liveQueryClient.subscribe(mQuery).handle(Event.created) { _, object in
            // This is where we handle the event
            print(object)
        }
        */
//        addLayer(.demographics)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupPhilly()

        audioOut()
        startRecognizer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if appMode == .ask {
            doAsk()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var twoWord = false
    var processing = false
    var addressMode = false
    
    func processText(text:String) {
        showNoah(true)
        if processing { return }
        processing = true
        defer { showNoah(false); processing = false }
        let str = text.lowercased()
        let sa = str.components(separatedBy: " ")

        if addressMode {
            
            if sa.contains("done") {
                print(str)
                var addr = sa.dropLast().joined(separator: " ")
                print(addr)
                addr.append(", philadelphia")
                say(addr)
                addr.append(" pa")

                let philly = CLLocationCoordinate2D(latitude: 39.94, longitude: -75.19)
                let reg = CLCircularRegion(center: philly, radius: 30000, identifier: "philly")
                CLGeocoder().geocodeAddressString(addr, in: reg) { marks, error in
                    defer { self.addressMode = false }
                    if error != nil || marks == nil || marks!.isEmpty {
                        print("No Address Result")
                        self.say("I can't find that address")
                        return
                    }
                    guard let marks = marks else { return }
                    self.playDone()
                    print(marks)
                    if let loc = marks.first?.location {
                        print(loc)
                        let nc = AGSCamera(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, altitude: 187.5, heading: 0, pitch: 0, roll: 0)
                        
                        let fpc : AGSFirstPersonCameraController = self.sceneView.cameraController as! AGSFirstPersonCameraController
                        fpc.isFadingTransition = true
                        fpc.translationFactor = 125
                        fpc.initialPosition = nc

                    }
                }
                
                /*
                CLGeocoder().geocodeAddressString(addr) { marks, error in
                    if error != nil { print(error!); return }
                    guard let marks = marks else {
                        print("No Address Result")
                        self.say("I can't find that address")
                        return
                    }
                    print(marks)
                    if let loc = marks.first?.location {
                        print(loc)
                    }
                }
                 */
            }
//            request.shouldReportPartialResults = true

            
            return
        }
        
        if sa.contains("help") {
            twoWord = false
            if appMode == .map {
                say("Try saying things like zoom, bigger, show, mark, vocabulary, or exit")
            } else {
                say("Try saying a location like Philidelphia")
            }
        } else if appMode == .ask {
            twoWord = false
            say("Let's go to philly!")
            resetPhilly()
            if !arMotionDataSource.started {
                arMotionDataSource.start { (error) in
                    if let error = error { print("error: \(error.localizedDescription)")}
                }
            }
            UIView.animate(withDuration: 1.0) { self.askIV.alpha = 0 }
            appMode = .map
        } else if sa.contains("vocabulary") {
            twoWord = false
            say("These are the commands I know: zoom, bigger, address, origin, mark, info, share, clear, picture, exit, show safety, crime, demo, census")

        } else if sa.contains("done") || sa.contains("exit") {
            twoWord = false
//            restartRecording(play:true)
            say("Leaving philly!")
            if appMode == .ask { return }
            UIView.animate(withDuration: 0.5) { self.askIV.alpha = 1 }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.doAsk()
                self.appMode = .ask
                
                let removes = self.sceneView.graphicsOverlays.filter { $0 is AGSGraphicsOverlay }
                self.sceneView.graphicsOverlays.removeObjects(in: removes)
                scene.operationalLayers.removeAllObjects()
                
                self.arMotionDataSource.stop()
            }
            /*
        } else if sa.contains("down") {
            twoWord = false
            restartRecording(play:true)
            let cam = sceneView.currentViewpointCamera()
            let z = cam.location.z
            let newCam = cam.elevate(withDeltaAltitude: -z/2)
            sceneView.setViewpointCamera(newCam, duration: 1.5, completion: nil)

        } else if sa.contains("up") {
            twoWord = false
            restartRecording(play:true)
            let cam = sceneView.currentViewpointCamera()
            let z = cam.location.z
            let newCam = cam.elevate(withDeltaAltitude: z)
            sceneView.setViewpointCamera(newCam, duration: 1.5, completion: nil)
            */
        } else if sa.contains("zoom") {
            twoWord = false
            let fpc : AGSFirstPersonCameraController = sceneView.cameraController as! AGSFirstPersonCameraController
            if fpc.translationFactor <= 125 {
                say("Too close")
            } else {
                restartRecording(play:true)

                let point = sceneView.screen(toBaseSurface: arscnView.center)

                let cam = sceneView.currentViewpointCamera()
                let loc = cam.location
                let xd = loc.x - (loc.x - point.x) / 2
                let yd = loc.y - (loc.y - point.y) / 2
                let zd = loc.z - (loc.z - point.z) / 2
                let np = AGSPoint(x: xd, y: yd, z: zd, m: loc.m, spatialReference: loc.spatialReference)
                
                let nc = AGSCamera(location: np, heading: cam.heading, pitch: cam.pitch, roll: cam.roll)
//                let nc = cam.elevate(withDeltaAltitude: -(cam.location.z / 2.0))
                
                fpc.isFadingTransition = true
                fpc.translationFactor = fpc.translationFactor / 2.0
                fpc.initialPosition = nc
            }
            
//            let nc = AGSCamera(latitude: pt.latitude, longitude: pt.longitude, altitude: 250, heading: 0, pitch: 70, roll: 0)

            /*
            let cam = sceneView.currentViewpointCamera()
            let pt = CLLocationCoordinate2D(latitude: 39.954934, longitude: -75.151022)
//            var p = AGSPoint(clLocationCoordinate2D: pt)
            let nc = AGSCamera(latitude: pt.latitude, longitude: pt.longitude, altitude: 250, heading: 0, pitch: 70, roll: 0)
//            let newCam = cam.move(toLocation: p)
            sceneView.setViewpointCamera(nc, duration: 1.5, completion: nil)
             */
            
        } else if sa.contains("bigger") {
            twoWord = false
            let fpc : AGSFirstPersonCameraController = sceneView.cameraController as! AGSFirstPersonCameraController

            if fpc.translationFactor >= 2000 {
                say("Too far")
            } else {
                restartRecording(play:true)
                
                let cam = sceneView.currentViewpointCamera()
                let nc = cam.elevate(withDeltaAltitude: cam.location.z)
                
                
                fpc.isFadingTransition = true
                fpc.translationFactor = fpc.translationFactor * 2.0
                fpc.initialPosition = nc
            }
            
        } else if sa.contains("origin") {
            twoWord = false
            restartRecording(play:true)
            resetPhilly()

        } else if sa.contains("mark") {
            twoWord = false
            restartRecording(play:true)
            
            let point = sceneView.screen(toBaseSurface: arscnView.center)
//            let p = sceneView.screen(toLocation: arscnView.center, completion: {point in
//            })

            /*
            let cam = sceneView.currentViewpointCamera()
            
            var mp : AGSPoint = AGSGeometryEngine.projectGeometry(cam.location, to: .webMercator())! as! AGSPoint

            
//            let cp : AGSPoint = AGSGeometryEngine.projectGeometry(mp, to: .wgs84()) as! AGSPoint
            let point = AGSPointMake3D(mp.x, mp.y + 200, 50, mp.m, mp.spatialReference)
             */

            var relativeGraphicsOverlay: AGSGraphicsOverlay!
            relativeGraphicsOverlay = AGSGraphicsOverlay()
            relativeGraphicsOverlay.sceneProperties?.surfacePlacement = AGSSurfacePlacement.relative
            sceneView.graphicsOverlays.add(relativeGraphicsOverlay)

            let greenMarker = AGSSimpleMarkerSymbol(style: .circle, color: .green, size: 20)
            let relativeGraphic = AGSGraphic(geometry: point, symbol: greenMarker)
            relativeGraphicsOverlay.graphics.add(relativeGraphic)

            /*
            let pt = CLLocationCoordinate2D(latitude: 39.954934, longitude: -75.151022)
            //            var p = AGSPoint(clLocationCoordinate2D: pt)
            let nc = AGSCamera(latitude: pt.latitude, longitude: pt.longitude, altitude: 250, heading: 0, pitch: 70, roll: 0)
            //            let newCam = cam.move(toLocation: p)
            sceneView.setViewpointCamera(nc, duration: 1.5, completion: nil)
             */

        } else if sa.contains("share") {
            twoWord = false
//            restartRecording(play:true)

            var found = false
            defer {
                if !found { self.say("No mark to share") }
            }
            guard let overlay = sceneView.graphicsOverlays.lastObject as? AGSGraphicsOverlay else { return }
            guard let g = (overlay.graphics.firstObject as? AGSGraphic)?.geometry else { return }

            found = true
            let geom = AGSGeometryEngine.projectGeometry(g, to: .wgs84()) as! AGSPoint
            let fg = AGSPoint(x: geom.x, y: geom.y, spatialReference: geom.spatialReference)

            // https://services2.arcgis.com/PmX3KsvHLzk1y5Hn/arcgis/rest/services/Philly_View_Sharing/FeatureServer/0

            featureTable.load(completion: { error in
                if error != nil { print(error); return }
                
                let ng = AGSGeometryEngine.normalizeCentralMeridian(of: fg)
                let feature = self.featureTable.createFeature(attributes: [
                    "Sender":self.myIdent,
                    "Receiver":self.myIdent == self.edIdent ? self.noahIdent : self.edIdent
                    ], geometry: ng)
                guard let arcgisFeature = feature as? AGSArcGISFeature else { return }
                self.featureTable.add(arcgisFeature) {(error: Error?) -> Void in
                    if let error = error {
                        print("Error while adding feature :: \(error.localizedDescription)")
                        return
                    }
                    self.featureTable.applyEdits(completion: { (featureEditResults: [AGSFeatureEditResult]?, error: Error?)-> Void in
                        if let error = error {
                            print("Error while applying edit :: \(error.localizedDescription)")
                            return
                        }
                        self.say("Shared")
                        print("Apply Edits successful")
                    })
                }

            })
//            let fl = AGSFeatureLayer(featureTable: ft)

            
        } else if sa.contains("info") {
            twoWord = false
//            restartRecording(play:true)
            
            spinner.startAnimating()
            var found = false
            defer {
                self.spinner.stopAnimating()
                if !found { say("No mark on map") }
            }
            guard let overlay = sceneView.graphicsOverlays.lastObject as? AGSGraphicsOverlay else { return }
            guard let g = (overlay.graphics.firstObject as? AGSGraphic)?.geometry else { return }
            
            found = true
            let geom = AGSGeometryEngine.projectGeometry(g, to: .wgs84()) as! AGSPoint
            let ll = geom.toCLLocationCoordinate2D()
            let loc = CLLocation(latitude: ll.latitude, longitude: ll.longitude)

            CLGeocoder().reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) -> Void in
                self.spinner.stopAnimating()
                guard error == nil else {
                    self.say("Unknown Place")
                    print("Reverse geocoder failed with error" + error!.localizedDescription)
                    return
                }
                guard let pm = placemarks?.first else {
                    self.say("Unknown Place")
                    print("Problem with the data received from geocoder")
                    return
                }
                
                let name = pm.name ?? ""
                let subTh = pm.subThoroughfare ?? ""
                let th = pm.thoroughfare ?? ""
                let subLoc = pm.subLocality ?? ""
                
                print(name)
                print(subTh)
                print(th)
                print(subLoc)
                
                let location = name + " " + subLoc
                print(location)
                if location.isEmpty { self.say("I'm not sure") }
                else { self.say(location) }
                
            })
            
        } else if sa.contains("clear") {
            twoWord = false
            restartRecording(play:true)
            
            let removes = sceneView.graphicsOverlays.filter { $0 is AGSGraphicsOverlay }
            sceneView.graphicsOverlays.removeObjects(in: removes)
            
        } else if sa.contains("picture") {
            twoWord = false
            restartRecording(play:true, sound: 1108)
            
            if let img = screenShot() {
                UIImageWriteToSavedPhotosAlbum(img, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
            }

        } else if sa.contains("address") {
            twoWord = false
            restartRecording(play:true)
            addressMode = true
//            request.shouldReportPartialResults = false
            
        } else if sa.contains("show") && !twoWord {
            twoWord = true
            scene.operationalLayers.removeAllObjects()
            playDone()
            audioIn()
            checkLayer(sa: sa)

        } else if twoWord {
            checkLayer(sa: sa)
        }
        
    }
    
    func screenShot() -> UIImage? {
        let v = arscnView.snapshotView(afterScreenUpdates: true)
        let sv = sceneView.snapshotView(afterScreenUpdates: true)
        if let layer = sv?.layer {
            let scale = UIScreen.main.scale
            UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
            if let context = UIGraphicsGetCurrentContext() {
                layer.render(in: context)
                let screenshot = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return screenshot
            }
        }
        return nil
    }
    @objc func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            say("Not saved, sorry!")
        } else {
            say("Image saved!")
        }
    }

    func checkLayer(sa:[String]) {
        if sa.contains("crime") {
            restartRecording(play:true)
            addLayer(.crime)
        } else if sa.contains("safety") {
            restartRecording(play:true)
            addLayer(.safety)
        } else if sa.contains("demo") {
            restartRecording(play:true)
            addLayer(.demographics)
        } else if sa.contains("census") {
            restartRecording(play:true)
            addLayer(.census)
        }
        twoWord = false
    }


}

