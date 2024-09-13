//
//  RiveModel.swift
//  RiveRuntime
//
//  Created by Zachary Duncan on 3/24/22.
//  Copyright © 2022 Rive. All rights reserved.
//

import Foundation
import Combine

@objc open class RiveModel: NSObject, ObservableObject {
    // NOTE: the order here determines the order in which memory garbage collected
    public internal(set) var stateMachine: RiveStateMachineInstance?
    public internal(set) var animation: RiveLinearAnimationInstance?
  public private(set) var artboard: RiveArtboard! {
    didSet {
      print("set artboard")
    }
  }
    internal private(set) var riveFile: RiveFile
    
    public init(riveFile: RiveFile) {
        self.riveFile = riveFile
    }
    
    public init(fileName: String, extension: String = ".riv", in bundle: Bundle = .main, loadCdn: Bool = true, customLoader: LoadAsset? = nil) throws {
        riveFile = try RiveFile(name: fileName, extension: `extension`, in: bundle, loadCdn: loadCdn, customLoader: customLoader)
    }
    
    public init(webURL: String, delegate: RiveFileDelegate, loadCdn: Bool) {
        riveFile = RiveFile(httpUrl: webURL, loadCdn:loadCdn, with: delegate)!
    }

    // rive-runtime defaults the volume to 1.0f
    // This value is used if there is no artboard,
    // and will be used to set the volume once a model is configured (with an artboard)
    private var _volume: Float = 1

    /// The volume of the current artboard, if available. Defaults to 1.
    @objc open var volume: Float {
        get {
            if let volume = artboard?.__volume {
                return volume
            }

            return _volume
        }
        set {
            _volume = newValue
            artboard?.__volume = newValue
        }
    }

    // MARK: - Setters
    
    /// Sets a new Artboard and makes the current StateMachine and Animation nil
    open func setArtboard(_ name: String) throws {
        do {
            stateMachine = nil
            animation = nil
            artboard = try riveFile.artboard(fromName: name)
            artboard.__volume = _volume
        }
        catch { throw RiveModelError.invalidArtboard("Name \(name) not found") }
    }
    
    /// Sets a new Artboard and makes the current StateMachine and Animation nil
    open func setArtboard(_ index: Int? = nil) throws {
        if let index = index {
            do {
                stateMachine = nil
                animation = nil
                artboard = try riveFile.artboard(from: index)
                artboard.__volume = _volume
            }
            catch { throw RiveModelError.invalidArtboard("Index \(index) not found") }
        } else {
            // This tries to find the 'default' Artboard
            do {
                artboard = try riveFile.artboard()
                artboard.__volume = _volume
            }
            catch { throw RiveModelError.invalidArtboard("No Default Artboard") }
        }
    }
    
    open func setStateMachine(_ name: String) throws {
        do { stateMachine = try artboard.stateMachine(fromName: name) }
        catch { throw RiveModelError.invalidStateMachine("Name \(name) not found") }
    }
    
    open func setStateMachine(_ index: Int? = nil) throws {
        do {
            // Set by index
            if let index = index {
                stateMachine = try artboard.stateMachine(from: index)
            }
            
            // Set from Artboard's default StateMachine configured in editor
            else if let defaultStateMachine = artboard.defaultStateMachine() {
                stateMachine = defaultStateMachine
            }
            
            // Set by index 0 as a fallback
            else {
                stateMachine = try artboard.stateMachine(from: 0)
            }
        }
        catch { throw RiveModelError.invalidStateMachine("Index \(index ?? 0) not found") }
    }
    
    open func setAnimation(_ name: String) throws {
        guard animation?.name() != name else { return }
        do { animation = try artboard.animation(fromName: name) }
        catch { throw RiveModelError.invalidAnimation("Name \(name) not found") }
    }
    
    open func setAnimation(_ index: Int? = nil) throws {
        // Defaults to 0 as it's assumed to be the first element in the collection
        let index = index ?? 0
        do { animation = try artboard.animation(from: index) }
        catch { throw RiveModelError.invalidAnimation("Index \(index) not found") }
    }
    
    // MARK: -
    
    public override var description: String {
        let art = "RiveModel - [Artboard: " + artboard.name()
        
        if let stateMachine = stateMachine {
            return art + "StateMachine: " + stateMachine.name() + "]"
        }
        else if let animation = animation {
            return art + "Animation: " + animation.name() + "]"
        }
        else {
            return art + "]"
        }
    }
    
    enum RiveModelError: Error {
        case invalidStateMachine(_ message: String)
        case invalidAnimation(_ message: String)
        case invalidArtboard(_ message: String)
    }
}
