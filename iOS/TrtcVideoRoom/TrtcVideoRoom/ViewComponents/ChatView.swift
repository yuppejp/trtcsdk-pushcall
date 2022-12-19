//
//  ChatView.swift
//  TrtcVideoRoom
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: TrtcViewModel
    @ObservedObject var room: Room
    @State private var inputText = ""
    @State private var scrollViewContentSize: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { reader in
                VStack {
                    //List { // https://developer.apple.com/forums/thread/712510
                    ScrollView {
                        VStack {
                            ForEach(room.messages) { message in
                                MessageItemView(message: message, myUserName: viewModel.defaults.userId)
                                    .id(message.id)
                                    .font(.footnote)
                                    //.background(.bar)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                        .background(
                            // ScrollView shrink to fit
                            // https://developer.apple.com/forums/thread/671690
                            GeometryReader { geometry -> Color in
                                DispatchQueue.main.async {
                                    scrollViewContentSize = geometry.size
                                }
                                return Color.clear
                            }
                        )

                    }
                    .frame(maxHeight: scrollViewContentSize.height)
                    //.background(.bar)
                    .listStyle(PlainListStyle())
                }
                .padding(4)
                .onAppear {
                    withAnimation(.linear(duration: 2)) {
                        if let id = room.messages.last?.id {
                            reader.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: room.messages.count) { _ in
                    withAnimation(.linear(duration: 2)) {
                        if let id = room.messages.last?.id {
                            reader.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }
            .onTapGesture {
                UIApplication.shared.closeKeyboard()
            }

            HStack {
                TextField("Input Message...", text: $inputText)
                    .onSubmit {
                        if !inputText.isEmpty {
                            viewModel.sendMessage(text: inputText)
                            inputText = ""
                        }
                    }
                    .font(.footnote)
                    .keyboardType(.default)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(4)
            }
            //.background(.background)
        }
        .background(.background.opacity(0.5))
    }
}

struct MessageItemView: View {
    var message: RoomMessage
    var myUserName: String
    
    var body: some View {
        if message.userName == myUserName {
            MyMessageItemView(message: message)
        } else {
            YourMessageItemView(message: message)
        }
    }
}

struct YourMessageItemView: View {
    var message: RoomMessage
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(message.userName)
                    .font(.caption2)
                    .padding(.leading, 4)
                
                BalloonText(message.text, color: .green, mirrored: true)
                    //.font(.body)
                    .padding(.leading, 8)
            }
            
            VStack() {
                Text(message.date.formatTime())
                    .font(.caption2)
                    .padding(.leading, 4)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            
            Spacer()
                .frame(maxWidth: .infinity)
        }
    }
}

struct MyMessageItemView: View {
    @State var message: RoomMessage
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
                .frame(maxWidth: .infinity)
            
            VStack() {
                Text(message.date.formatTime())
                    .font(.caption2)
                    .padding(.trailing, 4)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(message.userName)
                    .font(.caption2)
                    .padding(.trailing, 4)
                
                BalloonText(message.text, color: .green, mirrored: false)
                    //.font(.body)
                    .padding(.trailing, 8)
            }
        }
    }
}


extension Date {
    func formatTime() -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        f.locale = Locale(identifier: "ja_JP")
        let time = f.string(from: self)
        return time
    }
}

extension UIApplication {
    func closeKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TrtcViewModel(debugPreview: true)

        VStack {
            Button("add") {
                viewModel.room.messages.append(RoomMessage(userName: "user1", text: "test"))
            }
            ChatView(room: viewModel.room)
                .environmentObject(viewModel)
        }
            //.previewInterfaceOrientation(.landscapeLeft)
    }
}
