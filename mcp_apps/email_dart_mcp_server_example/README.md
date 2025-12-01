# Email Dart MCP Server Example

A Dart-based example server for handling email operations using MCP (Model Context Protocol).

## Features

- Send emails
- MCP protocol support
- Example server implementation

## Create Test Email
1. I used [Ethereal a fake SMTP service](https://ethereal.email/create) or use can use your own SMTP Email and Password.


## Getting Started

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/email_dart_mcp_server_example.git
   cd email_dart_mcp_server_example
   ```

2. **Install dependencies:**
   ```sh
   dart pub get
   ```

## Configuration

- Configure email settings in the appropriate configuration file or environment variables. Replace values as needed.
```
  final smtpServer = SmtpServer(
      'smtp.ethereal.email',
      username: 'username',
      password: 'password',
      port: 587,
    );

    final message = Message()
      ..from = Address('from-email', 'MCP Server')
      ..recipients.add(to)
      ..subject = subject
      ..text = content;
```


## How to use MCP Server

### Cursor IDE
1. Go to IDE MCP and Integration Settings
2. Add this JSON, change file path acc. to ur system
```
{
  "mcpServers": {
    "Dart MCP Server": {
      "command": "dart",
      "args": [
        "run",
        "C:\\Users\\Navoki\\AndroidStudioProjects\\email_dart_mcp_server_example\\bin\\email_dart_mcp_server_example.dart"
      ]
    }
  }
}


```
3.  Send prompt `Test and send email with dummy content and subject to abc@abc.com`

### MCP Inspector
1. Run this command in Terminal to launch MCP Inspector
   `npx @modelcontextprotocol/inspector`
2. Command: `dart`
3. Arguments: `run "C:\Users\Navoki\AndroidStudioProjects\mcp_flutter_dart_example\mcp_server_dart_example\bin\mcp_server_dart_example.dart"`
4. Click 'Connect'


## Project Structure

- `bin/` - Main entry point for the server
- `lib/` - Core library code


## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License.
