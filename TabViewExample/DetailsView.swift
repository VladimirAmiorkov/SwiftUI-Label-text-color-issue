//
//  DetailsView.swift
//  TabViewExample
//
//  Created by Vladimir Amiorkov on 3.02.25.
//

import SwiftUI

struct DetailsView: View {
    @State var item: Item
    
    var body: some View {
        TabView {
            Text("Item at \(item.timestamp!, formatter: itemFormatter2)")
            Text("Second")
            Text("Third")
            Text("Fourth")
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

#Preview {
    DetailsView(item: Item())
}


let itemFormatter2: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()
