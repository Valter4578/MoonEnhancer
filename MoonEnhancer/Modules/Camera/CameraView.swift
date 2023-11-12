//
//  CameraView.swift
//  MoonEnhancer
//
//  Created by Максим Алексеев  on 12.11.2023.
//

import SwiftUI
import PhotosUI

struct CameraView: View {
    @State var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Image("Gallery")
                    .renderingMode(.template)
                    .foregroundColor(.light)
                    .padding(.leading, 52)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .frame(width: 57, height: 57, alignment: .center)
                        .foregroundColor(.light)
                    
                    Circle()
                        .stroke(Color.light, lineWidth: 5)
                        .frame(width: 75, height: 75, alignment: .center)
                        .foregroundColor(.clear)
                    
                    Image("moonIcon")
                        .renderingMode(.template)
                        .foregroundColor(.lightGrey)
                        .frame(width: 34, height: 34)
                }
                
                Spacer()
                
                Image("History")
                    .renderingMode(.template)
                    .foregroundColor(.light)
                    .padding(.trailing, 52)
                
            }
            .frame(height: 158)
            .background(Color.black.opacity(0.6))
        }
    }
}

#Preview {
    CameraView()
}
