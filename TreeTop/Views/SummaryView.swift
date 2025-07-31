import SwiftUI

struct SummaryView: View {
    let result: SummaryResult

    var body: some View {
        ZStack {
            AnimatedForestBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)
                    
                    ExpandableSummaryView(result: result, initiallyExpanded: true)
                        .padding(.horizontal)
                    
                    Spacer()
                }
            }
        }
        .navigationTitle("Analysis Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Analysis Summary")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    SummaryView(result: SummaryResult(diagonalAverages: ["Diagonal 1": 50, "Diagonal 2": 60], overallAverage: 55))
}
