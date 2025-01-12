//
//  OutputListener.swift
//  SwiftLlamaApp
//
//  Created by Amit Samant on 12/01/25.
//

import Foundation
import SwiftUI
import OSLog
import Combine
import os


@available(iOS 15.0, *)
final class OutputListener: ObservableObject {

    @Published var logs: [OSLogEntryLog] = []

  var logsIsEmpty: Bool {
    logs.isEmpty
  }

  @Published var isLoading: Bool = false


  private var lastDate: Date?


    private static let store = try? OSLogStore(scope: .currentProcessIdentifier)

  init() {
    load()
  }

  private func fetchLogs() {
    guard let store = OutputListener.store else { return }

    var position: OSLogPosition?
    if let lastDate = lastDate {
      let ti = lastDate.timeIntervalSinceNow
      position = store.position(timeIntervalSinceEnd: ti)
    }

    do {

        let entries = try store.getEntries(at: position, matching: .subystemIn(["LLaMAServer"]))

      let filteredEntries = entries.compactMap { entry -> OSLogEntryLog? in
        guard let log = entry as? OSLogEntryLog,
                log.date.timeIntervalSince1970 > (lastDate?.timeIntervalSince1970 ?? 0 ) else { return nil }
        return log
      }


      Task { @MainActor in
        self.logs.append(contentsOf: filteredEntries)
        self.isLoading = false
        self.lastDate = self.logs.last?.date
      }
    } catch {
      print("Can't fetch entries: \(error)")
    }
  }

  func load() {
    isLoading = true
    DispatchQueue.global(qos: .userInteractive).async { [weak self] in
        Task {
            while true {
                try? await Task.sleep(for: .seconds(1))
                self?.fetchLogs()
            }
        }
    }
  }

  func clear() {
    logs = []
  }
}

@available(iOS 15.0, *)
extension Date {
  var logTimeString: String {
    formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().second().secondFraction(.fractional(3)))
  }
}

extension Sequence {
  func uniqueMap<K: Hashable>(_ kp: KeyPath<Element, K>) -> Set<K> {
    let mapped = map { $0[keyPath: kp]}
    return Set(mapped)
  }
}

extension Sequence {
  func uniqueMap(_ kp: KeyPath<Element, String>) -> Set<String> {
    let mapped = map { $0[keyPath: kp] }
    return Set(mapped.filter { $0 != "" })
  }
}

@available(iOS 15.0, *)
extension OSLogEntryLog.Level {
  var description: String {
    switch self {
    case .debug: return "debug"
    case .info: return "info"
    case .notice: return "notice"
    case .error: return "error"
    case .fault: return "fault"
    default: return ""
    }
  }

  var color: Color {
    switch self {
    case .debug: return .gray
    case .info: return .blue
    case .notice: return .mint
    case .error: return .red
    case .fault: return .black
    default: return .gray
    }
  }
}


public extension NSPredicate {
  /// Predicate for fetching from OSLogStore, allow to condition subsystem, and set if empty subsystem should be filtered.
  static func subystemIn(_ values: [String], orNil: Bool = true) -> NSPredicate {
    NSPredicate(format: "\(orNil ? "subsystem == nil OR" : "") subsystem in $LIST")
      .withSubstitutionVariables(["LIST" : values])
  }
}
