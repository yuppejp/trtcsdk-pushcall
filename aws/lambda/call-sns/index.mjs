import { SNSClient, PublishCommand, CreatePlatformEndpointCommand, DeleteEndpointCommand, ListEndpointsByPlatformApplicationCommand } from "@aws-sdk/client-sns";
const client = new SNSClient();
const snsArn = 'arn:aws:sns:XXX/APNS_VOIP_SANDBOX/TrtcVideoRoom';

import { DynamoDBClient, BatchWriteItemCommand, ScanCommand, DeleteItemCommand } from "@aws-sdk/client-dynamodb";
import { UpdateCommand } from "@aws-sdk/lib-dynamodb";
const dynamoClient = new DynamoDBClient();

export const handler = async(event) => {
    console.log('[enter] handler');
    console.log(`event: ${JSON.stringify(event)}`);

    try {
        var result = "";
        switch (event.command) {
        case 'RegisterEndpoint':
            result = await registerEndpoint(event.deviceToken, event.customUserData);
            break;
        case 'PushCall':
            result = await pushCall(event.userIds, event.message);
            break;
        case 'FetchRoomUsers':
            result = await fetchRoomUsers(event.roomId);
            break;

        case 'WriteMeeting':
            result = await writeMeeting(event.roomId, event.subject, event.startDate);
            break;
        case 'DeleteMeeting':
            result = await deleteMeeting(event.id);
            break;
        case 'ScanUpcomingMeetings':
            result = await scanUpcomingMeetings();
            break;
        case 'ScanMeetings':
            result = await scanMeetings(event.roomId);
            break;
        case 'Timer':
            result = await OnTimer();
            break;

        default:
            result = "unknown command: " + event.command;
        }
        const httpResponse = {
            statusCode: 200,
            body: JSON.stringify(result),
        };
        console.log(httpResponse);
        return httpResponse;
    } catch (error) {
        const response = {
            statusCode: 400,
            body: JSON.stringify(error),
        };
        console.log(response);
        return response;
    }
};

async function registerEndpoint(deviceToken, customUserData) {
    const regUserId = customUserData.userId ? customUserData.userId : ""; 
    const regRoomId = customUserData.roomId ? customUserData.roomId : ""; 
    var users = new Array();
    var alreadyRegistered = false;
    var response = await listEndpoints();
    for (const endpoint of response.Endpoints) {
        const attr = endpoint.Attributes;
        const token = attr.Token ? attr.Token : ""; 
        const userData = JSON.parse(attr.CustomUserData);
        const userId = userData.userId ? userData.userId : ""; 
        const roomId = userData.roomId ? userData.roomId : ""; 

        if (token == deviceToken && userId == regUserId && roomId == regRoomId) {
            alreadyRegistered = true;
        }
        else if (token == deviceToken && userId != regUserId) {
            // delete once
            response = await deleteEndpoint(endpoint.EndpointArn);
        }
        else if (userId == regUserId && roomId != regRoomId) {
            // delete once
            response = await deleteEndpoint(endpoint.EndpointArn);
        }
        else if (roomId == regRoomId) {
            if (userId.length != 0) {
                users.push(userId); // for result
            }
        }
    }

    if (!alreadyRegistered) {
        await createEndpoint(deviceToken, JSON.stringify(customUserData));
        users.push(regUserId);
    }

    const result = {
        'userId': regUserId,
        'roomId': regRoomId,
        'users': users
    };
    return result;
}

async function pushCall(userIds, message) {
    const response = await listEndpoints();
    for (const endpoint of response.Endpoints) {
        const userData = JSON.parse(endpoint.Attributes.CustomUserData);
        for (const userId of userIds) {
            if (userData.userId == userId) {
                await publish(endpoint.EndpointArn, message);
            }
        }
    }
    return 'OK';
}

async function pushCallByRoomId(roomId, message) {
    const response = await listEndpoints();
    for (const endpoint of response.Endpoints) {
        const userData = JSON.parse(endpoint.Attributes.CustomUserData);
        if (userData.roomId == roomId) {
            await publish(endpoint.EndpointArn, message);
        }
    }
    return 'OK';
}

async function fetchRoomUsers(targetRoomId) {
    var users = new Array();
    var response = await listEndpoints();
    for (const endpoint of response.Endpoints) {
        const userData = JSON.parse(endpoint.Attributes.CustomUserData);
        const userId = userData.userId ? userData.userId : ""; 
        const roomId = userData.roomId ? userData.roomId : ""; 
        if (roomId == targetRoomId) {
            if (userId.length != 0) {
                users.push(userId);
            }
        }
    }
    const result = {
        'roomId': targetRoomId,
        'users': users
    };
    return result;
}

async function createEndpoint(deviceToken, userData) {
    const input = {
        'PlatformApplicationArn': snsArn,
        'CustomUserData': userData,
        'Token': deviceToken
    };
    const command = new CreatePlatformEndpointCommand(input);
    const response = await client.send(command);
    return response;
}

async function deleteEndpoint(endpointArn) {
    const input = {
        'EndpointArn': endpointArn
    };
    const command = new DeleteEndpointCommand(input);
    const response = await client.send(command);
    console.log(response);
    return response;
}

async function listEndpoints() {
    const input = {
        'PlatformApplicationArn': snsArn
    };
    const command = new ListEndpointsByPlatformApplicationCommand(input);
    const response = await client.send(command);
    return response;
}

async function publish(arn, message) {
    const messageAttributes = {
        'AWS.SNS.MOBILE.APNS.PUSH_TYPE': {
            'DataType': 'String',
            'StringValue': 'voip'
        }
    };
    const input = {
        'TargetArn': arn,
        'Message': message,
        'Subject': 'subject1',
        'MessageAttributes': messageAttributes
    };
    const command = new PublishCommand(input);
    const response = await client.send(command);
    return response;
}
    
//
// DynamoDB functions
//

async function writeMeeting(roomId, subject, startDate) {
    const date = new Date();
    const timeIntervalSince1970 = date.getTime();
    const timeString = timeIntervalSince1970.toString();
    const params = {
      RequestItems: {
        TrtcVideoMeeting: [
          {
            PutRequest: {
              Item: {
                id: { N: timeString },
                roomId: { S: roomId },
                subject: { S: subject },
                startDate: { S: startDate },
                meetingStatus: { S: "upcoming" },
              },
            },
          }
        ],
      },
    };
    const command = new BatchWriteItemCommand(params);
    const response = await dynamoClient.send(command);
    console.log(response);
    return response;
}

async function deleteMeeting(id) {
    const params = {
        Key: { id: { N: id } },
        TableName: "TrtcVideoMeeting",
    };

    const command = new DeleteItemCommand(params);
    const response = await dynamoClient.send(command);
    console.log(response);
    return response;
}

async function scanMeetings(roomId) {
    const params = {
        FilterExpression: "roomId = :topic",
        ExpressionAttributeValues: {
            ":topic": { S: roomId },
        },
        TableName: "TrtcVideoMeeting",
    };

    const command = new ScanCommand(params);
    const response = await dynamoClient.send(command);
    return response;
}

async function scanUpcomingMeetings() {
    const params = {
        FilterExpression: "meetingStatus = :topic",
        ExpressionAttributeValues: {
            ":topic": { S: "upcoming" },
        },
        TableName: "TrtcVideoMeeting",
    };

    const command = new ScanCommand(params);
    const response = await dynamoClient.send(command);
    return response;
}

async function updateMeetingStatus(id, meetingStatus) {
    const params = {
        Key: { id: id },
        UpdateExpression: 'set #a = :x',
        ExpressionAttributeNames: {
            '#a': 'meetingStatus'
        },
        ExpressionAttributeValues: {
            ':x': meetingStatus
        },
        TableName: "TrtcVideoMeeting",
    };

    const command = new UpdateCommand(params);
    const response = await dynamoClient.send(command);
    return response;
}

async function OnTimer() {
    const response = await scanUpcomingMeetings();
    
    var count = 0;
    for (const item of response.Items) {
        const idString = item.id.N;
        const roomId = item.roomId.S;
        const subject = item.subject.S;
        const startDateString = item.startDate.S;
        const startDate = parseInt(startDateString, 10);
        
        const date = new Date();
        const now = date.getTime();
        const elapsed = now - startDate;
        
        console.log('id:' + idString+ ' roomId:' + roomId + ' subject:' + subject + ' startDate:' + startDate + ' elapsed:' + elapsed);
        
        const timeMargin1 = 10 * 60 * 1000; // 10 minutes ago
        const timeMargin2 = 1 * 60 * 1000; // 1 minutes later
        console.log('timeMargin1: '+ timeMargin1)
        console.log('timeMargin2: '+ timeMargin2)
        if (elapsed <= timeMargin1 && -elapsed <= timeMargin2) {
            console.log('Its time to start ' + subject);
            
            // VOIP Push
            await pushCallByRoomId(roomId, subject);
            
            // mark done
            const id = parseInt(idString, 10);
            const result = await updateMeetingStatus(id, 'done');
            count++;
        }
    }
    return { count: count };
}
