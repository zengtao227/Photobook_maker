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
