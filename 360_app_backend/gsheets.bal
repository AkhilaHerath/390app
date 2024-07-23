import ballerina/log;
import ballerinax/googleapis.sheets;

sheets:Client spreadsheetClient = check new (spreadsheetConfig);

# Returns the data set from the google sheet.
#
# + return - Data set from the google sheet
// Returns the data set from the google sheet.
//
// + spreadsheetId - ID of the spreadsheet
// + sheetNumber - Which sheet to retrieve data from
// + return - Data set from the google sheet
// Returns the data set from the google sheet.
//
// + spreadsheetId - ID of the spreadsheet
// + return - Data set from the google sheet
public function getSheetData(string spreadsheetId) returns (int|string|decimal)[][]|error {
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById("1WazHQTUPANNPnunIDYkebdec1vV47Uk7cA7ZkmUQMZw");
    if spreadsheet is error {
        log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
        return error("Spreadsheet not found: " + spreadsheet.message());

    }

    // Cover all cells in the sheet
    string a1Notation = A1_NOTATION + (spreadsheet.sheets[0].properties.gridProperties.rowCount).toString();
    string workSheetName = spreadsheet.sheets[0].properties.title;
    sheets:Range|error openRes = spreadsheetClient->getRange(spreadsheet.spreadsheetId, workSheetName, a1Notation);
    if openRes is error {
        log:printError(openRes.toString());
        return error("An error occurred while reading the spreadsheet!");
    }

    return openRes.values;
}

public function getSheetTwoData(string spreadsheetId) returns (int|string|decimal)[][]|error {
    sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById("1WazHQTUPANNPnunIDYkebdec1vV47Uk7cA7ZkmUQMZw");
    if spreadsheet is error {
        log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
        return error("Spreadsheet not found: " + spreadsheet.message());

    }

    // Cover all cells in the sheet
    string a1Notation = A1_NOTATION + (spreadsheet.sheets[1].properties.gridProperties.rowCount).toString();
    string workSheetName = spreadsheet.sheets[1].properties.title;
    sheets:Range|error openRes = spreadsheetClient->getRange(spreadsheet.spreadsheetId, workSheetName, a1Notation);
    if openRes is error {
        log:printError(openRes.toString());
        return error("An error occurred while reading the spreadsheet!");
    }

    return openRes.values;
}

# Append data to the google sheet.
#
# + sheetNumber - Which sheet to write data  
# + dataRow - Data array to be appended
# + return - Error if any
// Append data to the google sheet.
//
// + spreadsheetId - ID of the spreadsheet
// + sheetNumber - Which sheet to write data
// + dataRow - Data array to be appended
// + return - Error if any
// Append data to the google sheet.
//
// + spreadsheetId - ID of the spreadsheet
// + sheetNumber - Which sheet to write data
// + dataRow - Data array to be appended
// + return - Error if any
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
