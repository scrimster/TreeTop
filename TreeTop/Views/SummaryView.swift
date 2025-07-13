import SwiftUI

struct SummaryView: View {
    let result: SummaryResult

    var body: some View {
        List {
            ForEach(result.diagonalAverages.keys.sorted(), id: \.self) { key in
                if let value = result.diagonalAverages[key] {
                    HStack {
                        Text(key)
                        Spacer()
                        Text(String(format: "%.1f%%", value))
                    }
                }
            }
            HStack {
                Text("Overall")
                Spacer()
                Text(String(format: "%.1f%%", result.overallAverage))
                    .bold()
            }
        }
        .navigationTitle("Summary")
    }
}

#Preview {
    SummaryView(result: SummaryResult(diagonalAverages: ["Diagonal 1": 50, "Diagonal 2": 60], overallAverage: 55))
}
