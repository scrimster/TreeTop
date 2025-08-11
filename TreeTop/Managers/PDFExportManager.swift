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

        // Prepare renderer - Optimized for portrait A4
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 @ 72dpi
        let margin: CGFloat = 50 // Increased margin for better readability
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
                if cursorY + additionalHeight > pageRect.height - margin - 20 { // Add safety margin
                    ctx.beginPage()
                    cursorY = margin
                }
            }

            func drawText(_ text: String, font: UIFont, color: UIColor = .black) -> CGFloat {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                paragraph.alignment = .left
                paragraph.lineSpacing = 2 // Add line spacing for better readability
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let bounding = CGRect(x: margin, y: cursorY, width: contentWidth, height: .greatestFiniteMagnitude)
                let height = (text as NSString).boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil).height
                newPageIfNeeded(for: height + 4) // Add extra space for text
                (text as NSString).draw(with: CGRect(x: margin, y: cursorY, width: contentWidth, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
                cursorY += height + 4
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
                newPageIfNeeded(for: drawH + 8) // Add extra space for images
                image.draw(in: CGRect(x: margin, y: cursorY, width: drawW, height: drawH))
                cursorY += drawH + 8
                return CGSize(width: drawW, height: drawH)
            }

            func drawMaskGrid(title: String, images: [UIImage]) {
                guard !images.isEmpty else { return }
                cursorY += 8
                _ = drawText(title, font: .boldSystemFont(ofSize: 14))
                cursorY += 8
                
                // Optimize for portrait layout - 2 columns instead of 3 for better fit
                let columns: CGFloat = 2
                let gap: CGFloat = 16
                let cellW = (contentWidth - gap * (columns - 1)) / columns
                let cellH = cellW
                let labelHeight: CGFloat = 16

                var col: CGFloat = 0
                var rowStartY: CGFloat = cursorY
                var rowHeight: CGFloat = 0
                
                for (idx, img) in images.enumerated() {
                    // Check if we need a new page for this row
                    if col == 0 {
                        newPageIfNeeded(for: cellH + labelHeight + 16)
                        rowStartY = cursorY
                    }
                    
                    let targetRect = CGRect(x: margin + (cellW + gap) * col, y: rowStartY + labelHeight, width: cellW, height: cellH)
                    let scaled = scaledRect(for: img.size, into: targetRect)
                    
                    // Draw photo number label
                    let labelText = "Photo \(idx + 1)"
                    let labelAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                        .foregroundColor: UIColor.black
                    ]
                    let labelSize = (labelText as NSString).size(withAttributes: labelAttrs)
                    let labelX = targetRect.minX + (targetRect.width - labelSize.width) / 2
                    (labelText as NSString).draw(at: CGPoint(x: labelX, y: rowStartY), withAttributes: labelAttrs)
                    
                    // Draw image border/outline first
                    let borderRect = CGRect(x: targetRect.minX, y: targetRect.minY, width: targetRect.width, height: targetRect.height)
                    let borderPath = UIBezierPath(rect: borderRect)
                    UIColor.lightGray.setStroke()
                    borderPath.lineWidth = 1
                    borderPath.stroke()
                    
                    // Draw the image
                    img.draw(in: scaled)
                    
                    rowHeight = max(rowHeight, cellH + labelHeight + 8)
                    col += 1
                    
                    if Int(col) >= Int(columns) || idx == images.count - 1 {
                        cursorY = rowStartY + rowHeight + gap
                        col = 0
                        rowHeight = 0
                    }
                }
                cursorY += 8
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
            
            func drawMethodologySection() {
                let method = methodologyText()
                let methodFont = UIFont.systemFont(ofSize: 12)
                let titleFont = UIFont.boldSystemFont(ofSize: 16)
                
                // Calculate total height needed for the entire methodology section
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                paragraph.alignment = .left
                paragraph.lineSpacing = 2
                
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraph
                ]
                
                let methodAttrs: [NSAttributedString.Key: Any] = [
                    .font: methodFont,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraph
                ]
                
                let titleHeight = ("Methodology" as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: titleAttrs,
                    context: nil
                ).height
                
                let methodHeight = (method as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: methodAttrs,
                    context: nil
                ).height
                
                let totalHeight = titleHeight + 8 + methodHeight + 8 + 20 // Include spacing and separator
                
                // Check if we need a new page for the entire methodology section
                newPageIfNeeded(for: totalHeight)
                
                // Draw the title
                ("Methodology" as NSString).draw(
                    with: CGRect(x: margin, y: cursorY, width: contentWidth, height: titleHeight),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: titleAttrs,
                    context: nil
                )
                cursorY += titleHeight + 8
                
                // Draw the methodology text
                (method as NSString).draw(
                    with: CGRect(x: margin, y: cursorY, width: contentWidth, height: methodHeight),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: methodAttrs,
                    context: nil
                )
                cursorY += methodHeight + 8
                
                // Draw separator bar
                let separatorY = cursorY + 10
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: separatorY))
                path.addLine(to: CGPoint(x: margin + contentWidth, y: separatorY))
                UIColor(white: 0.8, alpha: 1).setStroke()
                path.lineWidth = 1
                path.stroke()
                cursorY = separatorY + 10
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
                _ = drawImage(image, maxWidth: contentWidth, maxHeight: 250) // Slightly larger for better visibility
                drawDivider(spacing: 10)
                
                // Force a page break after center reference
                ctx.beginPage()
                cursorY = margin
            }

            // MARK: Masks Section
            _ = drawText("Segmentation Masks", font: .boldSystemFont(ofSize: 16))
            cursorY += 8
            let masks1 = loadMasks(for: project, diagonal: "Diagonal 1")
            let masks2 = loadMasks(for: project, diagonal: "Diagonal 2")
            if masks1.isEmpty && masks2.isEmpty {
                _ = drawText("No masks found. Run analysis to generate segmentation masks.", font: .systemFont(ofSize: 12), color: .darkGray)
            } else {
                drawMaskGrid(title: "Diagonal 1", images: masks1)
                drawMaskGrid(title: "Diagonal 2", images: masks2)
            }
            drawDivider(spacing: 10)

            // MARK: Methodology (at the end)
            drawMethodologySection()
        }

        return outputURL
    }

    // MARK: - Helpers
    private func loadMasks(for project: Project, diagonal: String) -> [UIImage] {
        guard let folder = project.maskFolderURL(forDiagonal: diagonal) else { return [] }
        guard let items = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return [] }
        let imageURLs = items.filter { ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased()) }
        let limited = imageURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).prefix(50) // increased limit to show more photos
        return limited.compactMap { UIImage(contentsOfFile: $0.path) }
    }

    private func methodologyText() -> String {
        return """
        Photos are captured along two diagonals radiating from a center reference point beneath the canopy. Images are organized as Diagonal 1 and Diagonal 2. The app processes each photo with a Core ML semantic segmentation model (imageseg_canopy_model) to estimate sky vs canopy pixels. Before inference, each image is resized to 256×256 pixels and normalized. The model outputs a per‑pixel probability map; the mean sky probability is computed and canopy cover is estimated as (1 − meanSky) × 100%. The overall canopy cover is the average across all processed photos, and per‑diagonal averages are also reported. Masks rendered in this report visualize the model's output for each photo.
        """
    }
}


