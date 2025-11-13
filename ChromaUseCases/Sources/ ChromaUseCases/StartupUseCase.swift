// UseCases/StartupUseCase.swift
// Handles camera permission + startup readiness, framework-free.

import Foundation
import ChromaDomain

public enum StartupState: Sendable {
   case idle
   case checkingPermissions
   case requestingPermissions
   case ready
   case blockedPermission
   case failed(String)
}

public protocol StartupUseCase: Sendable {
   /// Evaluate current startup state without prompting the user.
   func evaluateStartupState() async -> StartupState

   /// If needed, request camera permissions and return the new state.
   func requestPermissionsIfNeeded() async -> StartupState
}

public actor StartupInteractor: StartupUseCase {
   private let permissions: PermissionsGateway

   public init(permissions: PermissionsGateway) {
       self.permissions = permissions
   }

   public func evaluateStartupState() async -> StartupState {
       let status = await permissions.cameraAuthorizationStatus()
       switch status {
       case .authorized:
           return .ready
       case .notDetermined:
           return .checkingPermissions
       case .denied, .restricted:
           return .blockedPermission
       }
   }

   public func requestPermissionsIfNeeded() async -> StartupState {
       let status = await permissions.cameraAuthorizationStatus()
       switch status {
       case .authorized:
           return .ready
       case .denied, .restricted:
           return .blockedPermission
       case .notDetermined:
           let granted = await permissions.requestCameraAccess()
           return granted ? .ready : .blockedPermission
       }
   }
}
