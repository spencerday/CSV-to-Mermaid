//
//  ContentView.swift
//  csv to mermaid
//
//  Created by Spencer Day on 6/20/23.
//

import SwiftUI
import Cocoa

struct ContentView: View {
    
    @State var csvStr: String = ""
    @State var mermaid: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter the CSV", text: $csvStr, axis: .vertical)
            Button("Make Mermaid", action: makeMermaid)
            Button("Copy Mermaid", action: copyMermaid)
            ScrollView {  // displaying output
                Text(mermaid)
                    .lineLimit(nil)
                    .textSelection(.enabled)
            }
        }
        .padding()
    }
    
    /**
        This function makes the Mermaid markdown, magic!
     */
    func makeMermaid() -> Void {
        
        var rowsArr = parseCSV(csv: csvStr)
        var colsArr = transposeArray(arr: rowsArr)

        // bad csv
        if colsArr.isEmpty {
            mermaid = "Invalid CSV input, try again"
            return
        }
        if colsArr[0].count < 3  {
            mermaid = "Invalid CSV input, try again"
            return
        }
        
        clearMermaid()
        var parts = makeParts(cols: Array(colsArr[1...]))
        
        // create the mermaid output, it's just a long string
        mermaid = FLOWCHART_THEME + partIDs + toolIDs + subgraphs + arrows + classes
    }
    
    /**
         A button for copying the mermaid that is created
     */
    func copyMermaid() -> Void {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(mermaid, forType: NSPasteboard.PasteboardType.string)

        // Show an alert to indicate successful copy
        let alert = NSAlert()
        alert.messageText = "Copied"
        alert.informativeText = "Mermaid copied to clipboard."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
