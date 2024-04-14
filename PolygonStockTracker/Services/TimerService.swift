//
//  TimerService.swift
//  PolygonStockTracker
//
//  Created by Randy McLain on 3/1/24.
//

import Foundation

import Foundation

protocol TimeServicable {
    var timerPublisher: Published<Bool>.Publisher { get }
    func startTimer()
}

class TimerService: TimeServicable {
    var timerPublisher: Published<Bool>.Publisher { $timerIsReady }
    
    private var timer: Timer?
    private var timeInterval: TimeInterval
    @Published private var timerIsReady: Bool = false
    
    init(timerLength: UInt8) {
        self.timeInterval = TimeInterval(floatLiteral: Double(timerLength))
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timerIsReady = false
    }
    
    func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: self.timeInterval, repeats: true, block: { [weak self] ready in
            guard let self = self else { return }
                DispatchQueue.main.async {
                    self.timerIsReady = true
                    self.stopTimer()
                }
        })
    }
}
