//
//  LiquidGlassComponents.swift
//  TreeTop
//
//  Created by TreeTop Team on 7/20/25.
//

import SwiftUI

// MARK: - Liquid Glass Style Modifiers

struct LiquidGlassStyle: ViewModifier {
    let cornerRadius: CGFloat
    let strokeOpacity: Double
    let shadowRadius: CGFloat
    
    init(cornerRadius: CGFloat = 16, strokeOpacity: Double = 0.25, shadowRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
        self.strokeOpacity = strokeOpacity
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.2), in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(strokeOpacity * 1.0),
                                .white.opacity(strokeOpacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: .black.opacity(0.02), radius: shadowRadius * 0.5, x: 0, y: 2)
            .shadow(color: .white.opacity(0.01), radius: 1, x: 0, y: -1)
    }
}

struct LiquidGlassCircleStyle: ViewModifier {
    let strokeOpacity: Double
    let shadowRadius: CGFloat
    
    init(strokeOpacity: Double = 0.3, shadowRadius: CGFloat = 6) {
        self.strokeOpacity = strokeOpacity
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.2), in: Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(strokeOpacity * 1.0),
                                .white.opacity(strokeOpacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: .black.opacity(0.02), radius: shadowRadius * 0.5, x: 0, y: 2)
            .shadow(color: .white.opacity(0.01), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Extension for Easy Use

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, strokeOpacity: Double = 0.25, shadowRadius: CGFloat = 8) -> some View {
        modifier(LiquidGlassStyle(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity, shadowRadius: shadowRadius))
    }
    
    func liquidGlassCircle(strokeOpacity: Double = 0.3, shadowRadius: CGFloat = 6) -> some View {
        modifier(LiquidGlassCircleStyle(strokeOpacity: strokeOpacity, shadowRadius: shadowRadius))
    }
    
    func glassText(opacity: Double = 0.95) -> some View {
        self
            .foregroundColor(.white.opacity(opacity))
            .shadow(color: .white.opacity(0.02), radius: 1, x: 0, y: -1)
    }
    
    func glassTextSecondary(opacity: Double = 0.7) -> some View {
        self
            .foregroundColor(.white.opacity(opacity))
            .shadow(color: .white.opacity(0.01), radius: 1, x: 0, y: -1)
    }
    
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

// MARK: - Liquid Glass Components

struct LiquidGlassButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    let cornerRadius: CGFloat
    @State private var isPressed = false
    
    init(cornerRadius: CGFloat = 16, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .modifier(LiquidGlassStyle(cornerRadius: cornerRadius, strokeOpacity: isPressed ? 0.4 : 0.25))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
}

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .modifier(LiquidGlassStyle(cornerRadius: cornerRadius, strokeOpacity: 0.2, shadowRadius: 12))
    }
}

struct LiquidGlassFolder<Content: View>: View {
    let isExpanded: Bool
    let content: Content
    let cornerRadius: CGFloat
    
    init(isExpanded: Bool = false, cornerRadius: CGFloat = 14, @ViewBuilder content: () -> Content) {
        self.isExpanded = isExpanded
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .modifier(LiquidGlassStyle(
                cornerRadius: cornerRadius, 
                strokeOpacity: isExpanded ? 0.35 : 0.25,
                shadowRadius: isExpanded ? 10 : 6
            ))
    }
}
