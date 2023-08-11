//
//  Convert.swift
//  csv to mermaid
//
//  Created by Spencer Day on 6/22/23.
//

import Foundation

// Here are the theming setting for the Mermaid markdown
let INIT_STR: String = "%%{\ninit: {\n'flowchart': {\n'curve': 'bumpY',\n'padding': 10,\n'nodeSpacing': 150,\n'rankSpacing': 30}}\n}%%\n"
let CLASS_DEFS: [String: String] = [
    "TITLE": "classDef TITLE fill:none, stroke:none, font-size:11.5pt, font-weight:bold, text-decoration:underline;",
    "ACTION": "classDef ACTION fill:none;",
    "TEXT": "classDef TEXT fill:none, stroke:none, font-style: italic;",
    "NONCRITICAL": "classDef NONCRITICAL fill:#9FCAED, stroke:#0071CE, color:black;",
    "CRITICAL": "classDef CRITICAL fill:#0071CE, stroke:#003867;",
    "DEPENDENT": "classDef DEPENDENT fill:#FFAE9C, stroke:#003867, color:black;",
    "SUBGRAPH": "classDef SUBGRAPH fill:none, stroke:#888, font-size:0pt;"
]
let CHART_STYLE = "\nflowchart TD\n\n"
let FLOWCHART_THEME: String = INIT_STR + CHART_STYLE + Array(CLASS_DEFS.values).joined(separator: "\n")
let BOX_STYLE_INDEX: [String: [String: String]] = [
    "square": [
        "openBracket": "[",
        "closeBracket": "]"
    ],
    "rounded": [
        "openBracket": "(",
        "closeBracket": ")"
    ],
    "oval": [
        "openBracket": "([",
        "closeBracket": "])"
    ],
    "hexagon": [
        "openBracket": "{{",
        "closeBracket": "}}"
    ]
]
let BOX_STYLE = "hexagon"  // available options are the keys in BOX_STYLE_INDEX
let OPEN_BRACKET = BOX_STYLE_INDEX[BOX_STYLE]?["openBracket"]
let CLOSE_BRACKET = BOX_STYLE_INDEX[BOX_STYLE]?["closeBracket"]
let LINE = "==="
let ARROW = "==>"

// here are the strings for the actual mermaid markdown
var partIDs: String = ""
var toolIDs: String = ""
var arrows: String = ""
var subgraphs: String = ""
var classes: String = ""

/**
    Class that holds "description" information, which as of now is just actions and tools
 
    - Properties:
        - id: The id that will be associated with the description in mermaid
        - actions: an array of strings, with each item being an action
        - parts: An array of strings, with each item being a specific part
 */
class Description {
    var id: String = ""
    var actions: [String] = []
    var parts: [String] = []
    
    /**
        The initialization takes in the entire "description" string and parses it
     */
    init(id: String,
         description: String) {
        
        if description == "" {
            return
        }
        
        self.id = id
        
        let actionsParts = description.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        self.actions = actionsParts[0].components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        self.parts = actionsParts[1].components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    /**
        Make the tool ID definition
     
        - Returns: A string of the given tool definition
     */
    
    func makeToolDef() -> String {
        return self.id + "(\"" + self.actions.joined(separator: "\n") + "\n" + self.parts.joined(separator: "\n") + "\")" + "\n"
    }
    
    // makes the tool class defintion
    func makeToolClass() -> String {
        return "class \(self.id) TEXT\n"
    }
}

/**
    Class that defines every "part" in the csv:
    
    - Properties:
        - part: The name of the part
        - partID: The Mermaid markdown partID
        - partType: Title, Action, Text, Critical/Non-Critical, Dependent,Subgraph
        - description: S Description objects that holds the info about tools/actions
        - leadsToStr: String of the leadTo parts
        - leadsTo: All the Part objects this part leads to
        - IsSubgraph: Tells us is the part is included in a subgraph
 */
class Part {
    var part: String = ""
    var partID: String = ""
    var partType: String = ""
    var description: Description
    var leadsToStr: [String] = []
    var leadsTo: [Part] = []
    var isSubgraph: Bool = false
    
    // Part class initialization
    init(part: String,
         partID: String,
         partType: String,
         description: Description,
         leadsToStr: [String]) {
        self.part = part
        self.partID = partID
        self.partType = partType
        self.description = description
        self.leadsToStr = leadsToStr
    }
    
    /**
        Creates the part ID defintion
     
        - Returns: A string of the Part objects ID
     */
    func makePartDef() -> String {
        /*
            TODO: add more parsing here to make it "pretty", need another function
         */
        
        return self.partID + OPEN_BRACKET! + "\"" + self.part + "\"" + CLOSE_BRACKET! + "\n"
    }
    
    /**
        Makes the class definition for the part
     
        - Returns: A string of the Part objects class definition
     */
    func makeClassDef() -> String {
        if self.partType != "" {
            return "class \(self.partID) \(self.partType.replacingOccurrences(of: "-", with: "").uppercased())\n"
        }
        else {
            return ""
       }
    }
    
    /**
        Used when drawing arrows
     
        - Returns: The part's mermaid ID, based on if it's a subgraph or not
     */
    func getArrowID() -> String {
        if self.isSubgraph {
            return "SUB\(self.partID)"
        }
        else {
            return self.partID
        }
    }
}

/**
    Parses the given CSV an turns it into an array
 
    - Parameters:
        - csv: A string of a CSV file, which gets generated using a google sheets form
 
    - Returns: A multi-dimensional array of the CSV, trimming any leading or trailling whitespace
 */
func parseCSV(csv: String) -> [[String]] {
    var rows: [[String]] = []

    // Split the input string into individual rows
    let rowsArray = csv.components(separatedBy: "\n")

    for row in rowsArray {
        // Split each row into individual columns
        let columns = row.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Append the columns to the rows array
        rows.append(columns)
    }

    return rows
}

/**
    Transposes an array of strings
 
    - Parameters:
        - arr: The array of strings to transpose
 
    - Returns: The transposed array of strings
 */
func transposeArray(arr: [[String]]) -> [[String]] {
    guard !arr.isEmpty else {
        return []
    }
    
    let rowCount = arr.count
    let columnCount = arr[0].count
    
    var transposedArray: [[String]] = Array(repeating: Array(repeating: "", count: rowCount), count: columnCount)
    
    
    // TODO: guard here against an index out of range error, this would mean invalid csv input, ex, 1 row forgotten
    for i in 0..<rowCount {
        for j in 0..<columnCount {
            guard i < arr.count, j < arr[i].count else {
                return []
            }
            transposedArray[j][i] = arr[i][j]
        }
    }
    
    return transposedArray
}

/**
    Clear any previous Mermaid markdown when the button is pressed
 */
func clearMermaid() -> Void {
    partIDs = "\n\n"
    toolIDs = "\n\n"
    arrows = "\n\n"
    subgraphs = "\n\n"
    classes = "\n\n"
}

/**
    Searches an array of Part objects and returns the Part. This is helpful
    because the filter() built in function returns a set, which will cause
    errors
 
    - Parameters:
        - partName: The name of the part to search for in the given array
        - parts: An array of Part objects to search through
 
    - Returns: The Part object with the given name, if it exists, otherwise returns nil
 */
func findPart(partName: String, parts: [Part]) -> Part? {
    for part in parts {
        if partName == part.part {
            return part
        }
    }
    
    return nil
}

/**
    Creates a list of Part objects for each part in the csv
 
    - Parameters:
        - cols: An array of strings, where each string is a column in the provided CSV
 
    - Returns: An array of Part objects, each being a row in the CSV
 */
func makeParts(cols: [[String]]) -> [Part] {
    var descCount: Int = 0
    var parts: [Part] = []
    
    // go through the columns and create a Part object, then add it to the array
    for (i, col) in cols.enumerated() {
        
        /*
            TODO: this can be optimized so we don't create a Description every time, we only want to create one if there is a non-empty col[2]
         */
        var des = Description(id: "t" + String(i + 1),
                              description: col[2])
    
        var part = Part(part: col[0],
                        partID: "p\(i + 1)",
                        partType: col[1],
                        description: des,
                        leadsToStr: Array(col[3...])
                        )
        parts.append(part)
        
        // we can update the partIDs, toolsIDs, and classes here!
        partIDs += part.makePartDef()
        if col[2] != "" {  // make sure there is a description
            toolIDs += des.makeToolDef()
            classes += des.makeToolClass()
        }
        classes += part.makeClassDef()
    }
    
    // make the list of Part objects for each part
    for part in parts {
        var subgraph = ""
        for partStr in part.leadsToStr {
            if partStr != "" {
                if var found = findPart(partName: partStr, parts: parts) {
                    part.leadsTo.append(found)
                    if found.partType == "Dependent" {
                        part.isSubgraph = true
                        subgraph += found.partID + "\n"
                    }
                }
            }
        }
        if subgraph != "" {
            subgraphs += "subgraph SUB" + part.partID + "\n" + "\(part.partID)\n" + subgraph + "end\n"
            classes += "class SUB\(part.partID) SUBGRAPH\n"
        }
    }
    
    // draw the arrows
    for part in parts {
        for l in part.leadsTo {
            // if it leads to a part that has a description, connect to the description
            if l.description.id != "" {
                arrows += part.getArrowID() + LINE + l.description.id + "\n"
            }
            // if it leads to a part without a description, draw straight to the part
            else {
                arrows += part.getArrowID() + ARROW + l.getArrowID() + "\n"
            }
        }
        
        // connect the part description to the part
        if part.description.id != "" {
            arrows += part.description.id + ARROW + part.getArrowID() + "\n"
        }
    }
    
    return parts
}
