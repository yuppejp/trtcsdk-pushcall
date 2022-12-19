//
//  BalloonText.swift
//  TrtcVideoRoom
//

import SwiftUI

struct BalloonText: View {
    let text: String
    let color: Color
    let mirrored: Bool
    
    init(_ text: String,
         color: Color = Color(UIColor(red: 109/255, green: 230/255, blue: 123/255, alpha: 1.0)),
         mirrored: Bool = false
    ) {
        self.text = text
        self.color = color
        self.mirrored = mirrored
    }

    var body: some View {
        let cornerRadius = 8.0
        //let padding = 8
        
        Text(text)
            .padding(.leading, 8 + (mirrored ? cornerRadius * 0.6 : 0))
            .padding(.trailing, 8 + (!mirrored ? cornerRadius * 0.6 : 0))
            .padding(.vertical, 4 / 2)
            .foregroundColor(.white)
            .background(BalloonShape(
                cornerRadius: cornerRadius,
                color: color,
                mirrored: mirrored)
            )
    }
}

struct BalloonShape: View {
    var cornerRadius: Double
    var color: Color
    var mirrored = false
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let tailSize = CGSize(
                    width: cornerRadius * 0.6,
                    height: cornerRadius * 0.2)
                let shapeRect = CGRect(
                    x: 0,
                    y: 0,
                    width: geometry.size.width,
                    height: geometry.size.height)
                
                // 時計まわりに描いていく

                // 左上角丸
                path.addArc(
                    center: CGPoint(
                        x: shapeRect.minX + cornerRadius,
                        y: shapeRect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 279), clockwise: false)
                
                // 右上角丸
                path.addArc(
                    center: CGPoint(
                        x: shapeRect.maxX - cornerRadius - tailSize.width,
                        y: shapeRect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 270),
                    endAngle: Angle(degrees: 270 + 45), clockwise: false)

                // しっぽ上部
                path.addQuadCurve(
                    to: CGPoint(
                        x: shapeRect.maxX,
                        y: shapeRect.minY),
                    control: CGPoint(
                        x: shapeRect.maxX - (tailSize.width / 2),
                        y: shapeRect.minY))

                // しっぽ下部
                path.addQuadCurve(
                    to: CGPoint(
                        x: shapeRect.maxX - tailSize.width,
                        y: shapeRect.minY + (cornerRadius / 2) + tailSize.height),
                    control: CGPoint(
                        x: shapeRect.maxX - (tailSize.width / 2),
                        y: shapeRect.minY))

                // 右下角丸
                path.addArc(
                    center: CGPoint(
                        x: shapeRect.maxX - cornerRadius - tailSize.width,
                        y: shapeRect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90), clockwise: false)

                // 左下角丸
                path.addArc(
                    center: CGPoint(
                        x: shapeRect.minX + cornerRadius,
                        y: shapeRect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180), clockwise: false)
            }
            .fill(self.color)
            .rotation3DEffect(.degrees(mirrored ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
    }
}

struct BalloonText_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BalloonText("メッセージ1", color: .green)
                .font(.footnote)
            BalloonText("メッセージ2", color: .black.opacity(0.5), mirrored: true)
                .font(.footnote)
        }
    }
}
