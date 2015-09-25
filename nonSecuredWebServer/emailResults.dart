import "package:mailer/mailer.dart";
import "dart:io";


main(List<String> arguments) async {

  String fileName = arguments.elementAt(0);

  print("Results saved to $fileName");

  //"./results.txt"; //r'C:\Users\seclab2\Desktop\nonSecuredWebServer\results.txt';

  /* Set up using gmail for this */
  GmailSmtpOptions options = new GmailSmtpOptions()
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
    ..attachments.add(new Attachment(file: new File(fileName)));

  /* Send email */
  transport.send(envelope).then((_) => print('Email sent! Recipients: ${envelope.recipients}')).catchError((e) => print('Error: $e'));

}