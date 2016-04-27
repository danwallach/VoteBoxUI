import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;

public class NativeMessenger {


    private static ServerSocket toVotebox;
    private static Socket fromVotebox;
    private static DataInputStream voteboxRequest;
    private static DataOutputStream voteboxUpdate;

    public static void main(String[] args) throws IOException {

        try {

            toVotebox = new ServerSocket(6000);
            fromVotebox = toVotebox.accept();
            voteboxUpdate = new DataOutputStream(fromVotebox.getOutputStream());
            voteboxRequest = new DataInputStream(fromVotebox.getInputStream());

            while(true) {
                String s = readMessage();

                if(s != null) {
                    sendUpdate(s);
                    handleRequests();
                    System.err.println("Sent message " + s);
                }
            }
        }
        catch (Exception e) {
            System.err.println(e.getStackTrace());
            kill();
        }
    }

    public static void handleRequests() {
        try {
            sendMessage(voteboxRequest.readUTF());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void sendUpdate(String update) {
        try {
            voteboxUpdate.writeUTF(update);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static String readMessage() {
        String msg = "";
        try {
            int c, t = 0;
            for (int i = 0; i <= 3; i++) {
                t += Math.pow(256.0f, i) * System.in.read();
            }

            for (int i = 0; i < t; i++) {
                c = System.in.read();
                msg += (char) c;
            }
        } catch (Exception e) {
            System.err.println(e.getStackTrace());
        }
        return msg;
    }

    public static void sendMessage(String msgdata) {
        try {
            int dataLength = msgdata.length();
            System.out.write((byte) (dataLength & 0xFF));
            System.out.write((byte) ((dataLength >> 8) & 0xFF));
            System.out.write((byte) ((dataLength >> 16) & 0xFF));
            System.out.write((byte) ((dataLength >> 24) & 0xFF));

            // Writing the message itself
            System.out.write(msgdata.getBytes());
            System.out.flush();
        } catch (IOException e) {
            System.err.println(e.getStackTrace());
        }
    }

    public static void kill() {
        try {
            toVotebox.close();
            voteboxUpdate.close();
            voteboxRequest.close();
            System.exit(-1);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
