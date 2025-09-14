import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main(List<String> arguments) {
  final channel = stdioChannel(input: stdin, output: stdout);
  MyMCPServer mcpServer = MyMCPServer(channel);
}

base class MyMCPServer extends MCPServer
    with ToolsSupport, LoggingSupport, ElicitationRequestSupport {
  MyMCPServer(super.channel)
    : super.fromStreamChannel(
        implementation: Implementation(
          name: 'EmailMCPServer',
          version: '1.0.0',
        ),
        instructions: 'This is an example MCP server to Send Email .',
      ) {
    registerTool(sendEmailTool, sendEmail);
  }

  final sendEmailTool = Tool(
    name: "sendEmail",
    description:
        "Sends an email to the given recipient with subject and content using mailer package.",
    inputSchema: Schema.object(
      properties: {
        "to": Schema.string(description: "Recipient email address."),
        "subject": Schema.string(description: "Subject of the email."),
        "content": Schema.string(description: "Content/body of the email."),
      },
    ),
  );

  FutureOr<CallToolResult> sendEmail(CallToolRequest request) async {
    final to = request.arguments?['to'] as String?;
    final subject = request.arguments?['subject'] as String?;
    final content = request.arguments?['content'] as String?;

    if (to == null || subject == null || content == null) {
      return CallToolResult(
        content: [
          Content.text(
            text: 'Missing required arguments: to, subject, or content',
          ),
        ],
      );
    }

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

    try {
      final sendReport = await send(message, smtpServer);
      return CallToolResult(
        content: [Content.text(text: 'Email sent: ${sendReport.toString()}')],
      );
    } catch (e) {
      return CallToolResult(
        content: [Content.text(text: 'Failed to send email: $e')],
      );
    }
  }
}
