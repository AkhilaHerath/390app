import ballerina/http;
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
    resource function post email(string email) returns string|error {
        (int|string|decimal)[][]|error data = getSheetData(spreadsheetId);
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

    resource function get emails() returns (int|string|decimal)[][]|error {
        // Get all data from worksheet 1
        return getSheetData(spreadsheetId);
    }

    resource function get email/[int id]() returns map<anydata>|error {
        (int|string|decimal)[][]|error data = getSheetData(spreadsheetId);
        if data is error {
            return data;
        }
        if id <= 0 || id > data.length() {
            return error("Invalid ID");
        }
        // First column is ID and the second is email
        return {"email": data[id - 1][1]};
    }

    resource function get question/[int id]() returns map<anydata>|error {
        (int|string|decimal)[][]|error data = getSheetTwoData(spreadsheetId);
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
        return getSheetTwoData(spreadsheetId);
    }

    isolated resource function put email/[int id](map<anydata> email) returns string|error {
        return error("Update operation not supported");
    }

    resource function delete email/[int id]() returns string|error {

        return error("Delete operation not supported");
    }
}
// public function main(string... args) {
//     var response = spreadsheetClient->openSpreadsheetById("1WazHQTUPANNPnunIDYkebdec1vV47Uk7cA7ZkmUQMZw");
//     if (response is sheets:Spreadsheet) {
//         io:println("Spreadsheet Details: ", response);
//     } else {
//         io:println("Error: ", response);
//     }
// }
