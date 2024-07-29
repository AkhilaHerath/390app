import ballerina/http;
import ballerina/log;
import ballerinax/googleapis.sheets as sheets;

string spreadsheetId = "1WazHQTUPANNPnunIDYkebdec1vV47Uk7cA7ZkmUQMZw";

sheets:ConnectionConfig spreadsheetConfig = {
    auth: {
        clientId: "412566681781-ok7darnom4nfqoe1h5hve33njglgf17l.apps.googleusercontent.com",
        clientSecret: "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",
        refreshUrl: sheets:REFRESH_URL,
        refreshToken: "1//04hWZRvBJMwozCgYIARAAGAQSNwF-L9Ir5oSnk_2A2ICRKbVJPOG2FTAU6K1yNP8z_GRQCG5_tWFpUXlLCLjoZALkwBtGzRMjfU8"
    }
};

service / on new http:Listener(9091) {
    //add the an email to the sheet containing the emails
    resource function post email(string email) returns string|error {
        (int|string|decimal)[][]|error data = getSheetData(spreadsheetId, 0);
        if data is error {
            return "Failed to get sheet data: " + data.message();
        }
        //Incerements the ID when adding the email to the worksheet
        int nextId = 1;
        if data.length() > 0 {
            int maxId = data.length();
            foreach var row in data {
                if row[0] is int {
                    if <int>row[0] > maxId {
                        maxId = <int>row[0];
                    }
                }
            }
            nextId = maxId + 1;
        }

        error? result = appendData(spreadsheetId, 1, [nextId, email]);
        if result is error {
            return "Failed to add email: " + result.message();
        }
        return "Email added successfully";
    }

    //get all the emails from the sheet containing the emails
    resource function get emails() returns (int|string|decimal)[][]|error {
        // Get all data from worksheet 1
        return getSheetData(spreadsheetId, 0);
    }

    //get the email related to the ID from the sheet containing the emails
    resource function get email/[int id]() returns map<anydata>|error {
        (int|string|decimal)[][]|error data = getSheetData(spreadsheetId, 0);
        if data is error {
            return data;
        }
        if id <= 0 || id > data.length() {
            return error("Invalid ID");
        }
        // First column is ID and the second is email
        return {"email": data[id - 1][1]};
    }

    //get the questions from the sheet containing the questions
    resource function get question/[int id]() returns map<anydata>|error {
        (int|string|decimal)[][]|error data = getSheetData(spreadsheetId, 1);
        if data is error {
            return data;
        }
        if id <= 0 || id > data.length() {
            return error("Invalid ID");
        }
        // First column is ID and the second is question
        return {"question": data[id - 1][1]};
    }

    resource function get questions() returns (int|string|decimal)[][]|error {
        // Get all data from  worksheet 2
        return getSheetData(spreadsheetId, 1);
    }

    resource function post answersToSheets(Answers answers) returns string|error {
        (int|string|decimal)[][]|error data = getSheetData(spreadsheetId, 0);
        if data is error {
            return "Failed to get sheet data: " + data.message();
        }

        sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
        if spreadsheet is error {
            log:printError(spreadsheet.toString());
            return error("Spreadsheet not found!");
        }

        // Flag to check if the email matches an existing sheet
        boolean sheetExists = false;
        int sheetIndex = 0;

        // Iterate through each sheet in the spreadsheet
        foreach sheets:Sheet sheet in spreadsheet.sheets {
            sheetIndex += 1;
            if (answers.email.toString() == sheet.properties.title) {
                sheetExists = true;
                break;
            }
        }

        // If the sheet doesn't exist, create a new one
        if (!sheetExists) {
            error? newSheet = addNewSheet(spreadsheetId, answers.email.toString());
            if newSheet is error {
                return "Failed to create new sheet: " + newSheet.message();
            }
            // Update the sheetIndex to point to the newly created sheet
            sheetIndex = spreadsheet.sheets.length() + 1;
        }

        // Append the answers to the sheet
        string|error result = appendAnswers(spreadsheetId, sheetIndex, [answers]);
        if result is error {
            return "Failed to add data: " + result.message();
        }

        return "Data added successfully";
    }

    resource function post answers(string answer, string email) returns string|error {
        error? newSheet = addNewSheet(spreadsheetId, email);
        if newSheet is error {
            log:printError("Failed to add new sheet", 'error = newSheet);
            return "Failed to add new sheet: " + newSheet.message();
        }
        sheets:Spreadsheet|error spreadsheet = spreadsheetClient->openSpreadsheetById(spreadsheetId);
        if spreadsheet is error {
            log:printError("Failed to open spreadsheet", 'error = spreadsheet, spreadsheetId = spreadsheetId);
            return error("Spreadsheet not found: " + spreadsheet.message());

        }
        int sheetCount = spreadsheet.sheets.length();
        (int|string|decimal)[][]|error data = getSheetData(spreadsheetId, sheetCount - 1);
        if data is error {
            return "Failed to get sheet data: " + data.message();
        }
        int nextId = 1;
        if data.length() > 0 {
            int maxId = data.length();
            foreach var row in data {
                if row[0] is int {
                    if <int>row[0] > maxId {
                        maxId = <int>row[0];
                    }
                }
            }
            nextId = maxId + 1;
        }
        error? result = appendData(spreadsheetId, sheetCount, [nextId, answer]);
        if result is error {
            return "Failed to add email: " + result.message();
        }
        return "Email added successfully";
    }

    isolated
    resource function put email/[int id](map<anydata> email) returns string|error {
        return error("Update operation not supported");
    }

    resource function delete email/[int id]() returns string|error {

        return error("Delete operation not supported");
    }
}

// public function main(string... args) {
//     error? newSheet = addNewSheet(spreadsheetId, "Answers3");
//     if newSheet is error {
//         log:printError("Failed to add new sheet", 'error = newSheet); // Added error logging for the addNewSheet function
//     }
// }
