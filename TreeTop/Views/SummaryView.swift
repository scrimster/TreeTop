import SwiftUI

struct SummaryView: View {
    let summary: CanopyCaptureSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Capture Summary")
                    .font(.title)
                    .bold()

                // Image preview
                Image(uiImage: summary.image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)
                    .cornerRadius(16)
                    .shadow(radius: 4)

                // Info box
                VStack(spacing: 16) {
                    summaryRow(label: "Date", value: summary.date.formatted(date: .long, time: .omitted))
                    summaryRow(label: "Time", value: summary.date.formatted(date: .omitted, time: .shortened))
                    summaryRow(label: "Canopy Coverage", value: "\(summary.canopyPercentage, specifier: "%.1f")%")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .shadow(radius: 2)

                Spacer()
            }
            .padding()
        }
    }

    @ViewBuilder
    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .foregroundColor(.green)
        }
    }
}
