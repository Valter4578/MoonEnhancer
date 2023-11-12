//
//  TabBarView.swift
//  MoonEnhancer
//
//  Created by Максим Алексеев  on 12.11.2023.
//

import SwiftUI

struct TabBarView: View {
    @State var selectedIndex: Int = 0
    
    var body: some View {
        ZStack {
            ZStack {
                Color.tabBar
                HStack {
                    Image("Gallery")
                        .renderingMode(.template)
                        .foregroundColor(selectedIndex == 0 ? .mainPurple : .light)
                        .padding(.leading, 52)
                        .onTapGesture {
                            selectedIndex = 0
                        }
                    
                    Spacer()
                    
                    Image("History")
                        .renderingMode(.template)
                        .foregroundColor(selectedIndex == 2 ? .mainPurple : .light)
                        .padding(.trailing, 52)
                        .onTapGesture {
                            selectedIndex = 2
                        }
                }// HStack
                .frame(height: 68, alignment: .center)
            } // ZStack
            .frame(height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            ZStack(alignment: .center, content: {
                Circle()
                    .foregroundStyle(Color.mainPurple)
                    .frame(width: 65, height: 65)
                    .padding(.horizontal, 100)
                
                Image("cameraIcon")
            }) // ZStack
            .padding(.bottom, 50)
            .shadow(color: .purpleShadow, radius: 20, x: 0.0, y: 4.0)
        }
    }
}

#Preview {
    TabBarView()
}
