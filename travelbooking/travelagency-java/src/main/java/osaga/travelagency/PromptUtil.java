package osaga.travelagency;

import java.io.*;
import java.util.Arrays;

import static java.lang.System.*;

public class PromptUtil {

    static boolean getBoolValueFromPrompt(String variableName, String defaultValue) throws IOException {
        return getValueFromPrompt(variableName, defaultValue).equalsIgnoreCase("y")?true:false;
    }

    static String getValueFromPrompt(String variableName, String defaultValue) throws IOException {
        System.out.print("---> " + variableName+
                (defaultValue==null?"":"(default value is " + defaultValue + ")" )
                + " : ");
//        Scanner scanner = new Scanner (System.in);
//        String variableValue = scanner.next();

        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        String variableValue = br.readLine();
        if(variableValue == null || variableValue.trim().equals("")) {
            if (defaultValue == null ) {
                out.println(variableName + " value is required " );
                return getValueFromPrompt(variableName, defaultValue);
            } else {
                out.println("Using default:" + defaultValue );
                return defaultValue;
            }
        } else {
            return variableValue;
        }
    }

    static String getValueFromPromptSecure(String variableName, String defaultValue) throws IOException {
        char variableNamechar[] = null;
        try {
            variableNamechar = PasswordField.getPassword(in, "---> " + variableName+
                    (defaultValue==null?"":"(default value is " + defaultValue + ")" )
                    + " : ");
        } catch(IOException ioe) {
            ioe.printStackTrace();
        }
        if(variableNamechar == null ) {
            if (defaultValue == null) {
                out.println(variableName + " value is required " );
                return getValueFromPrompt(variableName, defaultValue);
            } else {
                out.println("Using default:" + defaultValue );
                return defaultValue;
            }
        } else {
            return String.valueOf(variableNamechar);
        }
    }

    static class MaskingThread extends Thread {
        private volatile boolean stop;
        private char echochar = '*';

        public MaskingThread(String prompt) {
            out.print(prompt);
        }

        public void run() {

            int priority = Thread.currentThread().getPriority();
            Thread.currentThread().setPriority(Thread.MAX_PRIORITY);

            try {
                stop = true;
                while(stop) {
                    out.print("\010" + echochar);
                    try {
                        // attempt masking at this rate
                        Thread.currentThread().sleep(1);
                    }catch (InterruptedException iex) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                }
            } finally { // restore the original priority
                Thread.currentThread().setPriority(priority);
            }
        }

        public void stopMasking() {
            this.stop = false;
        }
    }


    public static class PasswordField {

        public static final char[] getPassword(InputStream in, String prompt) throws IOException {
            MaskingThread maskingthread = new MaskingThread(prompt);
            Thread thread = new Thread(maskingthread);
            thread.start();

            char[] lineBuffer;
            char[] buf;
            int i;

            buf = lineBuffer = new char[128];

            int room = buf.length;
            int offset = 0;
            int c;

            loop:   while (true) {
                switch (c = in.read()) {
                    case -1:
                    case '\n':
                        break loop;

                    case '\r':
                        int c2 = in.read();
                        if ((c2 != '\n') && (c2 != -1)) {
                            if (!(in instanceof PushbackInputStream)) {
                                in = new PushbackInputStream(in);
                            }
                            ((PushbackInputStream)in).unread(c2);
                        } else {
                            break loop;
                        }

                    default:
                        if (--room < 0) {
                            buf = new char[offset + 128];
                            room = buf.length - offset - 1;
                            arraycopy(lineBuffer, 0, buf, 0, offset);
                            Arrays.fill(lineBuffer, ' ');
                            lineBuffer = buf;
                        }
                        buf[offset++] = (char) c;
                        break;
                }
            }
            maskingthread.stopMasking();
            if (offset == 0) {
                return null;
            }
            char[] ret = new char[offset];
            arraycopy(buf, 0, ret, 0, offset);
            Arrays.fill(buf, ' ');
            return ret;
        }
    }


}
