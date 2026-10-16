import SwiftUI
import CoreImage.CIFilterBuiltins

private struct UltraMark {
    let mode: String
    let points: [CGPoint]
    let text: String
}
struct UltraPhotoEditor: View {
    let draft: UltraMediaDraft
    let onSave: (UltraMediaDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var marks: [UltraMark] = []
    @State private var points: [CGPoint] = []
    @State private var mode = "pen"
    @State private var text = ""
    @State private var signature = UserWorkspace.defaults.string(forKey: "ultra.signature") ?? ""
    @State private var showText = false
    @State private var showSignature = false
    @State private var busy = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if let image {
                    GeometryReader { geometry in
                        let ratio = min(geometry.size.width / image.size.width, geometry.size.height / image.size.height)
                        let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
                        ZStack {
                            Image(uiImage: image).resizable().scaledToFit()
                            Canvas { context, _ in
                                for mark in marks { draw(mark, context: &context, size: size) }
                                if !points.isEmpty { draw(.init(mode: mode, points: points, text: ""), context: &context, size: size) }
                            }
                        }
                        .frame(width: size.width, height: size.height)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            let point = CGPoint(x: min(1, max(0, value.location.x / size.width)), y: min(1, max(0, value.location.y / size.height)))
                            if points.isEmpty { points = [point] }
                            if mode == "pen" { if points.count < 5000 { points.append(point) } } else { points = [points[0], point] }
                        }.onEnded { _ in
                            if !points.isEmpty { marks.append(.init(mode: mode, points: points, text: text)); points = [] }
                        })
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                } else { ProgressView() }
                Picker("כלי", selection: $mode) {
                    Text("סימון").tag("pen"); Text("חץ").tag("arrow"); Text("טשטוש").tag("blur"); Text("טקסט").tag("text")
                }.pickerStyle(.segmented).padding(.horizontal)
                HStack {
                    Button("טקסט") { showText = true }
                    Button("חתימה עסקית") { showSignature = true }
                    Button("בטל פעולה") { if !marks.isEmpty { marks.removeLast() } }.disabled(marks.isEmpty)
                }.buttonStyle(.bordered)
                Text(mode == "blur" ? "גרור מלבן על הפרטים להסתרה. הטשטוש ייצרב בקובץ שנשלח." : mode == "text" ? "קבע טקסט ולחץ במקום שבו תרצה להציב אותו." : "צייר או גרור חץ על התמונה.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                if busy { ProgressView("שומר תמונה…") }
                if let error { Text(error).foregroundStyle(.red) }
            }.padding(.bottom).disabled(busy)
            .navigationTitle("עריכת תמונה")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("ביטול") { dismiss() }.disabled(busy) }
                ToolbarItem(placement: .topBarTrailing) { Button("שמור") { save() }.disabled(image == nil || busy) }
            }
            .alert("טקסט לתמונה", isPresented: $showText) {
                TextField("טקסט", text: $text)
                Button("בחר מיקום") { mode = "text" }; Button("ביטול", role: .cancel) {}
            }
            .alert("חתימה עסקית שמורה", isPresented: $showSignature) {
                TextField("שם עסק / טלפון / חתימה", text: $signature)
                Button("הוסף ושמור") {
                    UserWorkspace.defaults.set(signature, forKey: "ultra.signature")
                    marks.append(.init(mode: "text", points: [.init(x: 0.05, y: 0.9)], text: signature))
                }
                Button("ביטול", role: .cancel) {}
            }
            .task {
                let sourceURL = draft.current
                image = await Task.detached {
                    guard let original = UIImage(contentsOfFile: sourceURL.path) else { return nil as UIImage? }
                    let scale = min(1, 4096 / max(original.size.width, original.size.height))
                    let size = CGSize(width: original.size.width * scale, height: original.size.height * scale)
                    let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
                    return UIGraphicsImageRenderer(size: size, format: format).image { _ in original.draw(in: CGRect(origin: .zero, size: size)) }
                }.value
            }
        }
    }
    private func draw(_ mark: UltraMark, context: inout GraphicsContext, size: CGSize) {
        let points = mark.points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
        guard let first = points.first else { return }
        if mark.mode == "text" {
            context.draw(Text(mark.text).font(.system(size: max(14, size.width * 0.045), weight: .bold)).foregroundColor(.white).shadow(color: .black, radius: 2), at: first, anchor: .topLeading)
        } else if mark.mode == "blur", let last = points.last {
            let rect = CGRect(x: min(first.x, last.x), y: min(first.y, last.y), width: abs(first.x - last.x), height: abs(first.y - last.y))
            context.fill(Path(rect), with: .color(.gray.opacity(0.85)))
        } else {
            var path = Path(); path.move(to: first); for point in points.dropFirst() { path.addLine(to: point) }
            if mark.mode == "arrow", let last = points.last {
                let a = atan2(last.y - first.y, last.x - first.x), length = max(12, size.width * 0.05)
                for offset in [CGFloat(-0.45), CGFloat(0.45)] {
                    path.move(to: last); path.addLine(to: CGPoint(x: last.x - cos(a + offset) * length, y: last.y - sin(a + offset) * length))
                }
            }
            context.stroke(path, with: .color(.red), style: .init(lineWidth: max(2, size.width * 0.005), lineCap: .round, lineJoin: .round))
        }
    }
    private func save() {
        guard let image else { return }; busy = true
        let savedMarks = marks, source = draft
        Task {
            do {
                let url = try await Task.detached {
                    let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
                    let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
                    let output = renderer.image { rendered in
                        image.draw(at: .zero)
                        let context = rendered.cgContext
                        for mark in savedMarks {
                            let points = mark.points.map { CGPoint(x: $0.x * image.size.width, y: $0.y * image.size.height) }
                            guard let first = points.first else { continue }
                            if mark.mode == "blur", let last = points.last {
                                let rect = CGRect(x: min(first.x,last.x), y: min(first.y,last.y), width: abs(first.x-last.x), height: abs(first.y-last.y)).integral
                                // Irreversible mosaic is drawn into a new flattened image; no hidden original layer.
                                if rect.width > 0, rect.height > 0, let crop = image.cgImage?.cropping(to: rect) {
                                    let tinySize = CGSize(width: max(1, rect.width / 22), height: max(1, rect.height / 22))
                                    let tiny = UIGraphicsImageRenderer(size: tinySize, format: format).image { _ in UIImage(cgImage: crop).draw(in: CGRect(origin: .zero, size: tinySize)) }
                                    context.saveGState(); context.interpolationQuality = .none; tiny.draw(in: rect); context.restoreGState()
                                }
                            } else if mark.mode == "text" {
                                let font = UIFont.boldSystemFont(ofSize: max(20, image.size.width * 0.045))
                                let shadow = NSShadow(); shadow.shadowColor = UIColor.black; shadow.shadowBlurRadius = 3
                                (mark.text as NSString).draw(at: first, withAttributes: [.font: font, .foregroundColor: UIColor.white, .shadow: shadow])
                            } else {
                                context.setStrokeColor(UIColor.red.cgColor); context.setLineWidth(max(3, image.size.width * 0.005)); context.setLineCap(.round); context.setLineJoin(.round)
                                context.beginPath(); context.move(to: first); for p in points.dropFirst() { context.addLine(to: p) }
                                if mark.mode == "arrow", let last = points.last {
                                    let angle = atan2(last.y-first.y,last.x-first.x), length = max(18,image.size.width * 0.05)
                                    for delta in [CGFloat(-0.45),CGFloat(0.45)] { context.move(to:last);context.addLine(to:CGPoint(x:last.x-cos(angle+delta)*length,y:last.y-sin(angle+delta)*length)) }
                                }
                                context.strokePath()
                            }
                        }
                    }
                    guard let data = output.jpegData(compressionQuality: 0.95) else { throw URLError(.cannotCreateFile) }
                    let url = UltraMediaEditing.temporary("jpg"); try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]); return url
                }.value
                var edited = source; edited.current = url; edited.edited = true; onSave(edited); dismiss()
            } catch { self.error = error.localizedDescription }
            busy = false
        }
    }
}
