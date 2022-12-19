//
//  MeetingScheduleView.swift
//  TrtcVideoRoom
//

import SwiftUI

struct Meeting: Identifiable {
    let id = UUID()
    var itemId: Int = 0
    var roomId: Int = 0
    var subject: String = ""
    var startDate: Date = Date()
    var meetingStatus: String = "upcomming" // upcomming, done, canceled
}

class MeetingList: Identifiable, ObservableObject {
    @Published var meetings: [Meeting]
    
    init(meetings: [Meeting]) {
        self.meetings = meetings
    }
}

struct MeetingScheduleView: View {
    @ObservedObject var meetingList: MeetingList
    @State private var showSheetView = false
    @State private var id: UUID?
    @EnvironmentObject var viewModel: TrtcViewModel

    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(meetingList.meetings) { meeting in
                        ItemView(meeting: meeting)
                            .id(meeting.id)
                            .onTapGesture {
                                id = meeting.id
                                showSheetView = true
                            }
                    }
                } header: {
                    Text("Schedule")
                }

                Section {
                    Button("Add Schedule") {
                        id = nil
                        showSheetView = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }

        }
        .sheet(isPresented: $showSheetView) {
            EdittingView(meetingList: meetingList, id: id, showSheetView: self.$showSheetView)
        }
        .onAppear {
            Task {
                let aws = viewModel.awsModel
                do {
                    let meetings = try await aws.scanMeeting(roomId: viewModel.defaults.roomId)
                    meetingList.meetings = meetings.sorted(by: { $0.startDate < $1.startDate })
                } catch {
                    viewModel.errMessage = error.localizedDescription
                }
            }
        }
        
    }
    
    struct ItemView: View {
        var meeting: Meeting
        
        var body: some View {
            HStack {
                Text(meeting.subject)
                Spacer()
                Text(meeting.startDate, style: .date)
                Text(meeting.startDate, style: .time)
            }
        }
    }
    
    struct EdittingView: View {
        var meetingList: MeetingList
        var id: UUID?
        @Binding var showSheetView: Bool
        @EnvironmentObject var viewModel: TrtcViewModel

        @State var meeting = Meeting()
        @State var push = true
        @State var message = ""
        
        var body: some View {
            VStack {
                Form {
                    Section(header: Text("Meeting")) {
                        TextField("Subject", text: $meeting.subject)

                        VStack {
                            HStack {
                                Text("Room ID")
                                Spacer(minLength: 0)
                                Text("1")
                            }
                            
                            DatePicker(selection: $meeting.startDate, label: { Text("Date") })
                        }
                    }
                    
                    Section(header: Text("Option")) {
                        Toggle(isOn: $push) {
                            VStack(alignment: .leading) {
                                Text("VOIP Push Notification")
                            }
                        }
                    }

                    Section(header: Text("")) {
                        if id == nil {
                            Button("Create Metting") {
                                Task {
                                    let aws = viewModel.awsModel
                                    do {
                                        try await aws.writeMeeting(roomId: viewModel.defaults.roomId,
                                                                   subject: meeting.subject,
                                                                   startDate: meeting.startDate)
                                        meetingList.meetings.append(meeting)
                                        showSheetView.toggle()
                                    } catch {
                                        viewModel.errMessage = error.localizedDescription
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .disabled(meeting.subject.isEmpty)
                        } else {
                            Button("Delete") {
                                Task {
                                    let aws = viewModel.awsModel
                                    do {
                                        try await aws.deleteMeeting(id: meeting.itemId)
                                        meetingList.meetings.removeAll(where: { $0.id == meeting.id })
                                        showSheetView.toggle()
                                    } catch {
                                        viewModel.errMessage = error.localizedDescription
                                    }
                                }
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                }
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.red)
                }
            }
            .onAppear {
                if let meeting = meetingList.meetings.first(where: { $0.id == id }) {
                    self.meeting = meeting
                }
            }
        }
    }
}

struct MeetingScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        let meeting1 = Meeting(roomId: 1, subject: "subject1", startDate: Date())
        let meeting2 = Meeting(roomId: 1, subject: "subject2", startDate: Date())
        let meeting3 = Meeting(roomId: 1, subject: "subject3", startDate: Date())
        let meetingList = MeetingList(meetings: [meeting1, meeting2, meeting3])
        MeetingScheduleView(meetingList: meetingList)
    }
}
