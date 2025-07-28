import SwiftUI

/// Performance settings manager for optimizing app performance
class PerformanceSettings: ObservableObject {
    static let shared = PerformanceSettings()
    
    @Published var useHighPerformanceMode: Bool {
        didSet {
            UserDefaults.standard.set(useHighPerformanceMode, forKey: "HighPerformanceMode")
        }
    }
    
    @Published var reduceMotion: Bool {
        didSet {
            UserDefaults.standard.set(reduceMotion, forKey: "ReduceMotion")
        }
    }
    
    @Published var simplifiedBackgrounds: Bool {
        didSet {
            UserDefaults.standard.set(simplifiedBackgrounds, forKey: "SimplifiedBackgrounds")
        }
    }
    
    private init() {
        self.useHighPerformanceMode = UserDefaults.standard.bool(forKey: "HighPerformanceMode")
        self.reduceMotion = UserDefaults.standard.bool(forKey: "ReduceMotion")
        self.simplifiedBackgrounds = UserDefaults.standard.bool(forKey: "SimplifiedBackgrounds")
        
        // Auto-detect performance mode based on device capabilities
        if useHighPerformanceMode == false && shouldAutoEnablePerformanceMode() {
            useHighPerformanceMode = true
            reduceMotion = true
            simplifiedBackgrounds = true
        }
    }
    
    /// Auto-detect if device needs performance optimizations
    private func shouldAutoEnablePerformanceMode() -> Bool {
        let processInfo = ProcessInfo.processInfo
        
        // Enable performance mode on devices with less than 3GB RAM
        if processInfo.physicalMemory < 3_000_000_000 {
            return true
        }
        
        // Enable on older device models (this is a simplified check)
        let deviceModel = UIDevice.current.model
        if deviceModel.contains("iPhone") {
            // This is a basic check - in production you'd want more sophisticated device detection
            return false
        }
        
        return false
    }
}

/// SwiftUI view for performance settings
struct PerformanceSettingsView: View {
    @StateObject private var settings = PerformanceSettings.shared
    
    var body: some View {
        ZStack {
            SimpleForestBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("Performance Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .glassText()
                    
                    Text("Optimize TreeTop for smoother performance")
                        .font(.system(.body, design: .rounded))
                        .glassTextSecondary(opacity: 0.7)
                        .multilineTextAlignment(.center)
                }
                
                LiquidGlassCard(cornerRadius: 16) {
                    VStack(spacing: 20) {
                        PerformanceToggle(
                            title: "High Performance Mode",
                            description: "Optimizes app for smoother performance",
                            icon: "bolt.fill",
                            isOn: $settings.useHighPerformanceMode
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        PerformanceToggle(
                            title: "Reduce Motion",
                            description: "Minimizes animations and transitions",
                            icon: "motion.disable",
                            isOn: $settings.reduceMotion
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        PerformanceToggle(
                            title: "Simplified Backgrounds",
                            description: "Uses static backgrounds without animations",
                            icon: "background.removal",
                            isOn: $settings.simplifiedBackgrounds
                        )
                    }
                    .padding(20)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PerformanceToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue.opacity(0.8))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .glassText()
                
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .glassTextSecondary(opacity: 0.7)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
}

#Preview {
    PerformanceSettingsView()
}
