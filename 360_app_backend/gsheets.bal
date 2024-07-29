import ballerina/log;
import ballerinax/googleapis.sheets;

sheets:Client spreadsheetClient = check new (spreadsheetConfig);

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
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById("1WazHQTUPANNPnunIDYkebdec1vV47Uk7cA7ZkmUQMZw");
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

type Answers record {
    string email;
    anydata answers;
};

function appendAnswers(string spreadsheetId, int sheetNumber, Answers[] answers) returns string|error {
    (int|string|decimal)[][] data = [];
    foreach var answer in answers {
        data.push([answer.email, (answer.answers.toString())]);
    }
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
    if spreadsheet is error {
        log:printError(spreadsheet.toString());
        return error("Spreadsheet not found!");
    }
    sheets:ValuesRange|error appendRowToSheet = spreadsheetClient->appendValues(spreadsheet.spreadsheetId, data,
                {sheetName: spreadsheet.sheets[sheetNumber - 1].properties.title});
    if appendRowToSheet is error {
        log:printError("Sheet data append error!", appendRowToSheet);
        return appendRowToSheet;
    }
    return "";
}

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
