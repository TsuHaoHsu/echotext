# EchoText - Flutter Messaging App


## Description
EchoText is a real-time messaging app built using Flutter and FastAPI. It supports user registration, login, sending and receiving text messages.
The app integrates with MongoDB to store user and message data.

## Features
- **User Authentication**: Login, registration, and JWT-based authentication(Currently does not retain login upon closing app).
- **Messaging**: Real-time text messaging with WebSocket support.
- **Friend Requests**: Add, accept, or cancel friend requests.
- **Profile Management**: View friends' profiles. (work in progress)
- **Real-time Updates**: New messages are pushed to the app instantly using WebSocket.

## Technologies
- **Flutter**: For the frontend mobile app development.
- **FastAPI**: For the backend API.
- **MongoDB**: To store users and message data.
- **WebSocket**: For real-time communication.
- **JWT**: For secure user authentication. 
- **Riverpod**: For user id and token management.
- **Dart**: Programming language for Flutter.

## Installation
### Prerequisites
- **Flutter**: Install Flutter SDK on your machine.  
- **MongoDB**: Set up a local or remote MongoDB database (check MongoDB installation).  
- **FastAPI**: Install FastAPI and dependencies for the backend.  
- **Android Studio/Android SDK/Android Emulator**: If you want to test it on a PC.

## API Endpoints

### Authentication
- POST /user/login: Logs in a user and returns a JWT token.
- POST /user/register: Registers a new user.

### Messaging
- GET /messages: Retrieves a list of messages.
- POST /messages: Sends a new message.

### Friend Requests
- POST /friends/add: Sends a friend request.
- POST /friends/remove: Removes a friend.
- GET /friends/pending: Lists pending friend requests.

## Usage

- **Login**: Enter email and password to log into the app.
- **Messaging**: Once logged in, users can search for contacts and send/receive messages.
- **Friend Requests**: Send friend requests to other users, and accept or reject pending requests.

![image-removebg-preview](https://github.com/user-attachments/assets/4ec816a0-acf0-4a86-a678-cb6bbca5a7bb)

## Additional Notes

I use ngrok myself to host
if you run into any problem email me @ tsuhaohsu@gmail.com

### FastAPI
For FastAPI part there is a requirements.txt in fastapi folder for installing dependency in your virtual environment

### Flutter
All you need to change is uri.template.dart (located in Constant folder),
remove template in filename and edit UriHTTP to your connection of choice (i used ngrok) 
and UriWS to the ip of your fastapi where you host your fastapi.

### MongoDB
Find fastapi/db.template.py, remove template in filename and edit the url to your mongodb url.

## Acknowledgments
Thank you to the Flutter and FastAPI communities for their great frameworks.
Icons and other assets are sourced from FontAwesome and Icons8.
Default profile picture © NIS America, Inc. All Rights Reserved.
- All other trademarks are properties of their respective owners.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
