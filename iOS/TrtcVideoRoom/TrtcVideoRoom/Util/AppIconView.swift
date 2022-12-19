//
//  AppIconView.swift
//  TrtcVideoRoom
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(.green.gradient)
                Image(systemName: "person.3.sequence.fill")
                    .resizable()
                    //.renderingMode(.original)
                    .foregroundColor(.white)
                    .scaledToFit()
                    .padding(40)
                    //.imageScale(.large)
            }
        }
        .frame(width: 300, height: 300)
    }
}

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView()
    }
}
