import "package:mailer/mailer.dart";
import "dart:io";


main() async {

  String inputFileName = "./results.txt"; //r'C:\Users\seclab2\Desktop\nonSecuredWebServer\results.txt';

  /* Set up using gmail for this */
  GmailSmtpOptions options = new GmailSmtpOptions()
    ..name = ""
    ..username = 'voteFlippingUI@gmail.com'
    ..password = 'STAR-Vote';

  /* Set up the transport protocol */
  SmtpTransport transport = new SmtpTransport(options);

  /* Create envelope */
  Envelope envelope = new Envelope()
    ..from = 'voteFlippingUI@gmail.com'
    ..fromName = 'VoteFlippingUI'
    ..recipients.add('mpk2@rice.edu')
    ..subject = 'VoteFlipping Study Results'
    ..text = "Here are your results!"
    ..attachments.add(new Attachment(file: new File(inputFileName)));

  /* Send email */
  transport.send(envelope).then((_) => print('Email sent!')).catchError((e) => print('Error: $e'));

}