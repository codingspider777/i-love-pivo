import Flutter
import UIKit
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var locationReply: FlutterResult?
  private var locationChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    locationManager.delegate = self
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DayDockLocation") {
      let channel = FlutterMethodChannel(name: "daydock/location", binaryMessenger: registrar.messenger())
      locationChannel = channel
      channel.setMethodCallHandler { [weak self] call, reply in
        guard call.method == "requestPermission", let self = self else { reply(FlutterMethodNotImplemented); return }
        guard CLLocationManager.locationServicesEnabled() else { reply("disabled"); return }
        if self.locationManager.authorizationStatus == .notDetermined {
          guard self.locationReply == nil else { reply("pending"); return }
          self.locationReply = reply
          self.locationManager.requestWhenInUseAuthorization()
        } else { reply(self.locationStatus()) }
      }
    }
  }
  private func locationStatus() -> String {
    switch locationManager.authorizationStatus {
      case .authorizedAlways, .authorizedWhenInUse: return "authorized"
      case .denied, .restricted: return "denied"
      default: return "notDetermined"
    }
  }
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard manager.authorizationStatus != .notDetermined, let reply = locationReply else { return }
    locationReply = nil
    reply(locationStatus())
  }
}
