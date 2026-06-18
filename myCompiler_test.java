import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;
import java.io.*;
import java.nio.file.*;

public class myCompiler_test {
    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.err.println("Usage: java myCompiler_test <input.c> [output.ll]");
            System.exit(1);
        }

        // 若有輸出檔案，把 System.out 重定向進去
        // (parser 內部用 System.out.println 輸出整個 IR)
        PrintStream origOut = System.out;
        if (args.length >= 2) {
            PrintStream fileOut = new PrintStream(new FileOutputStream(args[1]));
            System.setOut(fileOut);
        }

        // 1. 從命令列參數取得真實的檔案路徑與名稱
        String fileName = args[0];
        String src = new String(Files.readAllBytes(Paths.get(fileName)));

        // 2. 將動態取得的 fileName 傳給預處理器，讓 __FILE__ 可以正確替換
        src = myCompilerLexer.preprocess(src, fileName);

        // 3. 將預處理完的原始碼餵給 ANTLR 流程
        CharStream input = CharStreams.fromString(src);
        myCompilerLexer lexer = new myCompilerLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        myCompilerParser parser = new myCompilerParser(tokens);

        // 只把語法錯誤印到 stderr
        parser.removeErrorListeners();
        parser.addErrorListener(new BaseErrorListener() {
            @Override
            public void syntaxError(Recognizer<?,?> r, Object sym,
                                    int line, int col, String msg,
                                    RecognitionException e) {
                System.err.println("Syntax error at " + line + ":" + col + " " + msg);
            }
        });

        parser.program();   // 完整 IR 全部透過 System.out 印出

        if (args.length >= 2) {
            System.out.flush();
            System.setOut(origOut);
            System.out.println("Compilation completed. Output written to " + args[1]);
        }
    }
}