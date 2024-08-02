// import ballerina/io;

import ballerina/log;
import ballerinax/googleapis.sheets;

// sheets:Client spreadsheetClient = check new (spreadsheetConfig);
final sheets:Client spreadsheetClient = check initializeGoogleSheetClient();

# Returns the data set from the google sheet.
#
# + return - Data set from the google sheet
// Returns the data set from the google sheet.
//
# + spreadsheetId - ID of the spreadsheet
# + sheetNumber - Which sheet to retrieve data from
# + return - Data set from the google sheet
// Returns the data set from the google sheet.
public function getSheetData(string spreadsheetId, int sheetNumber) returns (int|string|decimal)[][]|error {
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
        return error("Spreadsheet not found: " + spreadsheet.message());

    }

    // Cover all cells in the sheet
    string a1Notation = A1_NOTATION + (spreadsheet.sheets[sheetNumber].properties.gridProperties.rowCount).toString();
    string workSheetName = spreadsheet.sheets[sheetNumber].properties.title;
    sheets:Range|error openRes = spreadsheetClient->getRange(spreadsheet.spreadsheetId, workSheetName, a1Notation);
    if openRes is error {
        log:printError(openRes.toString());
        return error("An error occurred while reading the spreadsheet!");
    }

    return openRes.values;
}

# Append data to the google sheet.
# + spreadsheetId - ID of the spreadsheet
# + sheetNumber - Which sheet to write data  
# + dataRow - Data array to be appended
# + return - Error if any
// Append data to the google sheet.
public function appendData(string spreadsheetId, int sheetNumber, (int|string|decimal)[] dataRow) returns error? {
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError(spreadsheet.toString());
        return error("Spreadsheet not found!");
    }
    sheets:ValueRange|error appendRowToSheet = spreadsheetClient->appendValue(spreadsheet.spreadsheetId,
            dataRow, {sheetName: spreadsheet.sheets[sheetNumber - 1].properties.title});
    if appendRowToSheet is error {
        log:printError(spreadsheet.toString());
        return error("Sheet data append error!");
    }
}

public function appendAnswers(string spreadsheetId, int sheetNumber, Answers[] answers) returns string|error {
    int answerCount = 0;
    int questionCount = check dataRowIndex(1);

    string[] emailArray = [];
    string[] answerArray = [];
    foreach var answer in answers {
        // answerCount += 1;
        emailArray.push(answer.email);
        while answerCount != questionCount {
            foreach var i in answer.answers {
                answerCount += 1;
                answerArray.push(i);
            }
        }
        // answerArray.push(answer.answers[0].toString());
    }
    log:printInfo("answer array data " + answerArray[1]);

    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError(spreadsheet.toString());
        return error("Spreadsheet not found!");
    }

    string sheetName = spreadsheet.sheets[sheetNumber - 1].properties.title;

    foreach var data in emailArray {
        sheets:ValuesRange|error? appendRowToSheet = spreadsheetClient->setCell(spreadsheet.spreadsheetId, sheetName, check emptyEmailRowIndex(sheetNumber, spreadsheetId), data.toString());
        if appendRowToSheet is error {
            log:printError("Sheet data append error!", appendRowToSheet);
            return appendRowToSheet;
        }
    }
    foreach var i in answerArray {
        answerCount += 1;
        sheets:ValuesRange|error? appendRowToSheet = spreadsheetClient->setCell(spreadsheet.spreadsheetId, sheetName, check emptyAnswerRowIndex(sheetNumber, spreadsheetId), i.toString());
        if appendRowToSheet is error {
            log:printError("Sheet data append error!", appendRowToSheet);
            return appendRowToSheet;
        }

    }

    return "";
}

// function appendAnswers(string spreadsheetId, int sheetNumber, Answers[] answers) returns string|error {
//     (int|string|decimal)[][] data = [];
//     foreach var answer in answers {
//         data.push([answer.email, (answer.answers.toString())]);
//     }
//     sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
//     if spreadsheet is error {
//         log:printError(spreadsheet.toString());
//         return error("Spreadsheet not found!");
//     }
//     sheets:ValuesRange|error appendRowToSheet = spreadsheetClient->appendValues(spreadsheet.spreadsheetId, data,
//                 {sheetName: spreadsheet.sheets[sheetNumber - 1].properties.title});
//     if appendRowToSheet is error {
//         log:printError("Sheet data append error!", appendRowToSheet);
//         return appendRowToSheet;
//     }
//     return "";
// }

// Adds a new sheet to the google spreadsheet.
//
// + spreadsheetId - ID of the spreadsheet
// + newSheetName - Name of the new sheet to be added
// + return - Error if any
public function addNewSheet(string spreadsheetId, string newSheetName) returns error? {
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
        return error("Spreadsheet not found: " + spreadsheet.message());
    }

    sheets:Sheet|error newSheet = spreadsheetClient->addSheet(spreadsheet.spreadsheetId, newSheetName);
    if newSheet is error {
        log:printError("Failed to add new sheet", 'error = newSheet, spreadsheetId = spreadsheetId);
        return error("Failed to add new sheet: " + newSheet.message());
    }

    log:printInfo("Successfully added a new sheet with name: " + newSheetName);
}

public function dataRowIndex(int sheetNumber) returns int|error {
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
        return error("Spreadsheet not found: " + spreadsheet.message());
    }
    string sheetName = spreadsheet.sheets[sheetNumber - 1].properties.title;
    sheets:Range|error existingData = spreadsheetClient->getRange(spreadsheet.spreadsheetId, sheetName, "A:A");
    if existingData is error {
        log:printError("Failed to retrieve data from sheet", 'error = existingData);
        return error("Failed to retrieve data: " + existingData.message());
    }
    int emptyRowIndex = existingData.values.length();
    return emptyRowIndex / 2;
}

public function emptyEmailRowIndex(int sheetNumber, string spreadsheetId) returns string|error {
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
        return error("Spreadsheet not found: " + spreadsheet.message());
    }
    string sheetName = spreadsheet.sheets[sheetNumber - 1].properties.title;
    sheets:Range|error existingData = spreadsheetClient->getRange(spreadsheet.spreadsheetId, sheetName, "A:A");
    if existingData is error {
        log:printError("Failed to retrieve data from sheet", 'error = existingData);
        return error("Failed to retrieve data: " + existingData.message());
    }
    int emptyRowIndex = existingData.values.length() + 1;
    string emptyRowA1Notation = "A" + emptyRowIndex.toString();
    return emptyRowA1Notation;
}

int columnCount = 0;

public function emptyAnswerRowIndex(int sheetNumber, string spreadsheetId) returns string|error {
    int qCount = check dataRowIndex(1);
    string[] alphabet = ["B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
        return error("Spreadsheet not found: " + spreadsheet.message());
    }
    string sheetName = spreadsheet.sheets[sheetNumber - 1].properties.title;
    sheets:Range|error existingData = spreadsheetClient->getRange(spreadsheet.spreadsheetId, sheetName, "A:A");
    if existingData is error {
        log:printError("Failed to retrieve data from sheet", 'error = existingData);
        return error("Failed to retrieve data: " + existingData.message());
    }
    int emptyRowIndex = existingData.values.length();
    log:printInfo("The existing data count " + emptyRowIndex.toString());
    // string emptyRowA1Notation = "B" + emptyRowIndex.toString();
    // log:printInfo("The index count " + qCount.toString());
    // string emptyRowA1Notation = "";
    while columnCount != qCount {
        // foreach var i in alphabet {
        string emptyRowA1Notation = alphabet[columnCount] + emptyRowIndex.toString();
        columnCount += 1;
        log:printInfo("The alpha count " + (alphabet[columnCount]).toString());
        return emptyRowA1Notation;
    }
    columnCount = 0;

    return "";
}

# Description.
#
# + spreadsheetId - parameter description  
# + sheetNumber - parameter description  
# + answers - parameter description
# + return - return value description
public function appendAnswersToCell(string spreadsheetId, int sheetNumber, Answers[] answers) returns string|error {
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
        return error("Spreadsheet not found: " + spreadsheet.message());
    }

    string sheetName = spreadsheet.sheets[sheetNumber - 1].properties.title;
    sheets:Range|error existingData = spreadsheetClient->getRange(spreadsheet.spreadsheetId, sheetName, "A:A");
    if existingData is error {
        log:printError("Failed to retrieve data from sheet", 'error = existingData);
        return error("Failed to retrieve data: " + existingData.message());
    }

    int emptyRowIndex = existingData.values.length() + 1;
    (int|string|decimal)[][] data = [];
    foreach var answer in answers {
        data.push([answer.email, (answer.answers.toString())]);
    }

    string a1Notation = A1_NOTATION + (emptyRowIndex + 1).toString();
    sheets:ValuesRange|error appendRowToSheet = spreadsheetClient->appendValues(spreadsheet.spreadsheetId, data,
                    {sheetName: sheetName, "a1Notation": a1Notation});
    if appendRowToSheet is error {
        log:printError("Sheet data append error!", appendRowToSheet);
        return appendRowToSheet;
    }
    return "Data appended successfully to row: " + emptyRowIndex.toString();
}

