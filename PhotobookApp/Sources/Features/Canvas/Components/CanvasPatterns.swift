import SwiftUI

// MARK: - Grid Pattern

struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 20
        
        for x in stride(from: 0, to: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0, to: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

// MARK: - Dots Pattern

struct DotsPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 15
            let dotSize: CGFloat = 3
            
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(.gray.opacity(0.3)))
                }
            }
        }
    }
}

// MARK: - Stripes Pattern

struct StripesPattern: View {
    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 10
            
            for x in stride(from: 0, to: size.width, by: stripeWidth * 2) {
                let rect = CGRect(x: x, y: 0, width: stripeWidth, height: size.height)
                context.fill(Path(rect), with: .color(.gray.opacity(0.2)))
            }
        }
    }
}

// MARK: - Diagonal Pattern

struct DiagonalPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 20
            
            for offset in stride(from: -size.height, to: size.width + size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: offset, y: 0))
                path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 1)
            }
        }
    }
}

// MARK: - Hearts Pattern

struct HeartsPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 25
            
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    context.draw(Text("♥").font(.system(size: 12)), at: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

// MARK: - Stars Pattern

struct StarsPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 25
            
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    context.draw(Text("★").font(.system(size: 12)), at: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

// MARK: - Waves Pattern

struct WavesPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 15
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                for x in stride(from: 0, to: size.width, by: 5) {
                    let relativeY = sin(x / 10.0) * 3
                    path.addLine(to: CGPoint(x: x, y: y + relativeY))
                }
                context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 1)
            }
        }
    }
}

// MARK: - Checks Pattern

struct ChecksPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 20
            for x in stride(from: 0, to: size.width, by: spacing * 2) {
                for y in stride(from: 0, to: size.height, by: spacing * 2) {
                    context.fill(Path(CGRect(x: x, y: y, width: spacing, height: spacing)), with: .color(.gray.opacity(0.1)))
                    context.fill(Path(CGRect(x: x + spacing, y: y + spacing, width: spacing, height: spacing)), with: .color(.gray.opacity(0.1)))
                }
            }
        }
    }
}

// MARK: - Zigzag Pattern

struct ZigzagPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 20
            let h: CGFloat = 5
            for y in stride(from: 0, to: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                for x in stride(from: 0, to: size.width, by: 20) {
                    path.addLine(to: CGPoint(x: x + 10, y: y + h))
                    path.addLine(to: CGPoint(x: x + 20, y: y))
                }
                context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 1)
            }
        }
    }
}

// MARK: - Stamp Shape

struct StampShape: Shape {
    func path(in rect: CGRect) -> Path {
        let holeRadius: CGFloat = 8
        let spacing: CGFloat = 20
        
        var path = Path()
        path.addRect(rect)
        
        let countX = Int(rect.width / spacing)
        let gapX = rect.width / CGFloat(countX)
        
        for i in 0...countX {
            let x = CGFloat(i) * gapX
            path.addEllipse(in: CGRect(x: x - holeRadius, y: -holeRadius, width: holeRadius*2, height: holeRadius*2))
        }
        
        for i in 0...countX {
            let x = CGFloat(i) * gapX
            path.addEllipse(in: CGRect(x: x - holeRadius, y: rect.height - holeRadius, width: holeRadius*2, height: holeRadius*2))
        }
        
        let countY = Int(rect.height / spacing)
        let gapY = rect.height / CGFloat(countY)
        
        for i in 0...countY {
            let y = CGFloat(i) * gapY
            path.addEllipse(in: CGRect(x: -holeRadius, y: y - holeRadius, width: holeRadius*2, height: holeRadius*2))
        }
        
        for i in 0...countY {
            let y = CGFloat(i) * gapY
            path.addEllipse(in: CGRect(x: rect.width - holeRadius, y: y - holeRadius, width: holeRadius*2, height: holeRadius*2))
        }
        
        return path
    }
}
