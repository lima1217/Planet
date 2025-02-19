//
//  WriterTitleView.swift
//  Planet
//
//  Created by Kai on 1/5/23.
//

import SwiftUI


struct WriterTitleView: View {
    @State private var updatingDate: Bool = false
    @State private var titleIsFocused: Bool = false
    @State private var initDate: Date = Date()
    
    @Binding var date: Date
    @Binding var title: String
    @FocusState var focusTitle: Bool
    
    var body: some View {
        HStack (spacing: 0) {
            Group {
                if #available(macOS 13.0, *) {
                    TextField("Title", text: $title)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .background(Color(NSColor.textBackgroundColor))
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($focusTitle, equals: titleIsFocused)
                } else {
                    CLTextFieldView(text: $title, placeholder: "Title")
                }
            }
            .frame(height: 34, alignment: .leading)
            .padding(.bottom, 2)
            .padding(.horizontal, 16)
            
            Spacer(minLength: 8)
            
            Text("\(date.simpleDateDescription())")
                .foregroundColor(.secondary)
                .background(Color(NSColor.textBackgroundColor))
            
            Spacer(minLength: 8)
            
            Button {
                updatingDate.toggle()
            } label: {
                Image(systemName: "calendar.badge.clock")
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
            .popover(isPresented: $updatingDate) {
                VStack (spacing: 10) {
                    Spacer()
                    
                    HStack {
                        HStack {
                            Text("Date")
                            Spacer()
                        }
                        .frame(width: 40)
                        Spacer()
                        DatePicker("", selection: $date, displayedComponents: [.date])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    .padding(.horizontal, 16)
                    
                    HStack {
                        HStack {
                            Text("Time")
                            Spacer()
                        }
                        .frame(width: 40)
                        Spacer()
                        DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    .padding(.horizontal, 16)
                    
                    Divider()
                    
                    HStack (spacing: 10) {
                        Spacer()
                        Button {
                            updatingDate = false
                            date = initDate
                        } label: {
                            Text("Cancel")
                        }
                        Button {
                            updatingDate = false
                        } label: {
                            Text("Set")
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .padding(.horizontal, 0)
                .frame(width: 280, height: 124)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .task {
            initDate = date
        }
    }
}

struct WriterTitleView_Previews: PreviewProvider {
    static var previews: some View {
        WriterTitleView(date: .constant(Date()), title: .constant(""))
    }
}
