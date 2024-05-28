//
//  SettingModel.swift
//  CoreMoose
//
//  Created by m x on 2024/2/1.
//

enum ModelType: String, Codable, CaseIterable {
    case MiGan
    case LaMa
    case Upscaler
}

enum SourceType: String, Codable, CaseIterable {
    case photo
    case finder
}

enum ToolType: String, Codable, CaseIterable {
    case standardMask, lasso
}

enum ThemeType: String, Codable, CaseIterable {
    case auto
    case light
    case dark
}
