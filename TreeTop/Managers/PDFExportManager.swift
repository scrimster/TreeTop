import Foundation
import UIKit

final class PDFExportManager {
    static let shared = PDFExportManager()

    private init() {}

    // MARK: - Public API
    func exportProjectReport(for project: Project) throws -> URL {
        guard let projectFolder = project.folderURL else {
            throw NSError(domain: "PDFExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing project folder URL"]) }

        let sanitizedName = project.name.replacingOccurrences(of: "/", with: "-")
        let fileName = "\(sanitizedName) - Report.pdf"
        let outputURL = projectFolder.appendingPathComponent(fileName)

        // Prepare renderer
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 @ 72dpi
        let margin: CGFloat = 36
        let contentWidth = pageRect.width - margin * 2
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "TreeTop Project Report",
            kCGPDFContextAuthor as String: "TreeTop"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        try renderer.writePDF(to: outputURL) { ctx in
            var cursorY: CGFloat = margin

            func newPageIfNeeded(for additionalHeight: CGFloat) {
                if cursorY + additionalHeight > pageRect.height - margin {
                    ctx.beginPage()
                    cursorY = margin
                }
            }

            func drawText(_ text: String, font: UIFont, color: UIColor = .black) -> CGFloat {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                paragraph.alignment = .left
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let bounding = CGRect(x: margin, y: cursorY, width: contentWidth, height: .greatestFiniteMagnitude)
                let height = (text as NSString).boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil).height
                newPageIfNeeded(for: height)
                (text as NSString).draw(with: CGRect(x: margin, y: cursorY, width: contentWidth, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
                cursorY += height
                return height
            }

            func drawDivider(spacing: CGFloat = 10) {
                newPageIfNeeded(for: spacing + 1 + spacing)
                cursorY += spacing
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: cursorY))
                path.addLine(to: CGPoint(x: margin + contentWidth, y: cursorY))
                UIColor(white: 0.8, alpha: 1).setStroke()
                path.lineWidth = 1
                path.stroke()
                cursorY += spacing
            }

            func drawImage(_ image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
                let aspect = image.size.width / max(image.size.height, 1)
                var drawW = maxWidth
                var drawH = drawW / aspect
                if drawH > maxHeight {
                    drawH = maxHeight
                    drawW = drawH * aspect
                }
                newPageIfNeeded(for: drawH)
                image.draw(in: CGRect(x: margin, y: cursorY, width: drawW, height: drawH))
                cursorY += drawH
                return CGSize(width: drawW, height: drawH)
            }

            func drawMaskGrid(title: String, images: [UIImage]) {
                guard !images.isEmpty else { return }
                cursorY += 8
                _ = drawText(title, font: .boldSystemFont(ofSize: 14))
                cursorY += 4
                let columns: CGFloat = 3
                let gap: CGFloat = 6
                let cellW = (contentWidth - gap * (columns - 1)) / columns
                let cellH = cellW

                var col: CGFloat = 0
                var rowHeight: CGFloat = 0
                for (idx, img) in images.enumerated() {
                    let targetRect = CGRect(x: margin + (cellW + gap) * col, y: cursorY, width: cellW, height: cellH)
                    let scaled = scaledRect(for: img.size, into: targetRect)
                    newPageIfNeeded(for: rowHeight == 0 ? cellH : 0)
                    img.draw(in: scaled)
                    rowHeight = max(rowHeight, cellH)
                    col += 1
                    if Int(col) >= Int(columns) || idx == images.count - 1 {
                        cursorY += rowHeight + gap
                        col = 0
                        rowHeight = 0
                    }
                }
            }

            func scaledRect(for imageSize: CGSize, into target: CGRect) -> CGRect {
                let aspectW = target.width / max(imageSize.width, 1)
                let aspectH = target.height / max(imageSize.height, 1)
                let scale = min(aspectW, aspectH)
                let w = imageSize.width * scale
                let h = imageSize.height * scale
                let x = target.minX + (target.width - w) / 2
                let y = target.minY + (target.height - h) / 2
                return CGRect(x: x, y: y, width: w, height: h)
            }

            // MARK: Cover / Header
            ctx.beginPage()
            _ = drawText("TreeTop Project Report", font: .boldSystemFont(ofSize: 22))
            _ = drawText(project.name, font: .systemFont(ofSize: 18))
            _ = drawText("Date: \(DateFormatter.localizedString(from: project.date, dateStyle: .medium, timeStyle: .short))", font: .systemFont(ofSize: 12), color: .darkGray)
            
            drawDivider(spacing: 12)
            
            // MARK: Project Details Section
            _ = drawText("Project Details", font: .boldSystemFont(ofSize: 16))
            cursorY += 8
            
            // Project metadata
            if let coord = project.centerCoordinate {
                _ = drawText("Coordinates: \(String(format: "%.5f, %.5f", coord.latitude, coord.longitude))", font: .systemFont(ofSize: 12))
            }
            _ = drawText("Elevation: \(String(format: "%.1f m", project.elevation))", font: .systemFont(ofSize: 12))
            
            // Weather condition
            if let weather = project.weatherCondition {
                _ = drawText("Weather: \(weather)", font: .systemFont(ofSize: 12))
            } else {
                _ = drawText("Weather: Not specified", font: .systemFont(ofSize: 12), color: .darkGray)
            }
            
            // Photo counts
            _ = drawText("Diagonal 1 Photos: \(project.diagonal1Photos)", font: .systemFont(ofSize: 12))
            _ = drawText("Diagonal 2 Photos: \(project.diagonal2Photos)", font: .systemFont(ofSize: 12))
            _ = drawText("Total Photos: \(project.totalPhotos)", font: .systemFont(ofSize: 12))
            
            // Analysis date
            if let last = project.lastAnalysisDate {
                _ = drawText("Last Analyzed: \(DateFormatter.localizedString(from: last, dateStyle: .medium, timeStyle: .short))", font: .systemFont(ofSize: 12))
            }
            
            drawDivider(spacing: 12)

            // MARK: Summary
            if let summary = project.storedSummaryResult {
                _ = drawText("Analysis Summary", font: .boldSystemFont(ofSize: 16))
                cursorY += 8
                _ = drawText(String(format: "Overall Canopy Cover: %.1f%%", summary.overallAverage), font: .systemFont(ofSize: 13))
                let diags = summary.diagonalAverages.keys.sorted()
                for d in diags {
                    if let v = summary.diagonalAverages[d] {
                        _ = drawText("\(d): \(String(format: "%.1f%%", v))", font: .systemFont(ofSize: 12))
                    }
                }
                drawDivider(spacing: 10)
            } else {
                _ = drawText("No stored analysis results found.", font: .italicSystemFont(ofSize: 12), color: .darkGray)
                drawDivider(spacing: 10)
            }

            // MARK: Center Reference (optional)
            if let refURL = project.centerReferenceImageURL(), let image = UIImage(contentsOfFile: refURL.path) {
                _ = drawText("Center Reference", font: .boldSystemFont(ofSize: 16))
                cursorY += 8
                _ = drawImage(image, maxWidth: contentWidth, maxHeight: 200)
                drawDivider(spacing: 10)
            }

            // MARK: Masks Section
            _ = drawText("Segmentation Masks", font: .boldSystemFont(ofSize: 16))
            cursorY += 4
            let masks1 = loadMasks(for: project, diagonal: "Diagonal 1")
            let masks2 = loadMasks(for: project, diagonal: "Diagonal 2")
            if masks1.isEmpty && masks2.isEmpty {
                _ = drawText("No masks found. Run analysis to generate segmentation masks.", font: .systemFont(ofSize: 12), color: .darkGray)
            } else {
                drawMaskGrid(title: "Diagonal 1", images: masks1)
                drawMaskGrid(title: "Diagonal 2", images: masks2)
            }
            drawDivider(spacing: 10)

            // MARK: Methodology
            _ = drawText("Methodology", font: .boldSystemFont(ofSize: 16))
            cursorY += 8
            let method = methodologyText()
            _ = drawText(method, font: .systemFont(ofSize: 12))
        }

        return outputURL
    }

    // MARK: - Helpers
    private func loadMasks(for project: Project, diagonal: String) -> [UIImage] {
        guard let folder = project.maskFolderURL(forDiagonal: diagonal) else { return [] }
        guard let items = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return [] }
        let imageURLs = items.filter { ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased()) }
        let limited = imageURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).prefix(24) // cap in report
        return limited.compactMap { UIImage(contentsOfFile: $0.path) }
    }

    private func methodologyText() -> String {
        return """
        Photos are captured along two diagonals radiating from a center reference point beneath the canopy. Images are organized as Diagonal 1 and Diagonal 2. The app processes each photo with a Core ML semantic segmentation model (imageseg_canopy_model) to estimate sky vs canopy pixels. Before inference, each image is resized to 256×256 pixels and normalized. The model outputs a per‑pixel probability map; the mean sky probability is computed and canopy cover is estimated as (1 − meanSky) × 100%. The overall canopy cover is the average across all processed photos, and per‑diagonal averages are also reported. Masks rendered in this report visualize the model's output for each photo.
        """
    }
}


