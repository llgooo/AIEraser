//
//  Publisher+ext.swift
//  CoreMoose
//
//  Created by m x on 2024/1/3.
//
import Combine
import Foundation

extension Publisher where Output == Date, Failure == Never {
    func pause(if condition: Bool) -> AnyPublisher<Date, Never> {
        condition ? Empty(completeImmediately: false).eraseToAnyPublisher() : self.eraseToAnyPublisher()
    }
}
