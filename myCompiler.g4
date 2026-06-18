grammar myCompiler;

// ══════════════════════════════════════════════════════════════════
// @lexer::members：提供靜態預處理器方法 preprocess()
// 支援：#define NAME VALUE（常數巨集）
//       #ifdef / #ifndef / #else / #endif（條件編譯）
//       #undef
//       #include（直接略過，不需要展開）
// 使用方式：在 myCompiler_test.java 裡，餵給 ANTLR 之前先呼叫：
//   source = myCompilerLexer.preprocess(source);
// ══════════════════════════════════════════════════════════════════
@lexer::members {
    // ✨ 新增這行用來記錄 __COUNTER__ 的值
    static int globalCounter = 0;
    // ✨ 建立一個類別來儲存巨集的資訊（區分一般巨集與函式巨集）
    static class MacroDef {
        boolean isFunctionLike;
        boolean isVariadic;   // 是否含 ... 可變參數（__VA_ARGS__）
        java.util.List<String> params;
        String body;
        
        MacroDef(String body) { 
            this.isFunctionLike = false;
            this.isVariadic = false;
            this.body = body; 
        }
        MacroDef(java.util.List<String> params, String body) { 
            this.isFunctionLike = true;
            this.isVariadic = !params.isEmpty() && params.get(params.size()-1).equals("...");
            if (this.isVariadic) params.remove(params.size()-1); // 移除 "..."，保留具名參數
            this.params = params; 
            this.body = body; 
        }
    }

    // ── #if 數值運算式求值 ──
    static boolean evalPPExpr(String expr, java.util.Map<String, MacroDef> macros,
                               java.util.Set<String> defined) {
        expr = expr.trim();
        // defined(X) 或 defined X
        if (expr.startsWith("defined")) {
            String inner = expr.substring(7).trim();
            if (inner.startsWith("(") && inner.endsWith(")"))
                inner = inner.substring(1, inner.length()-1).trim();
            return defined.contains(inner);
        }
        // ! 前綴
        if (expr.startsWith("!") && !expr.startsWith("!="))
            return !evalPPExpr(expr.substring(1).trim(), macros, defined);
        // 巨集值替換
        for (java.util.Map.Entry<String, MacroDef> e : macros.entrySet()) {
            if (e.getValue().params == null && !e.getValue().body.isEmpty()) {
                expr = expr.replaceAll("(?<![A-Za-z0-9_])" + java.util.regex.Pattern.quote(e.getKey())
                                       + "(?![A-Za-z0-9_])", e.getValue().body);
            }
        }
        expr = expr.trim();
        // ||
        int idx = expr.lastIndexOf("||");
        if (idx > 0) return evalPPExpr(expr.substring(0,idx), macros, defined)
                           || evalPPExpr(expr.substring(idx+2), macros, defined);
        // &&
        idx = expr.lastIndexOf("&&");
        if (idx > 0) return evalPPExpr(expr.substring(0,idx), macros, defined)
                           && evalPPExpr(expr.substring(idx+2), macros, defined);
        // 比較運算子（依長度排序避免誤判）
        for (String op : new String[]{"==","!=","<=",">=","<",">"}) {
            idx = expr.indexOf(op);
            if (idx > 0) {
                try {
                    long lv = Long.parseLong(expr.substring(0,idx).trim());
                    long rv = Long.parseLong(expr.substring(idx+op.length()).trim());
                    switch(op) {
                        case "==": return lv == rv; case "!=": return lv != rv;
                        case "<=": return lv <= rv; case ">=": return lv >= rv;
                        case "<":  return lv <  rv; case ">":  return lv >  rv;
                    }
                } catch (NumberFormatException ex) { return false; }
            }
        }
        // 純整數
        try { return Long.parseLong(expr) != 0; } catch (NumberFormatException ex) { return false; }
    }

    public static String preprocess(String source, String fileName) {
        java.util.LinkedHashMap<String, MacroDef> macros = new java.util.LinkedHashMap<>();
        java.util.Set<String> defined = new java.util.LinkedHashSet<>();
        StringBuilder out = new StringBuilder();

         // ✨ 每次編譯新檔案時重置 __COUNTER__
        globalCounter = 0;
        // ✨ 處理 __COUNTER__：逐字元掃描，跳過字串字面值內部
        {
            StringBuilder ctrSb = new StringBuilder();
            boolean inStrLit = false;
            int slen = source.length();
            for (int ci = 0; ci < slen; ci++) {
                char ch = source.charAt(ci);
                if (ch == '"' && (ci == 0 || source.charAt(ci-1) != '\\')) {
                    inStrLit = !inStrLit;
                    ctrSb.append(ch);
                } else if (!inStrLit && source.startsWith("__COUNTER__", ci)
                           && (ci == 0 || !Character.isLetterOrDigit(source.charAt(ci-1)) && source.charAt(ci-1) != '_')
                           && (ci+11 >= slen || (!Character.isLetterOrDigit(source.charAt(ci+11)) && source.charAt(ci+11) != '_'))) {
                    ctrSb.append(globalCounter++);
                    ci += 10; // "__COUNTER__".length()-1
                } else {
                    ctrSb.append(ch);
                }
            }
            source = ctrSb.toString();
        }

        // ── 預定義常用巨集 ──
        macros.put("NULL",       new MacroDef("0"));          defined.add("NULL");
        macros.put("EOF",        new MacroDef("-1"));         defined.add("EOF");
        macros.put("EXIT_SUCCESS", new MacroDef("0"));        defined.add("EXIT_SUCCESS");
        macros.put("EXIT_FAILURE", new MacroDef("1"));        defined.add("EXIT_FAILURE");
        macros.put("RAND_MAX",   new MacroDef("2147483647")); defined.add("RAND_MAX");
        macros.put("INT8_MIN",   new MacroDef("(-128)"));       defined.add("INT8_MIN");
        macros.put("INT8_MAX",   new MacroDef("127"));          defined.add("INT8_MAX");
        macros.put("UINT8_MAX",  new MacroDef("255"));          defined.add("UINT8_MAX");
        macros.put("INT16_MIN",  new MacroDef("(-32768)"));     defined.add("INT16_MIN");
        macros.put("INT16_MAX",  new MacroDef("32767"));        defined.add("INT16_MAX");
        macros.put("UINT16_MAX", new MacroDef("65535"));        defined.add("UINT16_MAX");
        macros.put("INT32_MIN",  new MacroDef("(-2147483648)")); defined.add("INT32_MIN");
        macros.put("INT32_MAX",  new MacroDef("2147483647"));   defined.add("INT32_MAX");
        macros.put("UINT32_MAX", new MacroDef("4294967295u"));  defined.add("UINT32_MAX");
        macros.put("INT64_MAX",  new MacroDef("9223372036854775807LL")); defined.add("INT64_MAX");
        macros.put("SIZE_MAX",   new MacroDef("18446744073709551615u")); defined.add("SIZE_MAX");
        // ── math.h 特殊常數 ──
        macros.put("INFINITY",   new MacroDef("(1.0/0.0)"));   defined.add("INFINITY");
        macros.put("HUGE_VAL",   new MacroDef("(1.0/0.0)"));   defined.add("HUGE_VAL");
        macros.put("HUGE_VALF",  new MacroDef("(1.0f/0.0f)")); defined.add("HUGE_VALF");
        macros.put("NAN",        new MacroDef("(0.0/0.0)"));   defined.add("NAN");
        macros.put("M_PI",       new MacroDef("3.14159265358979323846")); defined.add("M_PI");
        macros.put("M_E",        new MacroDef("2.71828182845904523536")); defined.add("M_E");
        macros.put("M_SQRT2",    new MacroDef("1.41421356237309504880")); defined.add("M_SQRT2");
        macros.put("M_LN2",      new MacroDef("0.69314718055994530942")); defined.add("M_LN2");
        macros.put("M_LOG2E",    new MacroDef("1.44269504088896340736")); defined.add("M_LOG2E");
        macros.put("INT_MAX",    new MacroDef("2147483647"));   defined.add("INT_MAX");
        macros.put("INT_MIN",    new MacroDef("(-2147483648)")); defined.add("INT_MIN");
        macros.put("LONG_MAX",   new MacroDef("9223372036854775807LL")); defined.add("LONG_MAX");
        macros.put("LONG_MIN", new MacroDef("(-9223372036854775808LL)")); defined.add("LONG_MIN");
        macros.put("ULONG_MAX",  new MacroDef("18446744073709551615u")); defined.add("ULONG_MAX");
        macros.put("CHAR_MAX",   new MacroDef("127"));          defined.add("CHAR_MAX");
        macros.put("CHAR_MIN",   new MacroDef("(-128)"));       defined.add("CHAR_MIN");
        macros.put("SEEK_SET",   new MacroDef("0"));            defined.add("SEEK_SET");
        macros.put("SEEK_CUR",   new MacroDef("1"));            defined.add("SEEK_CUR");
        macros.put("SEEK_END",   new MacroDef("2"));            defined.add("SEEK_END");
        macros.put("TRUE",       new MacroDef("1"));            defined.add("TRUE");
        macros.put("FALSE",      new MacroDef("0"));            defined.add("FALSE");
        // ── __DATE__ / __TIME__ ──
        {
            java.time.LocalDateTime now = java.time.LocalDateTime.now();
            String[] months = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
            String dateStr = String.format("%s %2d %d", months[now.getMonthValue()-1], now.getDayOfMonth(), now.getYear());
            String timeStr = String.format("%02d:%02d:%02d", now.getHour(), now.getMinute(), now.getSecond());
            macros.put("__DATE__", new MacroDef("\"" + dateStr + "\"")); defined.add("__DATE__");
            macros.put("__TIME__", new MacroDef("\"" + timeStr + "\"")); defined.add("__TIME__");
        }
        // guard macros so #ifdef __GNUC__ 等不報錯
        defined.add("_STDIO_H"); defined.add("_STDLIB_H"); defined.add("_STDINT_H");
        defined.add("_STRING_H"); defined.add("_MATH_H"); defined.add("_CTYPE_H");
        defined.add("__GNUC__"); defined.add("__linux__"); defined.add("__x86_64__");
        defined.add("__USE_MISC"); defined.add("_GNU_SOURCE"); defined.add("__USE_XOPEN2K8");

        // condStack 每個元素：boolean[3] = {parentActive, currentBranchActive, anyBranchTrueInChain}
        // parentActive       = 父層是否為 active（祖先 if 是否成立）
        // currentBranchActive= 本分支是否 active（輸出內容）
        // anyBranchTrueInChain = 本 if-elif-else 鏈中是否已有任何分支為 true
        java.util.Deque<boolean[]> condStack = new java.util.ArrayDeque<>();
        condStack.push(new boolean[]{true, true, true});

        // ── ✨ 多行巨集支援：將 backslash-newline (\\\n) 接合成單行 ──
        // 規則：行尾的 \ 表示下一行是本行的延續，兩行合併（去掉 \<LF>）
        // 為了保持行號對應正確，把消失的行補一個空行
        {
            StringBuilder joinedSb = new StringBuilder();
            String[] rawLines = source.split("\\n", -1);
            for (int ri = 0; ri < rawLines.length; ri++) {
                String rl = rawLines[ri];
                // ✨ 先 rstrip（去掉行末空白/\r），再判斷是否以 \ 結尾
                // 解決 "define SCALE(x) \ " 行末有空格導致 endsWith("\\") 失敗的問題
                String rlStripped = rl.stripTrailing();
                if (!rlStripped.equals(rl)) rl = rlStripped; // 如果有 trailing space 就用 stripped 版
                // 行尾是 \ 且不在字串字面值中（簡易判斷：雙引號數為偶數）
                while (rl.endsWith("\\")) {
                    String beforeSlash = rl.substring(0, rl.length() - 1);
                    long qc = beforeSlash.chars().filter(c -> c == '"').count();
                    if (qc % 2 != 0) break; // 在字串內的 \ 不處理
                    if (ri + 1 >= rawLines.length) { rl = beforeSlash; break; }
                    ri++;
                    String nextLine = rawLines[ri].stripLeading();
                    rl = beforeSlash + nextLine;
                    joinedSb.append("\n"); // 補空行以保持行號
                    // 下一行接合後仍可能以 \ 結尾，繼續迴圈處理
                    rl = rl.stripTrailing(); // 同樣處理接合後行末空白
                }
                joinedSb.append(rl).append("\n");
            }
            source = joinedSb.toString();
        }

        String[] lines = source.split("\\n", -1);
        // __COUNTER__：用 int[1] 盒子讓匿名內部類可修改
        int[] counterVal = {0};

        java.util.regex.Pattern definePattern = java.util.regex.Pattern.compile(
            "^\\s*#define\\s+([A-Za-z_][A-Za-z0-9_]*)(?:\\(([^)]*)\\))?(?:\\s+(.*))?");

        // ── 追蹤當前函式名稱（供 __func__ 使用）──
        String currentFuncName = "";
        java.util.regex.Pattern funcNamePat = java.util.regex.Pattern.compile(
            "^\\s*(?:(?:static|inline|extern|const)\\s+)*" +
            "(?:void|int|float|double|char|long|short|unsigned|bool|struct\\s+\\w+)" +
            "(?:\\s*\\*+\\s*|\\s+)([A-Za-z_][A-Za-z0-9_]*)\\s*\\(");

        for (int lineNum = 0; lineNum < lines.length; lineNum++) {
            String rawLine = lines[lineNum];
            int lineNumber = lineNum + 1;
            String line = rawLine.trim();
            boolean currentActive = condStack.peek()[0] && condStack.peek()[1];

            // ── 追蹤函式名稱 ──
            if (currentActive) {
                java.util.regex.Matcher fnm = funcNamePat.matcher(rawLine);
                if (fnm.find()) currentFuncName = fnm.group(1);
            }

            if (line.startsWith("#")) {
                if (line.startsWith("#ifdef")) {
                    String mName = line.substring(6).trim();
                    boolean val = currentActive && defined.contains(mName);
                    condStack.push(new boolean[]{currentActive, val, val});
                    out.append("\n"); continue;
                } else if (line.startsWith("#ifndef")) {
                    String mName = line.substring(7).trim();
                    boolean val = currentActive && !defined.contains(mName);
                    condStack.push(new boolean[]{currentActive, val, val});
                    out.append("\n"); continue;
                } else if (line.startsWith("#elif")) {
                    boolean[] top = condStack.pop();
                    boolean parentActive  = top[0];
                    boolean anyTrue       = top[2]; // 鏈中是否已有分支為 true
                    String expr = line.substring(5).trim();
                    boolean thisVal = parentActive && !anyTrue && evalPPExpr(expr, macros, defined);
                    condStack.push(new boolean[]{parentActive, thisVal, anyTrue || thisVal});
                    out.append("\n"); continue;
                } else if (line.startsWith("#if ") || line.equals("#if")) {
                    String expr = line.substring(3).trim();
                    boolean val = currentActive && evalPPExpr(expr, macros, defined);
                    condStack.push(new boolean[]{currentActive, val, val});
                    out.append("\n"); continue;
                } else if (line.startsWith("#else")) {
                    boolean[] top = condStack.pop();
                    boolean parentActive  = top[0];
                    boolean anyTrue       = top[2];
                    // #else 只有 parentActive 且鏈中尚無 true 分支才執行
                    boolean elseVal = parentActive && !anyTrue;
                    condStack.push(new boolean[]{parentActive, elseVal, anyTrue || elseVal});
                    out.append("\n"); continue;
                } else if (line.startsWith("#endif")) {
                    if (condStack.size() > 1) condStack.pop();
                    out.append("\n"); continue;
                }
                if (currentActive) {
                    if (line.startsWith("#define")) {
                        java.util.regex.Matcher m = definePattern.matcher(rawLine);
                        if (m.find()) {
                            String mName = m.group(1);
                            String paramStr = m.group(2);
                            String mVal = (m.group(3) != null) ? m.group(3).trim() : "";
                            // ── 去掉行末 // 注解（但不去掉字串字面值內的）──
                            int cmtIdx = mVal.indexOf("//");
                            if (cmtIdx >= 0) {
                                // 簡單判斷：// 前雙引號數為偶數才算是注解
                                String before = mVal.substring(0, cmtIdx);
                                long quoteCount = before.chars().filter(ch -> ch == '"').count();
                                if (quoteCount % 2 == 0) mVal = before.trim();
                            }
                            if (paramStr != null) {
                                java.util.List<String> params = new java.util.ArrayList<>();
                                for (String p : paramStr.split(",")) params.add(p.trim());
                                macros.put(mName, new MacroDef(params, mVal));
                            } else {
                                macros.put(mName, new MacroDef(mVal));
                            }
                            defined.add(mName);
                        }
                        out.append("\n"); continue;
                    } else if (line.startsWith("#undef")) {
                        String mName = line.substring(6).trim();
                        macros.remove(mName); defined.remove(mName);
                        out.append("\n"); continue;
                    } else if (line.startsWith("#include")) {
                        // ✨ #include "file.h"：展開使用者自訂 header
                        // #include <lib.h>：系統標頭，靜默略過（已用 guard macros 處理）
                        java.util.regex.Matcher inclM = java.util.regex.Pattern
                            .compile("^#include\\s+\"([^\"]+)\"").matcher(line);
                        if (inclM.find()) {
                            String inclFile = inclM.group(1);
                            // 從 fileName 推出 header 的搜尋目錄
                            java.io.File srcFile = new java.io.File(fileName);
                            java.io.File inclPath = new java.io.File(srcFile.getParent(), inclFile);
                            // 若找不到，也嘗試當前工作目錄
                            if (!inclPath.exists()) inclPath = new java.io.File(inclFile);
                            if (inclPath.exists()) {
                                try {
                                    String inclSrc = new String(java.nio.file.Files.readAllBytes(inclPath.toPath()), "UTF-8");
                                    // 遞迴 preprocess header（傳入 header 自己的路徑）
                                    // 簡化：直接展開（不遞迴呼叫以避免巨集表複雜度，共享當前 macros/defined）
                                    // 把 header 內容插入 source，讓後續行迴圈處理
                                    // 最簡單且正確的做法：把 header 的行插入 lines 陣列
                                    String[] inclLines = inclSrc.split("\n", -1);
                                    java.util.List<String> linesList = new java.util.ArrayList<>(java.util.Arrays.asList(lines));
                                    linesList.addAll(lineNum + 1, java.util.Arrays.asList(inclLines));
                                    lines = linesList.toArray(new String[0]);
                                    out.append("\n"); continue;
                                } catch (Exception inclEx) {
                                    System.err.println("Warning: Cannot read include file: " + inclPath);
                                }
                            } else {
                                System.err.println("Warning: Include file not found: " + inclFile);
                            }
                        }
                        out.append("\n"); continue;
                    } else if (line.startsWith("#pragma")) {
                        // #pragma 靜默忽略（含 #pragma once / #pragma GCC ...）
                        out.append("\n"); continue;
                    } else if (line.startsWith("#error")) {
                        String msg = line.substring(6).trim().replaceAll("^\"(.*)\"$", "$1");
                        System.err.println("Error! (preprocessor) #error: " + msg);
                        out.append("\n"); continue;
                    } else if (line.startsWith("#warning")) {
                        String msg = line.substring(8).trim().replaceAll("^\"(.*)\"$", "$1");
                        System.err.println("Warning: #warning: " + msg);
                        out.append("\n"); continue;
                    } else if (line.startsWith("#line")) {
                        // #line N / #line N "file" — 靜默忽略
                        out.append("\n"); continue;
                    }
                }
            }

            if (currentActive) {
                // ── Step A：先替換 __LINE__ / __FILE__ / __func__（引號外），再做常數巨集 ──
                String tempLine = rawLine.replace("\\\"", "\0");
                String[] parts = tempLine.split("\"", -1);
                StringBuilder afterBuiltinSB = new StringBuilder();
                for (int pIdx = 0; pIdx < parts.length; pIdx++) {
                    String pStr = parts[pIdx];
                    if (pIdx % 2 == 0) {
                        pStr = pStr.replaceAll("(?<![A-Za-z0-9_])__LINE__(?![A-Za-z0-9_])",
                                               String.valueOf(lineNumber));
                        pStr = pStr.replaceAll("(?<![A-Za-z0-9_])__FILE__(?![A-Za-z0-9_])",
                                             java.util.regex.Matcher.quoteReplacement("\"" + fileName + "\""));
                        pStr = pStr.replaceAll("(?<![A-Za-z0-9_])__func__(?![A-Za-z0-9_])",
                                               "\"" + currentFuncName + "\"");
                        pStr = pStr.replaceAll("(?<![A-Za-z0-9_])__FUNCTION__(?![A-Za-z0-9_])",
                                               "\"" + currentFuncName + "\"");
                        // __COUNTER__：每次使用遞增（用陣列盒子跨 lambda 共享）
                        while (pStr.matches(".*(?<![A-Za-z0-9_])__COUNTER__(?![A-Za-z0-9_]).*")) {
                            pStr = pStr.replaceFirst("(?<![A-Za-z0-9_])__COUNTER__(?![A-Za-z0-9_])",
                                                     String.valueOf(counterVal[0]++));
                        }
                        // __builtin_expect(expr, val) → (expr)  分支預測提示，靜默展開為第一引數
                        pStr = pStr.replaceAll("__builtin_expect\\s*\\(([^,]+),\\s*[^)]+\\)", "($1)");
                        // __builtin_unreachable() → 靜默忽略
                        pStr = pStr.replaceAll("__builtin_unreachable\\s*\\(\\s*\\)", "(void)0");
                        // __builtin_constant_p(x) → 0  (不做常數偵測)
                        pStr = pStr.replaceAll("__builtin_constant_p\\s*\\([^)]*\\)", "0");
                        // __extension__ 關鍵字靜默
                        pStr = pStr.replaceAll("(?<![A-Za-z0-9_])__extension__(?![A-Za-z0-9_])", "");
                        // ✨ __attribute__((...)) 靜默忽略（支援任意嵌套括號）
                        // 先處理雙層括號 __attribute__((xxx)) 或 __attribute__((xxx, yyy))
                        pStr = pStr.replaceAll("__attribute__\\s*\\(\\s*\\([^)]*\\)\\s*\\)", "");
                        // 常數巨集（非函式型）也在引號外替換
                        for (java.util.Map.Entry<String, MacroDef> entry : macros.entrySet()) {
                            if (!entry.getValue().isFunctionLike) {
                                pStr = pStr.replaceAll(
                                    "(?<![A-Za-z0-9_])" + java.util.regex.Pattern.quote(entry.getKey()) + "(?![A-Za-z0-9_])",
                                    java.util.regex.Matcher.quoteReplacement(entry.getValue().body));
                            }
                        }
                    }
                    afterBuiltinSB.append(pStr);
                    if (pIdx < parts.length - 1) afterBuiltinSB.append("\"");
                }
                String afterBuiltin = afterBuiltinSB.toString().replace("\0", "\\\"");

                // ── Step B：用平衡括號法展開函式型巨集（可跨引號邊界）──
                String expandedLine = afterBuiltin;
                boolean anyExpanded = true;
                int expandPass = 0;
                while (anyExpanded && expandPass++ < 20) {
                    anyExpanded = false;
                    for (java.util.Map.Entry<String, MacroDef> entry : macros.entrySet()) {
                        if (!entry.getValue().isFunctionLike) continue;
                        String mName = entry.getKey();
                        MacroDef mDef = entry.getValue();
                        java.util.regex.Pattern startPat = java.util.regex.Pattern.compile(
                            "(?<![A-Za-z0-9_])" + java.util.regex.Pattern.quote(mName) + "\\s*\\(");
                        java.util.regex.Matcher startM = startPat.matcher(expandedLine);
                        int searchFrom = 0;
                        StringBuilder resultSB = new StringBuilder();
                        boolean foundAny = false;
                        while (startM.find(searchFrom)) {
                            int macroStart = startM.start();
                            int parenOpen  = startM.end() - 1;

                            // ── 檢查 macroStart 是否在字串字面值內部（引號計數）──
                            String beforeMacro = expandedLine.substring(0, macroStart).replace("\\\"", "\0");
                            long quotesBefore = beforeMacro.chars().filter(c -> c == '"').count();
                            if (quotesBefore % 2 != 0) {
                                // ✨ 在字串字面值內：把從 searchFrom 到（含）macroStart 的字元 append 到 resultSB，
                                //    然後從 macroStart+1 繼續搜尋，防止漏掉字串內容
                                resultSB.append(expandedLine, searchFrom, macroStart + 1);
                                searchFrom = macroStart + 1;
                                foundAny = true; // 讓最後的 append tail 生效
                                continue;
                            }

                            // 平衡括號搜尋（跳過字串內容）
                            int depth = 1, i = parenOpen + 1;
                            boolean inStr = false;
                            while (i < expandedLine.length() && depth > 0) {
                                char ch = expandedLine.charAt(i);
                                if (ch == '"' && (i == 0 || expandedLine.charAt(i-1) != '\\')) inStr = !inStr;
                                if (!inStr) {
                                    if (ch == '(') depth++;
                                    else if (ch == ')') depth--;
                                }
                                i++;
                            }
                            if (depth != 0) { searchFrom = startM.end(); continue; }
                            int macroEnd = i;
                            String argsStr = expandedLine.substring(parenOpen + 1, macroEnd - 1);
                            // 用平衡括號分割引數（正確處理巢狀括號和字串）
                            java.util.List<String> argList = new java.util.ArrayList<>();
                            int ad = 0; boolean aInStr = false; int argStart = 0;
                            for (int j = 0; j < argsStr.length(); j++) {
                                char ch = argsStr.charAt(j);
                                if (ch == '"' && (j == 0 || argsStr.charAt(j-1) != '\\')) aInStr = !aInStr;
                                if (!aInStr) {
                                    if (ch == '(') ad++;
                                    else if (ch == ')') ad--;
                                    else if (ch == ',' && ad == 0) {
                                        argList.add(argsStr.substring(argStart, j).trim());
                                        argStart = j + 1;
                                    }
                                }
                            }
                            argList.add(argsStr.substring(argStart).trim());
                            if (argList.size() == 1 && argList.get(0).isEmpty() && mDef.params.isEmpty()) argList.clear();
                            // ── 替換參數（支援 # 字串化 和 ## 連接）──
                            String replacedBody = mDef.body;
                            
                            // 👇 ✨ 新增：處理可變參數 __VA_ARGS__ 與逗號吞噬 ✨ 👇
                            if (mDef.isVariadic) {
                                String vaArgs = "";
                                // 將超出固定參數數量的引數全部串接起來
                                if (argList.size() > mDef.params.size()) {
                                    StringBuilder vaSb = new StringBuilder();
                                    for (int k = mDef.params.size(); k < argList.size(); k++) {
                                        if (k > mDef.params.size()) vaSb.append(", ");
                                        vaSb.append(argList.get(k));
                                    }
                                    vaArgs = vaSb.toString();
                                }

                                if (vaArgs.trim().isEmpty()) {
                                    // 關鍵：若沒有傳入可變參數，連同前面的逗號一起消除 (處理 , ##__VA_ARGS__)
                                    replacedBody = replacedBody.replaceAll(",\\s*##\\s*__VA_ARGS__\\b", "");
                                    replacedBody = replacedBody.replaceAll("\\b__VA_ARGS__\\b", "");
                                } else {
                                    // 若有可變參數，正常替換
                                    replacedBody = replacedBody.replaceAll("##\\s*__VA_ARGS__\\b", java.util.regex.Matcher.quoteReplacement(vaArgs));
                                    replacedBody = replacedBody.replaceAll("\\b__VA_ARGS__\\b", java.util.regex.Matcher.quoteReplacement(vaArgs));
                                }
                            }
                            // 👆 ✨ __VA_ARGS__ 處理結束 ✨ 👆

                            // Step 1：先處理 ## token 連接（在參數替換前）
                            for (int k = 0; k < mDef.params.size() && k < argList.size(); k++) {
                                String param = java.util.regex.Pattern.quote(mDef.params.get(k));
                                String arg   = java.util.regex.Matcher.quoteReplacement(argList.get(k));
                                // For ## param or param ##, replace only the operand first and keep ##.
                                // This keeps a##b from becoming my_b before b can be replaced.
                                replacedBody = replacedBody.replaceAll(
                                    "(##\\s*)" + param + "(?![A-Za-z0-9_])", "$1" + arg);
                                replacedBody = replacedBody.replaceAll(
                                    "(?<![A-Za-z0-9_])" + param + "(?![A-Za-z0-9_])(\\s*##)", arg + "$1");
                            }
                            // 剩餘的 ## 直接連接（無參數的情況）
                            replacedBody = replacedBody.replaceAll("\\s*##\\s*", "");

                            // Step 2：# 字串化（#param → "arg"）
                            for (int k = 0; k < mDef.params.size() && k < argList.size(); k++) {
                                String param = java.util.regex.Pattern.quote(mDef.params.get(k));
                                String arg   = argList.get(k);
                                // # 前綴：把參數值包成字串字面值
                                String escaped = arg.replace("\\", "\\\\").replace("\"", "\\\"");
                                replacedBody = replacedBody.replaceAll(
                                    "#\\s*" + param + "(?![A-Za-z0-9_])",
                                    java.util.regex.Matcher.quoteReplacement("\"" + escaped + "\""));
                            }

                            // Step 3：普通參數替換
                            for (int k = 0; k < mDef.params.size() && k < argList.size(); k++) {
                                replacedBody = replacedBody.replaceAll(
                                    "(?<![A-Za-z0-9_])" + java.util.regex.Pattern.quote(mDef.params.get(k)) + "(?![A-Za-z0-9_])",
                                    java.util.regex.Matcher.quoteReplacement(argList.get(k)));
                            }
                            // Step 4：__VA_ARGS__ 展開（把具名參數之後的所有引數合併）
                            if (mDef.isVariadic) {
                                int namedCount = mDef.params.size();
                                StringBuilder vaArgs = new StringBuilder();
                                for (int k = namedCount; k < argList.size(); k++) {
                                    if (k > namedCount) vaArgs.append(", ");
                                    vaArgs.append(argList.get(k));
                                }
                                String vaStr = java.util.regex.Matcher.quoteReplacement(vaArgs.toString());
                                // ##__VA_ARGS__：若 vaArgs 為空則也吃掉前面的逗號
                                if (vaArgs.length() == 0) {
                                    replacedBody = replacedBody.replaceAll(",\\s*##\\s*__VA_ARGS__", "");
                                    replacedBody = replacedBody.replaceAll("##\\s*__VA_ARGS__", "");
                                } else {
                                    replacedBody = replacedBody.replaceAll("##\\s*__VA_ARGS__", vaStr);
                                }
                                replacedBody = replacedBody.replaceAll("__VA_ARGS__", vaStr);
                            }
                            resultSB.append(expandedLine, searchFrom, macroStart);
                            resultSB.append(replacedBody);
                            searchFrom = macroEnd;
                            foundAny = true;
                            anyExpanded = true;
                        }
                        if (foundAny) {
                            resultSB.append(expandedLine.substring(searchFrom));
                            expandedLine = resultSB.toString();
                        }
                    }
                }
                // ── Step C：函式型巨集展開後，再做一次 __func__/__LINE__ 替換 ──
                // 因為 LOG(msg) 展開後本體裡才出現 __func__/__LINE__
                if (expandedLine.contains("__func__") || expandedLine.contains("__FUNCTION__")
                        || expandedLine.contains("__LINE__") || expandedLine.contains("__FILE__")) {
                    String[] parts2 = expandedLine.replace("\\\"", "\0").split("\"", -1);
                    StringBuilder sb2 = new StringBuilder();
                    for (int pi = 0; pi < parts2.length; pi++) {
                        String ps = parts2[pi];
                        if (pi % 2 == 0) {
                            ps = ps.replaceAll("(?<![A-Za-z0-9_])__LINE__(?![A-Za-z0-9_])", String.valueOf(lineNumber));
                            ps = ps.replaceAll("(?<![A-Za-z0-9_])__FILE__(?![A-Za-z0-9_])", 
                                                java.util.regex.Matcher.quoteReplacement("\"" + fileName + "\""));
                            ps = ps.replaceAll("(?<![A-Za-z0-9_])__func__(?![A-Za-z0-9_])", "\"" + currentFuncName + "\"");
                            ps = ps.replaceAll("(?<![A-Za-z0-9_])__FUNCTION__(?![A-Za-z0-9_])", "\"" + currentFuncName + "\"");
                        }
                        sb2.append(ps);
                        if (pi < parts2.length - 1) sb2.append("\"");
                    }
                    expandedLine = sb2.toString().replace("\0", "\\\"");
                }
                out.append(expandedLine).append("\n");
            } else {
                out.append("\n");
            }
        }
         // ✨ 後處理：合併相鄰字串字面值（"a" "b" → "ab"），避免 ANTLR 解析 " 問題
        String processed = out.toString();
        {
            char Q = '"';  // 用變數避免 ANTLR 誤判字串邊界
            // 模式：Q 非Q非換行或跳脫序列 Q 空白 Q 非Q非換行或跳脫序列 Q
            String adjPat = Q + "((?:[^\\\\" + Q + "\\n]|\\\\.)*)" + Q + "\\s+" + Q + "((?:[^\\\\" + Q + "\\n]|\\\\.)*)" + Q;
            java.util.regex.Pattern adjStrPat = java.util.regex.Pattern.compile(adjPat);
            java.util.regex.Matcher adjM;
            int maxIter = 20;
            while (maxIter-- > 0) {
                adjM = adjStrPat.matcher(processed);
                StringBuffer adjSb = new StringBuffer();
                boolean found = false;
                while (adjM.find()) {
                    adjM.appendReplacement(adjSb,
                        java.util.regex.Matcher.quoteReplacement(Q + adjM.group(1) + adjM.group(2) + Q));
                    found = true;
                }
                adjM.appendTail(adjSb);
                if (!found) break;
                processed = adjSb.toString();
            }
        }
        return processed;
    }
}

@header {
    import java.util.HashMap;
    import java.util.List;
    import java.util.ArrayList;
    import java.util.LinkedHashMap;
}

// 將 @members 改成 @parser::members 解決衝突
@parser::members {
    enum TypeInfo { Int, Float, Double, Char, Void, Struct, Boolean, Error, Pointer,
                    Long,          // i64  signed long / long long
                    Short,         // i16  signed short
                    UnsignedInt,   // i32  unsigned int / unsigned
                    UnsignedLong,  // i64  unsigned long / unsigned long long
                    UnsignedShort, // i16  unsigned short
                    UnsignedChar   // i8   unsigned char
    }

    class Info {
        TypeInfo theType;   
        int  varIndex;      
        int  iValue;        
        double fValue;      
        String  tmp;        
        boolean isConstant; 
        String structName;
        int arraySize = -1;
        int arrayDim2 = -1;
        int arrayDim3 = -1;  // ✨ 3D 陣列第三維度（-1 = 非三維）
        int scopeLevel = 0; // 記錄這個變數是在哪一層宣告的
        
        // ── 指標相關（升級為多層指標架構） ──
        boolean isPointer = false;   // 舊欄位保留：只要 ptrDepth > 0 這裡就設為 true，確保既有代碼不崩潰
        TypeInfo pointeeType = null; // ✨ 核心語意轉變：在此架構下，此欄位將永久代表「最底層的核心基礎型別」（例如：int** 的最底層是 Int）
        int ptrDepth = 0;            // ✨ 新增指標深度：0 = 非指標純量, 1 = 一級指標 (*), 2 = 雙層指標 (**)
        TypeInfo baseType = null;    // ✨ 就是這裡！編譯器找不到的 baseType！
         boolean isUnsigned = false; 
    }

    // ✨ Designated initializer 輔助類別
    // 每個 initializer list 中的元素，可選地帶有 .field 或 [idx] designator
    static class DesignElem {
        Info val;
        String fieldName;  // ".x" → "x"，無 designator 則 null
        int    arrayIdx;   // "[2]" → 2，無 designator 則 -1
        int    rangeEnd;   // "[lo ... hi]" → hi，非範圍則 -1（GNU 擴充）
        DesignElem(Info v) { this.val = v; this.fieldName = null; this.arrayIdx = -1; this.rangeEnd = -1; }
        DesignElem(Info v, String f) { this.val = v; this.fieldName = f; this.arrayIdx = -1; this.rangeEnd = -1; }
        DesignElem(Info v, int i)    { this.val = v; this.fieldName = null; this.arrayIdx = i; this.rangeEnd = -1; }
        DesignElem(Info v, int lo, int hi) { this.val = v; this.fieldName = null; this.arrayIdx = lo; this.rangeEnd = hi; }
    }

    // 2. 新增多層指標 LLVM 型別產生器
    String toLLVMPtrType(TypeInfo baseType, int depth) {
        String base = toLLVMType(baseType);
        for (int i = 0; i < depth; i++) {
            base += "*";
        }
        return base;
    }

    class StructDef {
        String name;
        boolean isUnion = false;
        List<TypeInfo> fTypes = new ArrayList<>();
        List<String> fNames = new ArrayList<>();
        // ✨ 新增這兩行：為了完整支援結構體內的「指標」與「嵌套結構體」
        List<TypeInfo> fPointeeTypes = new ArrayList<>();
        List<String> fStructNames = new ArrayList<>();
        // ✨ bit-field：每個欄位的位元寬度（-1 表示非 bit-field）
        List<Integer> bitWidths = new ArrayList<>();
        boolean hasBitFields = false; // 是否含有 bit-field 欄位
        // ✨ 匿名 struct/union：記錄每個欄位若來自匿名嵌套 struct/union，
        //    其對應的匿名 struct name（非匿名欄位為 null）
        List<String> anonParentStructName = new ArrayList<>();
        // ── ✨ Flexible Array Member（C99 FAM）──
        boolean hasFAM = false;
        TypeInfo famElemType = null;
        String famElemStructName = null;
    }

    // ✨ 匿名成員查詢（遞迴多層版本）：
    //    在 outerStruct 中尋找欄位 fieldName。
    //    回傳 int[] path，其中：
    //      path[0]          = 外層欄位索引（直接命中 or 匿名 sub-struct 的欄位索引）
    //      path[1]          = 匿名 sub-struct 中的欄位索引（-1 = 直接在外層）
    //      path[2], path[3] = 第三、四層（-1 = 不存在）… 最多支援 4 層
    //    找不到回傳 null。
    int[] resolveAnonField(StructDef outer, String fieldName) {
        return resolveAnonFieldRec(outer, fieldName, new int[0], 0);
    }
    int[] resolveAnonFieldRec(StructDef outer, String fieldName, int[] prefix, int depth) {
        if (outer == null || depth > 4) return null;
        for (int i = 0; i < outer.fNames.size(); i++) {
            String fn = outer.fNames.get(i);
            // 直接命中
            if (fn.equals(fieldName)) {
                // 回傳 prefix + [i, -1]
                int[] res = new int[prefix.length + 2];
                System.arraycopy(prefix, 0, res, 0, prefix.length);
                res[prefix.length]     = i;
                res[prefix.length + 1] = -1;
                return res;
            }
            // 匿名嵌套 struct/union
            String anonSN = (outer.anonParentStructName != null && i < outer.anonParentStructName.size())
                            ? outer.anonParentStructName.get(i) : null;
            if (anonSN != null && outer.fTypes.get(i) == TypeInfo.Struct) {
                StructDef inner = structRegistry.get(anonSN);
                if (inner != null) {
                    // 先試直接命中 inner
                    for (int j = 0; j < inner.fNames.size(); j++) {
                        if (inner.fNames.get(j).equals(fieldName)) {
                            int[] res = new int[prefix.length + 2];
                            System.arraycopy(prefix, 0, res, 0, prefix.length);
                            res[prefix.length]     = i;
                            res[prefix.length + 1] = j;
                            return res;
                        }
                    }
                    // 再遞迴進入 inner 的匿名子成員
                    int[] newPrefix = new int[prefix.length + 1];
                    System.arraycopy(prefix, 0, newPrefix, 0, prefix.length);
                    newPrefix[prefix.length] = i;
                    int[] deeper = resolveAnonFieldRec(inner, fieldName, newPrefix, depth + 1);
                    if (deeper != null) return deeper;
                }
            }
        }
        return null;
    }
    
    int staticLocalCounter = 0; // ✨ static 局部變數全域 uid 計數器
    HashMap<String, StructDef> structRegistry = new HashMap<>();
    HashMap<String, Info> symtab = new HashMap<>();
    HashMap<String, Info> globalSymtab = new HashMap<>();
    HashMap<String, List<TypeInfo>> funcRegistry = new HashMap<>();
    HashMap<String, Boolean> funcIsVariadic = new HashMap<>(); // ✨ variadic 使用者函式
    // ── 記錄函式每個 Pointer 參數的 pointeeType：fname → List<TypeInfo or null> ──
    HashMap<String, List<TypeInfo>> funcPointerRegistry = new HashMap<>();
    HashMap<String, List<String>> funcPointerStructRegistry = new HashMap<>();
    HashMap<String, TypeInfo> funcRetPointeeRegistry = new HashMap<>();

    // ── 函式回傳 struct 型別登記表：funcName → structName ──
    HashMap<String, String> funcStructRetRegistry = new HashMap<>();
    // ── declaratorList 需要知道目前正在宣告的型別，讓它能在 parse init 前做 alloca ──
    TypeInfo pendingDeclType = TypeInfo.Error;
    String   pendingDeclStructName = null;
    // ── enum：name → integer value ──
    HashMap<String, Integer> enumConstants = new HashMap<>();
    // ── const int 的編譯期數值（供 int arr[MAX] 使用）──
    HashMap<String, Integer> constIntValues = new HashMap<>();
    // ── typedef：alias → TypeInfo ──
    HashMap<String, TypeInfo> typedefMap = new HashMap<>();
    // ── typedef struct：alias → struct name ──
    HashMap<String, String> typedefStructMap = new HashMap<>();
    // ── typedef function pointer：alias → LLVM function-pointer type string ──
    // e.g. "Cmp" → "i32 (i32, i32)*"
    HashMap<String, String> funcPtrTypedefMap = new HashMap<>();
    // 追蹤已定義（有 body）的函式，防止重複定義
    java.util.HashSet<String> definedFuncs = new java.util.HashSet<>();
    
    List<List<String>> TextCodeBuffers = new ArrayList<>();
    List<String> currentTextCodeBuffer; 
    
    int tmpCnt = 0;   
    int labelCnt = 0; 
    int strCnt = 0; 
    int loopDepth = 0; // 記錄目前的迴圈深度
    int switchDepth = 0; // ✨ 新增：記錄目前的 switch 深度
    int currentScopeLevel = 0; // 記錄當前的大括號深度

    // ── goto 支援 ──
    // key: 使用者標號名稱 (e.g. "done"), value: 對應的 LLVM label 名稱 (e.g. "Luser_done0")
    HashMap<String, String> gotoTable = new HashMap<>();
    // forward-reference patch list: [userName, placeholderLabel, lineNumber]
    java.util.List<String[]> forwardGotoPatches = new java.util.ArrayList<>();

    List<String> stringDefs = new ArrayList<>(); 
    HashMap<String, String> stringLiterals = new HashMap<>();
    // ── 記錄每個全域字串常數的 byte 長度（含 null），供 GEP 查表 ──
    HashMap<String, Integer> strLengths = new HashMap<>(); 
    
    boolean inGlobalScope = true;
    boolean lastInstrIsTerminator = false;
    String currentSwitchTmp = null;
    boolean skipNextScopeRestore = false; // functionDefinition 用，避免雙重 scope 還原

    // ── TCO（尾呼叫優化）支援：ArrayDeque 禁止 null，使用哨兵 "" ──
    static final String TCO_LABEL_NONE = "";
    java.util.Deque<String>       currentFuncNameStack  = new java.util.ArrayDeque<>();
    java.util.Deque<List<String>> currentFuncParamSlots = new java.util.ArrayDeque<>();
    java.util.Deque<List<String>> currentFuncParamTypes = new java.util.ArrayDeque<>();
    java.util.Deque<List<String>> currentFuncParamNames = new java.util.ArrayDeque<>();
    java.util.Deque<String>       tcoLoopLabelStack     = new java.util.ArrayDeque<>();
    String getCurrentFuncName() {
        return currentFuncNameStack.isEmpty() ? "" : currentFuncNameStack.peek();
    }
    String getOrCreateTcoLoopLabel() {
        if (tcoLoopLabelStack.isEmpty()) return "";
        String lbl = tcoLoopLabelStack.peek();
        if (TCO_LABEL_NONE.equals(lbl)) {
            tcoLoopLabelStack.pop();
            lbl = newLabel("Ltco_loop");
            tcoLoopLabelStack.push(lbl);
        }
        return lbl;
    }
    // ── 多檔案連結：已 emit 的 extern declare（避免重複）──
    java.util.Set<String> emittedExternDecls = new java.util.HashSet<>();
    // ── 多檔案連結：暫存 prototype 的 declare 字串，EOF 時再決定是否輸出 ──
    java.util.Map<String, String> pendingDeclares = new java.util.LinkedHashMap<>();

    // 使用 Stack 記錄每層函式的回傳型別，避免巢狀函式污染
    List<TypeInfo> returnTypeStack = new ArrayList<>();
    TypeInfo getCurrentReturnType() {
        return returnTypeStack.isEmpty() ? TypeInfo.Void : returnTypeStack.get(returnTypeStack.size() - 1);
    }
    // ── 平行 Stack：記錄每層函式回傳 struct 的名稱（非 struct 時為 null）──
    List<String> returnStructNameStack = new ArrayList<>();
    String getCurrentReturnStructName() {
        return returnStructNameStack.isEmpty() ? null : returnStructNameStack.get(returnStructNameStack.size() - 1);
    }
    // ── 記錄哪些 %tN 是 i8*（char 陣列 GEP 結果），供 printfStatement 判斷 ──
    java.util.HashSet<String> charPtrTemps = new java.util.HashSet<>();
    // 專門記錄每一個大括號裡面「真的宣告了哪些變數」
    java.util.Stack<java.util.HashSet<String>> scopeTracker = new java.util.Stack<>();
    // ── 最近一次 &x 取址的 pointeeType 和 tmp，供 callArg 建立完整的 Info ──
    TypeInfo lastAddrOfPointee = null;
    String   lastAddrOfTmp     = null;

    public void init() {
        symtab.clear();
        funcRegistry.clear();
        funcPointerRegistry.clear();
        funcPointerStructRegistry.clear();
        globalSymtab.clear();
        structRegistry.clear();
        enumConstants.clear();
        typedefMap.clear();
        // 👇 ✨ 新增：預先註冊 stdint.h 與 size_t 的內建型別 ✨ 👇
        typedefMap.put("int8_t", TypeInfo.Char);
        typedefMap.put("uint8_t", TypeInfo.UnsignedChar);
        typedefMap.put("int16_t", TypeInfo.Short);
        typedefMap.put("uint16_t", TypeInfo.UnsignedShort);
        typedefMap.put("int32_t", TypeInfo.Int);
        typedefMap.put("uint32_t", TypeInfo.UnsignedInt);
        typedefMap.put("int64_t", TypeInfo.Long);
        typedefMap.put("uint64_t", TypeInfo.UnsignedLong);
        typedefMap.put("size_t", TypeInfo.UnsignedLong);
        typedefMap.put("time_t", TypeInfo.Long);
        typedefMap.put("clock_t", TypeInfo.Long);
        typedefMap.put("ptrdiff_t", TypeInfo.Long);
        typedefMap.put("ssize_t", TypeInfo.Long);
        typedefMap.put("off_t", TypeInfo.Long);
        typedefMap.put("FILE", TypeInfo.Void);
        // ── 預先宣告 stdout / stdin / stderr（FILE* 全域變數） ──
        {
            Info stdoutInfo = new Info();
            stdoutInfo.theType = TypeInfo.Pointer;
            stdoutInfo.baseType = TypeInfo.Void;
            stdoutInfo.isPointer = true;
            stdoutInfo.ptrDepth = 1;
            stdoutInfo.tmp = "@stdout";
            globalSymtab.put("stdout", stdoutInfo);
            Info stdinInfo = new Info();
            stdinInfo.theType = TypeInfo.Pointer;
            stdinInfo.baseType = TypeInfo.Void;
            stdinInfo.isPointer = true;
            stdinInfo.ptrDepth = 1;
            stdinInfo.tmp = "@stdin";
            globalSymtab.put("stdin", stdinInfo);
            Info stderrInfo = new Info();
            stderrInfo.theType = TypeInfo.Pointer;
            stderrInfo.baseType = TypeInfo.Void;
            stderrInfo.isPointer = true;
            stderrInfo.ptrDepth = 1;
            stderrInfo.tmp = "@stderr";
            globalSymtab.put("stderr", stderrInfo);
        }
        // ── 預先登記 struct tm（time.h）讓 localtime/gmtime 回傳值能用 -> 存取 ──
        {
            StructDef tmDef = new StructDef();
            tmDef.name = "tm";
            // C 標準 struct tm 欄位順序（全部 int）
            String[] tmFields = {"tm_sec","tm_min","tm_hour","tm_mday","tm_mon",
                                 "tm_year","tm_wday","tm_yday","tm_isdst"};
            for (String f : tmFields) {
                tmDef.fNames.add(f);
                tmDef.fTypes.add(TypeInfo.Int);
                tmDef.fPointeeTypes.add(null);
                tmDef.fStructNames.add(null);
            }
            structRegistry.put("tm", tmDef);
            typedefMap.put("struct tm", TypeInfo.Struct);
            typedefStructMap.put("struct tm", "tm");
        }
        typedefStructMap.clear();
        // ── jmp_buf：登記為 struct __jmp_buf（[8 x i64]），在 clear 之後加入才不被清掉 ──
        typedefMap.put("jmp_buf", TypeInfo.Struct);
        typedefStructMap.put("jmp_buf", "__jmp_buf");
        {
            StructDef jmpDef = new StructDef();
            jmpDef.name = "__jmp_buf";
            // 用 8 個 i64 欄位模擬 [8 x i64]
            for (int ji = 0; ji < 8; ji++) {
                jmpDef.fNames.add("_j" + ji);
                jmpDef.fTypes.add(TypeInfo.Long);
                jmpDef.fPointeeTypes.add(null);
                jmpDef.fStructNames.add(null);
                jmpDef.bitWidths.add(-1);
                jmpDef.anonParentStructName.add(null);
            }
            structRegistry.put("__jmp_buf", jmpDef);
        }
        definedFuncs.clear();
        inGlobalScope = true;
        lastInstrIsTerminator = false;
        currentSwitchTmp = null;
        skipNextScopeRestore = false;
        terminatorStack.clear();
        loopLabelStack.clear();
        returnTypeStack.clear();
        charPtrTemps.clear();
        // ── TCO 清除 ──
        currentFuncNameStack.clear();
        currentFuncParamSlots.clear();
        currentFuncParamTypes.clear();
        currentFuncParamNames.clear();
        tcoLoopLabelStack.clear();
        emittedExternDecls.clear();
        pendingDeclares.clear();
        TextCodeBuffers.clear();
        stringDefs.clear();
        stringLiterals.clear();
        strLengths.clear();
        cseTable.clear();
        gotoTable.clear();
        forwardGotoPatches.clear();
        tmpCnt = 0;
        labelCnt = 0;
        strCnt = 0;
        TextCodeBuffers.add(new ArrayList<>());
        currentTextCodeBuffer = TextCodeBuffers.get(0);
    }

    public java.util.Map<String, String> exactTypeMap = new java.util.HashMap<>();

    String newTemp() { return "%t" + (tmpCnt++); }
    String newLabel(String base) { return base + (labelCnt++); }
    
    

    // ── 新增：將 char (i8) 提升為 int (i32)，符合 C integer promotion ──
    String charPromote(String tmp) {
        String result = newTemp();
        addInstruction(result + " = sext i8 " + tmp + " to i32");
        return result;
    }

    String toLLVMType(TypeInfo type) {
        if (type == null) return "i32";
        switch (type) {
            case Int:          return "i32";
            case Long:         return "i64";
            case Short:        return "i16";
            case Float:        return "float";
            case Double:       return "double";
            case Char:         return "i8";
            case UnsignedChar: return "i8";
            case UnsignedShort:return "i16";
            case UnsignedInt:  return "i32";
            case UnsignedLong: return "i64";
            case Boolean:      return "i1";
            case Void:         return "void";
            case Pointer:      return "i8*";
            case Error:        return "i32";
            default:           return "i32";
        }
    }

    // ── 判斷某個 TypeInfo 是否屬於無號整數型別 ──
    boolean isUnsignedType(TypeInfo t) {
        // ✨ Bug fix：Boolean (i1) 在 C 語意中視為無號（值只會是 0 或 1），
        //    擴展到更寬整數型別時必須用 zext，而非 sext（否則 true 會變成 -1）
        return t == TypeInfo.UnsignedInt || t == TypeInfo.UnsignedLong
            || t == TypeInfo.UnsignedShort || t == TypeInfo.UnsignedChar
            || t == TypeInfo.Boolean;
    }

    // ── 判斷某個 TypeInfo 是否是整數型別（含 Short/Unsigned 系列）──
    boolean isIntegerType(TypeInfo t) {
        return t == TypeInfo.Int || t == TypeInfo.Long || t == TypeInfo.Short
            || t == TypeInfo.UnsignedInt || t == TypeInfo.UnsignedLong
            || t == TypeInfo.UnsignedShort || t == TypeInfo.UnsignedChar
            || t == TypeInfo.Char || t == TypeInfo.Boolean;
    }

    // ── C 整數提升：Short/UnsignedShort/UnsignedChar → Int（32-bit 平台規則）──
    // 回傳提升後的 TypeInfo；若不需要提升則原樣回傳
    TypeInfo integerPromote(TypeInfo t) {
        if (t == TypeInfo.Char || t == TypeInfo.Short || t == TypeInfo.UnsignedShort
                || t == TypeInfo.UnsignedChar || t == TypeInfo.Boolean) return TypeInfo.Int;
        return t;
    }

    // ── 發出提升到 Int 所需的 sext/zext 指令，並回傳新 tmp；若不需要則原樣回傳 ──
    String emitIntPromotion(TypeInfo srcType, String srcTmp) {
        if (srcType == TypeInfo.Short) {
            String r = newTemp(); addInstruction(r + " = sext i16 " + srcTmp + " to i32"); return r;
        }
        // signed char（Char）→ sext；unsigned char → zext
        if (srcType == TypeInfo.Char) {
            String r = newTemp(); addInstruction(r + " = sext i8 " + srcTmp + " to i32"); return r;
        }
        if (srcType == TypeInfo.UnsignedShort || srcType == TypeInfo.UnsignedChar) {
            String r = newTemp(); addInstruction(r + " = zext " + toLLVMType(srcType) + " " + srcTmp + " to i32"); return r;
        }
        if (srcType == TypeInfo.Boolean) {
            String r = newTemp(); addInstruction(r + " = zext i1 " + srcTmp + " to i32"); return r;
        }
        return srcTmp;
    }

    // ── 一般算術型別提升（Usual Arithmetic Conversions）──
    // 決定兩個運算元共同結果型別（嚴格依 C11 §6.3.1.8 優先序）
    TypeInfo usualArithConvert(TypeInfo a, TypeInfo b) {
        if (a == TypeInfo.Double || b == TypeInfo.Double) return TypeInfo.Double;
        if (a == TypeInfo.Float  || b == TypeInfo.Float)  return TypeInfo.Float;
        // 先做 integer promotion
        a = integerPromote(a); b = integerPromote(b);
        if (a == TypeInfo.UnsignedLong || b == TypeInfo.UnsignedLong) return TypeInfo.UnsignedLong;
        if (a == TypeInfo.Long || b == TypeInfo.Long) return TypeInfo.Long;
        if (a == TypeInfo.UnsignedInt || b == TypeInfo.UnsignedInt) return TypeInfo.UnsignedInt;
        return TypeInfo.Int;
    }

    // ── 發出從 srcType→dstType 所需的轉型指令，回傳新 tmp ──
    String emitConvert(TypeInfo srcType, String srcTmp, TypeInfo dstType) {
        if (srcType == dstType) return srcTmp;
        String src = toLLVMType(srcType);
        String dst = toLLVMType(dstType);
        String r = newTemp();
        // float/double 系列
        if (dstType == TypeInfo.Double && (srcType == TypeInfo.Float)) {
            addInstruction(r + " = fpext float " + srcTmp + " to double"); return r;
        }
        if (dstType == TypeInfo.Float && srcType == TypeInfo.Double) {
            addInstruction(r + " = fptrunc double " + srcTmp + " to float"); return r;
        }
        if ((dstType == TypeInfo.Float || dstType == TypeInfo.Double) && isIntegerType(srcType)) {
            String conv = isUnsignedType(srcType) ? "uitofp" : "sitofp";
            addInstruction(r + " = " + conv + " " + src + " " + srcTmp + " to " + dst); return r;
        }
        if (isIntegerType(dstType) && (srcType == TypeInfo.Float || srcType == TypeInfo.Double)) {
            String conv = isUnsignedType(dstType) ? "fptoui" : "fptosi";
            addInstruction(r + " = " + conv + " " + src + " " + srcTmp + " to " + dst); return r;
        }
        // 整數系列
        int srcBits = bitWidth(srcType);
        int dstBits = bitWidth(dstType);
        if (dstBits > srcBits) {
            String conv = isUnsignedType(srcType) ? "zext" : "sext";
            addInstruction(r + " = " + conv + " " + src + " " + srcTmp + " to " + dst); return r;
        }
        if (dstBits < srcBits) {
            addInstruction(r + " = trunc " + src + " " + srcTmp + " to " + dst); return r;
        }
        // 同位寬（如 Int ↔ UnsignedInt）：bitcast 或直接用
        return srcTmp; // LLVM i32 有號無號同 IR
    }

    int bitWidth(TypeInfo t) {
        if (t == TypeInfo.Long || t == TypeInfo.UnsignedLong || t == TypeInfo.Double) return 64;
        if (t == TypeInfo.Short || t == TypeInfo.UnsignedShort) return 16;
        if (t == TypeInfo.Char  || t == TypeInfo.UnsignedChar)  return 8;
        if (t == TypeInfo.Boolean) return 1;
        return 32; // Int, UnsignedInt, Float, Pointer
    }

    // ✨ 新增這個：支援深度 (depth) 和 Struct 的 LLVM 指標型別產生器！
    // 編譯器找不到的三個參數的方法就是這個！
    String toLLVMPtrType(TypeInfo base, String structName, int depth) {
        if (depth == 0) {
            return (base == TypeInfo.Struct && structName != null) ? "%struct." + structName : toLLVMType(base);
        }
        String res = (base == TypeInfo.Struct && structName != null) ? "%struct." + structName : toLLVMType(base);
        if (base == TypeInfo.Void) res = "i8"; // 防護網：void* 轉 i8*
        for(int i = 0; i < depth; i++) {
            res += "*";
        }
        return res;
    }

    // ── 取得指標對應的 LLVM 型別字串（e.g. Int → "i32*"）──
    String toLLVMPtrType(TypeInfo pointee) {
        // ✨ 新增這行：攔截 void*，強迫它變成 LLVM 合法的 i8*
        if (pointee == TypeInfo.Void) return "i8*"; 
        return toLLVMType(pointee) + "*";
    }

    String toLLVMPtrType(TypeInfo pointee, String structName) {
        if (pointee == TypeInfo.Struct && structName != null) {
            return "%struct." + structName + "*";
        }
        return toLLVMPtrType(pointee);
    }

    // ── 從 Info 取得該指標變數的 LLVM pointee 型別字串 ──
    String getPointeeLLVMType(Info info) {
        if (info.pointeeType != null) return toLLVMType(info.pointeeType);
        return "i32"; // 預設
    }

    // ── 精準計算 LLVM UTF-8 字串長度的小幫手 ──
    // ── 計算字串 inner（不含引號）的 LLVM byte 長度（含 null）──
    int calcLLVMStrLen(String inner) {
        int bytes = 0;
        int i = 0;
        while (i < inner.length()) {
            if (inner.charAt(i) == '\\' && i + 1 < inner.length()) {
                char esc = inner.charAt(i + 1);
                if (esc == 'x') {
                    bytes += 1; i += 4;
                } else if (esc >= '0' && esc <= '7') {
                    bytes += 1;
                    int end = i + 2;
                    while (end < inner.length() && end < i + 4 && inner.charAt(end) >= '0' && inner.charAt(end) <= '7') end++;
                    i = end;
                } else {
                    bytes += 1; i += 2;
                }
            } else {
                int cp = inner.codePointAt(i);
                if      (cp < 0x80)    bytes += 1;
                else if (cp < 0x800)   bytes += 2;
                else if (cp < 0x10000) bytes += 3;
                else                   bytes += 4;
                i += Character.charCount(cp);
            }
        }
        return bytes + 1;
    }

    // ── 把 inner 轉成 LLVM IR c"..." 格式，非 ASCII 字元轉 \XX，支援 \xNN / \ooo ──
    String toIRString(String inner) {
        StringBuilder sb = new StringBuilder();
        int i = 0;
        while (i < inner.length()) {
            if (inner.charAt(i) == '\\' && i + 1 < inner.length()) {
                char esc = inner.charAt(i + 1);
                switch (esc) {
                    case 'n':  sb.append("\\0A"); i += 2; break;
                    case 't':  sb.append("\\09"); i += 2; break;
                    case 'r':  sb.append("\\0D"); i += 2; break;
                    case '\\': sb.append("\\5C"); i += 2; break;
                    case '"':  sb.append("\\22"); i += 2; break;
                    case '\'': sb.append("\\27"); i += 2; break;
                    case '0':  sb.append("\\00"); i += 2; break;
                    case 'a':  sb.append("\\07"); i += 2; break;
                    case 'b':  sb.append("\\08"); i += 2; break;
                    case 'f':  sb.append("\\0C"); i += 2; break;
                    case 'v':  sb.append("\\0B"); i += 2; break;
                    case 'x':
                        // \xNN：十六進位逃脫序列
                        if (i + 3 < inner.length()) {
                            String hexStr = inner.substring(i + 2, Math.min(i + 4, inner.length()));
                            try {
                                int hexVal = Integer.parseInt(hexStr, 16);
                                sb.append(String.format("\\%02X", hexVal));
                                i += 2 + hexStr.length();
                            } catch (NumberFormatException _ex) { sb.append("\\00"); i += 2; }
                        } else { sb.append("\\00"); i += 2; }
                        break;
                    default:
                        if (esc >= '0' && esc <= '7') {
                            // \ooo：八進位逃脫序列
                            int end = i + 2;
                            while (end < inner.length() && end < i + 4 && inner.charAt(end) >= '0' && inner.charAt(end) <= '7') end++;
                            try {
                                int octVal = Integer.parseInt(inner.substring(i + 1, end), 8);
                                sb.append(String.format("\\%02X", octVal));
                            } catch (NumberFormatException _eo) { sb.append("\\00"); }
                            i = end;
                        } else {
                            sb.append(String.format("\\%02X", (int)esc)); i += 2;
                        }
                        break;
                }
            } else {
                int cp = inner.codePointAt(i);
                if (cp < 0x80) {
                    sb.append((char) cp);
                } else {
                    try {
                        byte[] utf8 = new String(Character.toChars(cp)).getBytes("UTF-8");
                        for (byte b : utf8) sb.append(String.format("\\%02X", b & 0xFF));
                    } catch (Exception e2) { sb.append(String.format("\\%02X", cp & 0xFF)); }
                }
                i += Character.charCount(cp);
            }
        }
        sb.append("\\00");
        return sb.toString();
    }

    int getLLVMStringLength(String rawStr) {
        return calcLLVMStrLen(rawStr.substring(1, rawStr.length() - 1));
    }

    // ── 收集並延遲輸出 declare 避免重複 ──
    void decl(String s) {
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("@([a-zA-Z0-9_.]+)\\s*\\(").matcher(s);
        if (m.find()) {
            String fname = m.group(1);
            pendingDeclares.put(fname, s);
            emittedExternDecls.add("func:" + fname);
        } else {
            System.out.println(s);
        }
    }

   void printHeader() {
        System.out.println("; ModuleID = 'main'");
        System.out.println("target triple = \"x86_64-pc-linux-gnu\"");
        
        decl("declare i32 @printf(i8*, ...) nounwind");
        decl("declare i32 @__isoc99_scanf(i8*, ...)");
        decl("declare i32 @__isoc99_sscanf(i8*, i8*, ...)");
        decl("declare i32 @__isoc99_fscanf(i8*, i8*, ...)");
        decl("declare float @my_hashhash(float, float)");
        // I/O
        decl("declare i32 @getchar()");
        decl("declare i32 @putchar(i32)");
        // ── 新增：sprintf / snprintf ──
        decl("declare i32 @sprintf(i8*, i8*, ...)");
        decl("declare i32 @snprintf(i8*, i64, i8*, ...)");
        // string.h
        decl("declare i64 @strlen(i8*)");
        decl("declare i8* @strcpy(i8*, i8*)");
        decl("declare i8* @strcat(i8*, i8*)");
        decl("declare i32 @strcmp(i8*, i8*)");
        decl("declare i8* @strncpy(i8*, i8*, i64)");
        decl("declare i8* @strncat(i8*, i8*, i64)");
        decl("declare i32 @strncmp(i8*, i8*, i64)");
        decl("declare i8* @strstr(i8*, i8*)");
        decl("declare i8* @strchr(i8*, i32)");
        decl("declare i8* @strrchr(i8*, i32)");
        decl("declare i8* @strtok(i8*, i8*)");
        // ── 新增：atoi / atof ──
        decl("declare i32 @atoi(i8*)");
        decl("declare double @atof(i8*)");
        // math.h
        decl("declare double @sqrt(double)");
        decl("declare double @pow(double, double)");
        decl("declare double @fabs(double)");
        decl("declare double @floor(double)");
        decl("declare double @ceil(double)");
        decl("declare double @sin(double)");
        decl("declare double @cos(double)");
        decl("declare double @log(double)");
        decl("declare double @fmod(double, double)");
        // ── fmin / fmax / fma / fdim / signbit ──
        decl("declare double @fmin(double, double)");
        decl("declare double @fmax(double, double)");
        decl("declare double @fma(double, double, double)");
        decl("declare double @fdim(double, double)");
        decl("declare double @copysign(double, double)");
        decl("declare i32 @__signbit(double)");
        decl("declare i32 @__isnan(double)");
        decl("declare i32 @__isinf(double)");
        decl("declare i32 @__finite(double)");
        // ── 行程/環境 ──
        decl("declare i8* @getenv(i8*)");
        decl("declare i32 @system(i8*)");
        decl("declare i32 @putenv(i8*)");
        // ── 整數除法結構 ──
        System.out.println("%struct.div_t = type { i32, i32 }");
        System.out.println("%struct.ldiv_t = type { i64, i64 }");
        decl("declare %struct.div_t @div(i32, i32)");
        decl("declare %struct.ldiv_t @ldiv(i64, i64)");
        // ── 其他常用 ──
        decl("declare i32 @atexit(i8*)");
        decl("declare void @_exit(i32)");
        // ── 新增：abs（stdlib.h）──
        decl("declare i32 @abs(i32)");
        decl("declare i64 @labs(i64)");
        decl("declare i64 @llabs(i64)");
        decl("declare i64 @strtol(i8*, i8**, i32)");
        decl("declare i64 @strtoll(i8*, i8**, i32)");
        decl("declare i64 @strtoul(i8*, i8**, i32)");
        decl("declare double @strtod(i8*, i8**)");
        decl("declare float @strtof(i8*, i8**)");
        decl("declare i32 @rand()");
        decl("declare void @srand(i32)");
        decl("declare i64 @time(i8*)");
        // ── qsort / bsearch ──
        decl("declare void @qsort(i8*, i64, i64, i8*)");
        decl("declare i8* @bsearch(i8*, i8*, i64, i64, i8*)");
        // ── time.h struct tm + 函式 ──
        System.out.println("%struct.tm = type { i32, i32, i32, i32, i32, i32, i32, i32, i32 }");
        decl("declare %struct.tm* @localtime(i64*)");
        decl("declare %struct.tm* @gmtime(i64*)");
        decl("declare i64 @mktime(%struct.tm*)");
        decl("declare i64 @strftime(i8*, i64, i8*, %struct.tm*)");
        decl("declare double @difftime(i64, i64)");
        // ── math.h lround / llround / nearbyint / round / trunc / exp / tan / … ──
        decl("declare i64 @lround(double)");
        decl("declare i64 @llround(double)");
        decl("declare double @nearbyint(double)");
        decl("declare double @round(double)");
        decl("declare double @trunc(double)");
        decl("declare double @exp(double)");
        decl("declare double @exp2(double)");
        decl("declare double @log2(double)");
        decl("declare double @log10(double)");
        decl("declare double @tan(double)");
        decl("declare double @asin(double)");
        decl("declare double @acos(double)");
        decl("declare double @atan(double)");
        decl("declare double @atan2(double, double)");
        decl("declare double @sinh(double)");
        decl("declare double @cosh(double)");
        decl("declare double @tanh(double)");
        decl("declare double @cbrt(double)");
        decl("declare double @hypot(double, double)");
        // ✨ 新增：動態記憶體配置宣告 ✨
        decl("declare i8* @malloc(i32)");
        decl("declare void @free(i8*)");
        decl("declare i8* @calloc(i32, i32)");
        decl("declare i8* @realloc(i8*, i32)");
        decl("declare void @abort() noreturn");
        decl("declare i32 @isxdigit(i32)");
        decl("declare i32 @isblank(i32)");
        decl("declare i32 @iscntrl(i32)");
        decl("declare i32 @isgraph(i32)");
        decl("declare i8* @memcpy(i8*, i8*, i32)");
        decl("declare i8* @memset(i8*, i32, i32)");
        decl("declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i1 immarg)");
        // ✨ 位元操作 intrinsics
        decl("declare i32 @llvm.ctpop.i32(i32)");
        decl("declare i64 @llvm.ctpop.i64(i64)");
        decl("declare i32 @llvm.ctlz.i32(i32, i1)");
        decl("declare i64 @llvm.ctlz.i64(i64, i1)");
        decl("declare i32 @llvm.cttz.i32(i32, i1)");
        decl("declare i64 @llvm.cttz.i64(i64, i1)");
        decl("declare i16 @llvm.bswap.i16(i16)");
        decl("declare i32 @llvm.bswap.i32(i32)");
        decl("declare i64 @llvm.bswap.i64(i64)");
        decl("declare i32 @memcmp(i8*, i8*, i32)");
        // ✨ 新增：memmove / memchr / strspn / strcspn / strpbrk
        decl("declare i8* @memmove(i8*, i8*, i64)");
        decl("declare i8* @memchr(i8*, i32, i64)");
        decl("declare i64 @strspn(i8*, i8*)");
        decl("declare i64 @strcspn(i8*, i8*)");
        decl("declare i8* @strpbrk(i8*, i8*)");
        // ✨ 新增：檔案 I/O 外部函式宣告 ✨
        decl("declare i8* @fopen(i8*, i8*)");
        decl("declare i32 @fclose(i8*)");
        decl("declare i32 @fputs(i8*, i8*)");
        decl("declare i32 @fgetc(i8*)");
        // ── 新增：fprintf / fgets / feof ──
        decl("declare i32 @fprintf(i8*, i8*, ...)");
        decl("declare i8* @fgets(i8*, i32, i8*)");
        decl("declare i32 @feof(i8*)");
        decl("declare i64 @fwrite(i8*, i64, i64, i8*)");
        decl("declare i64 @fread(i8*, i64, i64, i8*)");
        decl("declare i32 @fseek(i8*, i64, i32)");
        decl("declare i64 @ftell(i8*)");
        decl("declare void @rewind(i8*)");
        decl("declare i32 @ferror(i8*)");
        decl("declare void @perror(i8*)");
        decl("declare i8* @strerror(i32)");
        decl("declare i32 @remove(i8*)");
        decl("declare i32 @rename(i8*, i8*)");
        decl("declare i8* @strdup(i8*)");
        decl("declare i32 @fputc(i32, i8*)");
        decl("declare i32 @ungetc(i32, i8*)");
        // ── 新增第一批功能宣告 ──
        decl("declare void @clearerr(i8*)");
        decl("declare i8* @tmpfile()");
        decl("declare i8* @tmpnam(i8*)");
        decl("declare i8* @popen(i8*, i8*)");
        decl("declare i32 @pclose(i8*)");
        decl("declare i32 @setvbuf(i8*, i8*, i32, i64)");
        decl("declare void @setbuf(i8*, i8*)");
        decl("declare double @modf(double, double*)");
        decl("declare double @frexp(double, i32*)");
        decl("declare double @ldexp(double, i32)");
        decl("declare double @scalbn(double, i32)");
        decl("declare double @logb(double)");
        decl("declare i32 @ilogb(double)");
        decl("declare i8* @signal(i32, i8*)");
        decl("declare i32 @raise(i32)");
        // ── va_list 支援（LLVM 內建）──
        decl("declare void @llvm.va_start(i8*)");
        decl("declare void @llvm.va_end(i8*)");
        decl("declare void @llvm.va_copy(i8*, i8*)");

        decl("declare i32 @vprintf(i8*, i8*)");
        decl("declare i32 @vfprintf(i8*, i8*, i8*)");
        decl("declare i32 @vsprintf(i8*, i8*, i8*)");
        decl("declare i32 @vsnprintf(i8*, i64, i8*, i8*)");
        // ── 新增：exit（stdlib.h）──
        decl("declare void @exit(i32) noreturn");
        // ── 新增：ctype.h ──
        decl("declare i32 @isdigit(i32)");
        decl("declare i32 @isalpha(i32)");
        decl("declare i32 @isalnum(i32)");
        decl("declare i32 @isspace(i32)");
        decl("declare i32 @isupper(i32)");
        decl("declare i32 @islower(i32)");
        decl("declare i32 @toupper(i32)");
        decl("declare i32 @tolower(i32)");
        decl("declare i32 @isprint(i32)");
        decl("declare i32 @ispunct(i32)");

        // ── ✨ stdio.h 補完：puts / gets / freopen / fflush ──
        decl("declare i32 @puts(i8*)");
        decl("declare i8* @gets(i8*)");
        decl("declare i8* @freopen(i8*, i8*, i8*)");
        decl("declare i32 @fflush(i8*)");

        // ── ✨ stdlib.h 補完：aligned_alloc / _Exit ──
        decl("declare i8* @aligned_alloc(i64, i64)");
        decl("declare void @_Exit(i32) noreturn");

        // ── ✨ 字串補完：asprintf / strsep ──
        decl("declare i32 @asprintf(i8**, i8*, ...)");
        decl("declare i8* @strsep(i8**, i8*)");

        // ── ✨ setjmp / longjmp（jmp_buf = [8 x i64]）──
        System.out.println("%struct.__jmp_buf = type { i64, i64, i64, i64, i64, i64, i64, i64 }");
        decl("declare i32 @setjmp(i8*)");
        decl("declare void @longjmp(i8*, i32) noreturn");

        // ── ✨ stdio stdout / stdin / stderr 全域指標 ──
        System.out.println("@stdout = external global i8*");
        System.out.println("@stdin  = external global i8*");
        System.out.println("@stderr = external global i8*");

        System.out.println();
    }
    // 自動追蹤 Terminator (跳轉/回傳) 防呆機制 + ✨ 終極防漏水濾網 ✨
    void addInstruction(String instr) {
        String trimmed = instr.trim();
        
        // 總閘門安全攔截：如果是錯誤訊息，直接分流到 stderr，絕對不污染 IR 緩衝區！
        if (trimmed.startsWith("Error!")) {
            System.err.println(instr);
            return; // 轉向後直接結束，不加入 buffer
        }

        // 正常的 LLVM 指令才允許進入 buffer
        currentTextCodeBuffer.add(instr);
        if (trimmed.startsWith("br ") || trimmed.startsWith("ret ") || trimmed.startsWith("switch ")) {
            lastInstrIsTerminator = true;
        } else {
            lastInstrIsTerminator = false;
        }
    }
    // Stack to save/restore lastInstrIsTerminator across buffer push/pop
    List<Boolean> terminatorStack = new ArrayList<>();

    void pushBuffer() {
        terminatorStack.add(lastInstrIsTerminator);
        lastInstrIsTerminator = false;
        List<String> newBuffer = new ArrayList<>();
        TextCodeBuffers.add(newBuffer);
        currentTextCodeBuffer = newBuffer;
    }

    List<String> popBuffer() {
        if (TextCodeBuffers.size() <= 1) {
            throw new IllegalStateException("Cannot pop the main TextCode buffer.");
        }
        List<String> poppedBuffer = TextCodeBuffers.remove(TextCodeBuffers.size() - 1);
        currentTextCodeBuffer = TextCodeBuffers.get(TextCodeBuffers.size() - 1);
        if (!terminatorStack.isEmpty()) {
            lastInstrIsTerminator = terminatorStack.remove(terminatorStack.size() - 1);
        }
        return poppedBuffer;
    }

    public List<String> getFinalTextCode() {
        if (TextCodeBuffers.isEmpty()) return new ArrayList<>();
        return TextCodeBuffers.get(0);
    }

    // 將任意型別的值轉成 i1 (boolean)，符合 C 語言語意（非零為真）
    String coerceToBool(TypeInfo type, String tmp) {
        if (type == TypeInfo.Boolean) return tmp;
        String result = newTemp();
        if (type == TypeInfo.Float || type == TypeInfo.Double) {
            addInstruction(result + " = fcmp one " + toLLVMType(type) + " " + tmp + ", 0.0");
        } else if (type == TypeInfo.Pointer || charPtrTemps.contains(tmp)) {
            // ── 指標比較：LLVM 要求用 null，不能用整數 0 ──
            String ptrLLVM = exactTypeMap.containsKey(tmp) ? exactTypeMap.get(tmp) : "i8*";
            addInstruction(result + " = icmp ne " + ptrLLVM + " " + tmp + ", null");
        } else {
            // 所有整數型別（含 Short、UnsignedInt、UnsignedLong…）都用 icmp ne
            addInstruction(result + " = icmp ne " + toLLVMType(type) + " " + tmp + ", 0");
        }
        return result;
    }

    // ── toPtr：NULL 巨集展開為整數 "0"，傳 i8* 參數時要轉成 "null" ──
    String toPtr(Info arg) {
        if (arg == null) return "null";
        if ("0".equals(arg.tmp) || "null".equals(arg.tmp)) return "null";
        return arg.tmp;
    }

    // ── toFilePtr：FILE* 指標統一轉成 i8*（bitcast 非 i8* 指標型別 / inttoptr 整數型別）──
    String toFilePtr(Info arg) {
        if (arg == null) return "null";
        String t = arg.tmp;
        if ("0".equals(t) || "null".equals(t)) return "null";
        String llvmT = exactTypeMap.containsKey(t) ? exactTypeMap.get(t) : "i8*";
        if (!llvmT.equals("i8*")) {
            String casted = newTemp();
            if (!llvmT.endsWith("*")) {
                // 非指標整數：用 inttoptr
                String intVal = t;
                if (llvmT.equals("i32")) {
                    String ext = newTemp();
                    addInstruction(ext + " = zext i32 " + intVal + " to i64");
                    intVal = ext; llvmT = "i64";
                }
                addInstruction(casted + " = inttoptr " + llvmT + " " + intVal + " to i8*");
            } else {
                addInstruction(casted + " = bitcast " + llvmT + " " + t + " to i8*");
            }
            return casted;
        }
        return t;
    }

    String toCharPtr(Info arg) {
        if (arg == null) return "null";
        String val = arg.tmp;
        
        // NULL 防護網
        if ("0".equals(val) || "null".equals(val)) {
            exactTypeMap.put("null", "i8*");
            return "null";
        }
        
        // 透過小本本 (exactTypeMap) 查出真實的 LLVM 型別
        String srcType = "i8*"; // 預設
        if (exactTypeMap.containsKey(val)) {
            srcType = exactTypeMap.get(val);
        } else if (arg.theType != TypeInfo.Pointer && !arg.isPointer && arg.arraySize <= 0) {
            // 如果連指標都不是，補上 * 避免 bitcast 語法錯誤
            srcType = toLLVMType(arg.theType) + "*";
        }

        // 如果不是 i8*，就產生轉換指令
        if (!srcType.equals("i8*")) {
            String casted = newTemp();
            if (!srcType.endsWith("*")) {
                // ── 非指標整數（如 i32）：必須用 inttoptr，bitcast 在此非法 ──
                String intVal = val;
                if (srcType.equals("i32")) {
                    String ext = newTemp();
                    addInstruction(ext + " = zext i32 " + intVal + " to i64");
                    intVal = ext; srcType = "i64";
                }
                addInstruction(casted + " = inttoptr " + srcType + " " + intVal + " to i8*");
            } else {
                addInstruction(casted + " = bitcast " + srcType + " " + val + " to i8*");
            }
            exactTypeMap.put(casted, "i8*");
            return casted;
        }
        return val;
    }

    List<String[]> loopLabelStack = new ArrayList<>();
    void pushLoopLabels(String breakLabel, String continueLabel) {
        loopLabelStack.add(new String[]{breakLabel, continueLabel});
    }
    void popLoopLabels() {
        if (!loopLabelStack.isEmpty()) loopLabelStack.remove(loopLabelStack.size() - 1);
    }
    String getCurrentBreakLabel() {
        if (loopLabelStack.isEmpty()) return null;
        return loopLabelStack.get(loopLabelStack.size() - 1)[0];
    }
    String getCurrentContinueLabel() {
        if (loopLabelStack.isEmpty()) return null;
        return loopLabelStack.get(loopLabelStack.size() - 1)[1];
    }

    // ══════════════════════════════════════════════
    // DCE（Dead Code Elimination）
    // 對每個函式的 IR 指令串列做兩種 pass：
    //
    // Pass 1 — Unreachable Code Elimination（UCE）
    //   在每個 basic block 裡，一旦出現 terminator（ret/br/switch）
    //   就把同一 block 後面的指令全部移除，直到下一個 label。
    //
    // Pass 2 — Dead Store Elimination（DSE）
    //   找出 alloca 變數，若其 store 後從未被 load 讀取過，
    //   就把多餘的 store 移除（最後一個 store 保留以防 alloca 完全沒用到）。
    //
    // Pass 3 — Trivial Dead Assignment（TDA）
    //   找出 %tN = ... 的計算結果，若 %tN 從未被後續指令使用，
    //   且該指令是純計算（無副作用：非 call/store/br/ret），就移除。
    // ══════════════════════════════════════════════

    // ── goto Forward-Reference Patcher ──
    // 在函式結束時呼叫，把所有 "br label %Lgoto_fwd_XXX" 替換成真正的 LLVM label。
    // 如果使用者標號根本不存在，印出 Error。
    void patchGotoForwardRefs() {
        for (String[] patch : forwardGotoPatches) {
            String userName  = patch[0];
            String fwdLabel  = patch[1];
            int    errorLine = Integer.parseInt(patch[2]);
            String realLabel = gotoTable.get(userName);
            if (realLabel == null) {
                System.err.println("Error! line " + errorLine + ": label '" + userName + "' used in goto but never defined.");
                continue;
            }
            String oldInstr = "br label %" + fwdLabel;
            String newInstr = "br label %" + realLabel;
            for (int i = 0; i < currentTextCodeBuffer.size(); i++) {
                if (currentTextCodeBuffer.get(i).trim().equals(oldInstr)) {
                    currentTextCodeBuffer.set(i, newInstr);
                }
            }
        }
        forwardGotoPatches.clear();
    }

    List<String> applyDCE(List<String> instrs) {
        List<String> afterUCE = eliminateUnreachable(instrs);
        List<String> afterDSE = eliminateDeadStores(afterUCE);
        List<String> afterTDA = eliminateTrivialDeadAssignments(afterDSE, instrs);
        return afterTDA;
    }

    // ══════════════════════════════════════════════════════════════
    // Peephole Optimization
    // 在 DCE 之後、輸出之前對每一條 IR 指令做模式比對和替換。
    //
    // 支援的模式：
    //   P1  add  iN %t, 0          → %t        (加零消除)
    //   P2  sub  iN %t, 0          → %t        (減零消除)
    //   P3  mul  iN %t, 0          → 0         (乘零消除)
    //   P4  mul  iN %t, 1          → %t        (乘一消除)
    //   P5  sdiv iN %t, 1          → %t        (除一消除)
    //   P6  mul  i32 %t, 2         → shl i32 %t, 1   (乘 2 轉移位)
    //   P7  sdiv i32 %t, 2         → ashr i32 %t, 1  (除 2 轉移位)
    //   P8  mul  i32 %t, 4         → shl i32 %t, 2
    //   P9  sdiv i32 %t, 4         → ashr i32 %t, 2
    //   P10 fadd fT %t, 0.0        → %t        (浮點加零消除)
    //   P11 fsub fT %t, 0.0        → %t        (浮點減零消除)
    //   P12 fmul fT %t, 1.0        → %t        (浮點乘一消除)
    //   P13 %r = icmp eq iN %t, %t → %r = true (自身比較)
    //   P14 %r = icmp ne iN %t, %t → %r = false
    //   P15 %r = sub iN 0, 0       → %r = 0   (常數運算殘留)
    //   P16 br i1 true, label %A, label %B → br label %A  (常數分支化簡)
    //   P17 br i1 false, label %A, label %B → br label %B
    //   P18 %r = shl iN %t, 0      → %t        (移位零消除)
    //   P19 %r = or  iN %t, 0      → %t        (or 零消除)
    //   P20 %r = and iN %t, -1     → %t        (and 全一消除)
    //   P21 %r = xor iN %t, 0      → %t        (xor 零消除)
    // ══════════════════════════════════════════════════════════════
    List<String> applyPeephole(List<String> instrs) {
        // 第一遍：收集哪些 %tN 已被替換成另一個值（用於 propagation）
        java.util.Map<String, String> subst = new java.util.LinkedHashMap<>();

        java.util.function.Function<String, String> resolve = (s) -> {
            String cur = s;
            while (subst.containsKey(cur)) cur = subst.get(cur);
            return cur;
        };

        List<String> pass1 = new java.util.ArrayList<>();
        for (String raw : instrs) {
            String line = raw.trim();

            // ── 提取 LHS = RHS ──
            // 形如 "%tN = op type operand1, operand2"
            if (!line.matches("%t\\d+ = .*")) {
                // 替換 br i1 true / false（P16/P17）
                if (line.matches("br i1 (true|false), label %[^,]+, label %[^\\s]+")) {
                    String[] parts = line.split("[,\\s]+");
                    // parts: ["br","i1","true/false","label","%A","label","%B"]
                    boolean cond = parts[2].equals("true");
                    String target = cond ? parts[4] : parts[6];
                    pass1.add("br label " + target);
                    continue;
                }
                // 其他非賦值指令：做操作數替換
                String replaced = line;
                for (java.util.Map.Entry<String, String> e : subst.entrySet()) {
                    // 只替換完整的 token（前後是非字母數字）
                    // ✨ 修正：若替換值為整數字面值且指令含指標型別，跳過（避免 i8* 0 非法）
                    String _to = e.getValue();
                    if (_to.matches("-?\\d+")) {
                        // ✨ 只在替換目標出現於指標型別操作位置時才阻止（避免 store i32 %tN 的 %tN 無法被替換）
                        // 精確判斷：被替換的 token 是否緊接在 i8* 之後（pointer-valued operand）
                        String _from = e.getKey();
                        boolean _ptrCtx = replaced.contains("i8* " + _from)
                                || replaced.contains("inttoptr") || replaced.contains("bitcast") || replaced.contains("ptrtoint");
                        if (_ptrCtx) continue;
                    }
                    replaced = replaced.replaceAll(
                        "(?<![%\\w])" + java.util.regex.Pattern.quote(e.getKey()) + "(?![\\w])",
                        e.getValue());
                }
                pass1.add(replaced);
                continue;
            }

            String lhs = line.split(" = ", 2)[0].trim();
            String rhs = line.split(" = ", 2)[1].trim();

            // 先 resolve 所有操作數
            // ✨ 修正：若替換值為整數字面值，且目前指令含指標型別關鍵字，跳過（避免 i8* 0 非法）
            for (java.util.Map.Entry<String, String> e : subst.entrySet()) {
                String _to = e.getValue();
                if (_to.matches("-?\\d+")) {
                    // ✨ 只在替換目標是指標值操作位置時才阻止（避免 i8* 0 非法）
                    String _from = e.getKey();
                    boolean _ptrCtx = rhs.contains("i8* " + _from)
                            || rhs.contains("inttoptr") || rhs.contains("bitcast") || rhs.contains("ptrtoint");
                    if (_ptrCtx) continue;
                }
                rhs = rhs.replaceAll(
                    "(?<![%\\w])" + java.util.regex.Pattern.quote(e.getKey()) + "(?![\\w])",
                    e.getValue());
            }

            // ── 整數運算模式 ──
            // add iN %t, 0  |  add iN 0, %t
            java.util.regex.Matcher mAddRightZero = java.util.regex.Pattern.compile(
                "add (i(?:8|16|32|64)) (.+), 0$").matcher(rhs);
            java.util.regex.Matcher mAddLeftZero = java.util.regex.Pattern.compile(
                "add (i(?:8|16|32|64)) 0, (.+)$").matcher(rhs);
            boolean addRightZero = mAddRightZero.matches();
            boolean addLeftZero = mAddLeftZero.matches();
            if (addRightZero || addLeftZero) {
                String keep = addRightZero ? mAddRightZero.group(2) : mAddLeftZero.group(2);
                subst.put(lhs, keep); continue; // P1：消除，不輸出這條指令
            }
            // sub iN %t, 0
            if (rhs.matches("sub i(8|16|32|64) .+, 0$")) {
                String[] tok = rhs.split("[,\\s]+");
                subst.put(lhs, tok[2]); continue; // P2
            }
            // mul iN %t, 0  |  mul iN 0, %t → 0
            if (rhs.matches("mul i(8|16|32|64) .+, 0$") || rhs.matches("mul i(8|16|32|64) 0, .+$")) {
                subst.put(lhs, "0"); continue; // P3
            }
            // mul iN %t, 1
            if (rhs.matches("mul i(8|16|32|64) .+, 1$")) {
                String[] tok = rhs.split("[,\\s]+");
                subst.put(lhs, tok[2]); continue; // P4
            }
            // sdiv iN %t, 1
            if (rhs.matches("sdiv i(8|16|32|64) .+, 1$")) {
                String[] tok = rhs.split("[,\\s]+");
                subst.put(lhs, tok[2]); continue; // P5
            }
            // mul i32 %t, 2  → shl i32 %t, 1
            java.util.regex.Matcher mMul2 = java.util.regex.Pattern.compile(
                "mul (i32|i64) (.+), (\\d+)$").matcher(rhs);
            if (mMul2.matches()) {
                int rv = Integer.parseInt(mMul2.group(3));
                if (rv > 1 && (rv & (rv-1)) == 0) {
                    int sh = Integer.numberOfTrailingZeros(rv);
                    pass1.add(lhs + " = shl " + mMul2.group(1) + " " + mMul2.group(2) + ", " + sh); // P6/P8
                    continue;
                }
            }
            // sdiv i32 %t, 2 → ashr i32 %t, 1 的轉換已移除：
            // ashr（算術右移）對負數是「向負無窮取整」，而 C 的 sdiv 是「向零取整」，
            // 兩者在被除數為負且不整除時結果不同（差1），直接轉換會導致錯誤結果。
            // sdiv 本身已是 LLVM 對 C 除法語意的正確實作，交由後續 LLVM 後端
            // （opt/llc）視情況自行做正確的 sdiv-by-constant 強度削減。
            // ── 浮點運算模式 ──
            java.util.regex.Matcher mFAddRightZero = java.util.regex.Pattern.compile(
                "fadd (float|double) (.+), 0\\.0$").matcher(rhs);
            java.util.regex.Matcher mFAddLeftZero = java.util.regex.Pattern.compile(
                "fadd (float|double) 0\\.0, (.+)$").matcher(rhs);
            boolean faddRightZero = mFAddRightZero.matches();
            boolean faddLeftZero = mFAddLeftZero.matches();
            if (faddRightZero || faddLeftZero) {
                String keep = faddRightZero ? mFAddRightZero.group(2) : mFAddLeftZero.group(2);
                subst.put(lhs, keep); continue; // P10
            }
            if (rhs.matches("fsub (float|double) .+, 0\\.0$")) {
                String[] tok = rhs.split("[,\\s]+");
                subst.put(lhs, tok[2]); continue; // P11
            }
            java.util.regex.Matcher mFMulRightOne = java.util.regex.Pattern.compile(
                "fmul (float|double) (.+), 1\\.0$").matcher(rhs);
            java.util.regex.Matcher mFMulLeftOne = java.util.regex.Pattern.compile(
                "fmul (float|double) 1\\.0, (.+)$").matcher(rhs);
            boolean fmulRightOne = mFMulRightOne.matches();
            boolean fmulLeftOne = mFMulLeftOne.matches();
            if (fmulRightOne || fmulLeftOne) {
                String keep = fmulRightOne ? mFMulRightOne.group(2) : mFMulLeftOne.group(2);
                subst.put(lhs, keep); continue; // P12
            }
            // ── icmp 自身比較 (P13/P14) ──
            java.util.regex.Matcher mCmp = java.util.regex.Pattern.compile(
                "icmp (eq|ne) i(8|16|32|64) (%t\\d+), (%t\\d+)$").matcher(rhs);
            if (mCmp.matches() && mCmp.group(3).equals(mCmp.group(4))) {
                subst.put(lhs, mCmp.group(1).equals("eq") ? "true" : "false"); continue;
            }
            // ── 移位零（P18）──
            if (rhs.matches("shl i(8|16|32|64) .+, 0$") || rhs.matches("lshr i(8|16|32|64) .+, 0$") || rhs.matches("ashr i(8|16|32|64) .+, 0$")) {
                String[] tok = rhs.split("[,\\s]+");
                subst.put(lhs, tok[2]); continue;
            }
            // ── or/and/xor 零或全一（P19/P20/P21）──
            if (rhs.matches("or i(8|16|32|64) .+, 0$")) {
                String[] tok = rhs.split("[,\\s]+");
                subst.put(lhs, tok[2]); continue;
            }
            if (rhs.matches("xor i(8|16|32|64) .+, 0$")) {
                String[] tok = rhs.split("[,\\s]+");
                subst.put(lhs, tok[2]); continue;
            }
            if (rhs.matches("and i(8|16|32|64) .+, -1$")) {
                String[] tok = rhs.split("[,\\s]+");
                subst.put(lhs, tok[2]); continue;
            }

            // 其他指令不替換，直接輸出（但要把 rhs 裡的 resolved operands 寫進去）
            pass1.add(lhs + " = " + rhs);
        }

        // 第二遍：把 subst 的替換傳播到剩餘指令的所有操作數
        // ✨ 修正：若替換值為整數字面值 "0"，跳過會把 i8* 指標操作數替換成裸整數的情況
        List<String> pass2 = new java.util.ArrayList<>();
        for (String line : pass1) {
            String replaced = line;
            for (java.util.Map.Entry<String, String> e : subst.entrySet()) {
                String from = e.getKey();
                String to   = e.getValue();
                // ✨ 如果替換目標是整數字面值（如 "0"），且本指令含有指標型別關鍵字，
                //    則跳過此替換，避免把 i8* %tN 變成 i8* 0（LLVM IR 非法）
                if (to.matches("-?\\d+")) {
                    // ✨ 只在 token 出現於 i8* 指標值位置時才阻止，避免 store/add 等整數操作受波及
                    boolean isPointerCtx = replaced.contains("i8* " + from)
                            || replaced.contains("inttoptr") || replaced.contains("bitcast")
                            || replaced.contains("ptrtoint");
                    if (isPointerCtx) continue;
                }
                replaced = replaced.replaceAll(
                    "(?<![%\\w])" + java.util.regex.Pattern.quote(from) + "(?![\\w])",
                    to);
            }
            pass2.add(replaced);
        }

        return pass2;
    }

    // ── 依型別回傳正確的 LLVM alignment ──
    int getAlign(TypeInfo t) {
        if (t == TypeInfo.Double || t == TypeInfo.Long || t == TypeInfo.UnsignedLong || t == TypeInfo.Pointer) return 8;
        if (t == TypeInfo.Char || t == TypeInfo.UnsignedChar || t == TypeInfo.Boolean) return 1;
        if (t == TypeInfo.Short || t == TypeInfo.UnsignedShort) return 2;
        return 4; // Int, UnsignedInt, Float, Struct
    }
    int getAlign(String llvmT) {
        if (llvmT.equals("double") || llvmT.equals("i64")) return 8;
        if (llvmT.endsWith("*"))    return 8;
        if (llvmT.equals("i8"))     return 1;
        if (llvmT.equals("i16"))    return 2;
        return 4;
    }

    int alignUp(int value, int align) {
        return ((value + align - 1) / align) * align;
    }

    // ✨ 回傳某型別佔幾個 bytes（用於計算 memset 大小）
    int getLLVMTypeBytes(TypeInfo t) {
        if (t == TypeInfo.Double || t == TypeInfo.Long || t == TypeInfo.UnsignedLong || t == TypeInfo.Pointer) return 8;
        if (t == TypeInfo.Char || t == TypeInfo.UnsignedChar || t == TypeInfo.Boolean) return 1;
        if (t == TypeInfo.Short || t == TypeInfo.UnsignedShort) return 2;
        return 4; // Int, UnsignedInt, Float
    }

    // ✨ bit-field：計算某欄位的 bit offset（前面所有 bit-field 欄位的寬度總和）
    int bitFieldOffset(StructDef sdef, int fieldIdx) {
        int offset = 0;
        for (int i = 0; i < fieldIdx; i++) {
            int w = (i < sdef.bitWidths.size()) ? sdef.bitWidths.get(i) : -1;
            if (w > 0) offset += w;
        }
        return offset;
    }

    int sizeofType(TypeInfo t, String structName) {
        if (t == TypeInfo.Char || t == TypeInfo.UnsignedChar || t == TypeInfo.Boolean) return 1;
        if (t == TypeInfo.Short || t == TypeInfo.UnsignedShort) return 2;
        if (t == TypeInfo.Long || t == TypeInfo.UnsignedLong || t == TypeInfo.Double || t == TypeInfo.Pointer) return 8;
        if (t == TypeInfo.Struct) return sizeofStruct(structName);
        return 4; // Int, UnsignedInt, Float
    }
    
    // ── ✨ _Alignof 輔助函式：回傳型別的對齊需求（bytes）──
    int alignOf(TypeInfo t) {
        if (t == TypeInfo.Double || t == TypeInfo.Long || t == TypeInfo.UnsignedLong || t == TypeInfo.Pointer) return 8;
        if (t == TypeInfo.Short || t == TypeInfo.UnsignedShort) return 2;
        if (t == TypeInfo.Char || t == TypeInfo.UnsignedChar || t == TypeInfo.Boolean) return 1;
        return 4; // Int, UnsignedInt, Float
    }

    // ── ✨ 陣列邊界檢查輔助函式 ──
    // 靜態：索引為常數時編譯期警告；動態：索引為變數時插入執行期 icmp + br + abort block
    void emitBoundsCheck(int lineNum, String arrName, String idxTmp, boolean isConst, int iValue, int arraySize) {
        if (arraySize <= 0) return; // 大小未知（指標/VLA）→ 跳過
        if (isConst) {
            if (iValue < 0 || iValue >= arraySize) {
                System.err.println("Warning! " + lineNum + ": array index " + iValue
                    + " is out of bounds for '" + arrName + "' (size " + arraySize + ").");
            }
        } else {
            String okLabel  = newLabel("Lbounds_ok");
            String oobLabel = newLabel("Lbounds_oob");
            String chkTmp   = newTemp();
            addInstruction(chkTmp + " = icmp ult i32 " + idxTmp + ", " + arraySize);
            addInstruction("br i1 " + chkTmp + ", label %" + okLabel + ", label %" + oobLabel);
            addInstruction(oobLabel + ":");
            // ✨ 全域字串常數必須放到 stringDefs（頂層），不能用 addInstruction 放到函式 body 內
            String msgText = "Array out of bounds: " + arrName + " index %d, size " + arraySize;
            int msgLen = msgText.length() + 2; // +1 for \n, +1 for \0
            String msgGlobal = "@.oob_msg_" + (strCnt++);
            stringDefs.add(msgGlobal + " = private unnamed_addr constant [" + msgLen + " x i8] c\""
                + msgText + "\\0A\\00\", align 1");
            String msgPtr = newTemp();
            addInstruction(msgPtr + " = getelementptr inbounds [" + msgLen + " x i8], [" + msgLen + " x i8]* "
                + msgGlobal + ", i64 0, i64 0");
            addInstruction("call i32 (i8*, ...) @printf(i8* " + msgPtr + ", i32 " + idxTmp + ")");
            addInstruction("call void @abort()");
            addInstruction("unreachable");
            addInstruction(okLabel + ":");
        }
    }

    int sizeofStruct(String structName) {
        StructDef sdef = structRegistry.get(structName);
        if (sdef == null) return 4;
        // ✨ bit-field struct：整個打包成 i32 = 4 bytes
        if (sdef.hasBitFields) return 4;
        // ✨ FAM 欄位（[0 x T]）不計入 sizeof，與 GCC 行為一致
        int maxAlign = 1;
        for (int i = 0; i < sdef.fTypes.size(); i++) {
            int bw = (i < sdef.bitWidths.size()) ? sdef.bitWidths.get(i) : -1;
            TypeInfo ft = (bw == 0 && i < sdef.fPointeeTypes.size() && sdef.fPointeeTypes.get(i) != null)
                ? sdef.fPointeeTypes.get(i)
                : sdef.fTypes.get(i);
            int align = getAlign(ft);
            if (align > maxAlign) maxAlign = align;
        }
        
        // ✨ 新增：如果是 union，大小就是「最大成員的大小」
        if (sdef.isUnion) {
            int maxSize = 0;
            for (TypeInfo ft : sdef.fTypes) {
                int sz = sizeofType(ft, null);
                if (sz > maxSize) maxSize = sz;
            }
            return alignUp(maxSize, maxAlign);
        }
        
        int offset = 0;
        for (int i = 0; i < sdef.fTypes.size(); i++) {
            int bw = (i < sdef.bitWidths.size()) ? sdef.bitWidths.get(i) : -1;
            TypeInfo ft = (bw == 0 && i < sdef.fPointeeTypes.size() && sdef.fPointeeTypes.get(i) != null)
                ? sdef.fPointeeTypes.get(i)
                : sdef.fTypes.get(i);
            int align = getAlign(ft);
            offset = alignUp(offset, align);
            if (bw != 0) {
                int size = sizeofType(ft, null);
                offset += size;
            }
        }
        return alignUp(offset, maxAlign);
    }

    // ── Pass 1：Unreachable Code Elimination ──
    // terminator 之後、下一個 label 之前的指令全部移除
    List<String> eliminateUnreachable(List<String> instrs) {
        List<String> result = new ArrayList<>();
        boolean dead = false;
        for (String instr : instrs) {
            String t = instr.trim();

            // ── 永遠保留：函式框架結構 ──
            boolean isStructural = t.startsWith("define ") || t.equals("}") || t.isEmpty();
            // ── label 判斷：結尾是 ":" 且不含 "=" 和 "(" ──
            // 例如 "entry:" "then0:" "Luser_done0:" 但不是 "getelementptr inbounds ...:"
            boolean isLabel = !isStructural && t.endsWith(":")
                    && !t.contains("=") && !t.contains("(")
                    && t.indexOf(" ") == -1;

            if (isStructural || isLabel) {
                dead = false;
                result.add(instr);
                continue;
            }

            if (!dead) {
                result.add(instr);
            }

            // 遇到 terminator → 後面的同 block 指令是 dead
            if (t.startsWith("ret ") || t.startsWith("br ")
                    || t.startsWith("switch ") || t.equals("unreachable")) {
                dead = true;
            }
        }
        return result;
    }

    // ── Pass 2：Dead Store Elimination (含逃逸分析) ──
    List<String> eliminateDeadStores(List<String> instrs) {
        // 1. 收集所有 alloca ptr 名稱（形如 %t0 = alloca i32）
        java.util.Set<String> allocaPtrs = new java.util.LinkedHashSet<>();
        for (String instr : instrs) {
            String t = instr.trim();
            if (t.contains("= alloca")) {
                allocaPtrs.add(t.split("=")[0].trim());
            }
        }

        // ✨ 修正 1：逃逸分析 (Escape Analysis) ✨
        // 如果指標被當作數值存入另一個指標（例如 &x 存入 p），或者傳遞給函式、參與 GEP，
        // 則代表它「逃逸」了，我們必須放棄對它做 DSE，否則會誤刪它的初始化！
        java.util.Set<String> escapedPtrs = new java.util.HashSet<>();

        // ── Bug 3 修正：VLA 動態 alloca 的 size operand 追蹤 ──
        // 找出所有 "alloca T, i64 %tN" 中的 %tN，再往上追蹤到 load 的 src ptr，
        // 把那個 src ptr 標記為逃逸，防止 DSE 誤刪 VLA size 的 store。
        java.util.Map<String, String> tmpToSrcPtr = new java.util.HashMap<>();
        for (String instr : instrs) {
            String t = instr.trim();
            // 收集 load 指令：%tN = load TYPE, TYPE* %ptr
            if (t.matches("%t\\d+ = load .+, .+\\* %t\\d+.*")) {
                String[] parts = t.split(",");
                if (parts.length >= 2) {
                    String lhsTmp = t.split(" = ")[0].trim();
                    String srcPart = parts[1].trim(); // e.g. "i32* %t5, align 4"
                    java.util.regex.Matcher pm = java.util.regex.Pattern.compile("%t\\d+").matcher(srcPart);
                    if (pm.find()) tmpToSrcPtr.put(lhsTmp, pm.group());
                }
            }
        }
        for (String instr : instrs) {
            String t = instr.trim();
            // 找 VLA alloca: "... = alloca T, i64 %tN" 或含 i64 size 的 alloca
            if (t.contains("= alloca ") && t.contains(", i64 ")) {
                java.util.regex.Matcher am = java.util.regex.Pattern.compile("i64 (%t\\d+)").matcher(t);
                if (am.find()) {
                    String sizeTmp = am.group(1);
                    // sizeTmp 可能是 sext 的結果；再往上找 sext 的 src
                    for (String instr2 : instrs) {
                        String t2 = instr2.trim();
                        if (t2.startsWith(sizeTmp + " = sext ")) {
                            java.util.regex.Matcher sm = java.util.regex.Pattern.compile("%t\\d+").matcher(t2.split(" = sext ")[1]);
                            if (sm.find()) {
                                String loadTmp = sm.group();
                                String srcPtr = tmpToSrcPtr.get(loadTmp);
                                if (srcPtr != null) escapedPtrs.add(srcPtr);
                            }
                        }
                    }
                    // sizeTmp 本身也可能直接是 load 的結果
                    String directSrc = tmpToSrcPtr.get(sizeTmp);
                    if (directSrc != null) escapedPtrs.add(directSrc);
                }
            }
        }
        for (String instr : instrs) {
            String t = instr.trim();
            for (String ptr : allocaPtrs) {
                // 如果 ptr 出現在 store 的 value 位置 (e.g., store ty PTR, ty* dest)
                if (t.startsWith("store ")) {
                    String[] parts = t.split(", ");
                    if (parts.length > 0 && parts[0].endsWith(" " + ptr)) {
                        escapedPtrs.add(ptr);
                    }
                }
                // 參與 GEP 或 function call 也算逃逸
                else if (t.contains("getelementptr ") && t.contains(ptr)) {
                    escapedPtrs.add(ptr);
                }
                else if (t.contains("call ") && t.contains(" " + ptr)) {
                    escapedPtrs.add(ptr);
                }
            }
        }

        java.util.Set<Integer> deadStoreIdx = new java.util.HashSet<>();
        for (String ptr : allocaPtrs) {
            if (escapedPtrs.contains(ptr)) continue; // 逃逸的變數，直接跳過 DSE 保平安！

            int lastStoreIdx = -1;
            boolean loadSeen = false;
            for (int i = 0; i < instrs.size(); i++) {
                String t = instrs.get(i).trim();
                
                // ✨ 修正 2：精準切割匹配，防止字串誤判 ✨
                if (t.startsWith("store ")) {
                    String[] parts = t.split(", "); // 切割後 parts[1] 必定是 "i32* %t0"
                    if (parts.length >= 2 && parts[1].endsWith("* " + ptr)) {
                        if (lastStoreIdx >= 0 && !loadSeen) {
                            deadStoreIdx.add(lastStoreIdx); // 覆蓋前沒有 load，刪掉舊的
                        }
                        lastStoreIdx = i;
                        loadSeen = false;
                    }
                } else if (t.contains("load ")) {
                    String[] parts = t.split(", ");
                    if (parts.length >= 2 && parts[1].endsWith("* " + ptr)) {
                        loadSeen = true;
                    }
                } else if (t.endsWith(":") && !t.contains("=")) {
                    lastStoreIdx = -1; // 跨 block 保守重置
                    loadSeen = false;
                }
            }
            
            // 檢查是否完全沒有 load 過
            boolean anyLoad = false;
            for (String instr : instrs) {
                String t = instr.trim();
                if (t.contains("load ")) {
                    String[] parts = t.split(", ");
                    if (parts.length >= 2 && parts[1].endsWith("* " + ptr)) {
                        anyLoad = true; break;
                    }
                }
            }
            
            if (!anyLoad && lastStoreIdx >= 0) {
                // 完全沒 load 過，保留最後一個 store
            } else if (lastStoreIdx >= 0 && !loadSeen) {
                deadStoreIdx.add(lastStoreIdx);
            }
        }

        List<String> result = new ArrayList<>();
        for (int i = 0; i < instrs.size(); i++) {
            if (!deadStoreIdx.contains(i)) {
                result.add(instrs.get(i));
            }
        }
        return result;
    }
    // ── Pass 3：Trivial Dead Assignment Elimination ──
    // %tN = <純計算指令> 若 %tN 從未被使用 → 移除
    // refInstrs：用於掃描 usedTemps 的基準指令集（通常是 DSE 之前的完整集合）
    List<String> eliminateTrivialDeadAssignments(List<String> instrs, List<String> refInstrs) {
        // 先收集所有被使用的 tmp（從 refInstrs 掃描，防止 DSE 刪除 store 後級聯誤刪）
        java.util.Set<String> usedTemps = new java.util.HashSet<>();
        java.util.regex.Pattern usePattern = java.util.regex.Pattern.compile("%t(\\d+)");
        // 也收集每個 assignment 的 lhs（從 instrs 掃描，只刪當前還存在的指令）
        java.util.Map<String, Integer> assignedAt = new java.util.HashMap<>();

        // 用 refInstrs 掃描所有被 use 的 tmp
        for (int i = 0; i < refInstrs.size(); i++) {
            String t = refInstrs.get(i).trim();
            java.util.regex.Matcher m = usePattern.matcher(t);
            boolean firstMatch = true;
            String lhs = null;
            if (t.matches("%t\\d+ = .*")) {
                lhs = t.split(" = ")[0].trim();
            }
            while (m.find()) {
                String tmp = m.group(0);
                if (firstMatch && lhs != null && tmp.equals(lhs)) {
                    firstMatch = false;
                    continue;
                }
                usedTemps.add(tmp);
            }
        }

        // 用 instrs（DSE 後）收集 assignedAt
        for (int i = 0; i < instrs.size(); i++) {
            String t = instrs.get(i).trim();
            if (t.matches("%t\\d+ = .*")) {
                String lhs = t.split(" = ")[0].trim();
                assignedAt.put(lhs, i);
            }
        }

        // 純計算指令（無副作用）的前綴
        java.util.Set<String> pureOps = new java.util.HashSet<>(java.util.Arrays.asList(
            "add ", "sub ", "mul ", "sdiv ", "srem ",
            "fadd ", "fsub ", "fmul ", "fdiv ",
            "icmp ", "fcmp ",
            "sext ", "zext ", "trunc ", "sitofp ", "fptosi ", "fpext ", "fptrunc ",
            "and ", "or ", "xor ", "shl ", "lshr ", "ashr ",
            "getelementptr "
        ));

        java.util.Set<Integer> deadIdx = new java.util.HashSet<>();
        for (java.util.Map.Entry<String, Integer> e : assignedAt.entrySet()) {
            String tmp = e.getKey();
            int idx = e.getValue();
            if (usedTemps.contains(tmp)) continue;
            // 確認是純計算指令
            String instrBody = instrs.get(idx).trim();
            String rhs = instrBody.contains(" = ") ? instrBody.split(" = ", 2)[1].trim() : "";
            boolean isPure = false;
            for (String op : pureOps) {
                if (rhs.startsWith(op)) { isPure = true; break; }
            }
            if (isPure) {
                deadIdx.add(idx);
            }
        }

        List<String> result = new ArrayList<>();
        for (int i = 0; i < instrs.size(); i++) {
            if (!deadIdx.contains(i)) result.add(instrs.get(i));
        }
        return result;
    }

    // ══════════════════════════════════════════════
    // CSE（Common Subexpression Elimination）
    // key 格式："op|type|lhs|rhs"  value：已計算的 tmp 名稱
    // 每次進入新的 basic block（if/while/for body）時重置，
    // 確保不跨 branch 做不安全的消除
    // ══════════════════════════════════════════════
    HashMap<String, String> cseTable = new HashMap<>();

    // 嘗試 CSE：若相同運算已算過則回傳舊 tmp，否則 null
    String cseLookup(String op, String type, String l, String r) {
        String key = op + "|" + type + "|" + l + "|" + r;
        return cseTable.get(key);
    }
    // 登記 CSE 結果
    void cseRegister(String op, String type, String l, String r, String tmp) {
        String key = op + "|" + type + "|" + l + "|" + r;
        cseTable.put(key, tmp);
        // 交換律：加法/乘法/比較 == != 也登記對稱 key
        if (op.equals("add") || op.equals("fadd") || op.equals("mul") || op.equals("fmul")
            || op.equals("icmp eq") || op.equals("icmp ne") || op.equals("fcmp oeq") || op.equals("fcmp one")) {
            String symKey = op + "|" + type + "|" + r + "|" + l;
            cseTable.putIfAbsent(symKey, tmp);
        }
    }
    // 進入新的 basic block 時重置（避免跨分支使用）
    void cseReset() { cseTable.clear(); }

    void beginUnevaluatedExpression() {
        pushBuffer();
        cseReset();
    }

    void endUnevaluatedExpression() {
        popBuffer();
        cseReset();
    }

    // ══════════════════════════════════════════════
    // LICM（Loop-Invariant Code Motion）
    // 策略：對 while/for 的 body IR 做靜態分析：
    //   1. 收集 body 內所有 store 的目標 ptr（被修改的變數集合）
    //   2. 掃描每一條純計算指令：若其所有操作數都不在「被修改集合」中，
    //      且自身也不是 store/br/call/ret，即為 loop-invariant。
    //   3. 把這些指令提前到 preheader（loop 之前），body 裡只留一個 use。
    // 回傳值：hoisted = 要提到 preheader 的指令；body = 剩餘的 body 指令
    // ══════════════════════════════════════════════
    static class LICMResult {
        List<String> hoisted;
        List<String> body;
        LICMResult(List<String> h, List<String> b) { hoisted = h; body = b; }
    }

    // ✨ 參數新增 updateIR (for迴圈專用，while傳null即可)
    LICMResult applyLICM(List<String> bodyIR, List<String> updateIR) {
        // Step 1: 收集所有在迴圈內被 store 修改的 ptr（左值）
        java.util.Set<String> modifiedPtrs = new java.util.LinkedHashSet<>();

        java.util.regex.Pattern storePtrPat = java.util.regex.Pattern
            .compile("store\\s+\\S+\\s+\\S+,\\s*[\\w\\[\\] *.%]+\\*+\\s+(%[\\w.]+|@[\\w.]+)");

        List<String> allBodyIR = new java.util.ArrayList<>(bodyIR);
        if (updateIR != null) allBodyIR.addAll(updateIR);

        for (String instr : allBodyIR) {
            String t = instr.trim();
            if (t.startsWith("store ")) {
                java.util.regex.Matcher sm = storePtrPat.matcher(t);
                if (sm.find()) modifiedPtrs.add(sm.group(1));
            }
        }

        // ── 修正：call 指令中任何「指標型別」的引數，都視為可能被該呼叫修改 ──
        // 例如 scanf("%d", i32* %t1)、fscanf、sscanf 等函式會透過指標寫回變數，
        // 但本身不是 store 指令，因此 Step 1 的 store 掃描無法偵測到。
        // 保守處理：只要該 %tN/alloca 以「<type>* %name」形式出現在 call 的引數列表中，
        // 即視為該 ptr 在迴圈內被修改，避免其 load 結果被誤判為 loop-invariant 而外提。
        java.util.regex.Pattern callPtrArgPat = java.util.regex.Pattern
            .compile("[\\w\\[\\] *.%]+\\*+\\s*(%[\\w.]+)");
        for (String instr : allBodyIR) {
            String t = instr.trim();
            if (t.contains("call ")) {
                // 只看 call 之後的引數部分，避免誤判 call 結果本身的型別
                int callIdx = t.indexOf("call ");
                String afterCall = t.substring(callIdx);
                java.util.regex.Matcher cm = callPtrArgPat.matcher(afterCall);
                while (cm.find()) {
                    modifiedPtrs.add(cm.group(1));
                }
            }
        }

        // ── 修正：透過 GEP 間接 store 也算「修改」──
        // 若某個 %tN 是 GEP 結果且被 store 寫入，則 GEP 的所有 %tX 操作數都視為被修改，
        // 否則依賴這些 %tX 的 load 會被誤判為 loop-invariant 而外提。
        //
        // 同理：若 GEP 的 struct base 來自一個 load（load 了一個指標），
        // 那個指標的 alloca（以及之後衍生的 load/GEP）也不應外提。
        //
        // 實作：把「被 store 的 GEP 結果」的 RHS 中所有 %tX 都加入 modifiedPtrs，
        //       並重複傳播，直到不再有新增。
        java.util.Map<String, String> tmpDef = new java.util.HashMap<>(); // %tN -> RHS
        for (String instr : allBodyIR) {
            String t = instr.trim();
            if (t.matches("%t\\d+ = .*")) {
                String lhs = t.split(" = ")[0].trim();
                String rhs = t.split(" = ", 2)[1].trim();
                tmpDef.put(lhs, rhs);
            }
        }
        boolean gepChanged = true;
        while (gepChanged) {
            gepChanged = false;
            for (String ptr : new java.util.ArrayList<>(modifiedPtrs)) {
                String rhs = tmpDef.get(ptr);
                if (rhs == null) continue;
                if (rhs.startsWith("getelementptr ") || rhs.startsWith("load ") || rhs.startsWith("bitcast ")) {
                    java.util.regex.Matcher mm = java.util.regex.Pattern.compile("%t\\d+").matcher(rhs);
                    while (mm.find()) {
                        if (modifiedPtrs.add(mm.group())) gepChanged = true;
                    }
                }
            }
        }

        // Step 2: 定義所有「純計算」且允許外提的指令
        // ✨ 關鍵修正：移除 "load " 和 "getelementptr "，改在 Step 3 精準判斷
        java.util.Set<String> pureOpsLICM = new java.util.HashSet<>(java.util.Arrays.asList(
            "add ", "sub ", "mul ", "sdiv ", "srem ",
            "fadd ", "fsub ", "fmul ", "fdiv ",
            "icmp ", "fcmp ",
            "sext ", "zext ", "trunc ", "sitofp ", "fptosi ", "fpext ", "fptrunc ",
            "and ", "or ", "xor ", "shl ", "lshr ", "ashr ",
            "bitcast ", "ptrtoint ", "inttoptr "
        ));

        java.util.Set<String> variantTmps = new java.util.LinkedHashSet<>();

        // Step 3: 初始化 variantTmps
        for (String instr : bodyIR) {
            String t = instr.trim();
            if (!t.matches("%t\\d+ = .*")) continue;
            String lhs = t.split(" = ")[0].trim();
            String rhs = t.split(" = ", 2)[1].trim();

            boolean isPure = false;
            for (String op : pureOpsLICM) {
                if (rhs.startsWith(op)) { isPure = true; break; }
            }

            if (rhs.startsWith("getelementptr ")) {
                // GEP：若任一操作數 %tX 在 modifiedPtrs 裡，則此 GEP 結果也是 variant
                boolean gepVariant = false;
                java.util.regex.Matcher gm = java.util.regex.Pattern.compile("%t\\d+").matcher(rhs);
                while (gm.find()) {
                    if (modifiedPtrs.contains(gm.group())) { gepVariant = true; break; }
                }
                if (gepVariant || modifiedPtrs.contains(lhs)) variantTmps.add(lhs);
          } else if (rhs.startsWith("load ")) {
                java.util.regex.Matcher loadM = java.util.regex.Pattern
                    .compile(",\\s*[\\w\\[\\] *%.]+\\*+\\s+(%[\\w.]+|@[\\w.]+)")
                    .matcher(rhs);
                if (loadM.find()) {
                    String srcPtr = loadM.group(1);
                    // ✅ 修正：同時檢查 modifiedPtrs 和 variantTmps
                    if (modifiedPtrs.contains(srcPtr) || variantTmps.contains(srcPtr)) {
                        variantTmps.add(lhs);
                    }
                } else {
                    variantTmps.add(lhs);
                }
            } else if (!isPure) {
                variantTmps.add(lhs);
            }
        }

        // Step 4: 傳播變動性（只要依賴到 variantTmps 中的變數，自己也是變動的）
        boolean changed = true;
        while (changed) {
            changed = false;
            for (String instr : bodyIR) {
                String t = instr.trim();
                if (!t.matches("%t\\d+ = .*")) continue;
                String lhs = t.split(" = ")[0].trim();
                if (variantTmps.contains(lhs)) continue;

                java.util.regex.Matcher m = java.util.regex.Pattern.compile("%t\\d+").matcher(t);
                boolean isRhs = false;
                int firstEnd = t.indexOf(" = ");
                while (m.find()) {
                    if (m.start() > firstEnd) {
                        if (variantTmps.contains(m.group(0))) { isRhs = true; break; }
                    }
                }
                if (isRhs) {
                    variantTmps.add(lhs);
                    changed = true;
                }
            }
        }

        // Step 5: 根據 variantTmps 分離 hoisted 和 remaining
        List<String> hoisted = new ArrayList<>();
        List<String> remaining = new ArrayList<>();
        for (String instr : bodyIR) {
            String t = instr.trim();
            if (t.matches("%t\\d+ = .*")) {
                String lhs = t.split(" = ")[0].trim();
                if (!variantTmps.contains(lhs)) {
                    hoisted.add(instr);
                    continue;
                }
            }
            remaining.add(instr);
        }
        return new LICMResult(hoisted, remaining);
    }

    // ══════════════════════════════════════════════════════════════════
    // ✨ Loop Unrolling：常數次數小迴圈展開
    //
    // 條件（全部滿足才展開）：
    //   1. 迴圈次數可在編譯期確定（init / cond / update 均為常數形式）
    //   2. 展開後總指令數 ≦ UNROLL_THRESHOLD（預設 128）
    //   3. body 中無 break / continue / return / call（遞迴安全）
    //
    // 支援形式：for (int i = init; i < / <= / != bound; i++ / i += step)
    // 展開方式：直接複製 bodyIR N 次，以常數替換迴圈變數讀取，
    //           移除 br label %cond / bodyLabel / updateLabel 的跳轉。
    // ══════════════════════════════════════════════════════════════════
    static final int UNROLL_THRESHOLD = 128;  // 展開後最大指令數

    static class UnrollInfo {
        boolean canUnroll;
        String  iterVar;   // alloca ptr of loop var（如 %t0）
        int     initVal;
        int     boundVal;
        int     step;
        String  cmpOp;     // "lt" / "le" / "ne"
    }

    // 分析 forStatement 的 init / cond / update IR，回傳 UnrollInfo
    // ── analyzeForUnroll 修正版 ──
    // Fix D：initIR 可能含多個 alloca+store（如 int i=0 以外還有其他宣告）。
    //         必須先找 alloca，再找對應同一 ptr 的 store，才能確定是 for-var。
    // Fix E：condIR 中 icmp 的操作數必須追溯到 load %iterPtr 的 tmp，
    //         若 condIR 有多個 icmp（巢狀條件），只取來自 iterPtr 的那個。
    // Fix F：updateIR 的 step 必須是對 iterPtr 做 add 再 store 回去，
    //         純粹抓第一個 add 常數可能誤判其他 += 運算。
    UnrollInfo analyzeForUnroll(List<String> initIR, List<String> condIR,
                                List<String> updateIR, List<String> bodyIR) {
        UnrollInfo ui = new UnrollInfo();
        ui.canUnroll = false;

        // ── 1. Fix D：從 initIR 精確識別 for-var 的 alloca ptr ──
        // 步驟：找所有 alloca i32 → 得到候選 ptr 集合
        //       再找 store i32 <const>, i32* <ptr> → 只取 ptr 在候選集中的
        //       若有多個，取最後一個（for-var 通常是 initIR 最後宣告的）
        java.util.Set<String> allocaPtrs = new java.util.LinkedHashSet<>();
        java.util.regex.Matcher mAlloca = java.util.regex.Pattern
            .compile("(%t\\d+)\\s*=\\s*alloca i32").matcher(String.join("\n", initIR));
        while (mAlloca.find()) allocaPtrs.add(mAlloca.group(1));
        if (allocaPtrs.isEmpty()) return ui;

        String iterPtr = null; int initVal = Integer.MIN_VALUE;
        java.util.regex.Matcher mStore = java.util.regex.Pattern
            .compile("store i32 (-?\\d+),\\s*i32\\*\\s*(%t\\d+)").matcher(String.join("\n", initIR));
        while (mStore.find()) {
            String candidate = mStore.group(2);
            if (allocaPtrs.contains(candidate)) {
                initVal = Integer.parseInt(mStore.group(1));
                iterPtr = candidate;
                // 繼續找，取最後一個（最靠近 ';' 的 for-var）
            }
        }
        if (iterPtr == null) return ui;

        // ── 2. Fix E：condIR 中找到 load %iterPtr → 再找以該 tmp 為操作數的 icmp ──
        String condIRStr = String.join("\n", condIR);

        // 先找 load %iterPtr 的 tmp 名稱
        java.util.regex.Matcher mLoadCond = java.util.regex.Pattern
            .compile("(%t\\d+)\\s*=\\s*load i32,\\s*i32\\*\\s*"
                     + java.util.regex.Pattern.quote(iterPtr) + "(?:\\s*,.*)?")
            .matcher(condIRStr);
        if (!mLoadCond.find()) return ui;
        String loadedIterTmp = mLoadCond.group(1);  // e.g. "%t5"

        // 再找以 loadedIterTmp 為左操作數的 icmp
        String cmpOp = null; int boundVal = Integer.MIN_VALUE;
        java.util.regex.Matcher mCond = java.util.regex.Pattern
            .compile("icmp s?(lt|le|eq|ne) i32 "
                     + java.util.regex.Pattern.quote(loadedIterTmp) + ",\\s*(-?\\d+)")
            .matcher(condIRStr);
        if (!mCond.find()) return ui;
        cmpOp = mCond.group(1); boundVal = Integer.parseInt(mCond.group(2));

        // ── 3. Fix F：updateIR 中找 load %iterPtr → add K → store 回 %iterPtr ──
        // 必須同時滿足：load 來自 iterPtr，add 用了該 tmp，store 目標也是 iterPtr
        String updateIRStr = String.join("\n", updateIR);
        java.util.regex.Matcher mLoadUpd = java.util.regex.Pattern
            .compile("(%t\\d+)\\s*=\\s*load i32,\\s*i32\\*\\s*"
                     + java.util.regex.Pattern.quote(iterPtr) + "(?:\\s*,.*)?")
            .matcher(updateIRStr);
        if (!mLoadUpd.find()) return ui;
        String loadedUpdTmp = mLoadUpd.group(1);

        java.util.regex.Matcher mAdd = java.util.regex.Pattern
            .compile("(%t\\d+)\\s*=\\s*add\\s+(?:nsw\\s+)?i32 "
                     + java.util.regex.Pattern.quote(loadedUpdTmp) + ",\\s*(-?\\d+)")
            .matcher(updateIRStr);
        if (!mAdd.find()) return ui;
        int step = Integer.parseInt(mAdd.group(2));
        String addResultTmp = mAdd.group(1);

        // 確認 add 結果確實 store 回 iterPtr
        java.util.regex.Matcher mStoreBack = java.util.regex.Pattern
            .compile("store i32 " + java.util.regex.Pattern.quote(addResultTmp)
                     + ",\\s*i32\\*\\s*" + java.util.regex.Pattern.quote(iterPtr))
            .matcher(updateIRStr);
        if (!mStoreBack.find()) return ui;

        // ── 4. 計算迴圈次數 ──
        int count = 0; int cur = initVal;
        while (true) {
            boolean cond;
            if      (cmpOp.equals("lt")) cond = cur < boundVal;
            else if (cmpOp.equals("le")) cond = cur <= boundVal;
            else if (cmpOp.equals("ne")) cond = cur != boundVal;
            else break;
            if (!cond) break;
            count++; cur += step;
            if (count > UNROLL_THRESHOLD) return ui;
        }
        if (count == 0) return ui;

        // ── 5. body 安全性檢查 ──
        String bodyStr = String.join("\n", bodyIR);
        if (bodyStr.contains("call ") || bodyStr.contains("ret ")
            || bodyStr.contains("br label %Lfor_end")
            || bodyStr.contains("br label %Lfor_update")) {
            return ui;
        }

        ui.canUnroll = true; ui.iterVar = iterPtr;
        ui.initVal = initVal; ui.boundVal = boundVal;
        ui.step = step; ui.cmpOp = cmpOp;
        return ui;
    }

    // 展開 body N 次，以常數 i 替換每次迭代的迴圈變數 load
    // ── doUnroll：安全展開，三個關鍵修正 ──
    // Fix A：迴圈變數的 load 以常數取代，store 到 iterPtr 的指令整行刪除
    //         （避免 store i32 %t_iter, i32* iterPtr 殘留且指標被誤替換）
    // Fix B：所有 %tN 引用改用 regex \\b 邊界取代，防止 %t1→"1" 後
    //         後續 replace 把無關的 "1" 再度污染（如 i32* 1 變成合法 store 目標）
    // Fix C：iterPtr 本身（i32* 指標）不加入 remap，只刪除對它的 store 與 load
    List<String> doUnroll(UnrollInfo ui, List<String> bodyIR) {
        List<String> result = new ArrayList<>();

        // 預編譯：比對 "load i32, i32* %iterPtr" 的整行
        java.util.regex.Pattern loadIterPat = java.util.regex.Pattern
            .compile("(%t\\d+)\\s*=\\s*load i32,\\s*i32\\*\\s*"
                     + java.util.regex.Pattern.quote(ui.iterVar) + "(?:\\s*,.*)?$");
        // 預編譯：比對 "store i32 ..., i32* %iterPtr" 的整行（迭代自增產生的 store）
        java.util.regex.Pattern storeIterPat = java.util.regex.Pattern
            .compile("store i32\\s+\\S+,\\s*i32\\*\\s*"
                     + java.util.regex.Pattern.quote(ui.iterVar) + "(?:\\s*,.*)?$");

        int cur = ui.initVal;
        int iterCount = 0;
        while (true) {
            boolean cond;
            if      (ui.cmpOp.equals("lt")) cond = cur < ui.boundVal;
            else if (ui.cmpOp.equals("le")) cond = cur <= ui.boundVal;
            else if (ui.cmpOp.equals("ne")) cond = cur != ui.boundVal;
            else break;
            if (!cond) break;

            final String iterConst = String.valueOf(cur);

            // remap：%tN(old_lhs) → %tN(new_lhs)  或  %tN(iter_load) → "iterConst"
            // Fix B：value 若為常數，以特殊 sentinel 標記避免二次污染
            java.util.Map<String, String> remap = new java.util.LinkedHashMap<>();
            List<String> iterBody = new ArrayList<>();

            // ── Pass 1：掃描 body，決定每行的命運 ──
            for (String rawInstr : bodyIR) {
                String instr = rawInstr.trim();

                // (i) "load i32, i32* %iterPtr" → 不輸出，記 tmp → iterConst
                java.util.regex.Matcher lm = loadIterPat.matcher(instr);
                if (lm.find()) {
                    remap.put(lm.group(1), iterConst);
                    continue;
                }

                // (ii) "store i32 ..., i32* %iterPtr" → 不輸出（update 的 store，展開後無意義）
                java.util.regex.Matcher sm = storeIterPat.matcher(instr);
                if (sm.find()) {
                    continue;  // Fix A：直接跳過，不讓 iterPtr 指標被當成 store 目標殘留
                }

                // (iii) 其他定義指令：重新命名 LHS %tN，避免 SSA 衝突
                java.util.regex.Matcher defM = java.util.regex.Pattern
                    .compile("^(%t\\d+)\\s*=\\s*").matcher(instr);
                String outLine = rawInstr;
                if (defM.find()) {
                    String oldTmp = defM.group(1);
                    String freshTmp = newTemp();
                    remap.put(oldTmp, freshTmp);
                    // 替換 LHS（精確匹配 " = " 前的 %tN）
                    outLine = rawInstr.replace(oldTmp + " = ", freshTmp + " = ");
                }
                iterBody.add(outLine);
            }

            // ── Pass 2：將 remap 套用到 iterBody 的 RHS ──
            // Fix B：用 regex 詞邊界替換，防止 %t1 → "1" 後污染其他含 "1" 的字面值
            // 按 key 長度遞減排序（%t10 先於 %t1），確保不短路長 key
            List<String> sortedKeys = new ArrayList<>(remap.keySet());
            sortedKeys.sort((a, b2) -> Integer.compare(b2.length(), a.length()));

            for (String line : iterBody) {
                String out = line;
                for (String k : sortedKeys) {
                    String v = remap.get(k);
                    // Fix B 核心：用 Pattern.quote(k) + 負向 lookahead \\d 替換
                    // 確保 %t1 不會誤中 %t10、%t11、%t12...
                    String safeK = java.util.regex.Pattern.quote(k) + "(?!\\d)";
                    out = out.replaceAll(safeK, java.util.regex.Matcher.quoteReplacement(v));
                }
                result.add(out);
            }
            cur += ui.step;
            iterCount++;
        }
        result.add("; [loop-unrolled x" + iterCount + "]");
        return result;
    }

    // ══════════════════════════════════════════════════════════════════
    // GCP（Global Constant Propagation）跨 basic block 常數傳播
    //
    // 演算法（稀疏條件常數傳播簡化版）：
    //   1. 掃描每個函式的全部 IR，收集每個 alloca ptr 的「已知常數值」。
    //      規則：若某個 ptr 所有可到達的 store 都 store 同一個常數，
    //            則該 ptr 為「全域常數」。
    //   2. 將後續所有 load 該 ptr 的指令，替換成常數直接使用。
    //   3. 被替換的 load 指令刪除。
    //   4. 保守性：任何 call 指令出現、或 ptr 發生 store 的地方有控制流匯合
    //      點前有條件 store，則放棄對該 ptr 傳播（標記為 Bottom/unknown）。
    //
    // 注意：此 pass 在 DCE 之後執行，結果回傳給 peephole。
    // ══════════════════════════════════════════════════════════════════
    List<String> applyGCP(List<String> instrs) {
        // Step 1：收集每個函式邊界，找出各個 alloca ptr 的常數值
        // key = ptr name (e.g. "%t3"), value = 常數字串 或 null（不確定/多值）
        java.util.Map<String, String> constMap = new java.util.LinkedHashMap<>();
        // 用 "__MULTI__" 標記「已確認多值，不可傳播」
        final String MULTI = "__MULTI__";
        // 用 "__ESCAPE__" 標記「逃逸或被 call 汙染」
        final String ESCAPE = "__ESCAPE__";

        // 先掃一遍，建立 constMap
        java.util.Set<String> allocaPtrs = new java.util.LinkedHashSet<>();
        for (String raw : instrs) {
            String t = raw.trim();
            if (t.contains("= alloca") && !t.contains("alloca [") && !t.contains(", i64")) {
                // 純量 alloca（非陣列、非 VLA）
                String ptr = t.split(" = ")[0].trim();
                allocaPtrs.add(ptr);
                constMap.put(ptr, null); // null = 尚未見過任何 store
            }
        }

        // 掃 store 指令以填入 constMap
        java.util.regex.Pattern storePat = java.util.regex.Pattern.compile(
            "store\\s+(i\\d+|float|double)\\s+(-?[\\d.e+\\-]+|true|false|null),\\s*\\S+\\s+(%.+),");
        for (String raw : instrs) {
            String t = raw.trim();
            // 指標逃逸（ptr 出現在 call 的參數，或作為 store 的值）
            for (String ptr : allocaPtrs) {
                if (t.startsWith("call ") && t.contains(" " + ptr)) {
                    constMap.put(ptr, ESCAPE);
                }
                // store PTR to somewhere = ptr 逃逸
                if (t.startsWith("store ")) {
                    String[] parts2 = t.split(",");
                    if (parts2.length > 0 && parts2[0].trim().endsWith(" " + ptr)) {
                        constMap.put(ptr, ESCAPE);
                    }
                }
            }
            // store 常數到 ptr
            if (t.startsWith("store ")) {
                java.util.regex.Matcher sm = storePat.matcher(t);
                if (sm.find()) {
                    // parts: "store TYPE VAL, TYPE* PTR, align N"
                    String[] parts3 = t.split(",");
                    if (parts3.length >= 2) {
                        String valPart = parts3[0].trim(); // "store TYPE VAL"
                        String ptrPart = parts3[1].trim(); // "TYPE* PTR"
                        String[] valTokens = valPart.split("\\s+");
                        String storeVal = valTokens[valTokens.length - 1];
                        String[] ptrTokens = ptrPart.split("\\s+");
                        String storePtr = ptrTokens[ptrTokens.length - 1];
                        // storeVal 必須是純數字/boolean/null 才算常數
                        boolean isLiteralConst = storeVal.matches("-?[0-9][0-9.e+\\-]*|true|false|null");
                        if (allocaPtrs.contains(storePtr)) {
                            String cur = constMap.get(storePtr);
                            if (cur == null) {
                                // 第一次看到 store
                                constMap.put(storePtr, isLiteralConst ? storeVal : MULTI);
                            } else if (!cur.equals(ESCAPE) && !cur.equals(MULTI)) {
                                // 已有值：若相同則保留，否則標 MULTI
                                if (!cur.equals(storeVal) || !isLiteralConst) {
                                    constMap.put(storePtr, MULTI);
                                }
                            }
                        }
                    }
                } else {
                    // store 的值不是字面常數（是 %tN）→ 標記 MULTI
                    String[] parts4 = t.split(",");
                    if (parts4.length >= 2) {
                        String ptrPart = parts4[1].trim();
                        String[] ptrTokens = ptrPart.split("\\s+");
                        String storePtr = ptrTokens[ptrTokens.length - 1];
                        if (allocaPtrs.contains(storePtr)) {
                            String cur = constMap.get(storePtr);
                            if (cur == null || (!cur.equals(ESCAPE) && !cur.equals(MULTI))) {
                                constMap.put(storePtr, MULTI);
                            }
                        }
                    }
                }
            }
        }

        // Step 2：收集「確實為全域常數」的 ptr → constVal 對應
        java.util.Map<String, String> gcpMap = new java.util.LinkedHashMap<>();
        for (java.util.Map.Entry<String, String> e : constMap.entrySet()) {
            String v = e.getValue();
            if (v != null && !v.equals(MULTI) && !v.equals(ESCAPE)) {
                gcpMap.put(e.getKey(), v);
            }
        }

        if (gcpMap.isEmpty()) return instrs; // 沒有可傳播的常數，直接回傳

        // Step 3：替換 load 指令並刪除被替換的 load
        // 同時追蹤新 tmp → 常數值，以便後續指令也能受益
        java.util.Map<String, String> loadSubst = new java.util.LinkedHashMap<>();
        List<String> result = new java.util.ArrayList<>();

        java.util.regex.Pattern loadPat = java.util.regex.Pattern.compile(
            "(%t\\d+)\\s*=\\s*load\\s+(i\\d+|float|double),\\s*\\S+\\s+(%t\\d+),");

        for (String raw : instrs) {
            String t = raw.trim();
            // 替換已知 load-subst token（前面輪次傳播下來的）
            String replaced = t;
            for (java.util.Map.Entry<String, String> e : loadSubst.entrySet()) {
                replaced = replaced.replaceAll(
                    "(?<![%\\w])" + java.util.regex.Pattern.quote(e.getKey()) + "(?![\\w])",
                    e.getValue());
            }

            // 嘗試匹配 load 指令
            java.util.regex.Matcher lm = loadPat.matcher(replaced);
            if (lm.find()) {
                String lhsTmp = lm.group(1);
                String srcPtr = lm.group(3);
                if (gcpMap.containsKey(srcPtr)) {
                    String constVal2 = gcpMap.get(srcPtr);
                    // 記錄這個 load result → 常數，供後續指令替換
                    loadSubst.put(lhsTmp, constVal2);
                    // 刪除 load 指令（用 comment 留 trace，方便 debug）
                    result.add("; GCP: " + lhsTmp + " = " + constVal2 + " (propagated from " + srcPtr + ")");
                    continue;
                }
            }
            result.add(replaced.equals(t) ? raw : replaced); // 保持原始縮排
        }
        return result;
    }
    // ── ✨ 複合字面值元素收集 stack（供 clInitElem 規則與 primaryExpression 共用）──
    java.util.Deque<java.util.List<Info>> clLiteralStack = new java.util.ArrayDeque<>();

    boolean isCast() {
        org.antlr.v4.runtime.TokenStream ts = getTokenStream();
        if (ts.LA(2) == org.antlr.v4.runtime.Recognizer.EOF) return false;
        String next = ts.LT(2).getText(); // 偷看括號裡面的字
        return next.equals("int") || next.equals("float") || next.equals("double") ||
               next.equals("char") || next.equals("void") || next.equals("bool") ||
               next.equals("long") || next.equals("short") ||
               next.equals("unsigned") || next.equals("signed") ||
               next.equals("struct") || next.equals("union") ||
               next.equals("typeof") || next.equals("__typeof__") ||
               typedefMap.containsKey(next);
    }
}

// =============================
// Parser Rules with LLVM IR Generation
// =============================

program
    : {init();printHeader();} externalDeclaration* EOF
        {
            // Print global variable definitions
            for (Info ginfo : globalSymtab.values()) {
                // ── 新增過濾：只有 @ 開頭的才是真正的全域變數 IR，略過 enum 數字 ──
                // Only print complete global IR lines (containing " = global " or " = dso_local")
                // Array/string globals go through stringDefs; bare "@name" refs should not be printed
                if (ginfo.tmp != null && ginfo.tmp.contains(" = global ")) {
                    System.out.println(ginfo.tmp);
                }
            }
            // ── 多檔案連結：輸出沒有本 TU 定義的 prototype 的 declare ──
            for (java.util.Map.Entry<String, String> pd : pendingDeclares.entrySet()) {
                if (!definedFuncs.contains(pd.getKey())) {
                    System.out.println(pd.getValue());
                }
            }
            // Print string literal and struct type definitions
            for (String def : stringDefs) {
                System.out.println(def);
            }
            System.out.println();
            List<String> optimized = applyDCE(currentTextCodeBuffer);
            List<String> gcped     = applyGCP(optimized);
            List<String> peepholed = applyPeephole(gcped);
            for (String instr : peepholed) {
                String trimmed = instr.trim();
                if (trimmed.startsWith("define") || trimmed.equals("}") || trimmed.endsWith(":")) {
                    System.out.println(trimmed);
                } else {
                    System.out.println("  " + trimmed);
                }
            }
            System.out.println();
        }
    ;

externalDeclaration
    : functionDefinition
    | globalFuncPtrDeclaration
    | declaration
    | structDefinition
    | enumDefinition
    | typedefDefinition
    | staticAssertStatement  // ✨ _Static_assert 也可在全域 scope 使用
    ;

// ══════════════════════════════════════════════════════════════════
// 全域函式指標宣告
// 語法：retType (*gFpName)(paramTypes...) [= funcName];
// 例：int (*op)(int, int) = add;
//     void (*callback)(void);
// 在全域範疇生成：@gFpName = global <fpType> @funcName
// ══════════════════════════════════════════════════════════════════
globalFuncPtrDeclaration
    : t=typeSpecifier '(' '*' id=ID ')' '(' fpl=parameterList? ')' ('=' initFunc=ID)? ';'
      {
        if (!inGlobalScope) {
            System.err.println("Error! " + $id.getLine() + ": globalFuncPtrDeclaration only valid at file scope.");
        } else {
            // 建構函式指標 LLVM 型別字串，例如 "i32 (i32, i32)*"
            StringBuilder fpRet = new StringBuilder(toLLVMType($t.type));
            fpRet.append(" (");
            if ($fpl.ctx != null) {
                List<TypeInfo> pts = $fpl.paramTypes;
                List<Boolean> pisPtrs = $fpl.paramIsPtrs;
                List<TypeInfo> pptes = $fpl.paramPointees;
                for (int fi = 0; fi < pts.size(); fi++) {
                    if (fi > 0) fpRet.append(", ");
                    boolean fisPP = (pisPtrs != null && fi < pisPtrs.size() && pisPtrs.get(fi));
                    TypeInfo fpte = (pptes != null && fi < pptes.size()) ? pptes.get(fi) : null;
                    fpRet.append(fisPP && fpte != null ? toLLVMPtrType(fpte, null) : toLLVMType(pts.get(fi)));
                }
            }
            fpRet.append(")*");
            String fpType = fpRet.toString(); // e.g. "i32 (i32, i32)*"

            String name = $id.getText();
            String globalName = "@" + name;
            String initVal = ($initFunc != null) ? ("@" + $initFunc.getText()) : "null";

            // 生成全域變數 IR（加入 stringDefs 確保輸出順序正確）
            stringDefs.add(globalName + " = global " + fpType + " " + initVal + ", align 8");

            // 在 symtab / globalSymtab 登記
            Info info = new Info();
            info.theType = TypeInfo.Pointer;
            info.isPointer = true;
            info.structName = fpType; // 借用 structName 儲存函式指標型別字串
            info.tmp = globalName;
            globalSymtab.put(name, info);
            symtab.put(name, info);
        }
      }
    ;

// ── enum 定義：enum Color { RED, GREEN=5, BLUE }; ──
enumDefinition
    locals [int enumVal = 0]
    : 'enum' id=ID '{'
      // ── 處理第一個元素 (支援賦值) ──
      en1=ID ('=' ev1=DEC_NUM { $enumVal = Integer.parseInt($ev1.getText()); })?
      { 
          // 關鍵：將 Enum 註冊進變數表，讓 primaryExpression 能直接讀到數字！
          Info info1 = new Info();
          info1.theType = TypeInfo.Int;
          info1.tmp = String.valueOf($enumVal); // 直接把數字當作變數的 tmp
          info1.isConstant = true;
          globalSymtab.put($en1.getText(), info1);
          symtab.put($en1.getText(), info1);
          
          enumConstants.put($en1.getText(), $enumVal++); 
      }
      
      // ── 處理後續元素 (支援賦值) ──
      ( ',' en2=ID ('=' ev2=DEC_NUM { $enumVal = Integer.parseInt($ev2.getText()); })?
        { 
          Info info2 = new Info();
          info2.theType = TypeInfo.Int;
          info2.tmp = String.valueOf($enumVal);
          info2.isConstant = true;
          globalSymtab.put($en2.getText(), info2);
          symtab.put($en2.getText(), info2);
          
          enumConstants.put($en2.getText(), $enumVal++); 
        }
      )*
      '}' ';'
    ;

// ── 輔助 rule：解析 struct/union body 中的單一成員宣告 ──
// 分兩種：(A) 具名欄位  (B) 匿名 struct/union（以 '{' 開頭判斷）
// 用獨立 rule 而非 (A | B)* 是為了消除 ANTLR LL(*) 歧義：
//   B 的起始 token 是 'struct'|'union'，與 A 的 typeSpecifier 備選重疊，
//   導致 ANTLR 看到 '{' 時誤判。獨立 rule 讓 ANTLR 在進入 rule 後才決定走哪條分支。
structMemberDecl[StructDef sdef]
    // (B) 匿名 struct/union：token 序列為 ('struct'|'union') '{' ... '}' ';'
    //     必須排在 (A) 前面，讓 ANTLR 用 lookahead 優先比對
    : anonSU=('struct'|'union') '{'
      {
          String anonName = "__anon_" + $sdef.name + "_" + $sdef.fNames.size();
          StructDef anonDef = new StructDef();
          anonDef.name = anonName;
          anonDef.isUnion = $anonSU.getText().equals("union");
      }
      // 匿名 sub-body：支援再一層巢狀匿名 struct/union（遞迴呼叫自己）
      ( structMemberDecl[anonDef] )*
      '}' ';'
      {
          structRegistry.put(anonName, anonDef);
          // 輸出匿名 sub-struct 的 LLVM type 定義（必須在外層 type 之前宣告）
          StringBuilder anonSb = new StringBuilder();
          if (anonDef.isUnion) {
              int anonMaxSize = sizeofStruct(anonName);
              anonSb.append("%struct.").append(anonName).append(" = type { [").append(anonMaxSize).append(" x i8] }");
          } else {
              anonSb.append("%struct.").append(anonName).append(" = type { ");
              for (int ai = 0; ai < anonDef.fTypes.size(); ai++) {
                  if (ai > 0) anonSb.append(", ");
                  if (anonDef.fTypes.get(ai) == TypeInfo.Struct && anonDef.fStructNames.get(ai) != null) {
                      anonSb.append("%struct.").append(anonDef.fStructNames.get(ai));
                  } else if (anonDef.fTypes.get(ai) == TypeInfo.Pointer) {
                      TypeInfo apt = anonDef.fPointeeTypes.get(ai);
                      if (apt == TypeInfo.Struct && anonDef.fStructNames.get(ai) != null)
                          anonSb.append("%struct.").append(anonDef.fStructNames.get(ai)).append("*");
                      else
                          anonSb.append(apt != null ? toLLVMType(apt) : "i8").append("*");
                  } else {
                      anonSb.append(toLLVMType(anonDef.fTypes.get(ai)));
                  }
              }
              anonSb.append(" }");
          }
          stringDefs.add(anonSb.toString());
          // 在外層 sdef 新增一個 TypeInfo.Struct 欄位代表這個匿名 sub-struct
          $sdef.fTypes.add(TypeInfo.Struct);
          $sdef.fNames.add(anonName);
          $sdef.fPointeeTypes.add(null);
          $sdef.fStructNames.add(anonName);
          $sdef.bitWidths.add(-1);
          $sdef.anonParentStructName.add(anonName);
      }
    // (A) 具名欄位：typeSpecifier '*'? ID (':' bitwidth)? ';'
    | t=typeSpecifier star='*'? d=ID (':' bw=DEC_NUM)? ';'
      {
          $sdef.fTypes.add( ($star != null) ? TypeInfo.Pointer : $t.type );
          $sdef.fNames.add($d.getText());
          $sdef.fPointeeTypes.add( ($star != null) ? $t.type : null );
          $sdef.fStructNames.add( $t.sname );
          int bwVal = ($bw != null) ? Integer.parseInt($bw.getText()) : -1;
          $sdef.bitWidths.add(bwVal);
          if (bwVal >= 0) $sdef.hasBitFields = true;
          $sdef.anonParentStructName.add(null);
      }
    // ── ✨ (C) Flexible Array Member：typeSpecifier ID '[' ']' ';'（C99 FAM）──
    // 語法：struct Hdr { int n; int data[]; };
    // LLVM 表示：[0 x i32]，GEP 時以 sizeof(struct) 作基底動態偏移
    | ft=typeSpecifier fd=ID '[' ']' ';'
      {
          // FAM 記為 arraySize=0 的陣列指標，LLVM 用 [0 x T] 表示
          $sdef.fTypes.add(TypeInfo.Pointer);          // 在 LLVM type 輸出時特殊處理
          $sdef.fNames.add($fd.getText());
          $sdef.fPointeeTypes.add($ft.type);
          $sdef.fStructNames.add($ft.sname);
          $sdef.bitWidths.add(0);                      // 0 = FAM 標記
          $sdef.anonParentStructName.add(null);
          $sdef.hasFAM = true;                         // ✨ 旗標：此 struct 有 FAM
          $sdef.famElemType = $ft.type;                // ✨ 記住 FAM 元素型別
          $sdef.famElemStructName = $ft.sname;
      }
    ;

structDefinition
    : structOrUnion=('struct' | 'union') id=ID '{'
      {
          StructDef sdef = new StructDef();
          sdef.name = $id.getText();
          sdef.isUnion = $structOrUnion.getText().equals("union");
      }
      ( structMemberDecl[sdef] )*
      '}' ';'
      {
          structRegistry.put(sdef.name, sdef);
          StringBuilder sb = new StringBuilder();
          if (sdef.isUnion) {
              int maxSize = sizeofStruct(sdef.name);
              sb.append("%struct.").append(sdef.name).append(" = type { [").append(maxSize).append(" x i8] }");
          } else if (sdef.hasBitFields) {
              sb.append("%struct.").append(sdef.name).append(" = type { i32 }");
          } else {
              sb.append("%struct.").append(sdef.name).append(" = type { ");
              boolean firstField = true;
              for (int i = 0; i < sdef.fTypes.size(); i++) {
                  int bw = (i < sdef.bitWidths.size()) ? sdef.bitWidths.get(i) : -1;
                  if (bw == 0) continue; // FAM is appended once below as [0 x T].
                  if (!firstField) sb.append(", ");
                  firstField = false;
                  if (sdef.fTypes.get(i) == TypeInfo.Struct && sdef.fStructNames.get(i) != null) {
                      // ✨ 匿名 sub-struct：輸出 %struct.__anon_... 而非 toLLVMType()
                      sb.append("%struct.").append(sdef.fStructNames.get(i));
                  } else if (sdef.fTypes.get(i) == TypeInfo.Pointer) {
                      sb.append("%struct.").append(sdef.name).append("*");
                  } else {
                      sb.append(toLLVMType(sdef.fTypes.get(i)));
                  }
              }
              sb.append(" }");
          }
          // ── ✨ FAM：在 LLVM type 最後補上 [0 x T] 欄位 ──
          if (sdef.hasFAM) {
              String famLL = (sdef.famElemType == TypeInfo.Struct && sdef.famElemStructName != null)
                  ? "%struct." + sdef.famElemStructName
                  : toLLVMType(sdef.famElemType != null ? sdef.famElemType : TypeInfo.Int);
              String prev = sb.toString();
              if (prev.endsWith(" }")) {
                  sb.setLength(prev.length() - 2);
                  if (prev.contains("{") && !prev.endsWith("{ }")) sb.append(", ");
                  else if (prev.endsWith("{ }")) { sb.setLength(prev.length() - 3); sb.append("{ "); }
                  sb.append("[0 x ").append(famLL).append("] }");
              }
          }
          stringDefs.add(sb.toString());
      }
    ;

// ══════════════════════════════════════════════
// typedef：支援基本型別別名 與 struct 別名
// 範例：typedef int MyInt;
//       typedef struct Point { int x; int y; } Point;
//       typedef struct Point PointAlias;
// ══════════════════════════════════════════════
typedefDefinition
    : 'typedef' structOrUnion=('struct'|'union') sname=ID? '{'
      {
        StructDef sdef = new StructDef();
        sdef.isUnion = $structOrUnion.getText().equals("union");
      }
    // ✨ 替換下面這個區塊 (順便補上了 star='*'? 讓 typedef 也能支援指標欄位) ✨
      ( ft=typeSpecifier star='*'? fn=ID (':' bw2=DEC_NUM)? ';'
        {
          sdef.fTypes.add( ($star != null) ? TypeInfo.Pointer : $ft.type );
          sdef.fNames.add($fn.getText());
          // 紀錄指標指向的型別與 struct 名稱
          sdef.fPointeeTypes.add( ($star != null) ? $ft.type : null );
          sdef.fStructNames.add( $ft.sname );
          int bwVal2 = ($bw2 != null) ? Integer.parseInt($bw2.getText()) : -1;
          sdef.bitWidths.add(bwVal2);
          if (bwVal2 >= 0) sdef.hasBitFields = true;
          sdef.anonParentStructName.add(null); // 具名欄位
        }
      )* // ✨ 替換到這裡 ✨
      '}' alias=ID ';'
      {
        sdef.name = ($sname != null) ? $sname.getText() : $alias.getText();
        structRegistry.put(sdef.name, sdef);
        
        StringBuilder sb = new StringBuilder();
        if (sdef.isUnion) {
            int maxSize = sizeofStruct(sdef.name);
            sb.append("%struct.").append(sdef.name).append(" = type { [").append(maxSize).append(" x i8] }");
        } else if (sdef.hasBitFields) {
            // ✨ bit-field struct：打包成單一 i32
            sb.append("%struct.").append(sdef.name).append(" = type { i32 }");
        } else {
            sb.append("%struct.").append(sdef.name).append(" = type { ");
            for (int i = 0; i < sdef.fTypes.size(); i++) {
                if (i > 0) sb.append(", ");
                sb.append(toLLVMType(sdef.fTypes.get(i)));
            }
            sb.append(" }");
        }
        stringDefs.add(sb.toString());
        
        typedefMap.put($alias.getText(), TypeInfo.Struct);
        typedefStructMap.put($alias.getText(), sdef.name);
        if ($sname != null && !$alias.getText().equals($sname.getText())) {
            typedefMap.put($sname.getText(), TypeInfo.Struct);
            typedefStructMap.put($sname.getText(), sdef.name);
        }
      }
    | 'typedef' ('struct'|'union') existingName=ID alias=ID ';'
      {
        typedefMap.put($alias.getText(), TypeInfo.Struct);
        typedefStructMap.put($alias.getText(), $existingName.getText());
      }
    // 3. 基本型別的 typedef (typedef int MyInt;)
    | 'typedef' t=typeSpecifier alias=ID ';'
      {
        if ($t.type == TypeInfo.Struct) {
            typedefMap.put($alias.getText(), TypeInfo.Struct);
            typedefStructMap.put($alias.getText(), $t.sname);
        } else {
            typedefMap.put($alias.getText(), $t.type);
        }
      }
    // 4. ✨ 函式指標 typedef (typedef retType (*Alias)(param1, param2, ...);)
    | 'typedef' ret=typeSpecifier retStar='*'? '(' '*' alias=ID ')' '(' fpl=parameterList? ')' ';'
      {
        // 建立 LLVM 函式指標型別字串，例如 "i32 (i32, i32)*"
        StringBuilder fpTypeStr = new StringBuilder();
        fpTypeStr.append(toLLVMType($ret.type));
        fpTypeStr.append(" (");
        if ($fpl.ctx != null) {
            List<TypeInfo> pts = $fpl.paramTypes;
            List<Boolean> pisPtrs = $fpl.paramIsPtrs;
            List<TypeInfo> pptes  = $fpl.paramPointees;
            for (int fi = 0; fi < pts.size(); fi++) {
                if (fi > 0) fpTypeStr.append(", ");
                boolean fisPP = (pisPtrs != null && fi < pisPtrs.size() && pisPtrs.get(fi));
                TypeInfo fpte = (pptes != null && fi < pptes.size()) ? pptes.get(fi) : null;
                fpTypeStr.append(fisPP && fpte != null ? toLLVMPtrType(fpte, null) : toLLVMType(pts.get(fi)));
            }
        }
        if ($retStar != null) fpTypeStr.append(")*"); else fpTypeStr.append(")*");
        String fpType = fpTypeStr.toString();
        funcPtrTypedefMap.put($alias.getText(), fpType);
        typedefStructMap.put($alias.getText(), fpType); // 讓 typeSpecifier 能帶出 fpType
        typedefMap.put($alias.getText(), TypeInfo.Pointer);
      }
    ;

functionDefinition
    : (extKw+='static'|extKw+='inline'|extKw+='extern')* t=typeSpecifier retPtr='*'? id=ID '(' pl=parameterList? ')'
      (
        // ── 情況 A：前置宣告 (prototype)，只有分號，沒有 body ──
        ';'
        {
          TypeInfo retType = ($retPtr != null) ? TypeInfo.Pointer : $t.type;
          if ($id.getText().equals("main")) retType = TypeInfo.Int;
          List<TypeInfo> funcSig = new ArrayList<>();
          funcSig.add(retType);
          if ($pl.ctx != null) {
              List<TypeInfo> pointeesSig = new ArrayList<>();
              List<String> pointeeStructsSig = new ArrayList<>();
              for (int pi = 0; pi < $pl.paramTypes.size(); pi++) {
                  funcSig.add($pl.paramTypes.get(pi));
                  pointeesSig.add((pi < $pl.paramPointees.size()) ? $pl.paramPointees.get(pi) : null);
                  pointeeStructsSig.add((pi < $pl.paramStructNames.size()) ? $pl.paramStructNames.get(pi) : null);
              }
              funcPointerRegistry.put($id.getText(), pointeesSig);
              funcPointerStructRegistry.put($id.getText(), pointeeStructsSig);
          }
          if (!funcRegistry.containsKey($id.getText())) {
              funcRegistry.put($id.getText(), funcSig);
          } else {
              // 重複 prototype：回傳型別必須一致
              List<TypeInfo> existing = funcRegistry.get($id.getText());
              if (existing.get(0) != retType) {
                  System.err.println("Error! " + $id.getLine() + ": Prototype return type mismatch for " + $id.getText() + ".");
              }
          }
          if (retType == TypeInfo.Pointer) {
              funcRetPointeeRegistry.put($id.getText(), $t.type);
              if ($t.type == TypeInfo.Struct && $t.sname != null) {
                  funcStructRetRegistry.put($id.getText(), $t.sname);
              }
          } else if (retType == TypeInfo.Struct && $t.sname != null) {
              funcStructRetRegistry.put($id.getText(), $t.sname);
          }
          // ── 多檔案連結：prototype（有分號無 body）一律記入 pendingDeclares；
          //    在 program EOF 時，若此函式在本 TU 沒有 define，才輸出 declare。──
          {
              String _fname2 = $id.getText();
              String _declKey2 = "func:" + _fname2;
              if (!emittedExternDecls.contains(_declKey2)) {
                  emittedExternDecls.add(_declKey2);
                  String _llvmRet2;
                  if (retType == TypeInfo.Struct && $t.sname != null) {
                      _llvmRet2 = "%struct." + $t.sname;
                  } else if (retType == TypeInfo.Pointer) {
                      _llvmRet2 = ($t.type == TypeInfo.Struct && $t.sname != null)
                          ? "%struct." + $t.sname + "*" : toLLVMPtrType($t.type, $t.sname);
                  } else {
                      _llvmRet2 = toLLVMType(retType);
                  }
                  StringBuilder _pSig2 = new StringBuilder();
                  boolean _isVarE2 = ($pl.ctx != null && $pl.isVariadic);
                  if ($pl.ctx != null) {
                      List<TypeInfo> _pts2 = $pl.paramTypes;
                      List<Boolean>  _isPtrs2 = $pl.paramIsPtrs;
                      List<TypeInfo> _pptes2  = $pl.paramPointees;
                      List<String>   _psns2   = $pl.paramStructNames;
                      for (int _ei2 = 0; _ei2 < _pts2.size(); _ei2++) {
                          if (_ei2 > 0) _pSig2.append(", ");
                          boolean _isPP2 = (_isPtrs2 != null && _ei2 < _isPtrs2.size() && _isPtrs2.get(_ei2));
                          TypeInfo _pte2 = (_pptes2 != null && _ei2 < _pptes2.size()) ? _pptes2.get(_ei2) : null;
                          String   _psn2 = (_psns2  != null && _ei2 < _psns2.size())  ? _psns2.get(_ei2)  : null;
                          _pSig2.append(_isPP2 ? toLLVMPtrType(_pte2, _psn2) : toLLVMType(_pts2.get(_ei2)));
                      }
                      if (_isVarE2) _pSig2.append(_pts2.isEmpty() ? "..." : ", ...");
                  }
                  pendingDeclares.put(_fname2, "declare " + _llvmRet2 + " @" + _fname2 + "(" + _pSig2 + ")");
              }
          }
        }
      |
        // ── 情況 B：完整實作 (有 body) ──
        {
          TypeInfo actualReturnType = ($retPtr != null) ? TypeInfo.Pointer : $t.type;
          if ($id.getText().equals("main")) actualReturnType = TypeInfo.Int;

          // ▼▼▼ 使用 Stack 記錄回傳型別，支援巢狀函式 ▼▼▼
          returnTypeStack.add(actualReturnType);
          // ── 同步推入 struct 名稱（非 struct 時為 null）──
          returnStructNameStack.add(actualReturnType == TypeInfo.Struct ? $t.sname : null);

          StringBuilder paramSig = new StringBuilder();
          List<TypeInfo> funcSig = new ArrayList<>();
          funcSig.add(actualReturnType);


          // ── 偵測 int main(int argc, char *argv[]) ──
          boolean isMainWithArgs = $id.getText().equals("main")
              && $pl.ctx != null
              && $pl.paramNames != null
              && $pl.paramNames.size() == 2;

          if (isMainWithArgs) {
              // define i32 @main(i32 %param_argc, i8** %param_argv)
              paramSig.append("i32 %param_argc, i8** %param_argv");
              funcSig.add(TypeInfo.Int);
              funcSig.add(TypeInfo.Pointer);
          } else if ($pl.ctx != null) {
              List<String> pnames = $pl.paramNames;
              List<TypeInfo> ptypes = $pl.paramTypes;
              List<Boolean> pisCharPtr = $pl.paramIsCharPtrs;
              List<Boolean> pisPtr2 = $pl.paramIsPtrs;
              List<TypeInfo> ppointees2 = $pl.paramPointees;
              List<String> pstructNames = $pl.paramStructNames;
              List<TypeInfo> pointeesSig = new ArrayList<>();
              List<String> pointeeStructsSig = new ArrayList<>();
              for (int pi = 0; pi < ptypes.size(); pi++) {
                  if (pi > 0) paramSig.append(", ");
                  boolean isCA = (pisCharPtr != null && pi < pisCharPtr.size() && pisCharPtr.get(pi));
                  boolean isPP = (pisPtr2 != null && pi < pisPtr2.size() && pisPtr2.get(pi));
                  TypeInfo pte = (ppointees2 != null && pi < ppointees2.size()) ? ppointees2.get(pi) : null;
                  String sname = (pstructNames != null && pi < pstructNames.size()) ? pstructNames.get(pi) : null;
                  
                  String llvmPT;
                  // ✨ 防呆攔截：精準處理函式指標參數，避免被誤當一般指標或結構體
                  if (sname != null && sname.contains("(")) {
                      llvmPT = sname;
                  } else if (sname != null && sname.endsWith("**")) {
                      llvmPT = sname;
                  } else if (sname != null && sname.startsWith("[") && sname.endsWith("]*")) {
                      // ✨ 2D 陣列參數：[N x T]* 直接使用
                      llvmPT = sname;
                  } else if (isPP && pte != null) {
                      llvmPT = toLLVMPtrType(pte, sname);
                  } else if (isCA) {
                      llvmPT = "i8*";
                  } else if (ptypes.get(pi) == TypeInfo.Struct && sname != null) {
                      llvmPT = "%struct." + sname;
                  } else {
                      llvmPT = toLLVMType(ptypes.get(pi));
                  }
                  
                  paramSig.append(llvmPT).append(" %param_").append(pnames.get(pi));
                  funcSig.add(ptypes.get(pi));
                  pointeesSig.add(pte);
                  pointeeStructsSig.add(sname);
              }
              funcPointerRegistry.put($id.getText(), pointeesSig);
              funcPointerStructRegistry.put($id.getText(), pointeeStructsSig);
          } // end: isMainWithArgs / else-if pl.ctx (paramSig)
          if (funcRegistry.containsKey($id.getText())) {
              List<TypeInfo> proto = funcRegistry.get($id.getText());
              if (proto.get(0) != actualReturnType) {
                  System.err.println("Error! " + $id.getLine() + ": Definition return type does not match prototype for " + $id.getText() + ".");
              }
              // ✨ 新增：prototype vs definition 參數數量比對
              int _protoParamCount = proto.size() - 1;
              int _defParamCount   = funcSig.size() - 1;
              if (_protoParamCount != _defParamCount) {
                  System.err.println("Error! " + $id.getLine() +
                      ": Parameter count mismatch for '" + $id.getText() +
                      "': prototype has " + _protoParamCount +
                      " param(s), definition has " + _defParamCount + ".");
              } else {
                  // ✨ 新增：逐位參數型別比對
                  for (int _ci = 1; _ci < proto.size(); _ci++) {
                      if (proto.get(_ci) != funcSig.get(_ci)) {
                          System.err.println("Error! " + $id.getLine() +
                              ": Parameter " + _ci + " type mismatch for '" + $id.getText() +
                              "': prototype expects " + proto.get(_ci) +
                              ", definition has " + funcSig.get(_ci) + ".");
                      }
                  }
              }
          }
        // 防止重複定義
          String emitFuncName = $id.getText();
          if (definedFuncs.contains(emitFuncName)) {
              System.err.println("Error! " + $id.getLine() + ": Function " + emitFuncName + " already defined.");
              // ✨ 核心修正：如果重複定義，動態改名加上行號（e.g., @duplicate_func_redefined_err_12）
              // 這樣既能噴出 Error，又不會讓 Clang 因為頂層名稱碰撞而崩潰！
              emitFuncName = emitFuncName + "_redefined_err_" + $id.getLine();
          } else {
              definedFuncs.add(emitFuncName);
              funcRegistry.put(emitFuncName, funcSig);
              // ✨ 登記 variadic
              if ($pl.ctx != null && $pl.isVariadic) funcIsVariadic.put(emitFuncName, true);
          }

          inGlobalScope = false;
          // struct 回傳型別登記
          if (actualReturnType == TypeInfo.Struct && $t.sname != null) {
              funcStructRetRegistry.put(emitFuncName, $t.sname);
          }
          // ✨ 新增：指標回傳的指向型別登記 ✨
          if (actualReturnType == TypeInfo.Pointer) {
              funcRetPointeeRegistry.put(emitFuncName, $t.type);
              if ($t.type == TypeInfo.Struct && $t.sname != null) {
                  funcStructRetRegistry.put(emitFuncName, $t.sname);
              }
          }

        String retLLVM;
          if (actualReturnType == TypeInfo.Struct && $t.sname != null) {
              retLLVM = "%struct." + $t.sname;
          } else if (actualReturnType == TypeInfo.Pointer) {
              // ✨ 終極修復：如果指標的基底型別是 Struct，必須宣告為 %struct.名字* ✨
              if ($t.type == TypeInfo.Struct && $t.sname != null) {
                  retLLVM = "%struct." + $t.sname + "*";
              } else {
                  retLLVM = toLLVMPtrType($t.type, $t.sname); // 一般指標 (如 i32*)
              }
          } else {
              retLLVM = toLLVMType(actualReturnType);
          }
          // ✨ variadic 函式在 paramSig 後加 ...
          String varargSuffix = ($pl.ctx != null && $pl.isVariadic) ? ", ..." : "";
          addInstruction("define dso_local " + retLLVM + " @" + emitFuncName + "(" + paramSig + varargSuffix + ") {");
          addInstruction("entry:");
          // ── TCO push（哨兵 "" 代表尚未建立 loop label）──
          currentFuncNameStack.push(emitFuncName);
          tcoLoopLabelStack.push(TCO_LABEL_NONE);
          currentFuncParamSlots.push(new ArrayList<>());
          currentFuncParamTypes.push(new ArrayList<>());
          currentFuncParamNames.push(new ArrayList<>());

          HashMap<String, Info> savedSymtab = new HashMap<>(symtab);
          pushBuffer();

          if (isMainWithArgs) {
              // ── argc：i32 ──
              String argcSlot = newTemp();
              addInstruction(argcSlot + " = alloca i32, align 4");
              addInstruction("store i32 %param_argc, i32* " + argcSlot + ", align 4");
              Info argcInfo = new Info(); argcInfo.theType = TypeInfo.Int; argcInfo.tmp = argcSlot;
              symtab.put("argc", argcInfo);
              // ── argv：i8** ──
              String argvSlot = newTemp();
              addInstruction(argvSlot + " = alloca i8**, align 8");
              addInstruction("store i8** %param_argv, i8*** " + argvSlot + ", align 8");
              Info argvInfo = new Info(); argvInfo.theType = TypeInfo.Pointer; argvInfo.tmp = argvSlot;
              argvInfo.isPointer = true; argvInfo.pointeeType = TypeInfo.Char;
              argvInfo.structName = "i8**"; // 借用 structName 標記雙層指標
              symtab.put("argv", argvInfo);
          } else if ($pl.ctx != null) {
              List<String> pnames = $pl.paramNames;
              List<TypeInfo> ptypes = $pl.paramTypes;
              List<Boolean> pisCharPtr = $pl.paramIsCharPtrs;
              List<Boolean> pisPtr = $pl.paramIsPtrs;
              List<TypeInfo> ppointees = $pl.paramPointees;
              List<String> pstructNames2 = $pl.paramStructNames;
              for (int pi = 0; pi < ptypes.size(); pi++) {
                  String pname = pnames.get(pi);
                  boolean isCharArr = (pisCharPtr != null && pi < pisCharPtr.size() && pisCharPtr.get(pi));
                  boolean isPtrP = (pisPtr != null && pi < pisPtr.size() && pisPtr.get(pi));
                  TypeInfo pointeeT = (ppointees != null && pi < ppointees.size()) ? ppointees.get(pi) : null;
                  String sname2 = (pstructNames2 != null && pi < pstructNames2.size()) ? pstructNames2.get(pi) : null;
                String llvmT;
                  // ✨ 防呆攔截：處理函式指標參數
                  if (sname2 != null && sname2.contains("(")) {
                      llvmT = sname2;
                  } else if (sname2 != null && sname2.endsWith("**")) {
                      llvmT = sname2;
                  } else if (sname2 != null && sname2.startsWith("[") && sname2.endsWith("]*")) {
                      // ✨ 2D 陣列參數：[N x T]* 直接使用
                      llvmT = sname2;
                  } else if (isPtrP && pointeeT != null) {
                      llvmT = toLLVMPtrType(pointeeT, sname2);
                  } else if (isCharArr) {
                      llvmT = "i8*";
                  } else if (ptypes.get(pi) == TypeInfo.Struct && sname2 != null) {
                      llvmT = "%struct." + sname2;
                  } else {
                      llvmT = toLLVMType(ptypes.get(pi));
                  }
                  String ptr = newTemp();
                  addInstruction(ptr + " = alloca " + llvmT + ", align " + (isPtrP ? "8" : "4"));
                  addInstruction("store " + llvmT + " %param_" + pname + ", " + llvmT + "* " + ptr + ", align " + (isPtrP ? "8" : "4"));
                  Info info = new Info();
             
                  info.theType = isPtrP ? TypeInfo.Pointer : ptypes.get(pi);
                  info.tmp = ptr;
                  info.isPointer = isPtrP;
                  info.pointeeType = pointeeT;
                  info.structName = sname2;
                  if (isCharArr) info.arraySize = -1;

                  // ✨ 3D 陣列參數：解析 "[sz2 x [sz3 x T]]*" 格式
                  if (sname2 != null && sname2.startsWith("[") && sname2.endsWith("]*")) {
                      try {
                          String inner3D = sname2.substring(1, sname2.length() - 2); // "sz2 x [sz3 x T]" or "N x T"
                          int xIdx3 = inner3D.indexOf(" x ");
                          if (xIdx3 > 0) {
                              int dim2Val = Integer.parseInt(inner3D.substring(0, xIdx3).trim());
                              info.arrayDim2 = dim2Val;
                              // check if inner part is itself an array type "[sz3 x T]"
                              String rest3 = inner3D.substring(xIdx3 + 3).trim();
                              if (rest3.startsWith("[") && rest3.endsWith("]")) {
                                  // 3D: rest3 = "[sz3 x T]"
                                  String inner3 = rest3.substring(1, rest3.length() - 1);
                                  int xIdx3b = inner3.indexOf(" x ");
                                  if (xIdx3b > 0) info.arrayDim3 = Integer.parseInt(inner3.substring(0, xIdx3b).trim());
                              }
                          }
                      } catch (Exception _e3) { /* ignore */ }
                      info.isPointer = true;
                      info.ptrDepth = 1;
                      info.baseType = pointeeT != null ? pointeeT : TypeInfo.Int;
                      exactTypeMap.put(ptr, llvmT + "*");
                      symtab.put(pname, info);
                      continue;
                  }

                  // 👇 👇 ✨ 核心修正：為函式參數補齊多層指標架構 ✨ 👇 👇
                  if (isPtrP || isCharArr) {
                      if ("i8**".equals(sname2)) {
                          info.ptrDepth = 2;
                          info.baseType = TypeInfo.Char;
                      } else if (sname2 != null && sname2.contains("(")) {
                          info.ptrDepth = 1;
                          info.baseType = TypeInfo.Pointer; // 函式指標
                      } else {
                          info.ptrDepth = 1;
                          info.baseType = (pointeeT != null) ? pointeeT : TypeInfo.Int;
                      }
                  } else {
                      info.ptrDepth = 0;
                      info.baseType = ptypes.get(pi);
                  }
                  
                  // 將參數的 alloca 指標真實型別 (例如 i32** 或 i8***) 存入 exactTypeMap
                  exactTypeMap.put(ptr, llvmT + "*");
                  // 👆 👆 ✨ 新增結束 ✨ 👆 👆

                  symtab.put(pname, info);
                  // ── TCO：記錄此參數的 alloca slot 和 LLVM 型別 ──
                  if (!currentFuncParamSlots.isEmpty()) {
                      currentFuncParamSlots.peek().add(ptr);
                      currentFuncParamTypes.peek().add(llvmT);
                      currentFuncParamNames.peek().add(pname);
                  }
                }
          } // end isMainWithArgs / else-if pl.ctx (body)
        }
        compoundStatement
        {
          List<String> functionBodyIR = popBuffer();
          // ── TCO：若有自我尾呼叫，在 alloca/store 群之後插入 tco_loop label ──
          String _tcoLbl2 = tcoLoopLabelStack.isEmpty() ? TCO_LABEL_NONE : tcoLoopLabelStack.peek();
          if (!TCO_LABEL_NONE.equals(_tcoLbl2)) {
              int _ins = 0;
              for (int _i = 0; _i < functionBodyIR.size(); _i++) {
                  String _ln = functionBodyIR.get(_i).trim();
                  if (_ln.contains("= alloca") || _ln.startsWith("store ")) { _ins = _i + 1; }
                  else if (_ln.isEmpty() || _ln.endsWith(":")) { /* skip */ }
                  else { break; }
              }
              functionBodyIR.add(_ins, _tcoLbl2 + ":");
              functionBodyIR.add(_ins, "  br label %" + _tcoLbl2);
          }
          for (String instr : functionBodyIR) addInstruction(instr);
          // ── goto forward-reference 修補：在"}"前進行，確保所有 label 都已登記 ──
          patchGotoForwardRefs();
          gotoTable.clear(); // 每個函式的 label 命名空間獨立
          if (!lastInstrIsTerminator) {
              if ($t.type == TypeInfo.Void && !$id.getText().equals("main")) {
                  addInstruction("ret void");
              } else {
                  TypeInfo retT = getCurrentReturnType();
                  if (retT != TypeInfo.Void) {
                      System.err.println("Warning! " + $id.getLine() + ": control reaches end of non-void function '" + $id.getText() + "' without return.");
                  }
                  addInstruction("ret i32 0");
              }
          }
          addInstruction("}");
          symtab = savedSymtab;
          inGlobalScope = true;
          returnTypeStack.remove(returnTypeStack.size() - 1);
          if (!returnStructNameStack.isEmpty()) returnStructNameStack.remove(returnStructNameStack.size() - 1);
          // ── TCO pop ──
          if (!currentFuncNameStack.isEmpty())  currentFuncNameStack.pop();
          if (!tcoLoopLabelStack.isEmpty())      tcoLoopLabelStack.pop();
          if (!currentFuncParamSlots.isEmpty())  currentFuncParamSlots.pop();
          if (!currentFuncParamTypes.isEmpty())  currentFuncParamTypes.pop();
          if (!currentFuncParamNames.isEmpty())  currentFuncParamNames.pop();
        }
      )
    ;

parameterList returns [List<String> paramNames, List<TypeInfo> paramTypes, List<Boolean> paramIsCharPtrs, List<Boolean> paramIsPtrs, List<TypeInfo> paramPointees, List<String> paramStructNames, boolean isVariadic]
    : { $paramNames = new ArrayList<>(); $paramTypes = new ArrayList<>(); $paramIsCharPtrs = new ArrayList<>(); $paramIsPtrs = new ArrayList<>(); $paramPointees = new ArrayList<>(); $paramStructNames = new ArrayList<>(); $isVariadic = false; }
      ( 'void'
      | p=parameter
        { $paramNames.add($p.paramName); $paramTypes.add($p.paramType); $paramIsCharPtrs.add($p.isCharPtr); $paramIsPtrs.add($p.isPtrParam); $paramPointees.add($p.ptrPointee); $paramStructNames.add($p.structName); }
        (',' p2=parameter
        { $paramNames.add($p2.paramName); $paramTypes.add($p2.paramType); $paramIsCharPtrs.add($p2.isCharPtr); $paramIsPtrs.add($p2.isPtrParam); $paramPointees.add($p2.ptrPointee); $paramStructNames.add($p2.structName); })*
        (',' '...' { $isVariadic = true; })?
      | '...' { $isVariadic = true; }
      )
    ;

parameter returns [String paramName, TypeInfo paramType, boolean isCharPtr, boolean isPtrParam, TypeInfo ptrPointee, String structName]
    // 支援雙層指標參數 type **id（如 char **a, int **b）
    : ('const'|'volatile'|'restrict')* t=typeSpecifier ('const'|'volatile'|'restrict')* '*' '*' id=ID?
      { $paramName = ($id != null) ? $id.getText() : "";
        $paramType = TypeInfo.Pointer;
        $isCharPtr = false;
        $isPtrParam = true;
        $ptrPointee = TypeInfo.Pointer;
        String innerLL = ($t.type == TypeInfo.Char) ? "i8" : toLLVMType($t.type);
        $structName = innerLL + "**";
      }
    // ✨ 新增：支援 3D 陣列參數，例如 int grid[2][3][4] 或 int grid[][3][4]
    | ('const'|'volatile'|'restrict')* t=typeSpecifier ('const'|'volatile'|'restrict')* id=ID? '[' dg1=arraySize? ']' '[' sz2p=arraySize ']' '[' sz3p=arraySize ']'
      { $paramName = ($id != null) ? $id.getText() : "";
        $paramType = TypeInfo.Pointer;
        $isCharPtr = false;
        $isPtrParam = true;
        $ptrPointee = $t.type;
        // Encode as "[sz2 x [sz3 x T]]*" so param handler can recover dim2 and dim3
        String elemLLVM3 = toLLVMType($t.type);
        $structName = "[" + $sz2p.value + " x [" + $sz3p.value + " x " + elemLLVM3 + "]]*";
      }
    // ✨ 新增：支援 2D 陣列參數，例如 int arr[][4]（作為指標傳遞）
    | ('const'|'volatile'|'restrict')* t=typeSpecifier ('const'|'volatile'|'restrict')* id=ID? '[' ']' '[' sz2=arraySize ']'
      { $paramName = ($id != null) ? $id.getText() : "";
        $paramType = TypeInfo.Pointer;
        $isCharPtr = false;
        $isPtrParam = true;
        $ptrPointee = $t.type;
        // 2D array param: treat as pointer to inner array type, e.g. [4 x i32]*
        String elemLLVM = toLLVMType($t.type);
        $structName = "[" + $sz2.value + " x " + elemLLVM + "]*";
      }
    // ✨ 新增 1：支援 char *argv[] (指標陣列，視為雙層指標)
    | ('const'|'volatile'|'restrict')* t=typeSpecifier ('const'|'volatile'|'restrict')* '*' id=ID? '[' ']'
      { $paramName = ($id != null) ? $id.getText() : "";
        $paramType = TypeInfo.Pointer;
        $isCharPtr = false;
        $isPtrParam = true;
        $ptrPointee = TypeInfo.Pointer;
        $structName = "i8**"; // 特殊標記，讓 main 辨識
      }
    // ✨ 修正 2：將所有 ID 改為可選 (ID?)，完美支援 int (*fp)(int, int)
    | ('const'|'volatile'|'restrict')* t=typeSpecifier ('const'|'volatile'|'restrict')* id=ID? '[' ']'
      { $paramName = ($id != null) ? $id.getText() : "";
        $paramType = TypeInfo.Pointer;
        $isCharPtr = ($t.type == TypeInfo.Char); 
        $isPtrParam = true;
        $ptrPointee = $t.type;
        $structName = $t.sname;
      }
    // ✨ 新增：支援函式指標作為參數，例如 int (*op)(int, int)
    | t=typeSpecifier '(' '*' id=ID? ')' '(' (typeSpecifier (',' typeSpecifier)*)? ')'
      { 
        $paramName = ($id != null) ? $id.getText() : ""; 
        $paramType = TypeInfo.Pointer; // 函式指標本質就是一個指標
        $isCharPtr = false;
        $isPtrParam = true;
        $ptrPointee = null; 
        $structName = null; // ⚠️ 非常重要：保持 null，避免被誤認成 Struct！
        // ✨ 修改這裡：塞入一個帶有括號的型別，讓後面的邏輯能認出它是函式指標！
        $structName = "i32 (i32, i32)*";
      }
    | ('const'|'volatile'|'restrict')* t=typeSpecifier ('const'|'volatile'|'restrict')* '*' ('const'|'volatile'|'restrict')* id=ID?
      { $paramName = ($id != null) ? $id.getText() : ""; 
        $paramType = TypeInfo.Pointer;
        $isCharPtr = false;
        $isPtrParam = true; 
        $ptrPointee = $t.type; 
        $structName = $t.sname; }
    | ('const'|'volatile'|'restrict')* t=typeSpecifier ('const'|'volatile'|'restrict')* id=ID?
      { $paramName = ($id != null) ? $id.getText() : ""; 
        $paramType = $t.type; 
        $isCharPtr = false; 
        $isPtrParam = false;
        $ptrPointee = null; 
        $structName = $t.sname; }
    
    ;

declaration returns [TypeInfo type]
    locals [java.util.List<Info> arrInitList, String strInitVal, java.util.List<Integer> arrDesignIdxList, java.util.List<Integer> arrDesignRangeList, int autoIdx]
    // ── 前置修飾詞靜默忽略：volatile / restrict / __attribute__((...)) ──
    // （在每條 alt 前加 ('volatile'|'restrict'|'__attribute__'...)? 太繁瑣，
    //  改在 blockItem / externalDeclaration 層面吃掉）
    : ('static'|'extern'|'register')? t=typeSpecifier '(' '*' id=ID ')' '(' fpl=parameterList? ')' ('=' initFunc=ID)? ';'
      {
        $type = TypeInfo.Pointer;
        String name = $id.getText();
        if (symtab.containsKey(name)) {
            System.err.println("Error! " + $id.getLine() + ": Redeclared identifier " + name + ".");
        } else {
            // 建立函式型別字串，例如 "i32 (i32, i32)"
            StringBuilder fpRet = new StringBuilder(toLLVMType($t.type));
            fpRet.append(" (");
            if ($fpl.ctx != null) {
                List<TypeInfo> pts = $fpl.paramTypes;
                List<Boolean> pisPtrs = $fpl.paramIsPtrs;
                List<TypeInfo> pptes = $fpl.paramPointees;
                for (int fi = 0; fi < pts.size(); fi++) {
                    if (fi > 0) fpRet.append(", ");
                    boolean fisPP = (pisPtrs != null && fi < pisPtrs.size() && pisPtrs.get(fi));
                    TypeInfo fpte = (pptes != null && fi < pptes.size()) ? pptes.get(fi) : null;
                    fpRet.append(fisPP && fpte != null ? toLLVMPtrType(fpte, null) : toLLVMType(pts.get(fi)));
                }
            }
            fpRet.append(")*");
            String fpType = fpRet.toString(); // e.g. "i32 (i32, i32)*"

            String ptr = newTemp();
            addInstruction(ptr + " = alloca " + fpType + ", align 8");

            Info info = new Info();
            info.theType = TypeInfo.Pointer;
            info.isPointer = true;
            info.tmp = ptr;
            info.structName = fpType; // 借用 structName 存函式指標型別字串
            symtab.put(name, info);

            if ($initFunc != null) {
                addInstruction("store " + fpType + " @" + $initFunc.getText() + ", " + fpType + "* " + ptr + ", align 8");
            } else {
                addInstruction("store " + fpType + " null, " + fpType + "* " + ptr + ", align 8");
            }
        }
      }
  // ── 指標宣告升級版：支援 int *p 或 int **p ──
    | ('static'|'extern'|'register')? t=typeSpecifier s1='*' s2='*'? id=ID ('=' init=expression)? ';'
      {
        $type = TypeInfo.Pointer;
        String name = $id.getText();
        TypeInfo myBase = $t.type;
        int depth = ($s2 != null) ? 2 : 1; 
        
        String myPtrLLVM;
        if ($t.sname != null && $t.sname.contains("(")) {
            myPtrLLVM = $t.sname; 
        } else {
            myPtrLLVM = toLLVMPtrType(myBase, $t.sname, depth); 
        }
        
        if (symtab.containsKey(name)) {
            System.err.println("Error! " + $id.getLine() + ": Redeclared identifier " + name + ".");
        } else {
            Info info = new Info();
            info.theType = TypeInfo.Pointer;
            info.pointeeType = (depth == 2) ? TypeInfo.Pointer : myBase; 
            info.baseType = myBase; 
            info.ptrDepth = depth;  
            info.isPointer = true;
            info.structName = $t.sname;
            
            String ptr = newTemp();
            addInstruction(ptr + " = alloca " + myPtrLLVM + ", align 8");
            info.tmp = ptr;
            symtab.put(name, info);
            
            exactTypeMap.put(ptr, myPtrLLVM + "*"); 
            
            // ✨ 修正這裡：加入強大的 bitcast 防護網 ✨
            if ($init.ctx != null && $init.tmp != null) {
                String rhs = "0".equals($init.tmp) ? "null" : $init.tmp;
                
                // 如果不是 null，且型別不一樣，就強制轉型！
                if (!rhs.equals("null")) {
                    String srcLLVM = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : "i8*";
                    if (!srcLLVM.equals(myPtrLLVM)) {
                        String casted = newTemp();
                        addInstruction(casted + " = bitcast " + srcLLVM + " " + rhs + " to " + myPtrLLVM);
                        rhs = casted; // 把轉型後的結果交給 rhs
                    }
                }
                
                addInstruction("store " + myPtrLLVM + " " + rhs + ", " + myPtrLLVM + "* " + ptr + ", align 8");
            }
        }
      }
    // ── ✨ typedef 別名變數宣告（統一入口）：MyInt a; Rect rc; Cmp fn = f; ──
    // 語意謂詞：typedefMap 涵蓋所有 typedef（含 funcPtr typedef），用單一謂詞攔截
    | ('static'|'extern'|'register')? ('const')? tAlias=ID {typedefMap.containsKey($tAlias.getText())}? id=ID ('=' taInitExpr=expression)? ';'
      {
        String aliasName = $tAlias.getText();
        String name = $id.getText();
        // ── 分支：funcPtr typedef vs 一般 typedef ──
        if (funcPtrTypedefMap.containsKey(aliasName)) {
            // ── 函式指標 typedef：Cmp my_cmp = max_compare; ──
            String fpType = funcPtrTypedefMap.get(aliasName);
            if (symtab.containsKey(name)) {
                System.err.println("Error! " + $id.getLine() + ": Redeclared identifier " + name + ".");
                $type = TypeInfo.Error;
            } else {
                String ptr = newTemp();
                addInstruction(ptr + " = alloca " + fpType + ", align 8");
                Info info = new Info();
                info.theType = TypeInfo.Pointer;
                info.isPointer = true;
                info.ptrDepth = 1;
                info.baseType = TypeInfo.Pointer;
                info.structName = fpType;
                info.tmp = ptr;
                symtab.put(name, info);
                exactTypeMap.put(ptr, fpType + "*");
                if (!inGlobalScope && !scopeTracker.isEmpty()) scopeTracker.peek().add(name);
                if ($taInitExpr.ctx != null) {
                    String rhs = $taInitExpr.tmp;
                    String srcType = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : fpType;
                    if (!srcType.equals(fpType)) {
                        String casted = newTemp();
                        addInstruction(casted + " = bitcast " + srcType + " " + rhs + " to " + fpType);
                        rhs = casted;
                    }
                    addInstruction("store " + fpType + " " + rhs + ", " + fpType + "* " + ptr + ", align 8");
                } else {
                    addInstruction("store " + fpType + " null, " + fpType + "* " + ptr + ", align 8");
                }
                $type = TypeInfo.Pointer;
            }
        } else {
            // ── 一般 typedef：MyInt a = 42; Complex c1; Point p; ──
            TypeInfo aliasType = typedefMap.get(aliasName);
            String aliasStructName = typedefStructMap.get(aliasName);
            $type = aliasType;
            if (symtab.containsKey(name) && (inGlobalScope || (!scopeTracker.isEmpty() && scopeTracker.peek().contains(name)))) {
                System.err.println("Error! " + $id.getLine() + ": Redeclared identifier " + name + ".");
            } else {
                if (!inGlobalScope && !scopeTracker.isEmpty()) scopeTracker.peek().add(name);
                String llvmT;
                if (aliasType == TypeInfo.Struct && aliasStructName != null) {
                    llvmT = "%struct." + aliasStructName;
                } else {
                    llvmT = toLLVMType(aliasType);
                }
                int align = getAlign(aliasType);
                if (inGlobalScope) {
                    String globalName = "@" + name;
                    String zeroVal;
                    if (aliasType == TypeInfo.Float || aliasType == TypeInfo.Double) zeroVal = "0.0";
                    else if (aliasType == TypeInfo.Struct) zeroVal = "zeroinitializer";
                    else zeroVal = "0";
                    stringDefs.add(globalName + " = global " + llvmT + " " + zeroVal + ", align " + align);
                    Info info = new Info();
                    info.theType = aliasType;
                    info.structName = aliasStructName;
                    info.tmp = globalName;
                    symtab.put(name, info);
                    globalSymtab.put(name, info);
                } else {
                    String ptr = newTemp();
                    addInstruction(ptr + " = alloca " + llvmT + ", align " + align);
                    Info info = new Info();
                    info.theType = aliasType;
                    info.structName = aliasStructName;
                    info.tmp = ptr;
                    symtab.put(name, info);
                    if ($taInitExpr.ctx != null && $taInitExpr.tmp != null) {
                        String rhs = emitConvert($taInitExpr.type, $taInitExpr.tmp, aliasType);
                        addInstruction("store " + llvmT + " " + rhs + ", " + llvmT + "* " + ptr + ", align " + align);
                    }
                }
            }
        }
      }
    // ── 1a. 三維陣列宣告  type id[sz1][sz2][sz3]; ──
    | (stka3='static'|'extern'|'register')? ('const')? t=typeSpecifier id=ID '[' sz1Tok=arraySize ']' '[' sz2Tok=arraySize ']' '[' sz3Tok=arraySize ']' ';'
      {
        $arrInitList = null; $strInitVal = null; $arrDesignIdxList = null;
        String name = $id.getText();
        TypeInfo elemType = $t.type;
        int dim1 = $sz1Tok.value;
        int dim2 = $sz2Tok.value;
        int dim3 = $sz3Tok.value;
        String llvmT = toLLVMType(elemType);
        // [dim1 x [dim2 x [dim3 x T]]]
        String dim3Type = "[" + dim3 + " x " + llvmT + "]";
        String dim2Type = "[" + dim2 + " x " + dim3Type + "]";
        String arrType3 = "[" + dim1 + " x " + dim2Type + "]";

        if (inGlobalScope) {
            String globalName = "@" + name;
            Info info = new Info();
            info.theType = elemType;
            info.arraySize = dim1;
            info.arrayDim2 = dim2;
            info.arrayDim3 = dim3;
            info.tmp = globalName;
            stringDefs.add(globalName + " = global " + arrType3 + " zeroinitializer, align 4");
            globalSymtab.put(name, info);
            symtab.put(name, info);
        } else {
            if (!scopeTracker.isEmpty()) scopeTracker.peek().add(name);
            String ptr = newTemp();
            addInstruction(ptr + " = alloca " + arrType3 + ", align 4");
            Info info = new Info();
            info.theType = elemType;
            info.arraySize = dim1;
            info.arrayDim2 = dim2;
            info.arrayDim3 = dim3;
            info.tmp = ptr;
            symtab.put(name, info);
        }
        $type = elemType;
      }
    // ── 1. 支援 const 與 可選的第二維度，size 可為數字或常數 ID ──
    | (stka='static'|'extern'|'register')? ('const')? t=typeSpecifier id=ID '[' szTok=arraySize? ']' ('[' sz2Tok=arraySize ']')?
      { $arrInitList = null; $strInitVal = null; $arrDesignIdxList = null; $arrDesignRangeList = null; }
      ( '=' 
        ( '{'
            {
                $arrInitList = new java.util.ArrayList<>();
                // ✨ arrDesignIdxList: 每個元素對應的 designated index
                $arrDesignIdxList = new java.util.ArrayList<>();
                $autoIdx = 0; // 自動遞增計數器
            }
            // 第一個元素：可選 [idx]= 或 [lo ... hi]= 前綴
            ( '[' di0=DEC_NUM ELLIPSIS dhi0=DEC_NUM ']' '='
              { $autoIdx = Integer.parseInt($di0.getText()); }
              ei=assignmentExpression
              {
                Info _ai = new Info(); _ai.theType = $ei.type; _ai.tmp = $ei.tmp;
                $arrInitList.add(_ai);
                int _lo0 = Integer.parseInt($di0.getText());
                int _hi0 = Integer.parseInt($dhi0.getText());
                $arrDesignIdxList.add(_lo0);
                if ($arrDesignRangeList == null) $arrDesignRangeList = new java.util.ArrayList<>();
                $arrDesignRangeList.add(_hi0);
                $autoIdx = _hi0 + 1;
              }
            | '[' di0s=DEC_NUM ']' '='
              { $autoIdx = Integer.parseInt($di0s.getText()); }
              ei=assignmentExpression
              {
                Info _ai = new Info(); _ai.theType = $ei.type; _ai.tmp = $ei.tmp;
                $arrInitList.add(_ai);
                $arrDesignIdxList.add($autoIdx++);
                if ($arrDesignRangeList != null) $arrDesignRangeList.add(-1);
              }
            | ei=assignmentExpression
              {
                Info _ai = new Info(); _ai.theType = $ei.type; _ai.tmp = $ei.tmp;
                $arrInitList.add(_ai);
                $arrDesignIdxList.add($autoIdx++);
                if ($arrDesignRangeList != null) $arrDesignRangeList.add(-1);
              }
            )
          ( ','
              ( '[' di1=DEC_NUM ELLIPSIS dhi1=DEC_NUM ']' '='
                { $autoIdx = Integer.parseInt($di1.getText()); }
                ej=assignmentExpression
                {
                  Info _aj = new Info(); _aj.theType = $ej.type; _aj.tmp = $ej.tmp;
                  $arrInitList.add(_aj);
                  int _lo1 = Integer.parseInt($di1.getText());
                  int _hi1 = Integer.parseInt($dhi1.getText());
                  $arrDesignIdxList.add(_lo1);
                  if ($arrDesignRangeList == null) $arrDesignRangeList = new java.util.ArrayList<>();
                  $arrDesignRangeList.add(_hi1);
                  $autoIdx = _hi1 + 1;
                }
              | '[' di1s=DEC_NUM ']' '='
                { $autoIdx = Integer.parseInt($di1s.getText()); }
                ej=assignmentExpression
                {
                  Info _aj = new Info(); _aj.theType = $ej.type; _aj.tmp = $ej.tmp;
                  $arrInitList.add(_aj);
                  $arrDesignIdxList.add($autoIdx++);
                  if ($arrDesignRangeList != null) $arrDesignRangeList.add(-1);
                }
              | ej=assignmentExpression
                {
                  Info _aj = new Info(); _aj.theType = $ej.type; _aj.tmp = $ej.tmp;
                  $arrInitList.add(_aj);
                  $arrDesignIdxList.add($autoIdx++);
                  if ($arrDesignRangeList != null) $arrDesignRangeList.add(-1);
                }
              )
            )*
          '}'
        | str=STRINGLITERALS
          { $strInitVal = $str.getText(); $arrDesignIdxList = null; }
        )
      )?
      ';'
    {
        $type = $t.type;
        int arrSize   = (_localctx.szTok != null) ? $szTok.value : 0;
        String vlaSize = (_localctx.szTok != null) ? $szTok.vla_tmp : null;
        int dim2 = (_localctx.sz2Tok != null) ? $sz2Tok.value : -1;
        String name = $id.getText();

        // ── 若 arr[] 沒有明確大小但有字串初始化，從字串長度推斷 ──
        if (arrSize <= 0 && vlaSize == null && $strInitVal != null && $type == TypeInfo.Char) {
            String inner = $strInitVal.substring(1, $strInitVal.length() - 1);
            arrSize = calcLLVMStrLen(inner); // 含 null terminator
        }

        // ── VLA 不允許全域或帶初始化 ──
        if (vlaSize != null && inGlobalScope) {
            System.err.println("Error! " + $id.getLine() + ": VLA not allowed at file scope.");
        } else if (vlaSize != null && $arrInitList != null) {
            System.err.println("Error! " + $id.getLine() + ": VLA cannot have initializer.");
        } else if (arrSize <= 0 && vlaSize == null) {
            System.err.println("Error! " + $id.getLine() + ": Array size must be > 0.");
        } 
        // ✨ 1. 全域重複宣告
        else if (inGlobalScope && symtab.containsKey(name)) {
            System.err.println("Error! " + $id.getLine() + ": Redeclared identifier " + name + ".");
        } 
        // ✨ 2. 區域同層重複宣告
        else if (!inGlobalScope && !scopeTracker.isEmpty() && scopeTracker.peek().contains(name)) {
            System.err.println("Error! " + $id.getLine() + ": Redeclared identifier " + name + ".");
        } 
        // ✨ 3. 合法的新陣列宣告或合法遮蔽
        else {
            if (!inGlobalScope && !scopeTracker.isEmpty()) scopeTracker.peek().add(name);
            
            String llvmT = toLLVMType($type);
            Info info = new Info();
            info.theType = $type;
            info.scopeLevel = currentScopeLevel;

            // ── VLA：使用 alloca 的動態大小形式 ──
            if (vlaSize != null) {
                info.arraySize = -2; // -2 = VLA 標記（-1 已被用於「非陣列」）
                info.arrayDim2 = -1;
                String ptr = newTemp();
                // alloca <elemType>, i64 <n>  → LLVM 合法 VLA
                addInstruction(ptr + " = alloca " + llvmT + ", i64 " + vlaSize + ", align 4");
                info.tmp = ptr;
                info.isPointer = true;      // VLA 存取方式與指標相同
                info.pointeeType = $type;   // 供 [] 運算子使用
                symtab.put(name, info);
            } else {
                info.arraySize = arrSize;
                info.arrayDim2 = dim2;
                String arrType = (dim2 > 0) ? "[" + arrSize + " x [" + dim2 + " x " + llvmT + "]]" : "[" + arrSize + " x " + llvmT + "]";
                
                if (inGlobalScope) {
                    String globalName = "@" + name;
                    info.tmp = globalName;
                    stringDefs.add(globalName + " = global " + arrType + " zeroinitializer, align 4");
                    globalSymtab.put(name, info);
                    symtab.put(name, info);
                } else {
                    String ptr = newTemp();
                    addInstruction(ptr + " = alloca " + arrType + ", align 4");
                    info.tmp = ptr;
                    symtab.put(name, info);
                    
                    // ── 處理 {1, 2, 3} 陣列初始化 ──
                    if ($arrInitList != null) {
                        // ✨ 最大 designated index（含範圍 hi）不能超過陣列大小
                        int maxDesig = 0;
                        if ($arrDesignIdxList != null) {
                            for (int di = 0; di < $arrDesignIdxList.size(); di++) {
                                int lo = $arrDesignIdxList.get(di);
                                int hi = ($arrDesignRangeList != null && di < $arrDesignRangeList.size()) ? $arrDesignRangeList.get(di) : -1;
                                int effHi = (hi >= 0) ? hi : lo;
                                if (effHi > maxDesig) maxDesig = effHi;
                            }
                        }
                        if ($arrDesignIdxList != null && maxDesig >= arrSize) {
                            System.err.println("Error! " + $id.getLine() + ": Designated index " + maxDesig + " out of bounds for array '" + name + "' (size " + arrSize + ").");
                        } else if ($arrDesignIdxList == null && $arrInitList.size() > arrSize) {
                            System.err.println("Error! " + $id.getLine() + ": Too many initializers for array '" + name + "'. Expected " + arrSize + ", but got " + $arrInitList.size() + ".");
                        }
                        arrType = "[" + arrSize + " x " + llvmT + "]";

                        // ── 先把整個陣列 zeroinitialize（因為 designated init 可能跳過某些 index）──
                        boolean hasDesig = ($arrDesignIdxList != null);
                        boolean hasRange = ($arrDesignRangeList != null);
                        if (hasDesig) {
                            // memset 整個陣列為 0
                            String castPtr = newTemp();
                            addInstruction(castPtr + " = bitcast [" + arrSize + " x " + llvmT + "]* " + ptr + " to i8*");
                            int byteSize = arrSize * getLLVMTypeBytes($type);
                            addInstruction("call void @llvm.memset.p0i8.i64(i8* " + castPtr + ", i8 0, i64 " + byteSize + ", i1 false)");
                        }

                        for (int ai = 0; ai < $arrInitList.size(); ai++) {
                            // ✨ designated index / range
                            int storeIdxLo = ($arrDesignIdxList != null) ? $arrDesignIdxList.get(ai) : ai;
                            int storeIdxHi = -1;
                            if (hasRange && ai < $arrDesignRangeList.size()) {
                                storeIdxHi = $arrDesignRangeList.get(ai); // -1 = 非範圍
                            }
                            // 若不是範圍，hi = lo
                            if (storeIdxHi < 0) storeIdxHi = storeIdxLo;

                            Info elemInfo = $arrInitList.get(ai);
                            String elemTmp = elemInfo.tmp;
                            // 型別轉換
                            if (info.theType == TypeInfo.Float && elemInfo.theType == TypeInfo.Int) {
                                String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + elemTmp + " to float"); elemTmp = conv;
                            } else if (info.theType == TypeInfo.Double && elemInfo.theType == TypeInfo.Int) {
                                String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + elemTmp + " to double"); elemTmp = conv;
                            } else if (info.theType == TypeInfo.Int && (elemInfo.theType == TypeInfo.Float || elemInfo.theType == TypeInfo.Double)) {
                                String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(elemInfo.theType) + " " + elemTmp + " to i32"); elemTmp = conv;
                            } else if (info.theType == TypeInfo.Float && elemInfo.theType == TypeInfo.Double) {
                                String conv = newTemp(); addInstruction(conv + " = fptrunc double " + elemTmp + " to float"); elemTmp = conv;
                            } else if (info.theType == TypeInfo.Double && elemInfo.theType == TypeInfo.Float) {
                                String conv = newTemp(); addInstruction(conv + " = fpext float " + elemTmp + " to double"); elemTmp = conv;
                            } else if (info.theType == TypeInfo.Char && elemInfo.theType == TypeInfo.Int) {
                                String conv = newTemp(); addInstruction(conv + " = trunc i32 " + elemTmp + " to i8"); elemTmp = conv;
                            } else if (info.theType == TypeInfo.Int && elemInfo.theType == TypeInfo.Char) {
                                String conv = newTemp(); addInstruction(conv + " = sext i8 " + elemTmp + " to i32"); elemTmp = conv;
                            }

                            // ✨ 範圍展開：[lo ... hi] = val → store 到每個 index
                            for (int ri = storeIdxLo; ri <= storeIdxHi && ri < arrSize; ri++) {
                                String elemPtr = newTemp();
                                addInstruction(elemPtr + " = getelementptr inbounds " + arrType + ", " + arrType + "* " + ptr + ", i32 0, i32 " + ri);
                                addInstruction("store " + llvmT + " " + elemTmp + ", " + llvmT + "* " + elemPtr + ", align 4");
                            }
                        }
                    } 
                    // ── 處理 "Hello" 字串初始化 ──
                    else if ($strInitVal != null) {
                        if (info.theType != TypeInfo.Char) {
                            System.err.println("Error! " + $id.getLine() + ": Type mismatch. Cannot initialize non-char array '" + name + "' with a string literal.");
                        } else {
                            String rawStr = $strInitVal.substring(1, $strInitVal.length() - 1);
                            java.util.List<Integer> charBytes = new java.util.ArrayList<>();
                            int sIdx = 0;
                            while (sIdx < rawStr.length()) {
                                if (rawStr.charAt(sIdx) == '\\' && sIdx + 1 < rawStr.length()) {
                                    switch (rawStr.charAt(sIdx + 1)) {
                                        case 'n':  charBytes.add((int)'\n'); break;
                                        case 't':  charBytes.add((int)'\t'); break;
                                        case '0':  charBytes.add(0); break;
                                        case 'r':  charBytes.add((int)'\r'); break;
                                        case '\\': charBytes.add((int)'\\'); break;
                                        case '\'': charBytes.add((int)'\''); break;
                                        case '\"': charBytes.add((int)'"'); break;
                                        default:   charBytes.add((int)rawStr.charAt(sIdx+1)); break;
                                    }
                                    sIdx += 2;
                                } else {
                                    charBytes.add((int) rawStr.charAt(sIdx++));
                                }
                            }
                            charBytes.add(0);
                            if (charBytes.size() > arrSize) {
                                System.err.println("Error! " + $id.getLine() + ": String literal is too long for character array '" + name + "'.");
                            }
                            arrType = "[" + arrSize + " x i8]";
                            for (int bi = 0; bi < charBytes.size() && bi < arrSize; bi++) {
                                String ep = newTemp();
                                addInstruction(ep + " = getelementptr inbounds " + arrType + ", " + arrType + "* " + ptr + ", i32 0, i32 " + bi);
                                addInstruction("store i8 " + charBytes.get(bi) + ", i8* " + ep + ", align 1");
                            }
                        }
                    }
                }
            }
        }
      }
    | stk=('static'|'extern'|'register')? ('const')? t=typeSpecifier
      { pendingDeclType = $t.type; pendingDeclStructName = $t.sname; }
      dl=declaratorList ';'
      {
        pendingDeclType = TypeInfo.Error; // 重置
        $type = $t.type;
        boolean isStaticLocal = ($stk != null && $stk.getText().equals("static") && !inGlobalScope);

        // ════════════════════════════════════════════════
        // 兩趟處理：
        //   第一趟：全部 alloca + 放入 symtab（不做 store）
        //   第二趟：全部 store init（此時所有變數都已在 symtab）
        // 這樣 int p=5, q=p+3 才能正確讓 q 的 init 看到 p
        // ════════════════════════════════════════════════

        List<String> names = $dl.ids;
        List<Info>   initInfos2 = $dl.initInfos;
        List<List<Info>> initExprLists2 = $dl.initExprLists;
        List<List<DesignElem>> designLists2 = $dl.designLists;
        List<String> ptrs = new java.util.ArrayList<>();
        List<String> alignStrs = new java.util.ArrayList<>();
        List<String> llvmTs = new java.util.ArrayList<>();
        // ── 第一趟：對還沒 alloca 的變數做 alloca（全域 or declaratorList 沒能處理的）──
        for (int i2 = 0; i2 < names.size(); i2++) {
            String name = names.get(i2);
            String prealloc = $dl.preallocPtrs.get(i2);

            if (inGlobalScope) {
                // 全域：declaratorList 不做 alloca，這裡處理
                boolean _isExternDecl = ($stk != null && $stk.getText().equals("extern"));
                if (symtab.containsKey(name)) {
                    // ── extern 重宣告：允許（C 語意：多次 extern 宣告同一個外部符號是合法的）
                    if (!_isExternDecl) {
                        System.err.println("Error! " + $t.start.getLine() + ": Redeclared identifier " + name + ".");
                    }
                    ptrs.add(null); alignStrs.add("4"); llvmTs.add("i32");
                    continue;
                }
                Info info = new Info();
                info.theType = $type;
                info.structName = $t.sname;
                String llvmT2 = toLLVMType($type);
                if ($type == TypeInfo.Struct) llvmT2 = "%struct." + $t.sname;
                String globalName = "@" + name;
                if (_isExternDecl) {
                    // ── extern 變數宣告：生成 external global（讓連結器從其他編譯單元解析）──
                    String _declKey2 = "var:" + name;
                    if (!emittedExternDecls.contains(_declKey2)) {
                        emittedExternDecls.add(_declKey2);
                        stringDefs.add(globalName + " = external global " + llvmT2 + ", align " + getAlign($type));
                    }
                    info.tmp = globalName;
                    globalSymtab.put(name, info);
                    Info ref = new Info(); ref.theType = $type; ref.structName = $t.sname; ref.tmp = globalName;
                    symtab.put(name, ref);
                    ptrs.add(null); alignStrs.add("4"); llvmTs.add(llvmT2);
                } else {
                Info initInfo = initInfos2.get(i2);
                String initVal = ($type == TypeInfo.Float || $type == TypeInfo.Double) ? "0.0" : "0";
                if ($type == TypeInfo.Struct) initVal = "zeroinitializer";
                else if (initInfo != null && initInfo.theType != TypeInfo.Error) {
                    if (($type == TypeInfo.Float || $type == TypeInfo.Double) && initInfo.theType == TypeInfo.Int) {
                        try { int iv = Integer.parseInt(initInfo.tmp); float fv = (float)iv;
                              long bits = Double.doubleToLongBits((double)fv);
                              initVal = String.format("0x%016X", bits); } catch(Exception e2){initVal="0.0";}
                    } else if ($type == TypeInfo.Int && (initInfo.theType == TypeInfo.Float || initInfo.theType == TypeInfo.Double)) {
                        try { long bits2 = Long.parseUnsignedLong(initInfo.tmp.substring(2),16);
                              double dv = Double.longBitsToDouble(bits2);
                              initVal = String.valueOf((int)dv); } catch(Exception e3){initVal="0";}
                    } else if ($type == TypeInfo.Float && initInfo.theType == TypeInfo.Double) {
                        // Double hex → Float hex
                        try { long bits = Long.parseUnsignedLong(initInfo.tmp.startsWith("0x")||initInfo.tmp.startsWith("0X") ? initInfo.tmp.substring(2) : "0", 16);
                              double dv = Double.longBitsToDouble(bits);
                              float fv = (float)dv;
                              long fbits = Double.doubleToLongBits((double)fv);
                              initVal = String.format("0x%016X", fbits);
                        } catch(Exception ef){ initVal = initInfo.tmp; }
                    } else if ($type == TypeInfo.Double && initInfo.theType == TypeInfo.Float) {
                        // Float hex → Double hex（直接用，LLVM float hex 已是 64-bit 格式）
                        initVal = initInfo.tmp;
                    } else { initVal = initInfo.tmp; }
                }
                info.tmp = globalName + " = global " + llvmT2 + " " + initVal + ", align " + getAlign($type);
                globalSymtab.put(name, info);
                Info ref = new Info(); ref.theType = $type; ref.structName = $t.sname; ref.tmp = globalName;
                symtab.put(name, ref);
                ptrs.add(null); alignStrs.add("4"); llvmTs.add(llvmT2);
                } // end: !_isExternDecl

            } else if (prealloc != null) {
                // 區域：declaratorList 已做好 alloca，直接用
                String llvmT2 = (pendingDeclType == TypeInfo.Struct && $t.sname != null)
                    ? "%struct." + $t.sname : toLLVMType($type);
                String alignStr2 = String.valueOf(getAlign($type));
                // ✨ static 局部變數：把剛才 declaratorList 做的 alloca 提升為全域
                if (isStaticLocal) {
                    String globalN = "@__static_" + (staticLocalCounter++);
                    Info initInfo0 = initInfos2.get(i2);
                    String zeroV = ($type == TypeInfo.Float || $type == TypeInfo.Double) ? "0.0" : "0";
                    String initV0 = (initInfo0 != null && initInfo0.theType != TypeInfo.Error && initInfo0.tmp != null && !"0".equals(initInfo0.tmp)) ? initInfo0.tmp : zeroV;
                    stringDefs.add(globalN + " = global " + llvmT2 + " " + initV0 + ", align " + alignStr2);
                    // 把 declaratorList 已做的 alloca 指令移除，改用全域
                    List<String> buf2 = currentTextCodeBuffer;
                    if (buf2 != null) {
                        for (int sli = buf2.size() - 1; sli >= 0; sli--) {
                            String instr2 = buf2.get(sli);
                            if (instr2.equals(prealloc + " = alloca " + llvmT2 + ", align " + alignStr2)) {
                                buf2.remove(sli); break;
                            }
                        }
                    }
                    // 更新 symtab
                    for (Info si2 : symtab.values()) {
                        if (prealloc.equals(si2.tmp)) { si2.tmp = globalN; break; }
                    }
                    ptrs.add(null); alignStrs.add(alignStr2); llvmTs.add(llvmT2);
                    continue;
                }
                // 若是 const int，記錄編譯期數值
                if ($type == TypeInfo.Int) {
                    Info initInfo = initInfos2.get(i2);
                    if (initInfo != null) {
                        try { constIntValues.put(name, Integer.parseInt(initInfo.tmp)); } catch(Exception e2){}
                    }
                }
                ptrs.add(prealloc);
                alignStrs.add(alignStr2);
                llvmTs.add(llvmT2);

            } else {
            // 區域：declaratorList 沒能 alloca（通常是因為重複宣告，已在 declaratorList 報錯過）
                if (!scopeTracker.isEmpty() && scopeTracker.peek().contains(name)) {
                    // ✨ 修正：直接略過，不要再印一次錯誤！
                    ptrs.add(null); alignStrs.add("4"); llvmTs.add("i32");
                    continue;
                }
                if (!scopeTracker.isEmpty()) scopeTracker.peek().add(name);
                Info info = new Info();
                info.theType = $type;
                info.structName = $t.sname;
                String llvmT2 = toLLVMType($type);
                if ($type == TypeInfo.Struct) llvmT2 = "%struct." + $t.sname;
                String alignStr2 = String.valueOf(getAlign($type));
                // ✨ static 局部變數：改為全域宣告 ✨
                if (isStaticLocal) {
                    String globalN = "@__static_" + (staticLocalCounter++);
                    Info initInfo0 = initInfos2.get(i2);
                    String zeroV = ($type == TypeInfo.Float || $type == TypeInfo.Double) ? "0.0" : "0";
                    String initV0 = (initInfo0 != null && initInfo0.theType != TypeInfo.Error && initInfo0.tmp != null && !"0".equals(initInfo0.tmp)) ? initInfo0.tmp : zeroV;
                    stringDefs.add(globalN + " = global " + llvmT2 + " " + initV0 + ", align " + alignStr2);
                    info.tmp = globalN;
                    symtab.put(name, info);
                    globalSymtab.put(name, info);
                    // static 局部初始化已在 global，不需要 store
                    ptrs.add(null); alignStrs.add(alignStr2); llvmTs.add(llvmT2);
                    continue;
                }
                String ptr = newTemp();
                addInstruction(ptr + " = alloca " + llvmT2 + ", align " + alignStr2);
                info.tmp = ptr;
                symtab.put(name, info);
                if ($type == TypeInfo.Int) {
                    Info initInfo = initInfos2.get(i2);
                    if (initInfo != null) {
                        try { constIntValues.put(name, Integer.parseInt(initInfo.tmp)); } catch(Exception e2){}
                    }
                }
                ptrs.add(ptr);
                alignStrs.add(alignStr2);
                llvmTs.add(llvmT2);
            }
        }

        // ── 第二趟：store init（此時所有變數都已在 symtab）──
        // 注意：全域變數已在第一趟處理，第二趟只處理區域
        for (int i2 = 0; i2 < names.size(); i2++) {
            if (inGlobalScope) continue;
            String ptr = ptrs.get(i2);
            if (ptr == null) continue;
            String alignStr2 = alignStrs.get(i2);
            String llvmT2 = llvmTs.get(i2);
            Info initInfo = initInfos2.get(i2);
            List<Info> initExprList = initExprLists2.get(i2);

            if ($type == TypeInfo.Struct && initExprList != null) {
                StructDef sdef = structRegistry.get($t.sname);
                // ✨ 新增：如果是 union，只能初始化第一個成員
                int maxInit = (sdef != null && sdef.isUnion) ? 1 : (sdef != null ? sdef.fTypes.size() : 0);
                // ✨ 取出本變數的 designList（可能為 null）
                List<DesignElem> dlist = (designLists2 != null && i2 < designLists2.size()) ? designLists2.get(i2) : null;
                // ✨ 先偵測是否為 designated init（有任何 fieldName 非 null）
                boolean isDesig = false;
                if (dlist != null) { for (DesignElem de : dlist) { if (de.fieldName != null) { isDesig = true; break; } } }
                if (isDesig && sdef != null) {
                    // ── Designated struct init：{ .x = val, .y = val } ──
                    // 先把未指定的欄位 zeroinitializer
                    String llvmT3D = "%struct." + $t.sname;
                    for (int f = 0; f < maxInit; f++) {
                        // 找是否有 designator 指定此欄位
                        Info fInfo = null;
                        for (DesignElem de : dlist) {
                            if (de.fieldName != null && de.fieldName.equals(sdef.fNames.get(f))) {
                                fInfo = de.val; break;
                            }
                        }
                        // 沒有被指定：store 0（alloca 不保證 zeroinitializer）
                        if (fInfo == null) {
                            String fType = toLLVMType(sdef.fTypes.get(f));
                            String fPtr2 = newTemp();
                            addInstruction(fPtr2 + " = getelementptr inbounds " + llvmT3D + ", " + llvmT3D + "* " + ptr + ", i32 0, i32 " + f);
                            String zeroVal = (sdef.fTypes.get(f) == TypeInfo.Float) ? "0.0"
                                           : (sdef.fTypes.get(f) == TypeInfo.Double) ? "0.0"
                                           : (sdef.fTypes.get(f) == TypeInfo.Long || sdef.fTypes.get(f) == TypeInfo.UnsignedLong) ? "0"
                                           : "0";
                            addInstruction("store " + fType + " " + zeroVal + ", " + fType + "* " + fPtr2 + ", align 4");
                            continue;
                        }
                        String fType = toLLVMType(sdef.fTypes.get(f));
                        String fPtr2 = newTemp();
                        if (sdef.isUnion) {
                            addInstruction(fPtr2 + " = bitcast " + llvmT3D + "* " + ptr + " to " + fType + "*");
                        } else {
                            addInstruction(fPtr2 + " = getelementptr inbounds " + llvmT3D + ", " + llvmT3D + "* " + ptr + ", i32 0, i32 " + f);
                        }
                        // 型別轉換
                        String fTmp = fInfo.tmp;
                        if (sdef.fTypes.get(f) == TypeInfo.Int && fInfo.theType == TypeInfo.Char) {
                            String cv = newTemp(); addInstruction(cv + " = sext i8 " + fTmp + " to i32"); fTmp = cv;
                        } else if (sdef.fTypes.get(f) == TypeInfo.Char && fInfo.theType == TypeInfo.Int) {
                            String cv = newTemp(); addInstruction(cv + " = trunc i32 " + fTmp + " to i8"); fTmp = cv;
                        } else if ((sdef.fTypes.get(f) == TypeInfo.Float || sdef.fTypes.get(f) == TypeInfo.Double) && fInfo.theType == TypeInfo.Int) {
                            String cv = newTemp(); addInstruction(cv + " = sitofp i32 " + fTmp + " to " + fType); fTmp = cv;
                        }
                        addInstruction("store " + fType + " " + fTmp + ", " + fType + "* " + fPtr2 + ", align 4");
                    }
                } else {
                for (int f = 0; f < initExprList.size() && f < maxInit; f++) {
                    Info fInfo = initExprList.get(f);
                    String fType = toLLVMType(sdef.fTypes.get(f));
                    String fPtr2 = newTemp();
                    String llvmT3 = "%struct." + $t.sname;
                    
                    // ✨ Union 的魔法：不偏移，直接 bitcast 轉型
                    if (sdef.isUnion) {
                        addInstruction(fPtr2 + " = bitcast " + llvmT3 + "* " + ptr + " to " + fType + "*");
                    } else {
                        addInstruction(fPtr2 + " = getelementptr inbounds " + llvmT3 + ", " + llvmT3 + "* " + ptr + ", i32 0, i32 " + f);
                    }
                    addInstruction("store " + fType + " " + fInfo.tmp + ", " + fType + "* " + fPtr2 + ", align 4");
                }
                }
            } else if (initInfo != null && $type != TypeInfo.Struct) {
                String storeVal = initInfo.tmp;
                TypeInfo initType = initInfo.theType;
                // 👇 ✨ 補上 Long (i64) 相關的隱式轉型 ✨ 👇
                if ($type == TypeInfo.Long && (initType == TypeInfo.Int || initType == TypeInfo.Boolean || initType == TypeInfo.Char)) {
                    String srcT = (initType == TypeInfo.Char) ? "i8" : (initType == TypeInfo.Boolean) ? "i1" : "i32";
                    String extOp = (initType == TypeInfo.Boolean) ? "zext" : "sext"; // ✨ Bug fix：bool→long 必須 zext
                    String conv = newTemp();
                    addInstruction(conv + " = " + extOp + " " + srcT + " " + storeVal + " to i64"); storeVal = conv;
                } else if ($type == TypeInfo.Int && initType == TypeInfo.Long) {
                    String conv = newTemp();
                    addInstruction(conv + " = trunc i64 " + storeVal + " to i32"); storeVal = conv;
                } else if ($type == TypeInfo.Long && (initType == TypeInfo.Float || initType == TypeInfo.Double)) {
                    String conv = newTemp();
                    addInstruction(conv + " = fptosi " + toLLVMType(initType) + " " + storeVal + " to i64"); storeVal = conv;
                } else if (($type == TypeInfo.Float || $type == TypeInfo.Double) && initType == TypeInfo.Long) {
                    String conv = newTemp();
                    addInstruction(conv + " = sitofp i64 " + storeVal + " to " + llvmT2); storeVal = conv;
                } 
                // 👆 👆 新增結束 👆 👆
                else if ($type == TypeInfo.Int && (initType == TypeInfo.Float || initType == TypeInfo.Double)) {
                    String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(initType) + " " + storeVal + " to i32"); storeVal = conv;
                } else if (($type == TypeInfo.Float || $type == TypeInfo.Double) && initType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + storeVal + " to " + llvmT2); storeVal = conv;
                } else if ($type == TypeInfo.Float && initType == TypeInfo.Double) {
                    // ── Double → Float（截斷）──
                    String conv = newTemp(); addInstruction(conv + " = fptrunc double " + storeVal + " to float"); storeVal = conv;
                } else if ($type == TypeInfo.Double && initType == TypeInfo.Float) {
                    // ── Float → Double（提升）──
                    String conv = newTemp(); addInstruction(conv + " = fpext float " + storeVal + " to double"); storeVal = conv;
                } else if ($type == TypeInfo.Char && initType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = trunc i32 " + storeVal + " to i8"); storeVal = conv;
                } else if ($type == TypeInfo.Int && initType == TypeInfo.Char) {
                    String conv = newTemp(); addInstruction(conv + " = sext i8 " + storeVal + " to i32"); storeVal = conv;
                } else if ($type == TypeInfo.Boolean && initType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = icmp ne i32 " + storeVal + ", 0"); storeVal = conv;
                } else if ($type == TypeInfo.Int && initType == TypeInfo.Boolean) {
                    String conv = newTemp(); addInstruction(conv + " = zext i1 " + storeVal + " to i32"); storeVal = conv;
                } else if (isIntegerType($type) && isIntegerType(initType) && $type != initType) {
                    // ── Short/Unsigned 通用轉型（emitConvert 統一處理）──
                    storeVal = emitConvert(initType, storeVal, $type);
                }
                // ── 防護：若目標是 float/double 但 storeVal 是純整數字串，強制加 .0 ──
                if (($type == TypeInfo.Double || $type == TypeInfo.Float) && storeVal.matches("-?\\d+")) {
                    storeVal = storeVal + ".0";
                }
                addInstruction("store " + llvmT2 + " " + storeVal + ", " + llvmT2 + "* " + ptr + ", align " + alignStr2);
            }
        }
      }
    ;

// ── declaratorList：每個 ID parse 後立刻 alloca 放入 symtab，
//    再 parse init expression，確保 int p=5, q=p+3 正確 ──
declaratorList returns [List<String> ids, List<Info> initInfos, List<List<Info>> initExprLists, List<String> preallocPtrs, List<List<DesignElem>> designLists]
    @init {
        $ids = new ArrayList<>();
        $initInfos = new ArrayList<>();
        $initExprLists = new ArrayList<>();
        $preallocPtrs = new ArrayList<>();
        $designLists  = new ArrayList<>();
    }
    : idTok=ID
      {
        String _name = $idTok.getText();
        String _ptr = null;
        
        if (!inGlobalScope && pendingDeclType != TypeInfo.Error) {
            if (!scopeTracker.isEmpty() && scopeTracker.peek().contains(_name)) {
                System.err.println("Error! " + $idTok.getLine() + ": Redeclared identifier " + _name + ".");
            } else {
                if (!scopeTracker.isEmpty()) scopeTracker.peek().add(_name);
                
                String _llvmT;
                String _align;
                if ("__va_list".equals(pendingDeclStructName)) {
                    _llvmT = "[24 x i8]"; _align = "16";
                } else if (pendingDeclType == TypeInfo.Struct && pendingDeclStructName != null) {
                    _llvmT = "%struct." + pendingDeclStructName; _align = String.valueOf(getAlign(pendingDeclType));
                } else {
                    _llvmT = toLLVMType(pendingDeclType); _align = String.valueOf(getAlign(pendingDeclType));
                }
                
                _ptr = newTemp();
                addInstruction(_ptr + " = alloca " + _llvmT + ", align " + _align);
                
                Info _info = new Info();
                _info.theType = pendingDeclType;
                _info.structName = pendingDeclStructName;
                _info.tmp = _ptr;
                if ("__va_list".equals(pendingDeclStructName)) {
                    exactTypeMap.put(_ptr, "[24 x i8]*");
                }
                
                symtab.put(_name, _info);
            }
        }
        
        $ids.add(_name);
        $initInfos.add(null);
        $initExprLists.add(null);
        $designLists.add(null);
        $preallocPtrs.add(_ptr);
      }
      
      // ✨ 修正重點：當讀到第一個變數的陣列大小時，完整補齊 3 個符號表屬性
      ( '[' size=DEC_NUM ']' 
        {
            Info existingInfo = symtab.get(_name);
            if (existingInfo != null) {
                existingInfo.arraySize = Integer.parseInt($size.getText());
                existingInfo.isPointer = true;
                existingInfo.pointeeType = existingInfo.theType; // 核心：指向的型別就是它原本的型別 (Char)
            }
            
            Info globalExistingInfo = globalSymtab.get(_name);
            if (globalExistingInfo != null) {
                globalExistingInfo.arraySize = Integer.parseInt($size.getText());
                globalExistingInfo.isPointer = true;
                globalExistingInfo.pointeeType = globalExistingInfo.theType;
            }
        }
      )*
      
      ( '=' init=initializer 
        {
            $initInfos.set($initInfos.size()-1, $init.info);
            $initExprLists.set($initExprLists.size()-1, $init.exprList);
            $designLists.set($designLists.size()-1, $init.designList);
        }
      )?
      
    ( ',' 
        {
            int _last = $ids.size() - 1;
            if (_last >= 0 && $preallocPtrs.get(_last) != null && $initInfos.get(_last) != null 
                && !inGlobalScope && pendingDeclType != TypeInfo.Error) {
                String _prevPtr = $preallocPtrs.get(_last);
        
                Info _prevInit = $initInfos.get(_last);
                String _llvmT3 = (pendingDeclType == TypeInfo.Struct && pendingDeclStructName != null) 
                    ? "%struct." + pendingDeclStructName : toLLVMType(pendingDeclType);
                String _align3 = String.valueOf(getAlign(pendingDeclType));
       
                // ✨ FIX START: 補上同行宣告 (comma) 的隱式轉型邏輯 ✨
                String storeVal = _prevInit.tmp;
                TypeInfo initType = _prevInit.theType;
                // 👇 ✨ 補上 Long (i64) 相關的隱式轉型 ✨ 👇
                if (pendingDeclType == TypeInfo.Long && (initType == TypeInfo.Int || initType == TypeInfo.Boolean || initType == TypeInfo.Char)) {
                    String srcT = (initType == TypeInfo.Char) ? "i8" : (initType == TypeInfo.Boolean) ? "i1" : "i32";
                    String extOp = (initType == TypeInfo.Boolean) ? "zext" : "sext"; // ✨ Bug fix：bool→long 必須 zext
                    String conv = newTemp();
                    addInstruction(conv + " = " + extOp + " " + srcT + " " + storeVal + " to i64"); storeVal = conv;
                } else if (pendingDeclType == TypeInfo.Int && initType == TypeInfo.Long) {
                    String conv = newTemp();
                    addInstruction(conv + " = trunc i64 " + storeVal + " to i32"); storeVal = conv;
                } else if (pendingDeclType == TypeInfo.Long && (initType == TypeInfo.Float || initType == TypeInfo.Double)) {
                    String conv = newTemp();
                    addInstruction(conv + " = fptosi " + toLLVMType(initType) + " " + storeVal + " to i64"); storeVal = conv;
                } else if ((pendingDeclType == TypeInfo.Float || pendingDeclType == TypeInfo.Double) && initType == TypeInfo.Long) {
                    String conv = newTemp();
                    addInstruction(conv + " = sitofp i64 " + storeVal + " to " + _llvmT3); storeVal = conv;
                }
                // 👆 👆 新增結束 👆 👆
                else if (pendingDeclType == TypeInfo.Int && (initType == TypeInfo.Float || initType == TypeInfo.Double)) {
                    String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(initType) + " " + storeVal + " to i32"); storeVal = conv;
                } else if ((pendingDeclType == TypeInfo.Float || pendingDeclType == TypeInfo.Double) && initType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + storeVal + " to " + _llvmT3); storeVal = conv;
                } else if (pendingDeclType == TypeInfo.Float && initType == TypeInfo.Double) {
                    String conv = newTemp(); addInstruction(conv + " = fptrunc double " + storeVal + " to float"); storeVal = conv;
                } else if (pendingDeclType == TypeInfo.Double && initType == TypeInfo.Float) {
                    String conv = newTemp(); addInstruction(conv + " = fpext float " + storeVal + " to double"); storeVal = conv;
                } else if (pendingDeclType == TypeInfo.Char && initType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = trunc i32 " + storeVal + " to i8"); storeVal = conv;
                } else if (pendingDeclType == TypeInfo.Int && initType == TypeInfo.Char) {
                    String conv = newTemp(); addInstruction(conv + " = sext i8 " + storeVal + " to i32"); storeVal = conv;
                } else if (pendingDeclType == TypeInfo.Boolean && initType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = icmp ne i32 " + storeVal + ", 0"); storeVal = conv;
                } else if (pendingDeclType == TypeInfo.Int && initType == TypeInfo.Boolean) {
                    String conv = newTemp(); addInstruction(conv + " = zext i1 " + storeVal + " to i32"); storeVal = conv;
                } else if (isIntegerType(pendingDeclType) && isIntegerType(initType) && pendingDeclType != initType) {
                    // ── Short/Unsigned 通用轉型 ──
                    storeVal = emitConvert(initType, storeVal, pendingDeclType);
                
                }
                
                // 👇 👇 從這裡開始替換/新增 👇 👇
                // ✨ 核心修正 2：逗號連鎖宣告的 bitcast 防護網 ✨
                if (pendingDeclType == TypeInfo.Pointer && (initType == TypeInfo.Pointer || storeVal.equals("0"))) {
                    if (storeVal.equals("0")) {
                        storeVal = "null";
                    } else {
                        String srcLLVM = exactTypeMap.containsKey(storeVal) ? exactTypeMap.get(storeVal) : "i8*";
                        if (!srcLLVM.equals(_llvmT3)) {
                            String casted = newTemp();
                            addInstruction(casted + " = bitcast " + srcLLVM + " " + storeVal + " to " + _llvmT3);
                            storeVal = casted;
                        }
                    }
                }
                
                // 儲存已轉型的值
                addInstruction("store " + _llvmT3 + " " + storeVal + ", " + _llvmT3 + "* " + _prevPtr + ", align " + _align3);
                // ✨ 將已轉型完成的屬性同步回 _prevInit，防止 declaration 第2趟再度重複轉型
                _prevInit.tmp = storeVal;
                _prevInit.theType = pendingDeclType;
                // ✨ FIX END ✨
                // 👆 👆 替換到這裡 👆 👆
            }
        }
        
        idTok2=ID 
        {
            String _name2 = $idTok2.getText();
            String _ptr2 = null;
            if (!inGlobalScope && pendingDeclType != TypeInfo.Error) {
                if (!scopeTracker.isEmpty() && scopeTracker.peek().contains(_name2)) {
                    System.err.println("Error! " + $idTok2.getLine() + ": Redeclared identifier " + _name2 + ".");
                } else {
                    if (!scopeTracker.isEmpty()) scopeTracker.peek().add(_name2);
                    String _llvmT2 = (pendingDeclType == TypeInfo.Struct && pendingDeclStructName != null) 
                        ? "%struct." + pendingDeclStructName : toLLVMType(pendingDeclType);
                    String _align2 = (pendingDeclType == TypeInfo.Boolean) ? "1" 
                                   : (pendingDeclType == TypeInfo.Pointer) ? "8" : "4";
                    
                    _ptr2 = newTemp();
                    addInstruction(_ptr2 + " = alloca " + _llvmT2 + ", align " + _align2);
                    
                    Info _info2 = new Info();
                    _info2.theType = pendingDeclType;
                    _info2.structName = pendingDeclStructName;
                    _info2.tmp = _ptr2;
                    symtab.put(_name2, _info2);
                }
            }
            $ids.add(_name2);
            $initInfos.add(null);
            $initExprLists.add(null);
            $designLists.add(null);
            $preallocPtrs.add(_ptr2);
        }
        
        // ✨ 修正重點：針對逗號後的變數，同樣完整補齊 3 個屬性
        ( '[' size2=DEC_NUM ']' 
          {
              Info existingInfo2 = symtab.get(_name2);
              if (existingInfo2 != null) {
                  existingInfo2.arraySize = Integer.parseInt($size2.getText());
                  existingInfo2.isPointer = true;
                  existingInfo2.pointeeType = existingInfo2.theType;
              }
              
              Info globalExistingInfo2 = globalSymtab.get(_name2);
              if (globalExistingInfo2 != null) {
                  globalExistingInfo2.arraySize = Integer.parseInt($size2.getText());
                  globalExistingInfo2.isPointer = true;
                  globalExistingInfo2.pointeeType = globalExistingInfo2.theType;
              }
          }
        )*
        
        ( '=' init2=initializer 
          {
              $initInfos.set($initInfos.size()-1, $init2.info);
              $initExprLists.set($initExprLists.size()-1, $init2.exprList);
              $designLists.set($designLists.size()-1, $init2.designList);
          }
        )?
      )*
    ;

// ── arraySize：陣列大小可以是整數字面值、const int ID，或執行期運算式 (VLA) ──
// 回傳 value=-1 代表 VLA，呼叫端需從 vla_tmp 取得執行期大小
arraySize returns [int value, String vla_tmp]
    : n=DEC_NUM  { $value = Integer.parseInt($n.getText()); $vla_tmp = null; }
    | id=ID
      {
        if (constIntValues.containsKey($id.getText())) {
            $value = constIntValues.get($id.getText()); $vla_tmp = null;
        } else if (enumConstants.containsKey($id.getText())) {
            $value = enumConstants.get($id.getText()); $vla_tmp = null;
        } else {
            // ── 視為執行期大小 (VLA) ──
            Info vinfo = symtab.get($id.getText());
            if (vinfo == null) vinfo = globalSymtab.get($id.getText());
            if (vinfo != null) {
                String loadedSz = newTemp();
                addInstruction(loadedSz + " = load " + toLLVMType(vinfo.theType) + ", " + toLLVMType(vinfo.theType) + "* " + vinfo.tmp + ", align 4");
                // 確保是 i64 for alloca
                if (vinfo.theType != TypeInfo.Long) {
                    String sextTmp = newTemp();
                    addInstruction(sextTmp + " = sext i32 " + loadedSz + " to i64");
                    $vla_tmp = sextTmp;
                } else {
                    $vla_tmp = loadedSz;
                }
                $value = -1; // 旗標：VLA
            } else {
                System.err.println("Error! " + $id.getLine() + ": '" + $id.getText() + "' is not a compile-time constant.");
                $value = 1; $vla_tmp = null;
            }
        }
      }
    | e=expression
      {
        // ── 一般運算式作為陣列大小 (VLA) ──
        $value = -1;
        if ($e.type == TypeInfo.Long) {
            $vla_tmp = $e.tmp;
        } else {
            String sextTmp = newTemp();
            addInstruction(sextTmp + " = sext i32 " + $e.tmp + " to i64");
            $vla_tmp = sextTmp;
        }
      }
    ;

declarator returns [String id, Info initInfo, java.util.List<Info> initExprList]
    : idTok=ID 
      { 
        $id = $idTok.getText();
        $initInfo = null; 
        $initExprList = null;
      }
      ('=' init=initializer 
      { 
        $initInfo = $init.info; 
        $initExprList = $init.exprList;
      })?
    ;

initializer returns [Info info, java.util.List<Info> exprList, java.util.List<DesignElem> designList]
    : '{' 
      {
        $exprList  = new java.util.ArrayList<>();
        $designList = new java.util.ArrayList<>();
      }
      // ✨ 支援 designated initializer：.field = expr  或  [idx] = expr  或  plain expr
      ( ( '.' fld=ID '='
            { /* struct designated */ }
            de=assignmentExpression
            {
                Info _di = new Info(); _di.theType = $de.type; _di.tmp = $de.tmp;
                $exprList.add(_di);
                $designList.add(new DesignElem(_di, $fld.getText()));
            }
          | '[' aidx=DEC_NUM ']' '='
            { /* array designated */ }
            ae=assignmentExpression
            {
                Info _ai2 = new Info(); _ai2.theType = $ae.type; _ai2.tmp = $ae.tmp;
                $exprList.add(_ai2);
                $designList.add(new DesignElem(_ai2, Integer.parseInt($aidx.getText())));
            }
          // ✨ GNU 擴充：[lo ... hi] = val（範圍初始化）
          | '[' alo=DEC_NUM ELLIPSIS ahi=DEC_NUM ']' '='
            ae_r=assignmentExpression
            {
                Info _air = new Info(); _air.theType = $ae_r.type; _air.tmp = $ae_r.tmp;
                $exprList.add(_air);
                $designList.add(new DesignElem(_air, Integer.parseInt($alo.getText()), Integer.parseInt($ahi.getText())));
            }
          | pe=assignmentExpression
            {
                Info _pi = new Info(); _pi.theType = $pe.type; _pi.tmp = $pe.tmp;
                $exprList.add(_pi);
                $designList.add(new DesignElem(_pi));
            }
          )
        ( ','
          ( '.' fld2=ID '='
              de2=assignmentExpression
              {
                  Info _di2 = new Info(); _di2.theType = $de2.type; _di2.tmp = $de2.tmp;
                  $exprList.add(_di2);
                  $designList.add(new DesignElem(_di2, $fld2.getText()));
              }
            | '[' aidx2=DEC_NUM ']' '='
              ae2=assignmentExpression
              {
                  Info _ai3 = new Info(); _ai3.theType = $ae2.type; _ai3.tmp = $ae2.tmp;
                  $exprList.add(_ai3);
                  $designList.add(new DesignElem(_ai3, Integer.parseInt($aidx2.getText())));
              }
            // ✨ GNU 擴充：[lo ... hi] = val（範圍初始化，第二組及之後）
            | '[' alo2=DEC_NUM ELLIPSIS ahi2=DEC_NUM ']' '='
              ae_r2=assignmentExpression
              {
                  Info _air2 = new Info(); _air2.theType = $ae_r2.type; _air2.tmp = $ae_r2.tmp;
                  $exprList.add(_air2);
                  $designList.add(new DesignElem(_air2, Integer.parseInt($alo2.getText()), Integer.parseInt($ahi2.getText())));
              }
            | pe2=assignmentExpression
              {
                  Info _pi2 = new Info(); _pi2.theType = $pe2.type; _pi2.tmp = $pe2.tmp;
                  $exprList.add(_pi2);
                  $designList.add(new DesignElem(_pi2));
              }
          )
        )*
      )?
      '}'
      {
        // 若全部是 plain（無 designator），info = 第一個元素，向下相容
        $info = $exprList.isEmpty() ? new Info() : $exprList.get(0);
      }
    | str=STRINGLITERALS
      {
        // ── 字串字面值：用於 char 陣列初始化，如 char s[6] = "hello"; ──
        $exprList = null; $designList = null;
        $info = new Info();
        $info.theType = TypeInfo.Char;
        $info.tmp = $str.getText();
        $info.isConstant = true;
      }
    | e=assignmentExpression 
      { 
        $info = new Info();
        $info.theType = $e.type;
        $info.tmp = $e.tmp;
        $exprList = null; $designList = null;
      }
    ;

typeSpecifier returns [TypeInfo type, String sname]
    : 'int'    { $type = TypeInfo.Int;    $sname = null; }
    | 'float'  { $type = TypeInfo.Float;  $sname = null; }
    | 'double' { $type = TypeInfo.Double; $sname = null; }
    | 'char'   { $type = TypeInfo.Char;   $sname = null; }
    | 'void'   { $type = TypeInfo.Void;   $sname = null; }
    | 'va_list' { $type = TypeInfo.Pointer; $sname = "__va_list"; } // va_list → alloca [24 x i8], align 16
    | 'bool'   { $type = TypeInfo.Boolean; $sname = null; }
    | '_Bool'  { $type = TypeInfo.Boolean; $sname = null; }
    // ── 修飾詞前綴靜默忽略（volatile/restrict/const 後接真正型別）──
    | ('volatile'|'restrict') t2=typeSpecifier { $type = $t2.type; $sname = $t2.sname; }
    // ── ✨ typeof / __typeof__：型別推導（GCC 擴充）──
    | ('typeof'|'__typeof__') '(' { beginUnevaluatedExpression(); } te=expression ')' { endUnevaluatedExpression(); $type = $te.type; $sname = null; }
    | ('typeof'|'__typeof__') '(' ts2=typeSpecifier ')' { $type = $ts2.type; $sname = $ts2.sname; }
    // ── long long ──
    | 'unsigned' 'long' 'long' ('int')? { $type = TypeInfo.UnsignedLong;  $sname = null; }
    | 'signed'   'long' 'long' ('int')? { $type = TypeInfo.Long;          $sname = null; }
    | 'long' 'long' ('int')?            { $type = TypeInfo.Long;          $sname = null; }
    // ── long ──
    | 'unsigned' 'long' ('int')?        { $type = TypeInfo.UnsignedLong;  $sname = null; }
    | 'signed'   'long' ('int')?        { $type = TypeInfo.Long;          $sname = null; }
    | 'long' ('int')?                   { $type = TypeInfo.Long;          $sname = null; }
    // ── short ──
    | 'unsigned' 'short' ('int')?       { $type = TypeInfo.UnsignedShort; $sname = null; }
    | 'signed'   'short' ('int')?       { $type = TypeInfo.Short;         $sname = null; }
    | 'short' ('int')?                  { $type = TypeInfo.Short;         $sname = null; }
    // ── char 有無號 ──
    | 'unsigned' 'char'                 { $type = TypeInfo.UnsignedChar;  $sname = null; }
    | 'signed'   'char'                 { $type = TypeInfo.Char;          $sname = null; }
    // ── unsigned int / signed int / unsigned / signed ──
    | 'unsigned' 'int'                  { $type = TypeInfo.UnsignedInt;   $sname = null; }
    | 'signed'   'int'                  { $type = TypeInfo.Int;           $sname = null; }
    | 'unsigned'                        { $type = TypeInfo.UnsignedInt;   $sname = null; }
    | 'signed'                          { $type = TypeInfo.Int;           $sname = null; }
    | ('struct'|'union') id=ID { $type = TypeInfo.Struct; $sname = $id.getText(); }
    // ── typedef 別名與變數的通用通道 ──
    | id=ID
      {
        if (typedefMap.containsKey($id.getText())) {
            $type  = typedefMap.get($id.getText());
            $sname = typedefStructMap.get($id.getText());
        } else {
            $type  = TypeInfo.Error;
            $sname = $id.getText(); 
        }
      }
    ;
   
compoundStatement
    : '{'
      {
        scopeTracker.push(new java.util.HashSet<>()); // ✨ 進入大括號：發一張新的點名表
        currentScopeLevel++; // ✨ 進入 block：層級 +1
        // ── 關鍵修正：立刻讀取並重置 skipNextScopeRestore ──
        // 避免 inner block 繼承外層的 skip 旗標
        boolean mySkip = skipNextScopeRestore;
        skipNextScopeRestore = false;
        HashMap<String, Info> savedScope = new HashMap<>(symtab);
      }
      blockItem*
      '}'
      {
        currentScopeLevel--; // ✨ 離開 block：層級 -1
        if (mySkip) {
            // functionDefinition 的 body：由 functionDefinition 自己還原 symtab
        } else {
            symtab = savedScope;
        }
        scopeTracker.pop(); // ✨ 離開大括號：回收點名表
      }
    ;

blockItem
    : declaration
    | statement
    ;

statement
    : compoundStatement
    | expressionStatement
    | ifStatement
    | forStatement
    | whileStatement
    | doWhileStatement
    | breakStatement
    | continueStatement  
    | returnStatement
    | switchStatement
    | printfStatement
    | scanfStatement
    | gotoStatement
    | labeledStatement
    | staticAssertStatement
    ;

expressionStatement
    : expression? ';'
    ;

// ✨ C11 _Static_assert / static_assert：編譯期斷言
// 語法：_Static_assert(expr, "message") 或 _Static_assert(expr)
// 編譯期能求值時直接判斷；非常數時退化為執行期 abort 防護
staticAssertStatement
    : ('_Static_assert' | 'static_assert') '(' cond=assignmentExpression (',' msg=STRINGLITERALS)? ')' ';'
      {
        String assertMsg = ($msg != null) ? $msg.getText() : "\"_Static_assert failed\"";
        if ($cond.isConst) {
            // ✨ 完全編譯期：常數條件直接判斷
            if ($cond.constVal == 0) {
                // 斷言失敗：印出錯誤並讓編譯繼續（與 clang 行為一致：報錯但不中斷）
                System.err.println("Error! " + $start.getLine() + ": _Static_assert failed: " + assertMsg);
            }
            // 斷言通過：不生成任何 IR
        } else {
            // 非常數：退化為執行期 assert（呼叫 abort）
            // ── Fix 2：全域 scope 無法生成函式內指令，發警告後跳過 ──
            if (inGlobalScope) {
                System.err.println("Warning! " + $start.getLine()
                    + ": _Static_assert with non-constant condition in global scope — skipped: " + assertMsg);
            } else {
                // ── Fix 3：用 coerceToBool() 正確處理 int / float / pointer 各型別 ──
                String condTmp = coerceToBool($cond.type, $cond.tmp);
                String okLabel   = newLabel("sa_ok");
                String failLabel = newLabel("sa_fail");
                addInstruction("br i1 " + condTmp + ", label %" + okLabel + ", label %" + failLabel);
                addInstruction(failLabel + ":");
                String msgStrRaw = assertMsg.length() > 2
                    ? assertMsg.substring(1, assertMsg.length() - 1) : "_Static_assert failed";
                String fullMsg = "_Static_assert failed: " + msgStrRaw + "\n";
                String msgKey = "\"" + fullMsg + "\"";
                String msgVar;
                if (stringLiterals.containsKey(msgKey)) {
                    msgVar = stringLiterals.get(msgKey);
                } else {
                    msgVar = "@.str." + (strCnt++);
                    stringLiterals.put(msgKey, msgVar);
                    String llvmMsg = toIRString(fullMsg);
                    int msgLen = calcLLVMStrLen(fullMsg);
                    stringDefs.add(msgVar + " = private unnamed_addr constant [" + msgLen + " x i8] c\"" + llvmMsg + "\", align 1");
                    strLengths.put(msgVar, msgLen);
                }
                int gepLen = strLengths.containsKey(msgVar) ? strLengths.get(msgVar) : 32;
                String msgPtr = newTemp();
                addInstruction(msgPtr + " = getelementptr inbounds [" + gepLen + " x i8], [" + gepLen + " x i8]* " + msgVar + ", i64 0, i64 0");
                addInstruction("call i32 (i8*, ...) @printf(i8* " + msgPtr + ")");
                addInstruction("call void @abort()");
                addInstruction("unreachable");
                addInstruction(okLabel + ":");
            }
        }
      }
    ;

ifStatement
    : IF_TH LPAR e=expression RPAR
      { 
        List<String> s1_IR = null;
        List<String> s2_IR = null; 
        pushBuffer();
        cseReset();
      }
      s1=statement
      { s1_IR = popBuffer(); } 
      ('else'
        { pushBuffer(); cseReset(); }
        s2=statement
        { s2_IR = popBuffer(); } 
      )?
      {
        cseReset();
        if ($e.type == TypeInfo.Error) {
            // skip code gen on error
        } else if ($e.isConst) {
            // ✨ 前端 DCE：條件為編譯期常數 ✨
            if ($e.constVal != 0) {
                // 如果常數條件不為 0 (恆真)：直接展開 then 區塊，完全拋棄 else 區塊
                for (String instr : s1_IR) addInstruction(instr);
            } else {
                // 如果常數條件為 0 (恆假)：直接展開 else 區塊 (如果有的話)，拋棄 then 區塊
                if (s2_IR != null) {
                    for (String instr : s2_IR) addInstruction(instr);
                }
            }
        } else {
            // 🪵 一般路徑：動態條件跳轉 (原邏輯完整保留)
            String condTmp = coerceToBool($e.type, $e.tmp);
            String trueLabel = newLabel("Ltrue");
            String falseLabel = newLabel("Lfalse");
            String endLabel = newLabel("Lend");
            
            addInstruction("br i1 " + condTmp + ", label %" + trueLabel + ", label %" + falseLabel);
            
            addInstruction(trueLabel + ":");
            cseReset(); // ── CSE：新 basic block 重置 ──
            for (String instr : s1_IR) addInstruction(instr);
            boolean trueFellThrough = !lastInstrIsTerminator;
            if (trueFellThrough) addInstruction("br label %" + endLabel);
            
            addInstruction(falseLabel + ":");
            cseReset(); // ── CSE：新 basic block 重置 ──
            if (s2_IR != null) { 
                for (String instr : s2_IR) addInstruction(instr);
            }
            boolean falseFellThrough = !lastInstrIsTerminator;
            if (falseFellThrough) addInstruction("br label %" + endLabel);
            
            // ✨ 修正「遺漏回傳值」誤報：endLabel 只有在至少一個分支會 fall-through 時才是
            // 可達的合流點。若 then/else 兩分支都以 terminator（如 return）結尾，
            // endLabel 永遠不會被跳入，此時不應產生這個空的、不可達的 label block，
            // 否則會把 lastInstrIsTerminator 重置為 false，造成
            // 「control reaches end of non-void function without return」的誤報。
            if (trueFellThrough || falseFellThrough) {
                addInstruction(endLabel + ":");
                cseReset(); // ── CSE：合流點重置 ──
            }
        }
      }
    ;

forStatement
    : 'for' '('
      {
        // ── 保存 scope，for-init 宣告的變數不洩漏到外層 ──
        HashMap<String, Info> forSavedScope = new HashMap<>(symtab);
        scopeTracker.push(new java.util.HashSet<>());
        pushBuffer();
        cseReset();
      }
      ( forInit )?
      { List<String> initIR = popBuffer(); }
      ';'
      
      { pushBuffer(); cseReset(); } // ✨ 進入 cond 前清空記憶
      e2=expression?
      { List<String> conditionIR = popBuffer(); }
      ';'
      { pushBuffer(); cseReset(); } // ✨ 進入 update 前清空記憶
      e3=expression?
      { List<String> updateIR = popBuffer(); }
      ')'
      {
        String condLabel = newLabel("Lfor_cond");
        String bodyLabel = newLabel("Lfor_body");
        String updateLabel = newLabel("Lfor_update");
        String endLabel = newLabel("Lfor_end");
        pushLoopLabels(endLabel, updateLabel);

        loopDepth++; // ✨ 1. 進入迴圈：深度 +1
      }
      { pushBuffer(); cseReset(); } // ✨ 進入 body 前清空記憶
      s=statement
      {
        List<String> bodyIR = popBuffer();
        popLoopLabels();

        loopDepth--; // ✨ 2. 離開迴圈：深度 -1
      }
      {
        if (initIR != null) {
            for (String instr : initIR) addInstruction(instr);
        }

        // 將 conditionIR 與 updateIR 合併，一起交給 LICM 進行左值逃逸/修改掃描
        List<String> licmAnalysisIR = new ArrayList<>();
        if (conditionIR != null) licmAnalysisIR.addAll(conditionIR);
        if (updateIR != null) licmAnalysisIR.addAll(updateIR);

LICMResult licmFor = applyLICM(bodyIR, licmAnalysisIR);

        // ── ✨ Loop Unrolling：先分析是否可展開 ──
        UnrollInfo uInfo = analyzeForUnroll(initIR, conditionIR, updateIR, bodyIR);
        if (uInfo.canUnroll) {
            // 展開路徑：先輸出 LICM 外提指令，然後直接展開 body N 次，不生成 br/label
            for (String hi : licmFor.hoisted) addInstruction(hi);
            // 注意：initIR 已在上方（line 4736-4738）輸出，不重複輸出
            List<String> unrolled = doUnroll(uInfo, bodyIR);
            for (String instr : unrolled) addInstruction(instr);
            // 注意：endLabel 仍需輸出，因為之後的程式碼可能 br 到這裡
            addInstruction("br label %" + endLabel);
            addInstruction(endLabel + ":");
        } else {
            // 正常路徑（不可展開）
            for (String hi : licmFor.hoisted) {
                addInstruction(hi);
            }

            // 正常進入迴圈條件判斷
            addInstruction("br label %" + condLabel);

            addInstruction(condLabel + ":");
            if ($e2.ctx != null && conditionIR != null) {
                for (String instr : conditionIR) addInstruction(instr);
                String forCondTmp = coerceToBool($e2.type, $e2.tmp);
                addInstruction("br i1 " + forCondTmp + ", label %" + bodyLabel + ", label %" + endLabel);
            } else {
                addInstruction("br label %" + bodyLabel);
            }

            addInstruction(bodyLabel + ":");
            cseReset(); // ✨ 進入迴圈本體前清空 CSE
            if (licmFor.body != null) {
                for (String instr : licmFor.body) addInstruction(instr);
            }
            if(!lastInstrIsTerminator) addInstruction("br label %" + updateLabel);

            addInstruction(updateLabel + ":");
            if ($e3.ctx != null && updateIR != null) {
                for (String instr : updateIR) addInstruction(instr);
            }
            addInstruction("br label %" + condLabel);

            addInstruction(endLabel + ":");
        }
        cseReset();
        
        // ── 還原 scope ──
        symtab = forSavedScope;
        scopeTracker.pop();
      }
    ;
// for 迴圈初始化：支援宣告（int i=0）或單純 expression（i=0）
// 注意：forStatement 本身會吃第一個 ';'，所以這裡不能用含 ';' 的 declaration
forInit
    : t=typeSpecifier
      { pendingDeclType = $t.type; pendingDeclStructName = $t.sname; }
      dl=declaratorList
      {
        pendingDeclType = TypeInfo.Error;
        pendingDeclStructName = null;
        TypeInfo declType = $t.type;
        for (int i = 0; i < $dl.ids.size(); i++) {
            String name = $dl.ids.get(i);
            Info initInfo = $dl.initInfos.get(i);
            String prealloc = $dl.preallocPtrs.get(i);
            
            // 🚨 這是宣告 (例如 int j = 0)，絕對不能重用外層的變數！
            // 由於我們剛剛在 forStatement 已經 push 了一張全新的點名表，所以這裡一定是全新宣告！
            if (!scopeTracker.isEmpty()) scopeTracker.peek().add(name); // 簽到點名表

           
            String llvmT = toLLVMType(declType);
    
            String ptr = prealloc;
            Info info = symtab.get(name);
            if (info == null) {
                info = new Info();
                info.theType = declType;
                info.structName = $t.sname;
                ptr = newTemp();
                addInstruction(ptr + " = alloca " + llvmT + ", align " + getAlign(declType));
                info.tmp = ptr;
            }

            if (initInfo != null) {
                String storeVal = initInfo.tmp;
                TypeInfo initType = initInfo.theType;
                // 👇 ✨ 補上 Long (i64) 相關的隱式轉型 ✨ 👇
                if (declType == TypeInfo.Long && (initType == TypeInfo.Int || initType == TypeInfo.Boolean || initType == TypeInfo.Char)) {
                    String srcT = (initType == TypeInfo.Char) ? "i8" : (initType == TypeInfo.Boolean) ? "i1" : "i32";
                    String extOp = (initType == TypeInfo.Boolean) ? "zext" : "sext"; // ✨ Bug fix：bool→long 必須 zext
                    String conv = newTemp();
                    addInstruction(conv + " = " + extOp + " " + srcT + " " + storeVal + " to i64"); storeVal = conv;
                } else if (declType == TypeInfo.Int && initType == TypeInfo.Long) {
                    String conv = newTemp();
                    addInstruction(conv + " = trunc i64 " + storeVal + " to i32"); storeVal = conv;
                } else if (declType == TypeInfo.Long && (initType == TypeInfo.Float || initType == TypeInfo.Double)) {
                    String conv = newTemp();
                    addInstruction(conv + " = fptosi " + toLLVMType(initType) + " " + storeVal + " to i64"); storeVal = conv;
                } else if ((declType == TypeInfo.Float || declType == TypeInfo.Double) && initType == TypeInfo.Long) {
                    String conv = newTemp();
                    addInstruction(conv + " = sitofp i64 " + storeVal + " to " + llvmT); storeVal = conv;
                }
                // 👆 👆 新增結束 👆 👆
                else if (declType == TypeInfo.Int && (initType == TypeInfo.Float || initType == TypeInfo.Double)) {
                    String conv = newTemp();
                    addInstruction(conv + " = fptosi " + toLLVMType(initType) + " " + storeVal + " to i32");
                    storeVal = conv;
                } else if ((declType == TypeInfo.Float || declType == TypeInfo.Double) && initType == TypeInfo.Int) {
                    String conv = newTemp();
                    addInstruction(conv + " = sitofp i32 " + storeVal + " to " + llvmT);
                    storeVal = conv;
                } else if (declType == TypeInfo.Float && initType == TypeInfo.Double) {
                    String conv = newTemp();
                    addInstruction(conv + " = fptrunc double " + storeVal + " to float");
                    storeVal = conv;
                } else if (declType == TypeInfo.Double && initType == TypeInfo.Float) {
                    String conv = newTemp();
                    addInstruction(conv + " = fpext float " + storeVal + " to double");
                    storeVal = conv;
                } else if (declType == TypeInfo.Char && initType == TypeInfo.Int) {
                    String conv = newTemp();
                    addInstruction(conv + " = trunc i32 " + storeVal + " to i8");
                    storeVal = conv;
                } else if (isIntegerType(declType) && isIntegerType(initType) && declType != initType) {
                    storeVal = emitConvert(initType, storeVal, declType);
                }
                addInstruction("store " + llvmT + " " + storeVal + ", " + llvmT + "* " + ptr + ", align " + getAlign(declType));
            }   
            // 覆蓋 symtab！這就是 Shadowing 的奧義！
            symtab.put(name, info); 
        }
      }
    | expression
    ;

whileStatement
    : 'while' '(' 
      { pushBuffer(); cseReset(); } // ✨ 進入 cond 前清空記憶
      e=expression
      { List<String> conditionIR = popBuffer(); }
      ')' 
      {
        String condLabel = newLabel("Lwhile_cond");
        String bodyLabel = newLabel("Lwhile_body");
        String endLabel = newLabel("Lwhile_end");
        pushLoopLabels(endLabel, condLabel);

        loopDepth++; // ✨ 1. 進入迴圈：深度 +1
      }
      { pushBuffer(); cseReset(); } // ✨ 進入 body 前清空記憶
      s=statement
      { 
        List<String> bodyIR = popBuffer();
        popLoopLabels();

        loopDepth--; // ✨ 2. 離開迴圈：深度 -1
      }
      {
        // 將 conditionIR 作為 updateIR 傳入，讓 LICM 能掃描到裡面的 store 指令
        LICMResult licm = applyLICM(bodyIR, conditionIR);
        for (String hi : licm.hoisted) addInstruction(hi);

        addInstruction("br label %" + condLabel);
        
        addInstruction(condLabel + ":");
        for (String instr : conditionIR) addInstruction(instr);
        String whileCondTmp = coerceToBool($e.type, $e.tmp);
        addInstruction("br i1 " + whileCondTmp + ", label %" + bodyLabel + ", label %" + endLabel);
        
        addInstruction(bodyLabel + ":");
        cseReset(); // ✨ 進入迴圈本體前清空 CSE
        for (String instr : licm.body) addInstruction(instr);
        if(!lastInstrIsTerminator) addInstruction("br label %" + condLabel);
        
        addInstruction(endLabel + ":");
        cseReset();
      }
    ;
doWhileStatement
    locals [String bodyLabel, String condLabel, String endLabel]
    : 'do'
      {
        $bodyLabel = newLabel("Ldo_body");
        $condLabel = newLabel("Ldo_cond");
        $endLabel  = newLabel("Ldo_end");
        pushLoopLabels($endLabel, $condLabel);
        addInstruction("br label %" + $bodyLabel);
        addInstruction($bodyLabel + ":");
        pushBuffer();

        loopDepth++; // ✨ 1. 進入迴圈：深度 +1
      }
      s=statement
      {
        List<String> bodyIR = popBuffer();
        popLoopLabels();

        loopDepth--; // ✨ 2. 離開迴圈：深度 -1

        for (String instr : bodyIR) addInstruction(instr);
        if (!lastInstrIsTerminator) addInstruction("br label %" + $condLabel);
        addInstruction($condLabel + ":");
      }
      'while' '(' e=expression ')' ';'
      {
        String doCondTmp = coerceToBool($e.type, $e.tmp);
        addInstruction("br i1 " + doCondTmp + ", label %" + $bodyLabel + ", label %" + $endLabel);
        addInstruction($endLabel + ":");
        cseReset(); // ✨ 補上這行：迴圈結束後清空 CSE 記憶
      }
    ;

breakStatement
    : 'break' ';' 
      {
        // ✨ 修正條件：如果 loopDepth 和 switchDepth 都是 0，才是非法的 break！
        if (loopDepth == 0 && switchDepth == 0) {
            System.err.println("Error! " + $start.getLine() + ": break statement not within loop or switch.");
        }
        String breakLabel = getCurrentBreakLabel();
        if (breakLabel != null) addInstruction("br label %" + breakLabel);
      }
    ;

continueStatement
    : 'continue' ';'
        {
        // ✨ 新增防呆：如果不在迴圈內，就大聲報錯！
        if (loopDepth == 0) {
            System.err.println("Error! " + $start.getLine() + ": continue statement not within a loop.");
        }
        String continueLabel = getCurrentContinueLabel();
        if (continueLabel != null) addInstruction("br label %" + continueLabel);
      }
    ;

returnStatement
    : 'return' e=expression? ';'
      {
        if ($e.ctx != null) {
            String retTmp = $e.tmp;
            TypeInfo exprType = $e.type;
            TypeInfo mainReturnType = getCurrentReturnType();

            // ── Return 值的完整隱式型別轉換 ──
            if (mainReturnType == exprType) {
                // 型別相同，不需轉換
            } else if (mainReturnType == TypeInfo.Int && exprType == TypeInfo.Char) {
                // char → int: sext i8 to i32
                String conv = newTemp();
                addInstruction(conv + " = sext i8 " + retTmp + " to i32");
                retTmp = conv;
            } else if (mainReturnType == TypeInfo.Int && exprType == TypeInfo.Boolean) {
                // bool → int: zext i1 to i32
                String conv = newTemp();
                addInstruction(conv + " = zext i1 " + retTmp + " to i32");
                retTmp = conv;
            } else if (mainReturnType == TypeInfo.Int && (exprType == TypeInfo.Float || exprType == TypeInfo.Double)) {
                String conv = newTemp();
                addInstruction(conv + " = fptosi " + toLLVMType(exprType) + " " + retTmp + " to i32");
                retTmp = conv;
            } else if (mainReturnType == TypeInfo.Float && exprType == TypeInfo.Int) {
                String conv = newTemp();
                addInstruction(conv + " = sitofp i32 " + retTmp + " to float");
                retTmp = conv;
            } else if (mainReturnType == TypeInfo.Float && exprType == TypeInfo.Char) {
                String conv1 = newTemp();
                addInstruction(conv1 + " = sext i8 " + retTmp + " to i32");
                String conv2 = newTemp();
                addInstruction(conv2 + " = sitofp i32 " + conv1 + " to float");
                retTmp = conv2;
            } else if (mainReturnType == TypeInfo.Float && exprType == TypeInfo.Double) {
                String conv = newTemp();
                addInstruction(conv + " = fptrunc double " + retTmp + " to float");
                retTmp = conv;
            } else if (mainReturnType == TypeInfo.Double && exprType == TypeInfo.Int) {
                String conv = newTemp();
                addInstruction(conv + " = sitofp i32 " + retTmp + " to double");
                retTmp = conv;
            } else if (mainReturnType == TypeInfo.Double && exprType == TypeInfo.Char) {
                String conv1 = newTemp();
                addInstruction(conv1 + " = sext i8 " + retTmp + " to i32");
                String conv2 = newTemp();
                addInstruction(conv2 + " = sitofp i32 " + conv1 + " to double");
                retTmp = conv2;
            } else if (mainReturnType == TypeInfo.Double && exprType == TypeInfo.Float) {
                String conv = newTemp();
                addInstruction(conv + " = fpext float " + retTmp + " to double");
                retTmp = conv;
            } else if (mainReturnType == TypeInfo.Char && exprType == TypeInfo.Int) {
                // int → char: trunc i32 to i8
                String conv = newTemp();
                addInstruction(conv + " = trunc i32 " + retTmp + " to i8");
                retTmp = conv;
            } else if (mainReturnType == TypeInfo.Boolean && exprType == TypeInfo.Int) {
                // int → bool: trunc i32 to i1
                String conv = newTemp();
                addInstruction(conv + " = trunc i32 " + retTmp + " to i1");
                retTmp = conv;
            } else if (isIntegerType(mainReturnType) && isIntegerType(exprType) && mainReturnType != exprType) {
                retTmp = emitConvert(exprType, retTmp, mainReturnType);
            } else if ((mainReturnType == TypeInfo.Float || mainReturnType == TypeInfo.Double) && isIntegerType(exprType)) {
                String conv = isUnsignedType(exprType) ? "uitofp" : "sitofp";
                String r = newTemp();
                addInstruction(r + " = " + conv + " " + toLLVMType(exprType) + " " + retTmp + " to " + toLLVMType(mainReturnType));
                retTmp = r;
            }
        // ── 指標回傳：動態查表決定是 ret i32* 還是 ret %struct.Node* ──
         String retLLVMType;
         if (mainReturnType == TypeInfo.Pointer) {
             // ✨ 聰明地從小本本反查要回傳的真實型別 ✨
             retLLVMType = exactTypeMap.containsKey(retTmp) ? exactTypeMap.get(retTmp) : "i8*";
         } else if (mainReturnType == TypeInfo.Struct) {
             // ✨ struct 回傳：從 returnStructNameStack 取得正確的 %struct.Name ✨
             String sname = getCurrentReturnStructName();
             retLLVMType = (sname != null) ? "%struct." + sname : "i32";
             // ✨ retTmp 是 alloca 的指標（%struct.X*），必須先 load 成 value 才能 ret ✨
             String loadedVal = newTemp();
             addInstruction(loadedVal + " = load " + retLLVMType + ", " + retLLVMType + "* " + retTmp + ", align 4");
             retTmp = loadedVal;
         } else {
             retLLVMType = toLLVMType(mainReturnType);
         }
         // ── TCO 偵測：return self(args) → store + br tco_loop ──
         boolean _didTCO = false;
         String _selfFunc = getCurrentFuncName();
         List<String> _tcoSlots = currentFuncParamSlots.isEmpty() ? null : currentFuncParamSlots.peek();
         List<String> _tcoTypes = currentFuncParamTypes.isEmpty() ? null : currentFuncParamTypes.peek();
         if (!_selfFunc.isEmpty() && _tcoSlots != null && !_tcoSlots.isEmpty()
                 && currentTextCodeBuffer != null && !currentTextCodeBuffer.isEmpty()) {
             String _last = currentTextCodeBuffer.get(currentTextCodeBuffer.size()-1).trim();
             boolean _isSelf = _last.contains("@" + _selfFunc + "(")
                 && (_last.startsWith(retTmp + " = call ") || _last.startsWith("call void @" + _selfFunc + "("));
             if (_isSelf) {
                 int _po = _last.indexOf("@" + _selfFunc + "(") + _selfFunc.length() + 2;
                 int _pc = _last.lastIndexOf(")");
                 String _argsStr = (_po <= _pc) ? _last.substring(_po, _pc).trim() : "";
                 List<String> _argVals = new ArrayList<>();
                 if (!_argsStr.isEmpty()) {
                     int _d=0; StringBuilder _cur=new StringBuilder();
                     for (char _ch : _argsStr.toCharArray()) {
                         if (_ch=='('||_ch=='[') _d++;
                         else if (_ch==')'||_ch==']') _d--;
                         if (_ch==','&&_d==0) {
                             String _tok=_cur.toString().trim();
                             int _sp=_tok.lastIndexOf(' ');
                             _argVals.add(_sp>=0?_tok.substring(_sp+1):_tok);
                             _cur.setLength(0);
                         } else _cur.append(_ch);
                     }
                     if (_cur.length()>0){String _tok=_cur.toString().trim();int _sp=_tok.lastIndexOf(' ');_argVals.add(_sp>=0?_tok.substring(_sp+1):_tok);}
                 }
                 if (_argVals.size() == _tcoSlots.size()) {
                     currentTextCodeBuffer.remove(currentTextCodeBuffer.size()-1);
                     String _tcoL = getOrCreateTcoLoopLabel();
                     for (int _ti=0; _ti<_tcoSlots.size(); _ti++) {
                         addInstruction("store " + _tcoTypes.get(_ti) + " " + _argVals.get(_ti)
                             + ", " + _tcoTypes.get(_ti) + "* " + _tcoSlots.get(_ti)
                             + ", align " + (_tcoTypes.get(_ti).endsWith("*") ? "8" : "4"));
                     }
                     addInstruction("br label %" + _tcoL);
                     lastInstrIsTerminator = true;
                     _didTCO = true;
                 }
             }
         }
         if (!_didTCO) {
             addInstruction("ret " + retLLVMType + " " + retTmp);
         }
        } else {
            addInstruction("ret void");
        }
      }
    ;

switchStatement
    : 'switch' '(' e=expression ')'
      {
        switchDepth++; // ✨ 進入 switch：深度 +1
        String switchEndLabel = newLabel("Lswitch_end");
        pushLoopLabels(switchEndLabel, switchEndLabel);
        // switch 只支援整數型別，自動轉換
        currentSwitchTmp = $e.tmp;
        if ($e.type == TypeInfo.Boolean) {
            String conv = newTemp();
            addInstruction(conv + " = zext i1 " + $e.tmp + " to i32");
            currentSwitchTmp = conv;
        } else if ($e.type == TypeInfo.Float || $e.type == TypeInfo.Double) {
            System.err.println("Warning: switch expression should be integer type, auto-converting.");
            String conv = newTemp();
            addInstruction(conv + " = fptosi " + toLLVMType($e.type) + " " + $e.tmp + " to i32");
            currentSwitchTmp = conv;
        }
      }
      '{' sb=switchBody '}'
      {
        List<String> caseVals   = $sb.caseValues;
        List<String> caseLabels = $sb.caseLabels;
        String defaultLabel     = $sb.defaultLabel;
        String curSwitchEndLabel = getCurrentBreakLabel();
        popLoopLabels();
        switchDepth--; // ✨ 離開 switch：深度 -1

        String defaultTarget = defaultLabel != null ? defaultLabel : curSwitchEndLabel;
        StringBuilder swInstr = new StringBuilder();
        swInstr.append("switch i32 ").append(currentSwitchTmp)
               .append(", label %").append(defaultTarget).append(" [\n");
        for (int si = 0; si < caseVals.size(); si++) {
            swInstr.append("    i32 ").append(caseVals.get(si)).append(", label %").append(caseLabels.get(si)).append("\n");
        }
        swInstr.append("  ]");
        addInstruction(swInstr.toString());

        List<List<String>> caseBlocks = $sb.caseBlocks;
        // ✨ 修正 fall-through：case 沒有 terminator 時，fall 到下一個 case/default，而非直接跳 switch end
        // 建立 case 出現順序的有序標籤清單：case[0], case[1], ..., default
        List<String> allOrderedLabels = new ArrayList<>(caseLabels);
        if (defaultLabel != null) allOrderedLabels.add(defaultLabel);

        for (int si = 0; si < caseLabels.size(); si++) {
            addInstruction(caseLabels.get(si) + ":");
            for (String instr : caseBlocks.get(si)) addInstruction(instr);
            if (!lastInstrIsTerminator) {
                // fall-through 到下一個標籤（按宣告順序）
                int myPos = allOrderedLabels.indexOf(caseLabels.get(si));
                String fallTarget = (myPos + 1 < allOrderedLabels.size())
                    ? allOrderedLabels.get(myPos + 1)
                    : curSwitchEndLabel;
                addInstruction("br label %" + fallTarget);
            }
        }

        if (defaultLabel != null) {
            addInstruction(defaultLabel + ":");
            for (String instr : $sb.defaultBlock) addInstruction(instr);
            if(!lastInstrIsTerminator) addInstruction("br label %" + curSwitchEndLabel);
        }
        addInstruction(curSwitchEndLabel + ":");
        cseReset(); // ✨ 補上這行：switch 結束後清空 CSE 記憶
      }
    ;

switchBody returns [List<String> caseValues, List<String> caseLabels, List<List<String>> caseBlocks, String defaultLabel, List<String> defaultBlock]
    : {
        $caseValues  = new ArrayList<>();
        $caseLabels  = new ArrayList<>();
        $caseBlocks  = new ArrayList<>();
        $defaultLabel = null;
        $defaultBlock = new ArrayList<>();
      }
      // 在 constant 前面加入 sign='-'? 
      ( 'case' sign='-'? cv=constant ':'
        {
          String cLabel = newLabel("Lcase");
          String finalVal = $cv.value;
          // 如果有抓到負號，就把負號加回數字字串前面
          if ($sign != null) {
              finalVal = "-" + finalVal;
          }
          $caseValues.add(finalVal);
          $caseLabels.add(cLabel);
          pushBuffer();
        }
        blockItem*
        { $caseBlocks.add(popBuffer()); }
      | 'default' ':'
        {
          $defaultLabel = newLabel("Ldefault");
          pushBuffer();
        }
        blockItem*
        { $defaultBlock = popBuffer(); }
      )*
    ;

printfArgs returns [List<Info> argList]
    : { $argList = new ArrayList<>(); }
      a1=printfArg { $argList.add($a1.info); }
      (',' a2=printfArg { $argList.add($a2.info); })*
    ;

// ── 單一 printf 參數：優先辨識 char 陣列 ID（直接查 symtab 取指標）──
printfArg returns [Info info]
    : id=ID
      {
        $info = new Info();
        
        // ── 1. 新增：優先攔截 Enum 常數，直接回傳數字，不要產生 load ──
        if (enumConstants.containsKey($id.getText())) {
            $info.theType = TypeInfo.Int;
            $info.tmp = String.valueOf(enumConstants.get($id.getText()));
            $info.isConstant = true;
        } 
        // ── 2. 原本的邏輯：處理變數與字元陣列 ──
        else {
            Info sv = symtab.get($id.getText());
            if (sv == null) sv = globalSymtab.get($id.getText());
            
            if (sv != null && sv.theType == TypeInfo.Char && sv.arraySize > 0) {
                // ── char 陣列：直接 GEP 取 i8*，不 load ──
                String aType = "[" + sv.arraySize + " x i8]";
                String ptr = newTemp();
                addInstruction(ptr + " = getelementptr inbounds " + aType + ", " + aType + "* " + sv.tmp + ", i64 0, i64 0");
                charPtrTemps.add(ptr); // ← 標記此 tmp 是 i8*
                $info.theType = TypeInfo.Char;
                $info.tmp = ptr;
                $info.arraySize = sv.arraySize;
            } else {
                // 純量 ID 或指標 ID：load 值
                Info loaded = new Info();
                if (sv != null) {
                    if (sv.isPointer) {
                        // ── 指標變數：使用 exactTypeMap 取得正確 LLVM 型別（同 expression 規則），
                        //    避免 int* / double* 等非 i8* 指標被誤當成 i8* 來 load ──
                        String ptrLLVM = toLLVMPtrType(sv.baseType, sv.structName, sv.ptrDepth);
                        String expectedPtrType = exactTypeMap.containsKey(sv.tmp)
                            ? exactTypeMap.get(sv.tmp) : (ptrLLVM + "*");
                        String t = newTemp();
                        addInstruction(t + " = load " + ptrLLVM + ", " + expectedPtrType
                            + " " + sv.tmp + ", align 8");
                        exactTypeMap.put(t, ptrLLVM);
                        loaded.theType = TypeInfo.Pointer;
                        loaded.tmp = t;
                    } else {
                        String lt = toLLVMType(sv.theType);
                        String t = newTemp();
                        addInstruction(t + " = load " + lt + ", " + lt + "* " + sv.tmp + ", align " + getAlign(sv.theType));
                        loaded.theType = sv.theType;
                        loaded.tmp = t;
                    }
                } else {
                    loaded.theType = TypeInfo.Int;
                    loaded.tmp = "0";
                }
                $info = loaded;
            }
        }
      }
    // ── 字串字面值作為 printf 參數（如 __func__、__FILE__ 展開後，或直接傳 "str"）──
    | s=STRINGLITERALS
      {
        $info = new Info();
        String rawStr = $s.getText();
        String inner2 = rawStr.substring(1, rawStr.length() - 1);
        int strLen2 = calcLLVMStrLen(inner2);
        String llvmStr2 = toIRString(inner2);
        String strVar2;
        if (stringLiterals.containsKey(rawStr)) {
            strVar2 = stringLiterals.get(rawStr);
        } else {
            strVar2 = "@.str." + (strCnt++);
            stringLiterals.put(rawStr, strVar2);
            stringDefs.add(strVar2 + " = private unnamed_addr constant [" + strLen2 + " x i8] c\"" + llvmStr2 + "\", align 1");
            strLengths.put(strVar2, strLen2);
        }
        int gepLen2 = strLengths.containsKey(strVar2) ? strLengths.get(strVar2) : strLen2;
        String strPtr2 = newTemp();
        addInstruction(strPtr2 + " = getelementptr inbounds [" + gepLen2 + " x i8], [" + gepLen2 + " x i8]* " + strVar2 + ", i64 0, i64 0");
        charPtrTemps.add(strPtr2);
        $info.theType = TypeInfo.Char;
        $info.tmp = strPtr2;
        $info.arraySize = gepLen2;
      }
    | e=assignmentExpression
      { $info = new Info(); $info.theType = $e.type; $info.tmp = $e.tmp; }
    ;
    
printfStatement
    : 'printf' '(' format=STRINGLITERALS (',' args=printfArgs)? ')' ';'
      {
          String rawString = $format.getText();
          String inner = rawString.substring(1, rawString.length() - 1);
          // ── 使用輔助方法計算正確 byte 長度（支援中文等非 ASCII）──
          int strLen = calcLLVMStrLen(inner);
          String llvmString = toIRString(inner);
          String strVar;
          if (stringLiterals.containsKey(rawString)) {
              strVar = stringLiterals.get(rawString);
          } else {
              strVar = "@.str." + (strCnt++);
              stringLiterals.put(rawString, strVar);

              String strDef = strVar + " = private unnamed_addr constant [" + strLen + " x i8] c\"" + llvmString + "\", align 1";
              stringDefs.add(strDef);
              strLengths.put(strVar, strLen);
          }
          int gepLen = strLengths.containsKey(strVar) ? strLengths.get(strVar) : strLen;
          String strPtr = newTemp();
          addInstruction(strPtr + " = getelementptr inbounds [" + gepLen + " x i8], [" + gepLen + " x i8]* " + strVar + ", i64 0, i64 0");
          StringBuilder call = new StringBuilder();
          call.append("call i32 (i8*, ...) @printf(i8* ").append(strPtr);
          if ($args.ctx != null) {
              for (Info argInfo : $args.argList) {
                  call.append(", ");
                  if (argInfo.theType == TypeInfo.Float) {
                      // float 透過 varargs 必須提升為 double
                      String dblTmp = newTemp();
                      addInstruction(dblTmp + " = fpext float " + argInfo.tmp + " to double");
                      call.append("double ").append(dblTmp);
                  } else if (argInfo.theType == TypeInfo.Short) {
                      String extTmp = newTemp();
                      addInstruction(extTmp + " = sext i16 " + argInfo.tmp + " to i32");
                      call.append("i32 ").append(extTmp);
                  } else if (argInfo.theType == TypeInfo.UnsignedShort || argInfo.theType == TypeInfo.UnsignedChar) {
                      String extTmp = newTemp();
                      addInstruction(extTmp + " = zext " + toLLVMType(argInfo.theType) + " " + argInfo.tmp + " to i32");
                      call.append("i32 ").append(extTmp);
                  } else if (argInfo.theType == TypeInfo.Char) {
                      if (charPtrTemps.contains(argInfo.tmp)) {
                          // ── char 陣列 GEP 結果：已是 i8*，直接傳（%s）──
                          call.append("i8* ").append(argInfo.tmp);
                      } else {
                          // ── char 純量 (i8)：varargs 提升為 i32（%c）──
                          String extTmp = newTemp();
                          addInstruction(extTmp + " = sext i8 " + argInfo.tmp + " to i32");
                          call.append("i32 ").append(extTmp);
                      }
                  } else if (argInfo.theType == TypeInfo.Pointer
                             || (argInfo.theType == TypeInfo.Char && charPtrTemps.contains(argInfo.tmp))
                             || exactTypeMap.containsKey(argInfo.tmp)) {
                      // ── 指標型別（%p 或 %s）：直接傳 i8*，若非 i8* 先 bitcast/inttoptr ──
                      String ptrLLVM = exactTypeMap.containsKey(argInfo.tmp) ? exactTypeMap.get(argInfo.tmp) : "i8*";
                      if (ptrLLVM.equals("i8*")) {
                          call.append("i8* ").append(argInfo.tmp);
                      } else if (!ptrLLVM.endsWith("*")) {
                          // ── 非指標型別（如 i32）：用 inttoptr 而非 bitcast ──
                          String casted = newTemp();
                          // 確保整數寬度符合指標大小（i64 on 64-bit）
                          String intVal = argInfo.tmp;
                          if (ptrLLVM.equals("i32")) {
                              String ext = newTemp();
                              addInstruction(ext + " = zext i32 " + intVal + " to i64");
                              intVal = ext;
                              ptrLLVM = "i64";
                          }
                          addInstruction(casted + " = inttoptr " + ptrLLVM + " " + intVal + " to i8*");
                          call.append("i8* ").append(casted);
                      } else {
                          String casted = newTemp();
                          addInstruction(casted + " = bitcast " + ptrLLVM + " " + argInfo.tmp + " to i8*");
                          call.append("i8* ").append(casted);
                      }
                  } else {
                      call.append(toLLVMType(argInfo.theType)).append(" ").append(argInfo.tmp);
                  }
              }
          }
          call.append(")");
          addInstruction(call.toString());
      }
    ;

// ── scanf 參數：支援 &id（純量）和 id（char 陣列，%s）──
scanfArgs returns [List<Info> argList]
    : { $argList = new ArrayList<>(); }
      a=scanfSingleArg { $argList.add($a.info); }
      (',' b=scanfSingleArg { $argList.add($b.info); })*
    ;

scanfSingleArg returns [Info info]
    // &id：純量（int、float）傳 alloca 指標
    : '&' id=ID
      {
        $info = new Info();
        Info sv = symtab.get($id.getText());
        if (sv == null) sv = globalSymtab.get($id.getText());
        if (sv == null) {
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier " + $id.getText() + ".");
            $info.theType = TypeInfo.Int; $info.tmp = "0"; $info.arraySize = -1;
        } else {
            $info = new Info();
            $info.theType = sv.theType;
            $info.tmp = sv.tmp;   // alloca 指標（i32*、float*）
            $info.arraySize = -1; // 純量
        }
      }
    // id（無 &）：char 陣列，GEP 取 i8* 傳給 scanf %s
    | id=ID
      {
        $info = new Info();
        Info sv = symtab.get($id.getText());
        if (sv == null) sv = globalSymtab.get($id.getText());
        if (sv == null) {
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier " + $id.getText() + ".");
            $info.theType = TypeInfo.Char; $info.tmp = "0"; $info.arraySize = 1;
        } else if (sv.theType != TypeInfo.Char || sv.arraySize <= 0) {
            System.err.println("Error! " + $id.getLine() + ": '" + $id.getText() + "' is not a char array; use & for scalars.");
            $info = new Info(); $info.theType = sv.theType; $info.tmp = sv.tmp; $info.arraySize = -1;
        } else {
            // char 陣列：GEP 取首元素 i8*
            String aType = "[" + sv.arraySize + " x i8]";
            String ptr = newTemp();
            addInstruction(ptr + " = getelementptr inbounds " + aType + ", " + aType + "* " + sv.tmp + ", i64 0, i64 0");
            charPtrTemps.add(ptr);
            $info = new Info();
            $info.theType = TypeInfo.Char;
            $info.tmp = ptr;
            $info.arraySize = sv.arraySize; // > 0 表示已是 i8*
        }
      }
    ;

scanfStatement
    : 'scanf' '(' format=STRINGLITERALS (',' args=scanfArgs)? ')' ';'
    {
        String rawString = $format.getText();
        String inner = rawString.substring(1, rawString.length() - 1);
        // ── 使用輔助方法計算正確 byte 長度（支援中文等非 ASCII）──
        int strLen = calcLLVMStrLen(inner);
        String llvmString = toIRString(inner);
        String strVar;
        if (stringLiterals.containsKey(rawString)) {
            strVar = stringLiterals.get(rawString);
        } else {
            strVar = "@.str." + (strCnt++);
            stringLiterals.put(rawString, strVar);
            stringDefs.add(strVar + " = private unnamed_addr constant [" + strLen + " x i8] c\"" + llvmString + "\", align 1");
            strLengths.put(strVar, strLen);
        }
        int gepLen = strLengths.containsKey(strVar) ? strLengths.get(strVar) : strLen;
        String strPtr = newTemp();
        addInstruction(strPtr + " = getelementptr inbounds [" + gepLen + " x i8], [" + gepLen + " x i8]* " + strVar + ", i64 0, i64 0");
        StringBuilder call = new StringBuilder();
        call.append("call i32 (i8*, ...) @__isoc99_scanf(i8* ").append(strPtr);
        if ($args.ctx != null) {
            for (Info argInfo : $args.argList) {
                call.append(", ");
                if (argInfo.theType == TypeInfo.Char && argInfo.arraySize > 0) {
                    // %s：已是 i8*
                    call.append("i8* ").append(argInfo.tmp);
                } else {
                    // %d / %f：傳 alloca 指標
                    call.append(toLLVMType(argInfo.theType)).append("* ").append(argInfo.tmp);
                }
            }
        }
        call.append(")");
        addInstruction(call.toString());
    }
    ;

// ══════════════════════════════════════════════
// goto 陳述式：goto labelName;
// ══════════════════════════════════════════════
gotoStatement
    : 'goto' id=ID ';'
      {
        if (inGlobalScope) {
            System.err.println("Error! line " + $id.getLine() + ": goto statement not allowed in global scope.");
        } else {
            String userName = $id.getText();
            String realLabel = gotoTable.get(userName);
            if (realLabel != null) {
                // backward goto：目標 label 已知，直接發出 br
                addInstruction("br label %" + realLabel);
            } else {
                // forward goto：目標 label 尚未出現，用 placeholder 等待修補
                String fwdLabel = newLabel("Lgoto_fwd_");
                forwardGotoPatches.add(new String[]{ userName, fwdLabel, String.valueOf($id.getLine()) });
                addInstruction("br label %" + fwdLabel);
            }
        }
      }
    ;

// ══════════════════════════════════════════════
// 標號陳述式：labelName: statement
// 允許在標號後緊接任意 statement（包含空敘述 ;）
// ══════════════════════════════════════════════
labeledStatement
    : id=ID ':'
      {
        if (inGlobalScope) {
            System.err.println("Error! line " + $id.getLine() + ": label not allowed in global scope.");
        } else {
            String userName = $id.getText();
            if (gotoTable.containsKey(userName)) {
                System.err.println("Error! line " + $id.getLine() + ": duplicate label '" + userName + "'.");
            } else {
                String llvmLabel = newLabel("Luser_" + userName);
                gotoTable.put(userName, llvmLabel);
                // 若前一條指令不是 terminator，需補 br 讓 basic block 合法
                if (!lastInstrIsTerminator) {
                    addInstruction("br label %" + llvmLabel);
                }
                addInstruction(llvmLabel + ":");
            }
        }
      }
      statement
    ;

// ✨ 1. 在 returns 裡面加上 boolean isConst, double constVal
// ✨ 修正版 expression 規則
expression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=assignmentExpression
      {
        $type = $a.type;
        $tmp = $a.tmp;
        $isConst = $a.isConst; 
        $constVal = $a.constVal;
      }
      // ✨ 逗號運算子：用於 for update（如 i++, j--），依序求值，取最後型別
      (',' b=assignmentExpression
        {
          $type = $b.type;
          $tmp = $b.tmp;
          $isConst = $b.isConst;
          $constVal = $b.constVal;
        }
      )*
    ;

assignmentExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    // ── 解參考賦值：*(expr) = val，例如 *(p+2) = 99 ──
    : '*' '(' ep=expression ')' '=' b=assignmentExpression
      {
        if ($ep.type != TypeInfo.Pointer) {
            System.err.println("Error! line " + $start.getLine() + ": expression in *(...) is not a pointer.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            TypeInfo pointee = TypeInfo.Int;
            for (java.util.Map.Entry<String, Info> entry : symtab.entrySet()) {
                Info sv = entry.getValue();
                if (sv.isPointer && sv.pointeeType != null) { pointee = sv.pointeeType; break; }
            }
            String pointeeLLVM = toLLVMType(pointee);
            String rhs = $b.tmp;
            
            if (pointee == TypeInfo.Int && ($b.type == TypeInfo.Float || $b.type == TypeInfo.Double)) {
                String cv = newTemp(); addInstruction(cv + " = fptosi " + toLLVMType($b.type) + " " + rhs + " to i32"); rhs = cv;
            } else if ((pointee == TypeInfo.Float || pointee == TypeInfo.Double) && $b.type == TypeInfo.Int) {
                String cv = newTemp(); addInstruction(cv + " = sitofp i32 " + rhs + " to " + pointeeLLVM); rhs = cv;
            } else if (pointee == TypeInfo.Float && $b.type == TypeInfo.Double) {
                String cv = newTemp(); addInstruction(cv + " = fptrunc double " + rhs + " to float"); rhs = cv;
            } else if (pointee == TypeInfo.Double && $b.type == TypeInfo.Float) {
                String cv = newTemp(); addInstruction(cv + " = fpext float " + rhs + " to double"); rhs = cv;
            }
            
            int align = (pointee == TypeInfo.Double) ? 8 : 4;
            addInstruction("store " + pointeeLLVM + " " + rhs + ", " + pointeeLLVM + "* " + $ep.tmp + ", align " + align);
            $type = pointee; $tmp = rhs;
        }
      }
// ── 解參考賦值：*p = expr 或 **p = expr ──
    | s1='*' s2='*'? id=ID '=' b=assignmentExpression
      {
        int derefs = ($s2 != null) ? 2 : 1;
        Info info = symtab.get($id.getText());
        if (info == null) info = globalSymtab.get($id.getText());
        
        if (info == null || !info.isPointer || info.ptrDepth < derefs) {
            System.err.println("Error! " + $id.getLine() + ": Invalid dereference on '" + $id.getText() + "'.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            String ptrLLVM = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
            String pVal = newTemp();
            addInstruction(pVal + " = load " + ptrLLVM + ", " + ptrLLVM + "* " + info.tmp + ", align 8");
            
            String currentVal = pVal;
            String currentType = ptrLLVM;
            
            // ✨ 如果是 **p = x，第一次解參考需要先 load 出內層指標的位址
            for (int i = 0; i < derefs - 1; i++) {
                String nextType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth - 1 - i);
                String result = newTemp();
                addInstruction(result + " = load " + nextType + ", " + currentType + " " + currentVal + ", align 8");
                currentVal = result;
                currentType = nextType;
            }
            
            // 最後一次解參考的型別，就是我們要寫入的型別
            String targetPointeeLLVM = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth - derefs);
            String rhs = $b.tmp;
            TypeInfo rhsType = $b.type;
            
            // 隱式轉型
            if (info.baseType == TypeInfo.Int && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                String cv = newTemp(); addInstruction(cv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i32"); rhs = cv;
            } else if ((info.baseType == TypeInfo.Float || info.baseType == TypeInfo.Double) && rhsType == TypeInfo.Int) {
                String cv = newTemp(); addInstruction(cv + " = sitofp i32 " + rhs + " to " + targetPointeeLLVM); rhs = cv;
            } else if (info.baseType == TypeInfo.Float && rhsType == TypeInfo.Double) {
                // ✨ 新增：當要把 double 值的結果存進 float 指標時，進行向下轉型 (fptrunc)
                String cv = newTemp(); addInstruction(cv + " = fptrunc double " + rhs + " to float"); rhs = cv;
            } else if (info.baseType == TypeInfo.Double && rhsType == TypeInfo.Float) {
                // ✨ 新增：當要把 float 值的結果存進 double 指標時，進行向上提升 (fpext)
                String cv = newTemp(); addInstruction(cv + " = fpext float " + rhs + " to double"); rhs = cv;
            } else if (info.ptrDepth - derefs > 0 && rhs.equals("0")) {
                rhs = "null"; // 把 0 轉成 null 指標
            }
            
            // ✨ 核心修正：解參考寫入時的安全 bitcast 防護網 ✨
           if ((info.ptrDepth - derefs > 0) && (rhsType == TypeInfo.Pointer || rhs.equals("null"))) {
                if (rhs.equals("null")) {
                    exactTypeMap.put("null", targetPointeeLLVM);
                } else {
                    // ✨ 改為使用 targetPointeeLLVM 作為預設值
                    String srcLLVM = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : targetPointeeLLVM; 
                    if (!srcLLVM.equals(targetPointeeLLVM)) {
                        String casted = newTemp();
                        addInstruction(casted + " = bitcast " + srcLLVM + " " + rhs + " to " + targetPointeeLLVM);
                        rhs = casted;
                    }
                }
            }
            
            addInstruction("store " + targetPointeeLLVM + " " + rhs + ", " + currentType + " " + currentVal + ", align 8");
            $type = (info.ptrDepth - derefs > 0) ? TypeInfo.Pointer : info.baseType;
            $tmp = rhs;
        }
      }
    // ── 取址賦值：p = &x ──
    | id=ID '=' '&' src=ID
      {
        Info pInfo = symtab.get($id.getText());
        if (pInfo == null) pInfo = globalSymtab.get($id.getText());
        Info xInfo = symtab.get($src.getText());
        if (xInfo == null) xInfo = globalSymtab.get($src.getText());
        
        if (pInfo == null || !pInfo.isPointer) {
            System.err.println("Error! " + $id.getLine() + ": '" + $id.getText() + "' is not a pointer.");
            $type = TypeInfo.Error; $tmp = "0";
        } else if (xInfo == null) {
            System.err.println("Error! " + $src.getLine() + ": Undeclared identifier '" + $src.getText() + "'.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            // ✨ 核心升級：精準推導 p 的多層型別與 &x 的多層型別 ✨
            String ptrLLVM   = toLLVMPtrType(pInfo.baseType, pInfo.structName, pInfo.ptrDepth);
            
            // x 取址後的深度：原本的深度再 + 1
            int xDepth = xInfo.isPointer ? xInfo.ptrDepth + 1 : 1;
            TypeInfo xBaseType = xInfo.isPointer ? xInfo.baseType : xInfo.theType;
            String xLLVMType = toLLVMPtrType(xBaseType, xInfo.structName, xDepth);
            
            String addrTmp = xInfo.tmp;
            if (!ptrLLVM.equals(xLLVMType)) {
                String casted = newTemp();
                addInstruction(casted + " = bitcast " + xLLVMType + " " + xInfo.tmp + " to " + ptrLLVM);
                addrTmp = casted;
            }
            addInstruction("store " + ptrLLVM + " " + addrTmp + ", " + ptrLLVM + "* " + pInfo.tmp + ", align 8");
            $type = TypeInfo.Pointer; $tmp = addrTmp;
        }
      }
    // ── 字串字面值賦值給 char 陣列：buf = "hello"; ──
    | id=ID op='=' str=STRINGLITERALS
      {
        Info info = symtab.get($id.getText());
        if (info == null) info = globalSymtab.get($id.getText());
        if (info == null || info.theType != TypeInfo.Char || info.arraySize <= 0) {
            System.err.println("Error! " + $id.getLine() + ": '" + $id.getText() + "' must be a char array for string assignment.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            // 解析字串字面值，逐字元 store
            String rawStr = $str.getText();
            String inner  = rawStr.substring(1, rawStr.length() - 1);
            java.util.List<Integer> bytes = new java.util.ArrayList<>();
            int ssi = 0;
            while (ssi < inner.length()) {
                if (inner.charAt(ssi) == '\\' && ssi + 1 < inner.length()) {
                    switch (inner.charAt(ssi + 1)) {
                        case 'n':  bytes.add((int)'\n'); break;
                        case 't':  bytes.add((int)'\t'); break;
                        case '0':  bytes.add(0); break;
                        case 'r':  bytes.add((int)'\r'); break;
                        case '\\': bytes.add((int)'\\'); break;
                        case '\'': bytes.add((int)'\''); break;
                        case '"':  bytes.add((int)'"'); break;
                        default:   bytes.add((int)inner.charAt(ssi + 1)); break;
                    }
                    ssi += 2;
                } else {
                    bytes.add((int) inner.charAt(ssi++));
                }
            }
            bytes.add(0); // null terminator
            String arrType2 = "[" + info.arraySize + " x i8]";
            for (int bi = 0; bi < bytes.size() && bi < info.arraySize; bi++) {
                String ep = newTemp();
                addInstruction(ep + " = getelementptr inbounds " + arrType2 + ", " + arrType2 + "* " + info.tmp + ", i32 0, i32 " + bi);
                addInstruction("store i8 " + bytes.get(bi) + ", i8* " + ep + ", align 1");
            }
            // 回傳 i8* 指向陣列頭，方便鏈式使用
            String headPtr = newTemp();
            addInstruction(headPtr + " = getelementptr inbounds " + arrType2 + ", " + arrType2 + "* " + info.tmp + ", i32 0, i32 0");
            charPtrTemps.add(headPtr);
            $type = TypeInfo.Char; $tmp = headPtr;
        }
      }
    // ── 陣列元素寫入 a[idx1][idx2][idx3]? = expr ──
    | id=ID '[' idx=expression ']' ('[' idx2=expression ']')? ('[' idx3=expression ']')? op='=' b=assignmentExpression
      {
        Info info = symtab.get($id.getText());
        if (info == null) info = globalSymtab.get($id.getText());
        
        if (info == null) {
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier " + $id.getText() + ".");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            String elemPtr = newTemp();
            TypeInfo actualElemType;
            String elemLLVMType;
            
            if (info.arrayDim3 > 0 && $idx3.ctx != null && info.arrayDim2 > 0 && info.arraySize > 0) {
                // ── 三維本地陣列 GEP ──
                // ✨ 邊界檢查
                emitBoundsCheck($id.getLine(), $id.getText()+"[0]", $idx.tmp, $idx.isConst, (int)$idx.constVal, info.arraySize);
                emitBoundsCheck($id.getLine(), $id.getText()+"[1]", $idx2.tmp, $idx2.isConst, (int)$idx2.constVal, info.arrayDim2);
                emitBoundsCheck($id.getLine(), $id.getText()+"[2]", $idx3.tmp, $idx3.isConst, (int)$idx3.constVal, info.arrayDim3);
                actualElemType = info.theType;
                elemLLVMType = toLLVMType(actualElemType);
                String dim3TypeStr = "[" + info.arrayDim3 + " x " + elemLLVMType + "]";
                String dim2TypeStr = "[" + info.arrayDim2 + " x " + dim3TypeStr + "]";
                String arrType3D = "[" + info.arraySize + " x " + dim2TypeStr + "]";
                addInstruction(elemPtr + " = getelementptr inbounds " + arrType3D + ", " + arrType3D + "* " + info.tmp
                    + ", i32 0, i32 " + $idx.tmp + ", i32 " + $idx2.tmp + ", i32 " + $idx3.tmp);
            } else if (info.arrayDim2 > 0 && $idx2.ctx != null && info.arraySize > 0) {
                // ── 二維本地陣列 GEP (需要三個 index: 0, i, j) ──
                // ✨ 邊界檢查
                emitBoundsCheck($id.getLine(), $id.getText()+"[0]", $idx.tmp, $idx.isConst, (int)$idx.constVal, info.arraySize);
                emitBoundsCheck($id.getLine(), $id.getText()+"[1]", $idx2.tmp, $idx2.isConst, (int)$idx2.constVal, info.arrayDim2);
                actualElemType = info.theType;
                if (actualElemType == TypeInfo.Pointer) actualElemType = TypeInfo.Int;
                elemLLVMType = toLLVMType(actualElemType);
                String arrType = "[" + info.arraySize + " x [" + info.arrayDim2 + " x " + elemLLVMType + "]]";
                addInstruction(elemPtr + " = getelementptr inbounds " + arrType + ", " + arrType + "* " + info.tmp + ", i32 0, i32 " + $idx.tmp + ", i32 " + $idx2.tmp);
            } else if (info.arraySize > 0) {
                // ── 一維陣列 GEP ──
                // ✨ 邊界檢查
                emitBoundsCheck($id.getLine(), $id.getText(), $idx.tmp, $idx.isConst, (int)$idx.constVal, info.arraySize);
                actualElemType = info.theType;
                elemLLVMType = toLLVMType(actualElemType);
                String arrType = "[" + info.arraySize + " x " + elemLLVMType + "]";
                addInstruction(elemPtr + " = getelementptr inbounds " + arrType + ", " + arrType + "* " + info.tmp + ", i32 0, i32 " + $idx.tmp);
            } else if (info.arraySize == -2) {
                // ── VLA：alloca 直接回傳元素指標，GEP 不需要 load ──
                // Bug 3 修正：VLA 用 i64 alloca，GEP index 也必須用 i64
                actualElemType = info.theType;
                elemLLVMType = toLLVMType(actualElemType);
                String vlaIdxTmp = $idx.tmp;
                if ($idx.type != TypeInfo.Long) {
                    String sextIdx = newTemp();
                    addInstruction(sextIdx + " = sext i32 " + $idx.tmp + " to i64");
                    vlaIdxTmp = sextIdx;
                }
                addInstruction(elemPtr + " = getelementptr inbounds " + elemLLVMType + ", " + elemLLVMType + "* " + info.tmp + ", i64 " + vlaIdxTmp);
            } else if (info.isPointer || info.arraySize == -1) {
                // ✨ 特殊：3D 陣列參數 grid[][M][N]
                if (info.arrayDim3 > 0 && $idx3.ctx != null && info.arrayDim2 > 0) {
                    actualElemType = info.baseType != null ? info.baseType : TypeInfo.Int;
                    elemLLVMType = toLLVMType(actualElemType);
                    String sliceType3 = "[" + info.arrayDim3 + " x " + elemLLVMType + "]";
                    String rowType3  = "[" + info.arrayDim2 + " x " + sliceType3 + "]";
                    String rowPtrT3  = rowType3 + "*";
                    String basePtr3 = newTemp();
                    addInstruction(basePtr3 + " = load " + rowPtrT3 + ", " + rowPtrT3 + "* " + info.tmp + ", align 8");
                    String rowPtr3 = newTemp();
                    addInstruction(rowPtr3 + " = getelementptr inbounds " + rowType3 + ", " + rowPtrT3 + " " + basePtr3 + ", i32 " + $idx.tmp);
                    String slicePtr3 = newTemp();
                    addInstruction(slicePtr3 + " = getelementptr inbounds " + rowType3 + ", " + rowPtrT3 + " " + rowPtr3 + ", i32 0, i32 " + $idx2.tmp);
                    addInstruction(elemPtr + " = getelementptr inbounds " + sliceType3 + ", " + sliceType3 + "* " + slicePtr3 + ", i32 0, i32 " + $idx3.tmp);
                // ✨ 特殊：2D 陣列參數 arr[][N]（info.arrayDim2 > 0 且 isPointer）
                } else if (info.arrayDim2 > 0 && $idx2.ctx != null) {
                    actualElemType = info.baseType != null ? info.baseType : TypeInfo.Int;
                    if (actualElemType == TypeInfo.Pointer) actualElemType = TypeInfo.Int;
                    elemLLVMType = toLLVMType(actualElemType);
                    String rowType = "[" + info.arrayDim2 + " x " + elemLLVMType + "]";
                    String rowPtrT = rowType + "*";
                    // load the base pointer:  [4 x i32]** → [4 x i32]*
                    String basePtr = newTemp();
                    addInstruction(basePtr + " = load " + rowPtrT + ", " + rowPtrT + "* " + info.tmp + ", align 8");
                    // GEP to the i-th row:  getelementptr [4 x i32], [4 x i32]* base, i32 row
                    String rowPtr = newTemp();
                    addInstruction(rowPtr + " = getelementptr inbounds " + rowType + ", " + rowPtrT + " " + basePtr + ", i32 " + $idx.tmp);
                    // GEP to the j-th element within that row
                    addInstruction(elemPtr + " = getelementptr inbounds " + rowType + ", " + rowPtrT + " " + rowPtr + ", i32 0, i32 " + $idx2.tmp);
                } else {
                // ✨ 修正：多層指標陣列寫入，精準降低一層深度
                // ✨ 特殊：2D array param single-index write (arr[i] = row pointer)
                if (info.structName != null && info.structName.startsWith("[") && info.structName.endsWith("]*")) {
                    String rowPtrT2 = info.structName;
                    String rowTypeStr = rowPtrT2.substring(0, rowPtrT2.length() - 1);
                    actualElemType = TypeInfo.Pointer;
                    elemLLVMType = rowPtrT2;
                    String basePtr2 = newTemp();
                    addInstruction(basePtr2 + " = load " + rowPtrT2 + ", " + rowPtrT2 + "* " + info.tmp + ", align 8");
                    addInstruction(elemPtr + " = getelementptr inbounds " + rowTypeStr + ", " + rowPtrT2 + " " + basePtr2 + ", i32 " + $idx.tmp);
                } else {
                actualElemType = (info.ptrDepth > 1) ? TypeInfo.Pointer : info.baseType;
                elemLLVMType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth > 0 ? info.ptrDepth - 1 : 0);
                String ptrLLVMType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
                
                String loadedPtr = newTemp();
                addInstruction(loadedPtr + " = load " + ptrLLVMType + ", " + ptrLLVMType + "* " + info.tmp + ", align 8");
                addInstruction(elemPtr + " = getelementptr inbounds " + elemLLVMType + ", " + ptrLLVMType + " " + loadedPtr + ", i32 " + $idx.tmp);
                }
                }
            } else {
                // ── Fallback ──
                actualElemType = info.theType;
                elemLLVMType = toLLVMType(actualElemType);
                addInstruction(elemPtr + " = getelementptr inbounds " + elemLLVMType + ", " + elemLLVMType + "* " + info.tmp + ", i32 " + $idx.tmp);
            }
            
            // 處理陣列寫入的隱式轉型
            String rhsTmp = $b.tmp;
            if (actualElemType == TypeInfo.Float && $b.type == TypeInfo.Double) {
                rhsTmp = newTemp();
                addInstruction(rhsTmp + " = fptrunc double " + $b.tmp + " to float");
            } else if (actualElemType == TypeInfo.Float && $b.type == TypeInfo.Int) {
                rhsTmp = newTemp();
                addInstruction(rhsTmp + " = sitofp i32 " + $b.tmp + " to float");
            } else if (actualElemType == TypeInfo.Int && ($b.type == TypeInfo.Float || $b.type == TypeInfo.Double)) {
                rhsTmp = newTemp();
                addInstruction(rhsTmp + " = fptosi " + toLLVMType($b.type) + " " + $b.tmp + " to i32");
            } else if (actualElemType == TypeInfo.Char && $b.type == TypeInfo.Int) {
                rhsTmp = newTemp();
                addInstruction(rhsTmp + " = trunc i32 " + $b.tmp + " to i8");
            } else if (actualElemType == TypeInfo.Int && $b.type == TypeInfo.Char) {
                rhsTmp = newTemp();
                addInstruction(rhsTmp + " = sext i8 " + $b.tmp + " to i32");
            } else if ($b.type == TypeInfo.Boolean && (actualElemType == TypeInfo.Int || actualElemType == TypeInfo.Long
                       || actualElemType == TypeInfo.Short || actualElemType == TypeInfo.UnsignedInt
                       || actualElemType == TypeInfo.UnsignedLong || actualElemType == TypeInfo.UnsignedShort
                       || actualElemType == TypeInfo.UnsignedChar || actualElemType == TypeInfo.Char)) {
                // ✨ Bug fix：bool 寫入整數型別陣列元素時，需先 zext i1 → 目標寬度
                rhsTmp = newTemp();
                addInstruction(rhsTmp + " = zext i1 " + $b.tmp + " to " + elemLLVMType);
            } else if ($b.type == TypeInfo.Boolean && (actualElemType == TypeInfo.Float || actualElemType == TypeInfo.Double)) {
                // ✨ Bug fix：bool 寫入浮點型別陣列元素時，先 zext 成 i32 再轉浮點
                String ext = newTemp();
                addInstruction(ext + " = zext i1 " + $b.tmp + " to i32");
                rhsTmp = newTemp();
                addInstruction(rhsTmp + " = sitofp i32 " + ext + " to " + elemLLVMType);
            }
            
            // 👇 👇 從這裡開始替換 👇 👇
            // ✨ 核心修正 1：陣列元素寫入時的安全 bitcast 防護網 ✨
            if (actualElemType == TypeInfo.Pointer && ($b.type == TypeInfo.Pointer || rhsTmp.equals("0"))) {
                if (rhsTmp.equals("0")) {
                    rhsTmp = "null";
                    exactTypeMap.put("null", elemLLVMType);
                } else {
                    String srcLLVM = exactTypeMap.containsKey(rhsTmp) ? exactTypeMap.get(rhsTmp) : "i8*";
                    if (!srcLLVM.equals(elemLLVMType)) {
                        String casted = newTemp();
                        addInstruction(casted + " = bitcast " + srcLLVM + " " + rhsTmp + " to " + elemLLVMType);
                        rhsTmp = casted;
                    }
                }
            }
            // ✨ 儲存對齊改為 8，更安全地相容指標
            addInstruction("store " + elemLLVMType + " " + rhsTmp + ", " + elemLLVMType + "* " + elemPtr + ", align 8");
            $type = actualElemType;
            $tmp = rhsTmp;
            // 👆 👆 替換到這裡 👆 👆
        }
      }
// ── 分支：結構體/指標成員下標賦值 (如 p->data[i] = 'x', s.arr[i] = 42, ia->vals[i] += 10) ──
    | id1=ID opPtr2=(PERIOD | POINTTO) id2=ID '[' idx=expression ']' op2=('=' | '+=' | '-=' | '*=' | '/=' | '%=' | '<<=' | '>>=' | '&=' | '|=' | '^=') b2=assignmentExpression
      {
        String name = $id1.getText();
        Info info = symtab.get(name);
        if (info == null) info = globalSymtab.get(name);

        boolean isArrow = $opPtr2.getText().equals("->");

        if (info == null) {
            System.err.println("Error! " + $id1.getLine() + ": Undeclared identifier '" + name + "'.");
            $type = TypeInfo.Error; $tmp = "0"; $isConst = false; $constVal = 0;
        } else if (info.structName == null) {
            System.err.println("Error! " + $id1.getLine() + ": Cannot resolve struct type for '" + name + "'.");
            $type = TypeInfo.Error; $tmp = "0"; $isConst = false; $constVal = 0;
        } else {
            StructDef sdef = structRegistry.get(info.structName);
            int[] res = (sdef != null) ? resolveAnonField(sdef, $id2.getText()) : null;
            int fIdx = (res != null && res.length >= 1) ? res[0] : -1;

            if (fIdx < 0 || sdef == null) {
                System.err.println("Error! " + $id2.getLine() + ": No field '" + $id2.getText() + "' in struct " + info.structName + ".");
                $type = TypeInfo.Error; $tmp = "0"; $isConst = false; $constVal = 0;
            } else {
                // ── 取得 struct 基底指標 ──
                String structT = "%struct." + info.structName;
                String baseAddr;        // 指向 struct 本體的指標
                if (isArrow) {
                    baseAddr = newTemp();
                    addInstruction(baseAddr + " = load " + structT + "*, " + structT + "** " + info.tmp + ", align 8");
                } else {
                    baseAddr = info.tmp; // 直接是 alloca 指標
                }

                // ── GEP 到成員欄位 ──
                TypeInfo fType = sdef.fTypes.get(fIdx);
                TypeInfo fPointee = sdef.fPointeeTypes.get(fIdx);
                int famMark = sdef.bitWidths.get(fIdx);     // 0 = FAM

                String elemLLVMType;
                String fieldBasePtr;    // 指向 data[0] 的指標

                if (famMark == 0 && fPointee != null) {
                    // ── FAM：struct { int n; T data[]; }  ──
                    // data 欄位在 LLVM 是 [0 x T]，GEP 到 data[0] 再加 idx
                    elemLLVMType = toLLVMType(fPointee);
                    String arrType = "[0 x " + elemLLVMType + "]";
                    // GEP 到 [0 x T]* 欄位指標
                    String famFieldPtr = newTemp();
                    addInstruction(famFieldPtr + " = getelementptr inbounds " + structT
                                   + ", " + structT + "* " + baseAddr
                                   + ", i32 0, i32 " + fIdx);
                    exactTypeMap.put(famFieldPtr, arrType + "*");
                    // 再 GEP [0 x T] 取第 idx 個元素
                    fieldBasePtr = newTemp();
                    addInstruction(fieldBasePtr + " = getelementptr inbounds " + arrType
                                   + ", " + arrType + "* " + famFieldPtr
                                   + ", i32 0, i32 " + $idx.tmp);
                    exactTypeMap.put(fieldBasePtr, elemLLVMType + "*");
                } else if (fType == TypeInfo.Pointer && fPointee != null) {
                    // ── 一般指標欄位：struct { int n; T *arr; } ──
                    elemLLVMType = toLLVMType(fPointee);
                    // GEP 到 T** 欄位再 load 出 T*
                    String fPtrPtr = newTemp();
                    addInstruction(fPtrPtr + " = getelementptr inbounds " + structT
                                   + ", " + structT + "* " + baseAddr
                                   + ", i32 0, i32 " + fIdx);
                    String fPtrVal = newTemp();
                    addInstruction(fPtrVal + " = load " + elemLLVMType + "*, "
                                   + elemLLVMType + "** " + fPtrPtr + ", align 8");
                    // 再 GEP 取第 idx 個元素
                    fieldBasePtr = newTemp();
                    addInstruction(fieldBasePtr + " = getelementptr inbounds " + elemLLVMType
                                   + ", " + elemLLVMType + "* " + fPtrVal
                                   + ", i32 " + $idx.tmp);
                } else {
                    // 不可下標存取的欄位
                    System.err.println("Error! " + $id2.getLine() + ": Field '" + $id2.getText() + "' is not subscriptable.");
                    $type = TypeInfo.Error; $tmp = "0"; $isConst = false; $constVal = 0;
                    elemLLVMType = "i32"; fieldBasePtr = "undef";
                }

                // ── 隱式型別轉換後寫入 ──
                String rhs = $b2.tmp;
                TypeInfo rhsType = $b2.type;
                TypeInfo elemTI = (fPointee != null) ? fPointee : fType;
                String opText2 = $op2.getText();

                if (elemTI == TypeInfo.Float && rhsType == TypeInfo.Int) {
                    String c = newTemp(); addInstruction(c + " = sitofp i32 " + rhs + " to float"); rhs = c;
                } else if (elemTI == TypeInfo.Double && rhsType == TypeInfo.Int) {
                    String c = newTemp(); addInstruction(c + " = sitofp i32 " + rhs + " to double"); rhs = c;
                } else if (elemTI == TypeInfo.Char) {
                    elemLLVMType = "i8";
                    if (rhsType == TypeInfo.Int) {
                        String c = newTemp(); addInstruction(c + " = trunc i32 " + rhs + " to i8"); rhs = c;
                    }
                }

                // ── 依元素型別決定 align ──
                String storeAlign2 = (elemTI == TypeInfo.Char)   ? "1"
                                   : (elemTI == TypeInfo.Double) ? "8"
                                   : (elemTI == TypeInfo.Long)   ? "8"
                                   : "4";  // int / float / pointer → 4

                // 複合賦值：先 load 舊值，再做運算
                if (!opText2.equals("=")) {
                    String cur = newTemp();
                    addInstruction(cur + " = load " + elemLLVMType + ", " + elemLLVMType + "* " + fieldBasePtr + ", align " + storeAlign2);
                    boolean isFloat2 = (elemTI == TypeInfo.Float || elemTI == TypeInfo.Double);
                    String llvmOp2;
                    switch (opText2) {
                        case "+=":  llvmOp2 = isFloat2 ? "fadd" : "add";  break;
                        case "-=":  llvmOp2 = isFloat2 ? "fsub" : "sub";  break;
                        case "*=":  llvmOp2 = isFloat2 ? "fmul" : "mul";  break;
                        case "/=":  llvmOp2 = isFloat2 ? "fdiv" : "sdiv"; break;
                        case "%=":  llvmOp2 = "srem"; break;
                        case "<<=": llvmOp2 = "shl";  break;
                        case ">>=": llvmOp2 = "ashr"; break;
                        case "&=":  llvmOp2 = "and";  break;
                        case "|=":  llvmOp2 = "or";   break;
                        case "^=":  llvmOp2 = "xor";  break;
                        default:    llvmOp2 = "add";  break;
                    }
                    String res2 = newTemp();
                    addInstruction(res2 + " = " + llvmOp2 + " " + elemLLVMType + " " + cur + ", " + rhs);
                    rhs = res2;
                }

                addInstruction("store " + elemLLVMType + " " + rhs + ", " + elemLLVMType + "* " + fieldBasePtr + ", align " + storeAlign2);
                $type = elemTI;
                $tmp = rhs;
                $isConst = false; $constVal = 0;
            }
        }
      }
// ── 分支：結構體/指標成員賦值 (如 p->x = 10, s.y += 5, (*pp)->x = 10) ──
    |
    ( id1=ID | '(' s1='*' s2='*'? id1=ID ')' ) opPtr=(PERIOD | POINTTO) id2=ID op=('=' | '+=' | '-=' | '*=' | '/=' | '%=' | '<<=' | '>>=' | '&=' | '|=' | '^=') b=assignmentExpression
      {
        String name = $id1.getText();
        Info info = symtab.get(name);
        if (info == null) info = globalSymtab.get(name);
        
        boolean isArrow = $opPtr.getText().equals("->");
        int derefs = ($s1 != null) ? (($s2 != null) ? 2 : 1) : 0;
        
        // ✨ 精準區分錯誤與指標檢查 ✨
        if (info == null) {
            System.err.println("Error! " + $id1.getLine() + ": Undeclared identifier '" + name + "'.");
            $type = TypeInfo.Error;
            $tmp = "0";
        } else if (isArrow && !info.isPointer && derefs == 0) {
            System.err.println("Error! " + $id1.getLine() + ": '" + name + "' is not a pointer, cannot use '->'.");
            $type = TypeInfo.Error;
            $tmp = "0";
        } else if (!isArrow && info.theType != TypeInfo.Struct && derefs == 0) {
            System.err.println("Error! " + $id1.getLine() + ": '" + name + "' is not a struct, cannot use '.'.");
            $type = TypeInfo.Error;
            $tmp = "0";
        } else if (info.structName == null) {
            System.err.println("Error! " + $id1.getLine() + ": Cannot resolve struct type for '" + name + "'.");
            $type = TypeInfo.Error;
            $tmp = "0";
        } else {
            StructDef sdef = structRegistry.get(info.structName);
            // ✨ 用 resolveAnonField 支援匿名成員多層查找
            int[] anonResLV = resolveAnonField(sdef, $id2.getText());
            int fIdx = -1;
            StructDef effectiveSdefLV = sdef;
            int realFIdxLV = -1;

            if (anonResLV != null && anonResLV.length >= 2) {
                fIdx = anonResLV[0];
                int lastIdxLV = anonResLV[anonResLV.length - 1];
                if (anonResLV.length == 2 && lastIdxLV == -1) {
                    realFIdxLV = fIdx;
                    effectiveSdefLV = sdef;
                } else {
                    // 從 sdef 出發，沿 path[0..length-2] 逐層進入匿名 def
                    StructDef curDefLV = sdef;
                    for (int pi = 0; pi < anonResLV.length - 1; pi++) {
                        String aSN = curDefLV.fStructNames.get(anonResLV[pi]);
                        StructDef next = structRegistry.get(aSN);
                        if (next == null) break;
                        curDefLV = next;
                    }
                    effectiveSdefLV = curDefLV;
                    realFIdxLV = lastIdxLV;
                }
            }

            if (fIdx < 0 || realFIdxLV < 0 || effectiveSdefLV == null) {
                System.err.println("Error! " + $id2.getLine() + ": No field '" + $id2.getText() + "' in struct " + info.structName + ".");
                $type = TypeInfo.Error;
                $tmp = "0";
            } else {
                TypeInfo fType = effectiveSdefLV.fTypes.get(realFIdxLV);
                $type = fType;
                String structT = "%struct." + info.structName;

                String fPtr = newTemp();
                // ✨ 精準查出結構體欄位的真實型別 ✨
                String fLlvmT;
                List<TypeInfo> fPointees = effectiveSdefLV.fPointeeTypes;
                TypeInfo fPointee = (fPointees != null && realFIdxLV < fPointees.size()) ? fPointees.get(realFIdxLV) : null;
                if (fType == TypeInfo.Struct && effectiveSdefLV.fStructNames != null && realFIdxLV < effectiveSdefLV.fStructNames.size() && effectiveSdefLV.fStructNames.get(realFIdxLV) != null) {
                    fLlvmT = "%struct." + effectiveSdefLV.fStructNames.get(realFIdxLV);
                } else if (fType == TypeInfo.Pointer && fPointee != null) {
                    if (fPointee == TypeInfo.Struct && effectiveSdefLV.fStructNames.get(realFIdxLV) != null) {
                        fLlvmT = "%struct." + effectiveSdefLV.fStructNames.get(realFIdxLV) + "*";
                    } else if (fPointee == TypeInfo.Void) {
                        fLlvmT = "i8*";
                    } else {
                        fLlvmT = toLLVMType(fPointee) + "*";
                    }
                } else {
                    fLlvmT = toLLVMType(fType);
                }

                // ✨ 多層匿名成員 GEP（lvalue 版）
                String baseVal = info.tmp;
                if (derefs > 0) {
                    String ptrLLVM = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
                    String currentVal = newTemp();
                    addInstruction(currentVal + " = load " + ptrLLVM + ", " + ptrLLVM + "* " + info.tmp + ", align 8");
                    String currentType = ptrLLVM;
                    for (int i = 0; i < derefs; i++) {
                        String nextType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth - 1 - i);
                        String result = newTemp();
                        addInstruction(result + " = load " + nextType + ", " + currentType + " " + currentVal + ", align 8");
                        currentVal = result;
                        currentType = nextType;
                    }
                    baseVal = currentVal;
                }

                boolean isDirectLV = (anonResLV.length == 2 && anonResLV[1] == -1);
                if (!isDirectLV) {
                    // 多層匿名：逐層 GEP
                    StructDef curDefLV2 = sdef;
                    String curBaseLV = baseVal;
                    String curStructTLV = structT;
                    for (int pi = 0; pi < anonResLV.length - 1; pi++) {
                        int stepIdx = anonResLV[pi];
                        String anonSN2 = curDefLV2.fStructNames.get(stepIdx);
                        String anonStructT2 = "%struct." + anonSN2;
                        String stepPtr = newTemp();
                        if (curDefLV2.isUnion) {
                            // ✨ union：直接 bitcast 到子型別指標，不用 GEP（union LLVM type 只有 [N x i8]）
                            addInstruction(stepPtr + " = bitcast " + curStructTLV + "* " + curBaseLV + " to " + anonStructT2 + "*");
                        } else if (pi == 0 && isArrow && derefs == 0) {
                            String structAddr = newTemp();
                            addInstruction(structAddr + " = load " + curStructTLV + "*, " + curStructTLV + "** " + info.tmp + ", align 8");
                            addInstruction(stepPtr + " = getelementptr inbounds " + curStructTLV + ", " + curStructTLV + "* " + structAddr + ", i32 0, i32 " + stepIdx);
                        } else {
                            addInstruction(stepPtr + " = getelementptr inbounds " + curStructTLV + ", " + curStructTLV + "* " + curBaseLV + ", i32 0, i32 " + stepIdx);
                        }
                        curBaseLV = stepPtr;
                        curStructTLV = anonStructT2;
                        StructDef nextDef = structRegistry.get(anonSN2);
                        if (nextDef != null) curDefLV2 = nextDef;
                    }
                    int lastStepLV = anonResLV[anonResLV.length - 1];
                    if (curDefLV2 != null && curDefLV2.isUnion) {
                        addInstruction(fPtr + " = bitcast " + curStructTLV + "* " + curBaseLV + " to " + fLlvmT + "*");
                    } else {
                        addInstruction(fPtr + " = getelementptr inbounds " + curStructTLV + ", " + curStructTLV + "* " + curBaseLV + ", i32 0, i32 " + lastStepLV);
                    }
                } else if (derefs > 0) {
                    if (isArrow) {
                        if (sdef.isUnion) {
                            addInstruction(fPtr + " = bitcast " + structT + "* " + baseVal + " to " + fLlvmT + "*");
                        } else {
                            addInstruction(fPtr + " = getelementptr inbounds " + structT + ", " + structT + "* " + baseVal + ", i32 0, i32 " + fIdx);
                        }
                    } else {
                        if (sdef.isUnion) {
                            addInstruction(fPtr + " = bitcast " + structT + "* " + baseVal + " to " + fLlvmT + "*");
                        } else {
                            addInstruction(fPtr + " = getelementptr inbounds " + structT + ", " + structT + "* " + baseVal + ", i32 0, i32 " + fIdx);
                        }
                    }
                } else {
                    // 原本沒有括號解參考的邏輯
                    if (isArrow) {
                        String structAddr = newTemp();
                        addInstruction(structAddr + " = load " + structT + "*, " + structT + "** " + info.tmp + ", align 8");
                        if (sdef.isUnion) {
                            addInstruction(fPtr + " = bitcast " + structT + "* " + structAddr + " to " + fLlvmT + "*");
                        } else {
                            addInstruction(fPtr + " = getelementptr inbounds " + structT + ", " + structT + "* " + structAddr + ", i32 0, i32 " + fIdx);
                        }
                    } else {
                        if (sdef.isUnion) {
                            addInstruction(fPtr + " = bitcast " + structT + "* " + info.tmp + " to " + fLlvmT + "*");
                        } else {
                            addInstruction(fPtr + " = getelementptr inbounds " + structT + ", " + structT + "* " + info.tmp + ", i32 0, i32 " + fIdx);
                        }
                    }
                }
                
                // ════════ 下半部：隱式轉型與寫入儲存 ════════
                String opText = $op.getText();
                String llvmT = fLlvmT; // ✨ 直接沿用剛剛算好的精準型別
                String rhs = $b.tmp;
                TypeInfo rhsType = $b.type;

                if (fType == TypeInfo.Pointer) {
                    // ✨ 結構體指標的 NULL 防護網 ✨
                    if (rhs.equals("0")) {
                        rhs = "null";
                        exactTypeMap.put("null", llvmT);
                    } else {
                        String srcType = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : "i8*"; 
                        if (!srcType.equals(llvmT)) {
                            String casted = newTemp();
                            addInstruction(casted + " = bitcast " + srcType + " " + rhs + " to " + llvmT);
                            rhs = casted;
                        }
                    }
                    // 順便更新小本本
                    exactTypeMap.put(rhs, llvmT);
                }
                
                // 先做隱式轉型（= 和 += 等都需要）
                if (fType == TypeInfo.Float && rhsType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to float"); rhs = conv;
                } else if (fType == TypeInfo.Float && rhsType == TypeInfo.Double) {
                    String conv = newTemp(); addInstruction(conv + " = fptrunc double " + rhs + " to float"); rhs = conv;
                } else if (fType == TypeInfo.Int && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                    String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i32"); rhs = conv;
                } else if (fType == TypeInfo.Double && rhsType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to double"); rhs = conv;
                } else if (fType == TypeInfo.Double && rhsType == TypeInfo.Float) {
                    String conv = newTemp(); addInstruction(conv + " = fpext float " + rhs + " to double"); rhs = conv;
                }
                
                if (!opText.equals("=")) {
                    String cur = newTemp();
                    addInstruction(cur + " = load " + llvmT + ", " + llvmT + "* " + fPtr + ", align 8");
                    String result = newTemp();
                    boolean isFloat = (fType == TypeInfo.Float || fType == TypeInfo.Double);
                    String llvmOp;
                    switch (opText) {
                        case "+=": llvmOp = isFloat ? "fadd" : "add"; break;
                        case "-=": llvmOp = isFloat ? "fsub" : "sub"; break;
                        case "*=": llvmOp = isFloat ? "fmul" : "mul"; break;
                        case "/=": llvmOp = isFloat ? "fdiv" : (isUnsignedType(fType) ? "udiv" : "sdiv"); break;
                        case "%=": llvmOp = isUnsignedType(fType) ? "urem" : "srem"; break;
                        case "<<=": llvmOp = "shl"; break;
                        case ">>=": llvmOp = "ashr"; break;
                        case "&=":  llvmOp = "and"; break;
                        case "|=":  llvmOp = "or"; break;
                        case "^=":  llvmOp = "xor"; break;
                        default:   llvmOp = "add"; break;
                    }
                    addInstruction(result + " = " + llvmOp + " " + llvmT + " " + cur + ", " + rhs);
                    rhs = result;
                }

                // ✨ bit-field 寫入：load i32 → clear bits → or new value → store
                int bfWidth = (effectiveSdefLV.hasBitFields && realFIdxLV < effectiveSdefLV.bitWidths.size()) ? effectiveSdefLV.bitWidths.get(realFIdxLV) : -1;
                if (bfWidth > 0) {
                    int bfShift = bitFieldOffset(sdef, fIdx);
                    int bfMask  = ((1 << bfWidth) - 1); // e.g. width=3 → 0b111
                    // GEP to the i32 container (field 0 of the bit-field struct)
                    String bfContainerPtr = newTemp();
                    addInstruction(bfContainerPtr + " = getelementptr inbounds " + structT + ", " + structT + "* " + baseVal + ", i32 0, i32 0");
                    // load current packed value
                    String oldPacked = newTemp();
                    addInstruction(oldPacked + " = load i32, i32* " + bfContainerPtr + ", align 4");
                    // clear the field's bits:  old & ~(mask << shift)
                    int clearMask = ~(bfMask << bfShift);
                    String cleared = newTemp();
                    addInstruction(cleared + " = and i32 " + oldPacked + ", " + clearMask);
                    // truncate rhs to the field width, then shift left
                    String rhs32 = rhs;
                    // ensure rhs is i32
                    if (rhsType == TypeInfo.Char || rhsType == TypeInfo.Short) {
                        String ext = newTemp();
                        addInstruction(ext + " = zext " + toLLVMType(rhsType) + " " + rhs + " to i32");
                        rhs32 = ext;
                    }
                    // mask to field width
                    String maskedVal = newTemp();
                    addInstruction(maskedVal + " = and i32 " + rhs32 + ", " + bfMask);
                    // shift to position
                    String shifted = newTemp();
                    addInstruction(shifted + " = shl i32 " + maskedVal + ", " + bfShift);
                    // merge
                    String merged = newTemp();
                    addInstruction(merged + " = or i32 " + cleared + ", " + shifted);
                    // store back
                    addInstruction("store i32 " + merged + ", i32* " + bfContainerPtr + ", align 4");
                    $tmp = maskedVal;
                } else {
                // 儲存結果 (align 8 可以涵蓋指標與 double)
                addInstruction("store " + llvmT + " " + rhs + ", " + llvmT + "* " + fPtr + ", align 8");
                $tmp = rhs;
                }
            }
        }
        $isConst = false; $constVal = 0; // 賦值運算，取消常數折疊
      }
    // ── 分支:一般變數賦值 (如 a = 10, temp <<= 1) ──
    | id=ID  op=('=' | '+=' | '-=' | '*=' | '/=' | '%=' | '<<=' | '>>=' | '&=' | '|=' | '^=') b=assignmentExpression
      {
        String name = $id.getText();
        Info info = symtab.get(name);
        if (info == null) info = globalSymtab.get(name); // ✨ 加入全域變數尋找
        
        if (info == null) {
            // ✨ 真正把錯誤印出來！
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier '" + name + "'.");
            $type = TypeInfo.Error;
            $tmp = "0"; // 補上 fallback 防止後續當機
            
            // ✨ 補上屬性：發生錯誤，視為非常數
            $isConst = false; 
            $constVal = 0;
        } else {
                String opText = $op.getText();

                String llvmT;
                // ✨ 修正：根據 info 決定 LLVM 型別，全面支援多層指標
                if (info.structName != null && info.structName.contains("(")) {
                    // 函式指標：structName 存的是完整的函式指標型別字串
                    llvmT = info.structName;
                } else if (info.isPointer) {
                    // ✨ 核心升級：使用最新版的 ptrDepth 多層指標查表
                    llvmT = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
                } else if (info.theType == TypeInfo.Struct && info.structName != null) {
                    llvmT = "%struct." + info.structName;
                } else {
                    llvmT = toLLVMType(info.theType);
                }

                String rhs = $b.tmp;
                TypeInfo rhsType = $b.type;

                // Implicit type conversion on simple assignment
                if (opText.equals("=")) {
                    if (info.theType == TypeInfo.Long && (rhsType == TypeInfo.Int || rhsType == TypeInfo.Boolean || rhsType == TypeInfo.Char)) {
                        // ── Int/Char → Long：sext 到 i64；Bool → Long：zext 到 i64（✨ Bug fix）──
                        String srcT = (rhsType == TypeInfo.Char) ? "i8" : (rhsType == TypeInfo.Boolean) ? "i1" : "i32";
                        String extOp = (rhsType == TypeInfo.Boolean) ? "zext" : "sext";
                        String conv = newTemp();
                        addInstruction(conv + " = " + extOp + " " + srcT + " " + rhs + " to i64");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Int && rhsType == TypeInfo.Long) {
                        // ── Long → Int：trunc i64 → i32 ──
                        String conv = newTemp();
                        addInstruction(conv + " = trunc i64 " + rhs + " to i32");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Long && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                        // ── Float/Double → Long ──
                        String conv = newTemp();
                        addInstruction(conv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i64");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Float && rhsType == TypeInfo.Long) {
                        // ── Long → Float ──
                        String conv = newTemp();
                        addInstruction(conv + " = sitofp i64 " + rhs + " to float");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Double && rhsType == TypeInfo.Long) {
                        // ── Long → Double ──
                        String conv = newTemp();
                        addInstruction(conv + " = sitofp i64 " + rhs + " to double");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Int && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                        String conv = newTemp();
                        addInstruction(conv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i32");
                        rhs = conv;

                    // 👇 ✨ 修正：支援一般賦值時的指標轉整數 (ptrtoint) ✨ 👇
                    } else if ((info.theType == TypeInfo.Int || info.theType == TypeInfo.Error) && rhsType == TypeInfo.Pointer) {
                        String srcT = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : "i8*";
                        String conv = newTemp();
                        addInstruction(conv + " = ptrtoint " + srcT + " " + rhs + " to i32");
                        rhs = conv;
                        
                    // 👇 ✨ 修正：支援一般賦值時的整數轉指標 (inttoptr) ✨ 👇
                    } else if (info.isPointer && (rhsType == TypeInfo.Int || rhsType == TypeInfo.Error) && !rhs.equals("0")) {
                        String conv = newTemp();
                        addInstruction(conv + " = inttoptr i32 " + rhs + " to " + llvmT);
                        rhs = conv;
                    } else if ((info.theType == TypeInfo.Float || info.theType == TypeInfo.Double) && rhsType == TypeInfo.Int) {
                        String conv = newTemp();
                        addInstruction(conv + " = sitofp i32 " + rhs + " to " + llvmT);
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Float && rhsType == TypeInfo.Double) {
                        // ── Double → Float（截斷）: float f = 0.1; 0.1 是 double → fptrunc ──
                        String conv = newTemp();
                        addInstruction(conv + " = fptrunc double " + rhs + " to float");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Double && rhsType == TypeInfo.Float) {
                        // ── Float → Double（提升）──
                        String conv = newTemp();
                        addInstruction(conv + " = fpext float " + rhs + " to double");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Int && rhsType == TypeInfo.Boolean) {
                        String conv = newTemp();
                        addInstruction(conv + " = zext i1 " + rhs + " to i32");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Char && rhsType == TypeInfo.Int) {
                        // ── Char = Int：截斷為 i8 ──
                        String conv = newTemp();
                        addInstruction(conv + " = trunc i32 " + rhs + " to i8");
                        rhs = conv;
                    } else if (info.theType == TypeInfo.Int && rhsType == TypeInfo.Char) {
                        // ── Int = Char：符號擴展為 i32 ──
                        String conv = newTemp();
                        addInstruction(conv + " = sext i8 " + rhs + " to i32");
                        rhs = conv;
                    }       
                    
                    // ✨ 指標賦值時的安全 bitcast 防護網 ✨
                    if (info.isPointer && "0".equals(rhs)) rhs = "null"; // ✨ 整數 0 賦給指標 → null
                    if (info.isPointer && (rhsType == TypeInfo.Pointer || rhs.equals("null"))) {
                        String destLLVM = (info.structName != null && info.structName.contains("("))
                            ? info.structName
                            : toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
                        if (rhs.equals("null")) {
                            exactTypeMap.put("null", destLLVM);
                        } else {
                            // ✨ 改為使用 destLLVM 作為預設值，找不到就不會產生錯誤的 bitcast
                            String srcLLVM = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : destLLVM; 
                            if (!srcLLVM.equals(destLLVM)) {
                                String casted = newTemp();
                                addInstruction(casted + " = bitcast " + srcLLVM + " " + rhs + " to " + destLLVM);
                                rhs = casted;
                            }
                        }
                    }
                    
                    addInstruction("store " + llvmT + " " + rhs + ", " + llvmT + "* " + info.tmp + ", align " + (info.theType == TypeInfo.Boolean ? "1" : "8")); // ✨ 指標和一般賦值對齊建議改為 8 較安全
                    $type = info.theType;
                    $tmp = rhs;
                    
                } else {
                    if (!opText.equals("=")) {
                        String cur = newTemp();
                        addInstruction(cur + " = load " + llvmT + ", " + llvmT + "* " + info.tmp + ", align " + (info.theType == TypeInfo.Boolean ? "1" : "8"));
                        // 👇 ✨ 補上 Long (i64) 複合賦值的隱式轉型 ✨ 👇
                        if (info.theType == TypeInfo.Long && (rhsType == TypeInfo.Int || rhsType == TypeInfo.Boolean || rhsType == TypeInfo.Char)) {
                            String srcT = (rhsType == TypeInfo.Char) ? "i8" : (rhsType == TypeInfo.Boolean) ? "i1" : "i32";
                            String extOp = (rhsType == TypeInfo.Boolean) ? "zext" : "sext"; // ✨ Bug fix：bool→long 必須 zext
                            String conv = newTemp();
                            addInstruction(conv + " = " + extOp + " " + srcT + " " + rhs + " to i64"); rhs = conv;
                        } else if (info.theType == TypeInfo.Int && rhsType == TypeInfo.Long) {
                            String conv = newTemp();
                            addInstruction(conv + " = trunc i64 " + rhs + " to i32"); rhs = conv;
                        } else if (info.theType == TypeInfo.Long && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                            String conv = newTemp();
                            addInstruction(conv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i64"); rhs = conv;
                        } else if ((info.theType == TypeInfo.Float || info.theType == TypeInfo.Double) && rhsType == TypeInfo.Long) {
                            String conv = newTemp();
                            addInstruction(conv + " = sitofp i64 " + rhs + " to " + llvmT); rhs = conv;
                        }
                        // 👆 👆 新增結束 👆 👆
                        // 隱式轉型：rhs 必須與 lhs 型別一致
                        else if (info.theType == TypeInfo.Float && (rhsType == TypeInfo.Int)) {
                            String conv = newTemp();
                            addInstruction(conv + " = sitofp i32 " + rhs + " to float");
                            rhs = conv;
                        } else if (info.theType == TypeInfo.Int && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                            String conv = newTemp();
                            addInstruction(conv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i32");
                            rhs = conv;
                        } else if (info.theType == TypeInfo.Double && rhsType == TypeInfo.Int) {
                            String conv = newTemp();
                            addInstruction(conv + " = sitofp i32 " + rhs + " to double");
                            rhs = conv;
                        } else if (info.theType == TypeInfo.Float && rhsType == TypeInfo.Double) {
                            String conv = newTemp();
                            addInstruction(conv + " = fptrunc double " + rhs + " to float");
                            rhs = conv;
                        } else if (info.theType == TypeInfo.Double && rhsType == TypeInfo.Float) {
                            String conv = newTemp();
                            addInstruction(conv + " = fpext float " + rhs + " to double");
                            rhs = conv;
                        }
                        
                        String result = newTemp();
                        String llvmOp;
                        boolean isFloat = (info.theType == TypeInfo.Float || info.theType == TypeInfo.Double);
                        switch (opText) {
                            case "+=": llvmOp = isFloat ? "fadd" : "add"; break;
                            case "-=": llvmOp = isFloat ? "fsub" : "sub"; break;
                            case "*=": llvmOp = isFloat ? "fmul" : "mul"; break;
                            case "/=": llvmOp = isFloat ? "fdiv" : (isUnsignedType(info.theType) ? "udiv" : "sdiv"); break;
                            case "%=": llvmOp = isUnsignedType(info.theType) ? "urem" : "srem"; break;
                            case "<<=": llvmOp = "shl"; break;
                            case ">>=": llvmOp = "ashr"; break;
                            case "&=":  llvmOp = "and"; break;
                            case "|=":  llvmOp = "or"; break;
                            case "^=":  llvmOp = "xor"; break;
                            default:   llvmOp = "add"; break;
                        }
                        addInstruction(result + " = " + llvmOp + " " + llvmT + " " + cur + ", " + rhs);
                        rhs = result;
                    }
                    addInstruction("store " + llvmT + " " + rhs + ", " + llvmT + "* " + info.tmp + ", align 8");
                    $type = info.theType;
                    $tmp = rhs;
                }
            
            // ✨ 補上屬性：賦值運算有副作用，強制視為非常數，停止向上折疊
            $isConst = false; 
            $constVal = 0;
        }
      }
    // ── ✨ 括號包住的變數賦值：(id) op= expr（例如 SWAP 巨集展開後的 (ti) = (tj)）──
    | '(' id=ID ')' op=('=' | '+=' | '-=' | '*=' | '/=' | '%=' | '<<=' | '>>=' | '&=' | '|=' | '^=') b=assignmentExpression
      {
        String name = $id.getText();
        Info info = symtab.get(name);
        if (info == null) info = globalSymtab.get(name);

        if (info == null) {
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier '" + name + "'.");
            $type = TypeInfo.Error; $tmp = "0"; $isConst = false; $constVal = 0;
        } else {
            String opText = $op.getText();
            String llvmT;
            if (info.structName != null && info.structName.contains("(")) {
                llvmT = info.structName;
            } else if (info.isPointer) {
                llvmT = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
            } else if (info.theType == TypeInfo.Struct && info.structName != null) {
                llvmT = "%struct." + info.structName;
            } else {
                llvmT = toLLVMType(info.theType);
            }

            String rhs = $b.tmp;
            TypeInfo rhsType = $b.type;

            if (opText.equals("=")) {
                // implicit type conversions (same logic as the plain ID = expr branch)
                if (info.theType == TypeInfo.Long && (rhsType == TypeInfo.Int || rhsType == TypeInfo.Boolean || rhsType == TypeInfo.Char)) {
                    String srcT = (rhsType == TypeInfo.Char) ? "i8" : (rhsType == TypeInfo.Boolean) ? "i1" : "i32";
                    String extOp = (rhsType == TypeInfo.Boolean) ? "zext" : "sext"; // ✨ Bug fix：bool→long 必須 zext
                    String conv = newTemp(); addInstruction(conv + " = " + extOp + " " + srcT + " " + rhs + " to i64"); rhs = conv;
                } else if (info.theType == TypeInfo.Int && rhsType == TypeInfo.Long) {
                    String conv = newTemp(); addInstruction(conv + " = trunc i64 " + rhs + " to i32"); rhs = conv;
                } else if (info.theType == TypeInfo.Long && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                    String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i64"); rhs = conv;
                } else if (info.theType == TypeInfo.Float && rhsType == TypeInfo.Long) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i64 " + rhs + " to float"); rhs = conv;
                } else if (info.theType == TypeInfo.Double && rhsType == TypeInfo.Long) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i64 " + rhs + " to double"); rhs = conv;
                } else if (info.theType == TypeInfo.Int && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                    String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i32"); rhs = conv;
                } else if ((info.theType == TypeInfo.Float || info.theType == TypeInfo.Double) && rhsType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to " + llvmT); rhs = conv;
                } else if (info.theType == TypeInfo.Float && rhsType == TypeInfo.Double) {
                    String conv = newTemp(); addInstruction(conv + " = fptrunc double " + rhs + " to float"); rhs = conv;
                } else if (info.theType == TypeInfo.Double && rhsType == TypeInfo.Float) {
                    String conv = newTemp(); addInstruction(conv + " = fpext float " + rhs + " to double"); rhs = conv;
                } else if (info.theType == TypeInfo.Int && rhsType == TypeInfo.Boolean) {
                    String conv = newTemp(); addInstruction(conv + " = zext i1 " + rhs + " to i32"); rhs = conv;
                } else if (info.theType == TypeInfo.Char && rhsType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = trunc i32 " + rhs + " to i8"); rhs = conv;
                } else if (info.theType == TypeInfo.Int && rhsType == TypeInfo.Char) {
                    String conv = newTemp(); addInstruction(conv + " = sext i8 " + rhs + " to i32"); rhs = conv;
                }
                if (info.isPointer && "0".equals(rhs)) rhs = "null";
                if (info.isPointer && (rhsType == TypeInfo.Pointer || rhs.equals("null"))) {
                    String destLLVM = (info.structName != null && info.structName.contains("("))
                        ? info.structName : toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
                    if (!rhs.equals("null")) {
                        String srcLLVM = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : destLLVM;
                        if (!srcLLVM.equals(destLLVM)) {
                            String casted = newTemp();
                            addInstruction(casted + " = bitcast " + srcLLVM + " " + rhs + " to " + destLLVM);
                            rhs = casted;
                        }
                    } else {
                        exactTypeMap.put("null", destLLVM);
                    }
                }
                addInstruction("store " + llvmT + " " + rhs + ", " + llvmT + "* " + info.tmp + ", align " + (info.theType == TypeInfo.Boolean ? "1" : "8"));
                $type = info.theType; $tmp = rhs;
            } else {
                // compound assignment op
                String cur = newTemp();
                addInstruction(cur + " = load " + llvmT + ", " + llvmT + "* " + info.tmp + ", align 8");
                if (info.theType == TypeInfo.Long && (rhsType == TypeInfo.Int || rhsType == TypeInfo.Boolean || rhsType == TypeInfo.Char)) {
                    String srcT = (rhsType == TypeInfo.Char) ? "i8" : (rhsType == TypeInfo.Boolean) ? "i1" : "i32";
                    String extOp = (rhsType == TypeInfo.Boolean) ? "zext" : "sext"; // ✨ Bug fix：bool→long 必須 zext
                    String conv = newTemp(); addInstruction(conv + " = " + extOp + " " + srcT + " " + rhs + " to i64"); rhs = conv;
                } else if (info.theType == TypeInfo.Int && rhsType == TypeInfo.Long) {
                    String conv = newTemp(); addInstruction(conv + " = trunc i64 " + rhs + " to i32"); rhs = conv;
                } else if ((info.theType == TypeInfo.Float || info.theType == TypeInfo.Double) && rhsType == TypeInfo.Long) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i64 " + rhs + " to " + llvmT); rhs = conv;
                } else if (info.theType == TypeInfo.Float && rhsType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to float"); rhs = conv;
                } else if (info.theType == TypeInfo.Int && (rhsType == TypeInfo.Float || rhsType == TypeInfo.Double)) {
                    String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(rhsType) + " " + rhs + " to i32"); rhs = conv;
                } else if (info.theType == TypeInfo.Double && rhsType == TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to double"); rhs = conv;
                } else if (info.theType == TypeInfo.Float && rhsType == TypeInfo.Double) {
                    String conv = newTemp(); addInstruction(conv + " = fptrunc double " + rhs + " to float"); rhs = conv;
                } else if (info.theType == TypeInfo.Double && rhsType == TypeInfo.Float) {
                    String conv = newTemp(); addInstruction(conv + " = fpext float " + rhs + " to double"); rhs = conv;
                }
                String result = newTemp();
                boolean isFloat = (info.theType == TypeInfo.Float || info.theType == TypeInfo.Double);
                String llvmOp;
                switch (opText) {
                    case "+=":  llvmOp = isFloat ? "fadd" : "add"; break;
                    case "-=":  llvmOp = isFloat ? "fsub" : "sub"; break;
                    case "*=":  llvmOp = isFloat ? "fmul" : "mul"; break;
                    case "/=":  llvmOp = isFloat ? "fdiv" : (isUnsignedType(info.theType) ? "udiv" : "sdiv"); break;
                    case "%=":  llvmOp = isUnsignedType(info.theType) ? "urem" : "srem"; break;
                    case "<<=": llvmOp = "shl"; break;
                    case ">>=": llvmOp = "ashr"; break;
                    case "&=":  llvmOp = "and"; break;
                    case "|=":  llvmOp = "or"; break;
                    case "^=":  llvmOp = "xor"; break;
                    default:    llvmOp = "add"; break;
                }
                addInstruction(result + " = " + llvmOp + " " + llvmT + " " + cur + ", " + rhs);
                rhs = result;
                addInstruction("store " + llvmT + " " + rhs + ", " + llvmT + "* " + info.tmp + ", align 8");
                $type = info.theType; $tmp = rhs;
            }
            $isConst = false; $constVal = 0;
        }
      }
    | a=ternaryExpression
      { 
        $type = $a.type; 
        $tmp = $a.tmp; 
        // ✨ 就是這裡漏了！補上這兩行，把底層的常數接上來！
        $isConst = $a.isConst; 
        $constVal = $a.constVal;
      }
    ;

// ── 三元運算子 cond ? trueExpr : falseExpr ──
ternaryExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : cond=logicalOrExpression
      { 
        $type = $cond.type;
        $tmp = $cond.tmp; 
        $isConst = $cond.isConst; $constVal = $cond.constVal; 
      }
      ( '?'
        { 
          pushBuffer(); 
          cseReset(); // ✨ 在「解析」true 區塊前清空記憶！
        }
        te=expression
        { List<String> trueIR = popBuffer(); }
        ':'
        { 
          pushBuffer(); 
          cseReset(); // ✨ 在「解析」false 區塊前清空記憶！
        }
        fe=expression
        { 
          List<String> falseIR = popBuffer(); 
          cseReset(); // ✨ 離開三元運算後清空記憶！
        }
        {
          // 決定結果型別：若有任一邊是 float，結果就是 float
          TypeInfo resultType = ($te.type == TypeInfo.Float || $te.type == TypeInfo.Double ||
                                 $fe.type == TypeInfo.Float || $fe.type == TypeInfo.Double)
                                ? TypeInfo.Float : $te.type;
          String llvmT = toLLVMType(resultType);

          // 建立暫存 alloca 存放結果
          String resultPtr = newTemp();
          addInstruction(resultPtr + " = alloca " + llvmT + ", align 4");

          // 產生條件分支標籤
          String trueLabel  = newLabel("Ltern_true");
          String falseLabel = newLabel("Ltern_false");
          String endLabel   = newLabel("Ltern_end");

          String condBool = coerceToBool($cond.type, $cond.tmp);
          addInstruction("br i1 " + condBool + ", label %" + trueLabel + ", label %" + falseLabel);
          
          // true branch
          addInstruction(trueLabel + ":");
          for (String instr : trueIR) addInstruction(instr);
          String trueTmp = $te.tmp;
          if (resultType == TypeInfo.Float && $te.type == TypeInfo.Int) {
              String conv = newTemp();
              addInstruction(conv + " = sitofp i32 " + trueTmp + " to float");
              trueTmp = conv;
          }
          addInstruction("store " + llvmT + " " + trueTmp + ", " + llvmT + "* " + resultPtr + ", align 4");
          addInstruction("br label %" + endLabel);

          // false branch
          addInstruction(falseLabel + ":");
          for (String instr : falseIR) addInstruction(instr);
          String falseTmp = $fe.tmp;
          if (resultType == TypeInfo.Float && $fe.type == TypeInfo.Int) {
              String conv = newTemp();
              addInstruction(conv + " = sitofp i32 " + falseTmp + " to float");
              falseTmp = conv;
          }
          addInstruction("store " + llvmT + " " + falseTmp + ", " + llvmT + "* " + resultPtr + ", align 4");
          addInstruction("br label %" + endLabel);

          // end：load 結果
          addInstruction(endLabel + ":");
          String loadResult = newTemp();
          addInstruction(loadResult + " = load " + llvmT + ", " + llvmT + "* " + resultPtr + ", align 4");
          
          $type = resultType; $tmp = loadResult;
          $isConst = false; $constVal = 0; // 發生分支，視為非常數
          cseReset(); // ✨ 補上這行：分支結束後清空 CSE 記憶
        }
      )?
    ;

logicalOrExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=logicalAndExpression {
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op='||'
        {
          cseReset(); // ✨ 在解析右邊的 b 之前清空記憶！
          String resSlot = newTemp();
          addInstruction(resSlot + " = alloca i1, align 1");
          String lhsBool = coerceToBool($type, $tmp);
          addInstruction("store i1 " + lhsBool + ", i1* " + resSlot + ", align 1");
          String rhsLabel = newLabel("Lor_rhs");
          String endLabel = newLabel("Lor_end");
          addInstruction("br i1 " + lhsBool + ", label %" + endLabel + ", label %" + rhsLabel);
          addInstruction(rhsLabel + ":");
        }
        b=logicalAndExpression
        {
          String rhsBool = coerceToBool($b.type, $b.tmp);
          addInstruction("store i1 " + rhsBool + ", i1* " + resSlot + ", align 1");
          addInstruction("br label %" + endLabel);
          addInstruction(endLabel + ":");
          String finalRes = newTemp();
          addInstruction(finalRes + " = load i1, i1* " + resSlot + ", align 1");
          
          $type = TypeInfo.Boolean; $tmp = finalRes;
          $isConst = false; $constVal = 0;
          cseReset(); // ✨ 補上這行：分支結束後清空 CSE 記憶
        }
      )*
    ;

logicalAndExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=bitwiseOrExpression { 
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op='&&'
        {
          cseReset(); // ✨ 在解析右邊的 b 之前清空記憶！
          String resSlot = newTemp();
          addInstruction(resSlot + " = alloca i1, align 1");
          String lhsBool = coerceToBool($type, $tmp);
          addInstruction("store i1 " + lhsBool + ", i1* " + resSlot + ", align 1");
          String rhsLabel = newLabel("Land_rhs");
          String endLabel = newLabel("Land_end");
          addInstruction("br i1 " + lhsBool + ", label %" + rhsLabel + ", label %" + endLabel);
          addInstruction(rhsLabel + ":");
        }
        b=bitwiseOrExpression
        {
          String rhsBool = coerceToBool($b.type, $b.tmp);
          addInstruction("store i1 " + rhsBool + ", i1* " + resSlot + ", align 1");
          addInstruction("br label %" + endLabel);
          addInstruction(endLabel + ":");
          String finalRes = newTemp();
          addInstruction(finalRes + " = load i1, i1* " + resSlot + ", align 1");
          
          $type = TypeInfo.Boolean; $tmp = finalRes;
          $isConst = false; $constVal = 0;
          cseReset(); // ✨ 補上這行：分支結束後清空 CSE 記憶
        }
      )*
    ;

bitwiseOrExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=bitwiseXorExpression { 
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op='|' b=bitwiseXorExpression
        {
          String result = newTemp();
          addInstruction(result + " = or i32 " + $tmp + ", " + $b.tmp);
          $type = TypeInfo.Int; $tmp = result;
          $isConst = false; $constVal = 0;
        }
      )*
    ;

bitwiseXorExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=bitwiseAndExpression { 
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op='^' b=bitwiseAndExpression
        {
          String result = newTemp();
          addInstruction(result + " = xor i32 " + $tmp + ", " + $b.tmp);
          $type = TypeInfo.Int; $tmp = result;
          $isConst = false; $constVal = 0;
          cseReset(); // ✨ 補上這行：運算結束後清空 CSE 記憶
        }
      )*
    ;

bitwiseAndExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=shiftExpression { 
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op='&' b=shiftExpression
        {
          String result = newTemp();
          addInstruction(result + " = and i32 " + $tmp + ", " + $b.tmp);
          $type = TypeInfo.Int; $tmp = result;
          $isConst = false; $constVal = 0;
        }
      )*
    ;

shiftExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=relationalExpression { 
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op=('<<' | '>>') b=relationalExpression
        {
          String result = newTemp();
          String llvmOp = $op.getText().equals("<<") ? "shl" : "ashr";
          addInstruction(result + " = " + llvmOp + " i32 " + $tmp + ", " + $b.tmp);
          $type = TypeInfo.Int; $tmp = result;
          $isConst = false; $constVal = 0;
          cseReset(); // ✨ 補上這行：運算結束後清空 CSE 記憶
        }
      )*
    ;

relationalExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=additiveExpression { 
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op=('<' | '>' | '<=' | '>=' | '==' | '!=') b=additiveExpression
        {
          String result = newTemp();
          String llvmOp = "";

          // ── 先做 integer promotion（Short/UnsignedShort/UnsignedChar → Int）──
          String lhs = $tmp; TypeInfo lhsT = $type;
          String rhs = $b.tmp; TypeInfo rhsT = $b.type;
          lhs = emitIntPromotion(lhsT, lhs); lhsT = integerPromote(lhsT);
          rhs = emitIntPromotion(rhsT, rhs); rhsT = integerPromote(rhsT);
          // Char promotion
          if (lhsT == TypeInfo.Char) { String c = newTemp(); addInstruction(c + " = sext i8 " + lhs + " to i32"); lhs = c; lhsT = TypeInfo.Int; }
          if (rhsT == TypeInfo.Char) { String c = newTemp(); addInstruction(c + " = sext i8 " + rhs + " to i32"); rhs = c; rhsT = TypeInfo.Int; }

          boolean isFloatCmp = (lhsT == TypeInfo.Float || lhsT == TypeInfo.Double ||
                                rhsT == TypeInfo.Float || rhsT == TypeInfo.Double);
          // ── usual arithmetic conversion → cmpType ──
          TypeInfo cmpTypeInfo = usualArithConvert(lhsT, rhsT);
          lhs = emitConvert(lhsT, lhs, cmpTypeInfo);
          rhs = emitConvert(rhsT, rhs, cmpTypeInfo);
          String cmpType = toLLVMType(cmpTypeInfo);
          boolean isUnsignedCmp = isUnsignedType(cmpTypeInfo);

          // --- 指標比較防護 ---
          boolean lhsIsPtr = ($type == TypeInfo.Pointer || charPtrTemps.contains(lhs));
          boolean rhsIsPtr = ($b.type == TypeInfo.Pointer || charPtrTemps.contains(rhs));
          if (lhsIsPtr || rhsIsPtr) {
              // 若其中一方是整數 0（NULL），用 null 做指標比較
              boolean rhsIsZero = "0".equals(rhs) || "null".equals(rhs);
              boolean lhsIsZero = "0".equals(lhs) || "null".equals(lhs);
              if (lhsIsPtr && rhsIsZero) {
                  String ptrLLVM = exactTypeMap.containsKey(lhs) ? exactTypeMap.get(lhs) : "i8*";
                  String cmpOp = ($op.getText().equals("==")) ? "icmp eq" : "icmp ne";
                  addInstruction(result + " = " + cmpOp + " " + ptrLLVM + " " + lhs + ", null");
                  $type = TypeInfo.Boolean; $tmp = result; $isConst = false; $constVal = 0;
              } else if (rhsIsPtr && lhsIsZero) {
                  String ptrLLVM = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : "i8*";
                  String cmpOp = ($op.getText().equals("==")) ? "icmp eq" : "icmp ne";
                  addInstruction(result + " = " + cmpOp + " " + ptrLLVM + " " + rhs + ", null");
                  $type = TypeInfo.Boolean; $tmp = result; $isConst = false; $constVal = 0;
              } else {
                  // 兩個指標互相比較：ptrtoint 到 i64
                  String convL = lhs; String convR = rhs;
                  if (lhsIsPtr) {
                      convL = newTemp();
                      String lhsPtrT = exactTypeMap.containsKey(lhs) ? exactTypeMap.get(lhs) : "i8*";
                      addInstruction(convL + " = ptrtoint " + lhsPtrT + " " + lhs + " to i64");
                  }
                  if (rhsIsPtr) {
                      convR = newTemp();
                      String rhsPtrT = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : "i8*";
                      addInstruction(convR + " = ptrtoint " + rhsPtrT + " " + rhs + " to i64");
                  }
                  String cmpOp = ($op.getText().equals("==")) ? "icmp eq" : "icmp ne";
                  addInstruction(result + " = " + cmpOp + " i64 " + convL + ", " + convR);
                  $type = TypeInfo.Boolean; $tmp = result; $isConst = false; $constVal = 0;
              }
          } else {
              switch ($op.getText()) {
                  case "<":  llvmOp = isFloatCmp ? "fcmp olt" : (isUnsignedCmp ? "icmp ult" : "icmp slt"); break;
                  case ">":  llvmOp = isFloatCmp ? "fcmp ogt" : (isUnsignedCmp ? "icmp ugt" : "icmp sgt"); break;
                  case "<=": llvmOp = isFloatCmp ? "fcmp ole" : (isUnsignedCmp ? "icmp ule" : "icmp sle"); break;
                  case ">=": llvmOp = isFloatCmp ? "fcmp oge" : (isUnsignedCmp ? "icmp uge" : "icmp sge"); break;
                  case "==": llvmOp = isFloatCmp ? "fcmp oeq" : "icmp eq";  break;
                  case "!=": llvmOp = isFloatCmp ? "fcmp one" : "icmp ne";  break;
                  default:   llvmOp = "icmp eq"; break;
              }
              // ✨ 常數折疊：兩邊都是常數時，直接計算結果，不生成 IR
              if ($a.isConst && $b.isConst) {
                  double lv = $a.constVal, rv = $b.constVal;
                  boolean cmpRes;
                  switch ($op.getText()) {
                      case "<":  cmpRes = lv <  rv; break;
                      case ">":  cmpRes = lv >  rv; break;
                      case "<=": cmpRes = lv <= rv; break;
                      case ">=": cmpRes = lv >= rv; break;
                      case "==": cmpRes = lv == rv; break;
                      case "!=": cmpRes = lv != rv; break;
                      default:   cmpRes = false;    break;
                  }
                  $type = TypeInfo.Boolean;
                  $tmp = cmpRes ? "1" : "0";
                  $isConst = true; $constVal = cmpRes ? 1.0 : 0.0;
              } else {
                  addInstruction(result + " = " + llvmOp + " " + cmpType + " " + lhs + ", " + rhs);
                  $type = TypeInfo.Boolean; $tmp = result;
                  $isConst = false; $constVal = 0;
              }
          }
        }
      )*
    ;

additiveExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=multiplicativeExpression
      {
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op=('+'|'-') b=multiplicativeExpression
        {
          // Implicit type promotion: if either operand is float, result is float
          String lhs = $tmp;
          String rhs = $b.tmp;
          boolean opIsAdd = $op.getText().equals("+");

          // ── 整數提升：char/short/unsignedChar/unsignedShort/bool 參與運算前先提升為 int ──
          if ($type == TypeInfo.Char || $type == TypeInfo.Short || $type == TypeInfo.UnsignedChar || $type == TypeInfo.UnsignedShort || $type == TypeInfo.Boolean) {
              lhs = emitIntPromotion($type, lhs); $type = TypeInfo.Int; $isConst = false;
          }
          TypeInfo rhsType2 = $b.type;
          if (rhsType2 == TypeInfo.Char || rhsType2 == TypeInfo.Short || rhsType2 == TypeInfo.UnsignedChar || rhsType2 == TypeInfo.UnsignedShort || rhsType2 == TypeInfo.Boolean) {
              rhs = emitIntPromotion(rhsType2, rhs); rhsType2 = TypeInfo.Int;
          }

          // ── 指標算術：Pointer + Int 或 Int + Pointer → getelementptr ──
          if (opIsAdd && ($type == TypeInfo.Pointer || rhsType2 == TypeInfo.Pointer)) {
              String ptrTmp; String offTmp;
              if ($type == TypeInfo.Pointer) {
                  ptrTmp = lhs; offTmp = rhs;
              } else {
                  ptrTmp = rhs; offTmp = lhs;
              }
              // ✨ 修正：優先從 exactTypeMap 取得 ptrTmp 的精確 LLVM 型別（e.g. i8*, i32*）
              // 再從型別字串中推算 pointee 的 LLVM 型別，避免因隨機掃 symtab 而拿到錯誤的 pointeeType
              String ptLLVM;
              if (exactTypeMap.containsKey(ptrTmp)) {
                  String fullPtrT = exactTypeMap.get(ptrTmp); // e.g. "i8*" or "i32*"
                  // 去掉最後一個 '*' 得到 pointee 型別字串
                  ptLLVM = fullPtrT.endsWith("*") ? fullPtrT.substring(0, fullPtrT.length() - 1) : fullPtrT;
              } else {
                  // 從 symtab 找與 ptrTmp 名稱相符的符號（確定性查找）
                  TypeInfo pointee = TypeInfo.Int;
                  for (java.util.Map.Entry<String, Info> entry : symtab.entrySet()) {
                      Info sv = entry.getValue();
                      if (sv.tmp != null && sv.tmp.equals(ptrTmp) && sv.isPointer && sv.pointeeType != null) {
                          pointee = sv.pointeeType; break;
                      }
                  }
                  // 若仍找不到，再從全域符號表找
                  if (pointee == TypeInfo.Int) {
                      for (java.util.Map.Entry<String, Info> entry : globalSymtab.entrySet()) {
                          Info sv = entry.getValue();
                          if (sv.tmp != null && sv.tmp.equals(ptrTmp) && sv.isPointer && sv.pointeeType != null) {
                              pointee = sv.pointeeType; break;
                          }
                      }
                  }
                  ptLLVM = toLLVMType(pointee);
              }
              String gepResult = newTemp();
              addInstruction(gepResult + " = getelementptr inbounds " + ptLLVM + ", " + ptLLVM + "* " + ptrTmp + ", i32 " + offTmp);
              $type = TypeInfo.Pointer; $tmp = gepResult;
              exactTypeMap.put(gepResult, ptLLVM + "*"); // 標記算術結果的真實型別
              $isConst = false; $constVal = 0;
          // ── 指標差：Pointer - Pointer → ptrdiff (位元組差 ÷ 元素大小) ──
          } else if (!opIsAdd && $type == TypeInfo.Pointer && rhsType2 == TypeInfo.Pointer) {
              String lhsPtrT = exactTypeMap.containsKey(lhs) ? exactTypeMap.get(lhs) : "i8*";
              String rhsPtrT = exactTypeMap.containsKey(rhs) ? exactTypeMap.get(rhs) : "i8*";
              String li = newTemp(); addInstruction(li + " = ptrtoint " + lhsPtrT + " " + lhs + " to i64");
              String ri = newTemp(); addInstruction(ri + " = ptrtoint " + rhsPtrT + " " + rhs + " to i64");
              String diff64 = newTemp(); addInstruction(diff64 + " = sub i64 " + li + ", " + ri);
              // 除以 pointee 元素大小，得到元素個數差
              String pointeeT = lhsPtrT.endsWith("*") ? lhsPtrT.substring(0, lhsPtrT.length()-1).trim() : "i8";
              int elemSize = 1;
              if (pointeeT.equals("i64") || pointeeT.equals("double")) elemSize = 8;
              else if (pointeeT.equals("i32") || pointeeT.equals("float")) elemSize = 4;
              else if (pointeeT.equals("i16")) elemSize = 2;
              String byteDiv;
              if (elemSize > 1) {
                  byteDiv = newTemp(); addInstruction(byteDiv + " = sdiv i64 " + diff64 + ", " + elemSize);
              } else { byteDiv = diff64; }
              String diff32 = newTemp(); addInstruction(diff32 + " = trunc i64 " + byteDiv + " to i32");
              $type = TypeInfo.Int; $tmp = diff32; $isConst = false; $constVal = 0;
          } else {
            TypeInfo resultType;
            if ($type == TypeInfo.Double || rhsType2 == TypeInfo.Double)
              resultType = TypeInfo.Double;
            else if ($type == TypeInfo.Float || rhsType2 == TypeInfo.Float)
              resultType = TypeInfo.Float;
            // ── Bug 2 修正：Long（i64）與 UnsignedLong 皆優先於 Int（i32）── 
            else if ($type == TypeInfo.Long || rhsType2 == TypeInfo.Long || $type == TypeInfo.UnsignedLong || rhsType2 == TypeInfo.UnsignedLong) 
                resultType = TypeInfo.Long;
            else
              resultType = TypeInfo.Int;

          // ── 常數折疊 (Constant Folding)：兩邊都是常數，直接在 Java 計算 ──
          if ($isConst && $b.isConst) {
              double cv = opIsAdd ? ($constVal + $b.constVal) : ($constVal - $b.constVal);
              if (resultType == TypeInfo.Int || resultType == TypeInfo.Long) {
                  $tmp = String.valueOf((long) cv);
              } else if (resultType == TypeInfo.Double) {
                  // Double 精度：直接用 double bits
                  long bits = Double.doubleToLongBits(cv);
                  $tmp = String.format("0x%016X", bits);
              } else {
                  // Float 精度：先截成 float 再取 double bits
                  float fv = (float) cv;
                  long bits = Double.doubleToLongBits((double) fv);
                  $tmp = String.format("0x%016X", bits);
              }
              $type = resultType;
              $isConst = true;
              $constVal = cv;
          } else {
              $isConst = false;
              String llvmTarget = toLLVMType(resultType);
              // Promote lhs
              if (resultType == TypeInfo.Double && $type == TypeInfo.Int) {
                  String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + lhs + " to double"); lhs = conv;
              } else if (resultType == TypeInfo.Double && $type == TypeInfo.Long) {
                  String conv = newTemp(); addInstruction(conv + " = sitofp i64 " + lhs + " to double"); lhs = conv;
              } else if (resultType == TypeInfo.Double && $type == TypeInfo.Float) {
                  String conv = newTemp(); addInstruction(conv + " = fpext float " + lhs + " to double"); lhs = conv;
              } else if (resultType == TypeInfo.Float && $type == TypeInfo.Int) {
                  String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + lhs + " to float"); lhs = conv;
              } else if (resultType == TypeInfo.Long && $type == TypeInfo.Int) {
                  String conv = newTemp(); addInstruction(conv + " = sext i32 " + lhs + " to i64"); lhs = conv;
              }
              // Promote rhs
              if (resultType == TypeInfo.Double && rhsType2 == TypeInfo.Int) {
                  String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to double"); rhs = conv;
              } else if (resultType == TypeInfo.Double && rhsType2 == TypeInfo.Long) {
                  String conv = newTemp(); addInstruction(conv + " = sitofp i64 " + rhs + " to double"); rhs = conv;
              } else if (resultType == TypeInfo.Double && rhsType2 == TypeInfo.Float) {
                  String conv = newTemp(); addInstruction(conv + " = fpext float " + rhs + " to double"); rhs = conv;
              } else if (resultType == TypeInfo.Float && rhsType2 == TypeInfo.Int) {
                  String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to float"); rhs = conv;
              } else if (resultType == TypeInfo.Long && rhsType2 == TypeInfo.Int) {
                  String conv = newTemp(); addInstruction(conv + " = sext i32 " + rhs + " to i64"); rhs = conv;
              }
              String result = newTemp();
              String llvmOp;
              if (resultType == TypeInfo.Int || resultType == TypeInfo.Long) llvmOp = opIsAdd ? "add" : "sub";
              else                                                           llvmOp = opIsAdd ? "fadd" : "fsub";
              String llvmType = llvmTarget;

              // ── 代數化簡：+0 / -0 ──
              if (rhs.equals("0") || rhs.equals("0.0")) {
                  $type = resultType; $tmp = lhs;
              } else {
                  // ── CSE：查表是否已算過相同運算 ──
                  String cseKey = cseLookup(llvmOp, llvmType, lhs, rhs);
                  if (cseKey != null) {
                      $type = resultType; $tmp = cseKey;
                  } else {
                      addInstruction(result + " = " + llvmOp + " " + llvmType + " " + lhs + ", " + rhs);
                      cseRegister(llvmOp, llvmType, lhs, rhs, result);
                      $type = resultType; $tmp = result;
                  }
              }
          } // end else (non-pointer arithmetic)
        }
        }
      )*
    ;

multiplicativeExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    : a=unaryExpression
      {
        $type = $a.type; $tmp = $a.tmp;
        $isConst = $a.isConst; $constVal = $a.constVal;
      }
      ( op=('*'|'/'|'%'|'##') b=unaryExpression
        {
          String result = newTemp();
          if ($op.getText().equals("##")) {
              $isConst = false;
              if ($type != TypeInfo.Float || $b.type != TypeInfo.Float) {
                  System.err.println("Error! " + $start.getLine() + ": '##' requires float operands.");
                  $type = TypeInfo.Error; $tmp = "0";
                } else {
                // ── 撤銷 fadd，改回呼叫你在 myRuntime.c 寫好的專屬函式！ ──
                    addInstruction(result + " = call float @my_hashhash(float " + $tmp + ", float " + $b.tmp + ")");
                    $type = TypeInfo.Float; $tmp = result;
                }
          } else if ($op.getText().equals("%")) {
              // ── 先做 integer promotion ──
              String lhsMod = $tmp; TypeInfo lhsModT = $type;
              String rhsMod = $b.tmp; TypeInfo rhsModT = $b.type;
              lhsMod = emitIntPromotion(lhsModT, lhsMod); lhsModT = integerPromote(lhsModT);
              rhsMod = emitIntPromotion(rhsModT, rhsMod); rhsModT = integerPromote(rhsModT);
              TypeInfo modResult = usualArithConvert(lhsModT, rhsModT);
              // 升型到共同型別
              if (modResult == TypeInfo.Long && lhsModT == TypeInfo.Int) {
                  String c = newTemp(); addInstruction(c + " = sext i32 " + lhsMod + " to i64"); lhsMod = c;
              }
              if (modResult == TypeInfo.Long && rhsModT == TypeInfo.Int) {
                  String c = newTemp(); addInstruction(c + " = sext i32 " + rhsMod + " to i64"); rhsMod = c;
              }
              if ($isConst && $b.isConst && (modResult == TypeInfo.Int || modResult == TypeInfo.Long)) {
                  long cv = (long)$constVal % (long)$b.constVal;
                  $tmp = String.valueOf(cv); $type = modResult;
                  $isConst = true; $constVal = cv;
              } else {
                  String llvmModT = toLLVMType(modResult);
                  String remOp = isUnsignedType(modResult) ? "urem" : "srem";
                  addInstruction(result + " = " + remOp + " " + llvmModT + " " + lhsMod + ", " + rhsMod);
                  $type = modResult; $tmp = result; $isConst = false;
              }
          } else {
              // ── Char integer promotion ──
              String lhsMul = $tmp; TypeInfo lhsTypeMul = $type;
              String rhsMul = $b.tmp; TypeInfo rhsTypeMul = $b.type;
              if (lhsTypeMul == TypeInfo.Char) { lhsMul = charPromote(lhsMul); lhsTypeMul = TypeInfo.Int; $isConst = false; }
              if (rhsTypeMul == TypeInfo.Char) { rhsMul = charPromote(rhsMul); rhsTypeMul = TypeInfo.Int; }
              // ✨ 修正：比較/邏輯運算結果（i1）參與 *、/ 運算前，先 zext 為 i32
              // （additiveExpression 的 +、- 已有對應處理，這裡補上 *、/ 缺漏的部分）
              if (lhsTypeMul == TypeInfo.Boolean) { lhsMul = emitIntPromotion(lhsTypeMul, lhsMul); lhsTypeMul = TypeInfo.Int; $isConst = false; }
              if (rhsTypeMul == TypeInfo.Boolean) { rhsMul = emitIntPromotion(rhsTypeMul, rhsMul); rhsTypeMul = TypeInfo.Int; }

              TypeInfo resultType;
              if (lhsTypeMul == TypeInfo.Double || rhsTypeMul == TypeInfo.Double)
                  resultType = TypeInfo.Double;
              else if (lhsTypeMul == TypeInfo.Float || rhsTypeMul == TypeInfo.Float)
                  resultType = TypeInfo.Float;
              // ── Bug 2 修正：Long（i64）與 UnsignedLong 皆優先於 Int（i32）── 
              else if (lhsTypeMul == TypeInfo.Long || rhsTypeMul == TypeInfo.Long || lhsTypeMul == TypeInfo.UnsignedLong || rhsTypeMul == TypeInfo.UnsignedLong) 
                    resultType = TypeInfo.Long;
              else
                  resultType = TypeInfo.Int;
              String lhs = lhsMul;
              String rhs = rhsMul;

              // ── 常數折疊 (*, /) ──
              if ($isConst && $b.isConst) {
                  double cv;
                  if ($op.getText().equals("*")) cv = $constVal * $b.constVal;
                  else                           cv = $constVal / $b.constVal;
                  if (resultType == TypeInfo.Int || resultType == TypeInfo.Long) {
                      $tmp = String.valueOf((long) cv);
                  } else if (resultType == TypeInfo.Double) {
                      long bits = Double.doubleToLongBits(cv);
                      $tmp = String.format("0x%016X", bits);
                  } else {
                      float fv = (float) cv;
                      long bits = Double.doubleToLongBits((double) fv);
                      $tmp = String.format("0x%016X", bits);
                  }
                  $type = resultType; $isConst = true; $constVal = cv;
              } else {
                  $isConst = false;
                  String llvmTarget = toLLVMType(resultType);
                  // Promote lhs
                  if (resultType == TypeInfo.Double && lhsTypeMul == TypeInfo.Int) {
                      String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + lhs + " to double"); lhs = conv;
                  } else if (resultType == TypeInfo.Double && lhsTypeMul == TypeInfo.Long) {
                      String conv = newTemp(); addInstruction(conv + " = sitofp i64 " + lhs + " to double"); lhs = conv;
                  } else if (resultType == TypeInfo.Double && lhsTypeMul == TypeInfo.Float) {
                      String conv = newTemp(); addInstruction(conv + " = fpext float " + lhs + " to double"); lhs = conv;
                  } else if (resultType == TypeInfo.Float && lhsTypeMul == TypeInfo.Int) {
                      String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + lhs + " to float"); lhs = conv;
                  } else if (resultType == TypeInfo.Long && lhsTypeMul == TypeInfo.Int) {
                      String conv = newTemp(); addInstruction(conv + " = sext i32 " + lhs + " to i64"); lhs = conv;
                  }
                  // Promote rhs
                  if (resultType == TypeInfo.Double && rhsTypeMul == TypeInfo.Int) {
                      String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to double"); rhs = conv;
                  } else if (resultType == TypeInfo.Double && rhsTypeMul == TypeInfo.Long) {
                      String conv = newTemp(); addInstruction(conv + " = sitofp i64 " + rhs + " to double"); rhs = conv;
                  } else if (resultType == TypeInfo.Double && rhsTypeMul == TypeInfo.Float) {
                      String conv = newTemp(); addInstruction(conv + " = fpext float " + rhs + " to double"); rhs = conv;
                  } else if (resultType == TypeInfo.Float && rhsTypeMul == TypeInfo.Int) {
                      String conv = newTemp(); addInstruction(conv + " = sitofp i32 " + rhs + " to float"); rhs = conv;
                  } else if (resultType == TypeInfo.Long && rhsTypeMul == TypeInfo.Int) {
                      String conv = newTemp(); addInstruction(conv + " = sext i32 " + rhs + " to i64"); rhs = conv;
                  }
                  String llvmOp = $op.getText().equals("*") ? "fmul" : "fdiv";
                  if (resultType == TypeInfo.Int || resultType == TypeInfo.Long) llvmOp = $op.getText().equals("*") ? "mul" : "sdiv";

                  // ── 代數化簡 *1, /1, *0 ──
                  if (rhs.equals("1") || rhs.equals("1.0")) {
                      $type = resultType; $tmp = lhs;
                  } else if ($op.getText().equals("*") && (rhs.equals("0") || rhs.equals("0.0") || lhs.equals("0") || lhs.equals("0.0"))) {
                      $type = resultType; $tmp = (resultType == TypeInfo.Int) ? "0" : "0.0";
                  } else {
                      String llvmTypeMul = llvmTarget;
                      
                    // ✨ Strength Reduction：乘除 2 的冪次轉換為位移指令（支援 i32 與 i64） ✨ 
                    boolean rhsIsConst = $b.isConst; 
                    int rhsConstInt = (int) $b.constVal;
                    boolean isIntOrLong = (resultType == TypeInfo.Int || resultType == TypeInfo.Long || resultType == TypeInfo.UnsignedInt || resultType == TypeInfo.UnsignedLong);

                    if (isIntOrLong && $op.getText().equals("*") && rhsIsConst && rhsConstInt > 0 && (rhsConstInt & (rhsConstInt - 1)) == 0) {
                        int shift = Integer.numberOfTrailingZeros(rhsConstInt);
                        addInstruction(result + " = shl " + llvmTypeMul + " " + lhs + ", " + shift);
                        $type = resultType; $tmp = result;
                    } else if (isIntOrLong && $op.getText().equals("/") && rhsIsConst && rhsConstInt > 0 && (rhsConstInt & (rhsConstInt - 1)) == 0) {
                        int shift = Integer.numberOfTrailingZeros(rhsConstInt);
                        if (resultType == TypeInfo.UnsignedLong || resultType == TypeInfo.UnsignedInt) {
                            // unsigned 除以 2^n 等價於 lshr（無符號右移），無需修正
                            addInstruction(result + " = lshr " + llvmTypeMul + " " + lhs + ", " + shift);
                            $type = resultType; $tmp = result;
                        } else if (shift == 0) {
                            // /1：直接等於原值，無需任何位移
                            $type = resultType; $tmp = lhs;
                        } else {
                            // signed 除以 2^n（n>=1）：C 語意是「向零取整」，
                            // 純 ashr 是「向負無窮取整」，兩者在被除數為負且不整除時不同。
                            // 標準修正公式（與 LLVM/GCC 對 sdiv-by-pow2 的展開一致）：
                            //   bias = lshr(ashr(x, bitwidth-1), bitwidth-shift)   // x<0 時為 2^shift-1，否則為 0
                            //   result = ashr(x + bias, shift)
                            int bitwidth = llvmTypeMul.equals("i64") ? 64 : 32;
                            String signTmp = newTemp();
                            addInstruction(signTmp + " = ashr " + llvmTypeMul + " " + lhs + ", " + (bitwidth - 1));
                            String biasTmp = newTemp();
                            addInstruction(biasTmp + " = lshr " + llvmTypeMul + " " + signTmp + ", " + (bitwidth - shift));
                            String adjTmp = newTemp();
                            addInstruction(adjTmp + " = add " + llvmTypeMul + " " + lhs + ", " + biasTmp);
                            addInstruction(result + " = ashr " + llvmTypeMul + " " + adjTmp + ", " + shift);
                            $type = resultType; $tmp = result;
                        }
                    } else {
                          // ── CSE：查表是否已算過相同運算 ──
                          String cseKeyMul = cseLookup(llvmOp, llvmTypeMul, lhs, rhs);
                          if (cseKeyMul != null) {
                              $type = resultType; $tmp = cseKeyMul;
                          } else {
                              addInstruction(result + " = " + llvmOp + " " + llvmTypeMul + " " + lhs + ", " + rhs);
                              cseRegister(llvmOp, llvmTypeMul, lhs, rhs, result);
                              $type = resultType; $tmp = result;
                          }
                      }
                  }
              }
          }
        }
      )*
    ;

unaryExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
    // ── sizeof(type) ── 智慧判斷（型別或變數） ──
    : 'sizeof' '(' ts=typeSpecifier ')'
      {
          $type = TypeInfo.Int;
          $isConst = true;
          int sz = sizeofType($ts.type, $ts.sname);
          
          if ($ts.type != null) {
              if ($ts.type == TypeInfo.Error && $ts.sname != null) {
                  // 說明它不是型別，其實是個變數！
                  Info info = symtab.get($ts.sname);
                  if (info == null) info = globalSymtab.get($ts.sname);
                  
                  if (info != null) {
                      sz = sizeofType(info.theType, info.structName);
                  } else {
                      System.err.println("Error! Unknown variable or type '" + $ts.sname + "'.");
                  }
              } else {
                  // 正常的型別
                  if ($ts.type == TypeInfo.Double) sz = 8;
                  else if ($ts.type == TypeInfo.Char) sz = 1;
              }
          }
          $tmp = String.valueOf(sz);
          $constVal = sz;
      }
 // ── 取址運算子：&x 或 &arr[idx] ──
    | '&' id=ID ('[' idx=expression ']')?
      {
        $isConst = false; $constVal = 0;
        Info info = symtab.get($id.getText());
        if (info == null) info = globalSymtab.get($id.getText());
        if (info == null) {
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier '" + $id.getText() + "'.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            if ($idx.ctx == null) {
                // info.tmp 就是 alloca 位址，直接回傳
                $type = TypeInfo.Pointer;
                $tmp = info.tmp;
                lastAddrOfPointee = info.theType;
                lastAddrOfTmp = info.tmp;
                String addrLLVMType = info.isPointer
                    ? toLLVMPtrType(info.baseType, info.structName, info.ptrDepth + 1)
                    : toLLVMPtrType(info.theType, info.structName);
                exactTypeMap.put(info.tmp, addrLLVMType);
            } else {
                String llvmT = toLLVMType(info.theType);
                String elemPtr = newTemp();
                if (info.arraySize > 0) {
                    // ✨ &arr[idx] 邊界檢查
                    emitBoundsCheck($id.getLine(), $id.getText(), $idx.tmp, $idx.isConst, (int)$idx.constVal, info.arraySize);
                    String arrType = "[" + info.arraySize + " x " + llvmT + "]";
                    addInstruction(elemPtr + " = getelementptr inbounds " + arrType + ", " + arrType + "* " + info.tmp + ", i32 0, i32 " + $idx.tmp);
                } else if (info.arraySize == -2) {
                    // ── VLA：直接 GEP，不需要 load ──
                    addInstruction(elemPtr + " = getelementptr inbounds " + llvmT + ", " + llvmT + "* " + info.tmp + ", i32 " + $idx.tmp);
               } else if (info.isPointer || info.arraySize == -1) {
                    // ✨ 修正：多層指標陣列取址
                    TypeInfo actualElemType = (info.ptrDepth > 1) ? TypeInfo.Pointer : info.baseType;
                    llvmT = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth > 0 ? info.ptrDepth - 1 : 0);
                    String ptrLLVMType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
                    
                    String loadedPtr = newTemp();
                    addInstruction(loadedPtr + " = load " + ptrLLVMType + ", " + ptrLLVMType + "* " + info.tmp + ", align 8");
                    addInstruction(elemPtr + " = getelementptr inbounds " + llvmT + ", " + ptrLLVMType + " " + loadedPtr + ", i32 " + $idx.tmp);
                } else {
                    addInstruction(elemPtr + " = getelementptr inbounds " + llvmT + ", " + llvmT + "* " + info.tmp + ", i32 " + $idx.tmp);
                }
                $type = TypeInfo.Pointer;
                $tmp = elemPtr;
                lastAddrOfPointee = (info.isPointer && info.pointeeType != null) ? info.pointeeType : info.theType;
                lastAddrOfTmp = elemPtr;
                exactTypeMap.put(elemPtr, toLLVMPtrType(lastAddrOfPointee)); // ✨ 註冊精準型別
            }
        }
      }
   // ── 解參考讀取：*p 或 **p ──
    | s1='*' s2='*'? id=ID
      {
        int derefs = ($s2 != null) ? 2 : 1; // ✨ 判斷是解一次還是解兩次
        Info info = symtab.get($id.getText());
        if (info == null) info = globalSymtab.get($id.getText());
        
        if (info == null || !info.isPointer || info.ptrDepth < derefs) {
            System.err.println("Error! " + $id.getLine() + ": Invalid dereference on '" + $id.getText() + "'.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            String ptrLLVM = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
            String pVal = newTemp();
            addInstruction(pVal + " = load " + ptrLLVM + ", " + ptrLLVM + "* " + info.tmp + ", align 8");
            
            String currentVal = pVal;
            String currentType = ptrLLVM;
            
            // ✨ 利用迴圈，要解幾層就 load 幾次
            for (int i = 0; i < derefs; i++) {
                String nextType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth - 1 - i);
                String result = newTemp();
                int align = (info.ptrDepth - 1 - i > 0 || info.baseType == TypeInfo.Double) ? 8 : 4;
                addInstruction(result + " = load " + nextType + ", " + currentType + " " + currentVal + ", align " + align);
                currentVal = result;
                currentType = nextType;
            }
            
            $type = (info.ptrDepth - derefs > 0) ? TypeInfo.Pointer : info.baseType;
            $tmp = currentVal;
            if ($type == TypeInfo.Pointer) exactTypeMap.put(currentVal, currentType);
        }
      }
   // ── 解參考讀取：*(expr) → expr 是指標（GEP 結果），直接 load 其指向的值 ──
    | '*' '(' e=expression ')'
      {
        $isConst = false; $constVal = 0;
        if ($e.type != TypeInfo.Pointer) {
            System.err.println("Error! line " + $start.getLine() + ": expression in *(...) is not a pointer.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            // ✨ 修正：移除暴力的 symtab 迴圈，改用精準型態表 (exactTypeMap) 避免雙重指標崩潰 ✨
            String currentLLVMType = exactTypeMap.containsKey($e.tmp) ? exactTypeMap.get($e.tmp) : "i32*";
            String targetType = "i32"; // 預設值
            
            // 如果來源是 i32**，解引用後應該是 i32*
            if (currentLLVMType.endsWith("**")) {
                targetType = currentLLVMType.substring(0, currentLLVMType.length() - 1);
                $type = TypeInfo.Pointer;
            } 
            // 如果來源是 i32*，解引用後應該是 i32
            else if (currentLLVMType.endsWith("*")) {
                targetType = currentLLVMType.substring(0, currentLLVMType.length() - 1);
                // ✨ 根據 targetType 推斷正確的 TypeInfo ──
                if (targetType.equals("i32"))         $type = TypeInfo.Int;
                else if (targetType.equals("i64"))    $type = TypeInfo.Long;
                else if (targetType.equals("float"))  $type = TypeInfo.Float;
                else if (targetType.equals("double")) $type = TypeInfo.Double;
                else if (targetType.equals("i8"))     $type = TypeInfo.Char;
                else if (targetType.equals("i16"))    $type = TypeInfo.Short;
                else                                  $type = TypeInfo.Int; 
            }
            
            String val = newTemp();
            
            // ✨✨✨ 核心修正：如果 currentLLVMType 已經是 i32**，就不要再幫他加星星了！ ✨✨✨
            // 把原本的 `+ currentLLVMType + " "` 改成 `+ currentLLVMType + " "`，因為原本的寫法會變成 `load i32, i32* %t29`，但 `%t29` 其實是 `i32**`。
            addInstruction(val + " = load " + targetType + ", " + currentLLVMType + " " + $e.tmp + ", align 8");
            
            // 存入精準型態表供下一層的運算或指派使用（只有結果仍是指標才登記）
            if ($type == TypeInfo.Pointer) exactTypeMap.put(val, targetType);
            
            $tmp = val;
        }
      }
    // ── sizeof(expr) ── 根據型別決定大小 ──
    | 'sizeof' '(' ex=expression ')'
      {
        int sz = sizeofType($ex.type, null);
        $type = TypeInfo.Int; $tmp = String.valueOf(sz);
        $isConst = true; $constVal = sz;
      }
    // ── ✨ _Alignof(type) / __alignof__(type) ── 回傳對齊需求（compile-time constant）──
    | ('_Alignof'|'__alignof__') '(' ts=typeSpecifier ')'
      {
        int al = alignOf($ts.type);
        $type = TypeInfo.Int; $tmp = String.valueOf(al);
        $isConst = true; $constVal = al;
      }
    // ── ✨ _Alignof(expr) ──
    | ('_Alignof'|'__alignof__') '(' ex2=expression ')'
      {
        int al2 = alignOf($ex2.type);
        $type = TypeInfo.Int; $tmp = String.valueOf(al2);
        $isConst = true; $constVal = al2;
      }
    // ── 顯式型別轉換 (int)expr / (struct Node *)expr ──
    |
    { isCast() }? '(' ts=typeSpecifier star='*'? ')' ue=unaryExpression
      {
        $isConst = false; $constVal = 0;

        if ($ts.type == TypeInfo.Void && $star == null) {
            //System.err.println("Error! Cannot cast to void.");
            // C 語言允許 (void) 轉型來明確忽略運算式的結果 (例如 (void)0)
            $type = TypeInfo.Void; 
            $tmp = "0";

        } else if ($ue.type == TypeInfo.Error) {
            $type = TypeInfo.Error; $tmp = "0";

        } else if ($star != null) {
            // ✨ 魔王功能 1：指標強制轉型 (e.g., (int *)malloc(...)) ✨
            String targetType = ($ts.type == TypeInfo.Struct && $ts.sname != null) 
                                ? "%struct." + $ts.sname + "*" 
                                : toLLVMType($ts.type) + "*";
                                
            // 攔截 (void*) 強制轉型，轉為 i8*
            if (targetType.equals("void*")) targetType = "i8*";
            String result = newTemp();
            
            if ($ue.type == TypeInfo.Int) {
                addInstruction(result + " = inttoptr i32 " + $ue.tmp + " to " + targetType);
            } else {
                // 核心修正 3：動態查出 ue 的真實型別，不要硬塞 i8*
                String srcType = exactTypeMap.containsKey($ue.tmp) 
                                 ? exactTypeMap.get($ue.tmp) 
                                 : (($ue.type == TypeInfo.Pointer) ? "i8*" : toLLVMType($ue.type));
                                 
                if (!srcType.equals(targetType)) {
                    addInstruction(result + " = bitcast " + srcType + " " + $ue.tmp + " to " + targetType);
                } else {
                    result = $ue.tmp; // 型別一樣就不必轉，避免 LLVM 報錯
                }
            }
            
            $type = TypeInfo.Pointer; 
            $tmp = result;
            exactTypeMap.put(result, targetType); // ✨ 記進小本本，讓後面的邏輯認得它

        } else if ($ts.type == $ue.type) {
            $type = $ts.type; $tmp = $ue.tmp; // 相同型別：no-op

        } else if ($ts.type == TypeInfo.Int && ($ue.type == TypeInfo.Float || $ue.type == TypeInfo.Double)) {
            String result = newTemp();
            addInstruction(result + " = fptosi " + toLLVMType($ue.type) + " " + $ue.tmp + " to i32");
            $type = TypeInfo.Int; $tmp = result;
        // ── Int/UnsignedInt ↔ Float/Double ──
        } else if (($ts.type == TypeInfo.Float || $ts.type == TypeInfo.Double)
                && isIntegerType($ue.type)) {
            // 👈 用 emitConvert，它內部已正確用 uitofp vs sitofp
            String result = emitConvert($ue.type, $ue.tmp, $ts.type);
            $type = $ts.type; $tmp = result;

        } else if (isIntegerType($ts.type)
                && ($ue.type == TypeInfo.Float || $ue.type == TypeInfo.Double)) {
            // 👈 用 emitConvert，它內部已正確用 fptoui vs fptosi
            String result = emitConvert($ue.type, $ue.tmp, $ts.type);
            $type = $ts.type; $tmp = result;
            
        } else if (($ts.type == TypeInfo.Float || $ts.type == TypeInfo.Double) && $ue.type == TypeInfo.Int) {
            String result = newTemp();
            addInstruction(result + " = sitofp i32 " + $ue.tmp + " to " + toLLVMType($ts.type));
            $type = $ts.type; $tmp = result;

        } else if ($ts.type == TypeInfo.Int && $ue.type == TypeInfo.Char) {
            String result = newTemp();
            addInstruction(result + " = sext i8 " + $ue.tmp + " to i32");
            $type = TypeInfo.Int; $tmp = result;

        } else if ($ts.type == TypeInfo.Int && $ue.type == TypeInfo.UnsignedChar) {
            String result = newTemp();
            addInstruction(result + " = zext i8 " + $ue.tmp + " to i32");
            $type = TypeInfo.Int; $tmp = result;

        } else if ($ts.type == TypeInfo.Long && $ue.type == TypeInfo.Char) {
            String result = newTemp();
            addInstruction(result + " = sext i8 " + $ue.tmp + " to i64");
            $type = TypeInfo.Long; $tmp = result;

        } else if ($ts.type == TypeInfo.Long && $ue.type == TypeInfo.UnsignedChar) {
            String result = newTemp();
            addInstruction(result + " = zext i8 " + $ue.tmp + " to i64");
            $type = TypeInfo.Long; $tmp = result;

        } else if ($ts.type == TypeInfo.UnsignedChar && $ue.type == TypeInfo.Int) {
            String result = newTemp();
            addInstruction(result + " = trunc i32 " + $ue.tmp + " to i8");
            $type = TypeInfo.UnsignedChar; $tmp = result;

        } else if ($ts.type == TypeInfo.Char && $ue.type == TypeInfo.Int) {
            String result = newTemp();
            addInstruction(result + " = trunc i32 " + $ue.tmp + " to i8");
            $type = TypeInfo.Char; $tmp = result;

        // ✨ Short ↔ Int 互轉（bitcast 不合法，需要 sext/trunc）
        } else if ($ts.type == TypeInfo.Int && ($ue.type == TypeInfo.Short || $ue.type == TypeInfo.UnsignedShort)) {
            String result = newTemp();
            addInstruction(result + " = sext i16 " + $ue.tmp + " to i32");
            $type = TypeInfo.Int; $tmp = result;

        } else if (($ts.type == TypeInfo.Short || $ts.type == TypeInfo.UnsignedShort) && $ue.type == TypeInfo.Int) {
            String result = newTemp();
            addInstruction(result + " = trunc i32 " + $ue.tmp + " to i16");
            $type = $ts.type; $tmp = result;

        } else if ($ts.type == TypeInfo.Long && ($ue.type == TypeInfo.Short || $ue.type == TypeInfo.UnsignedShort)) {
            String result = newTemp();
            addInstruction(result + " = sext i16 " + $ue.tmp + " to i64");
            $type = TypeInfo.Long; $tmp = result;

        } else if (($ts.type == TypeInfo.Short || $ts.type == TypeInfo.UnsignedShort) && $ue.type == TypeInfo.Char) {
            String result = newTemp();
            addInstruction(result + " = sext i8 " + $ue.tmp + " to i16");
            $type = $ts.type; $tmp = result;

        } else if ($ts.type == TypeInfo.Double && $ue.type == TypeInfo.Float) {
            String result = newTemp();
            // Float → Double（提升）
            addInstruction(result + " = fpext float " + $ue.tmp + " to double");
            $type = TypeInfo.Double; $tmp = result;

        } else if ($ts.type == TypeInfo.Float && $ue.type == TypeInfo.Double) {
            String result = newTemp();
            addInstruction(result + " = fptrunc double " + $ue.tmp + " to float");
            $type = TypeInfo.Float; $tmp = result;

        } else if (($ts.type == TypeInfo.Float || $ts.type == TypeInfo.Double) && $ue.type == TypeInfo.Char) {
            String result1 = newTemp();
            addInstruction(result1 + " = sext i8 " + $ue.tmp + " to i32");
            String result2 = newTemp();
            addInstruction(result2 + " = sitofp i32 " + result1 + " to " + toLLVMType($ts.type));
            $type = $ts.type; $tmp = result2;

        } else if ($ts.type == TypeInfo.Char && ($ue.type == TypeInfo.Float || $ue.type == TypeInfo.Double)) {
            String result1 = newTemp();
            addInstruction(result1 + " = fptosi " + toLLVMType($ue.type) + " " + $ue.tmp + " to i32");
            String result2 = newTemp();
            addInstruction(result2 + " = trunc i32 " + result1 + " to i8");
            $type = TypeInfo.Char; $tmp = result2;
            
        // 👇 ✨ 修正：指標強制轉整數 (ptrtoint) 支援未宣告型別 (如 intptr_t 被解析為 Error) ✨ 👇
        } else if (($ts.type == TypeInfo.Int || $ts.type == TypeInfo.Error) && $ue.type == TypeInfo.Pointer) {
            String srcT = exactTypeMap.containsKey($ue.tmp) ? exactTypeMap.get($ue.tmp) : "i8*";
            String result = newTemp();
            addInstruction(result + " = ptrtoint " + srcT + " " + $ue.tmp + " to i32");
            $type = $ts.type; $tmp = result;

        } else if (($ts.type == TypeInfo.Long || $ts.type == TypeInfo.UnsignedLong) && $ue.type == TypeInfo.Pointer) {
            // ── (long)ptr：指標轉 i64，用 ptrtoint ──
            String srcT = exactTypeMap.containsKey($ue.tmp) ? exactTypeMap.get($ue.tmp) : "i8*";
            String result = newTemp();
            addInstruction(result + " = ptrtoint " + srcT + " " + $ue.tmp + " to i64");
            $type = $ts.type; $tmp = result;

        } else if ($ts.type == TypeInfo.Long && $ue.type == TypeInfo.Int) {
            // ── (long)int：sext i32 → i64 ──
            String result = newTemp();
            addInstruction(result + " = sext i32 " + $ue.tmp + " to i64");
            $type = TypeInfo.Long; $tmp = result;
            
        // 👇 ✨ 修正：整數強制轉指標 (inttoptr) 支援從 Error 轉回指標 ✨ 👇
        } else if ($ts.type == TypeInfo.Pointer && ($ue.type == TypeInfo.Int || $ue.type == TypeInfo.Error)) {
            String tgtT = toLLVMType($ts.type);
            if ($ts.type == TypeInfo.Struct && $ts.sname != null) tgtT = "%struct." + $ts.sname + "*";
            String result = newTemp();
            addInstruction(result + " = inttoptr i32 " + $ue.tmp + " to " + tgtT);
            $type = TypeInfo.Pointer;
            $tmp = result;
        // 👇 ✨ 修正：其他的指標互轉，必須產生 bitcast，不能只是 no-op ✨ 👇
        } else {
            String srcT = exactTypeMap.containsKey($ue.tmp) ? exactTypeMap.get($ue.tmp) : toLLVMType($ue.type);
            String tgtT = toLLVMType($ts.type);
            if ($ts.type == TypeInfo.Struct && $ts.sname != null) tgtT = "%struct." + $ts.sname + "*";
            
            if (!srcT.equals(tgtT)) {
                String result = newTemp();
                addInstruction(result + " = bitcast " + srcT + " " + $ue.tmp + " to " + tgtT);
                $type = $ts.type; $tmp = result;
            } else {
                // 型別真的完全相同，才做 no-op
                $type = $ts.type; $tmp = $ue.tmp;
            }
        }
      }
    | op=('++' | '--') id=ID
      {
        $isConst = false; $constVal = 0;
        Info info = symtab.get($id.getText());
        if (info == null) {
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier " + $id.getText() + ".");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            String llvmT = toLLVMType(info.theType);
            String loaded = newTemp();
            addInstruction(loaded + " = load " + llvmT + ", " + llvmT + "* " + info.tmp + ", align 4");
            String updated = newTemp();
            boolean isFloat = (info.theType == TypeInfo.Float || info.theType == TypeInfo.Double);
            String llvmOp = $op.getText().equals("++")
                ? (isFloat ? "fadd" : "add")
                : (isFloat ? "fsub" : "sub");
            String one = isFloat ? "1.0" : "1";
            addInstruction(updated + " = " + llvmOp + " " + llvmT + " " + loaded + ", " + one);
            addInstruction("store " + llvmT + " " + updated + ", " + llvmT + "* " + info.tmp + ", align 4");
            $type = info.theType;
            $tmp = updated;
        }
      }
    | op=('+' | '-' | '!' | '~') ue=unaryExpression
      {
        $isConst = false; $constVal = 0;
        String o = $op.getText();
        if (o.equals("~")) {
            String result = newTemp();
            addInstruction(result + " = xor i32 " + $ue.tmp + ", -1");
            $type = TypeInfo.Int;
            $tmp = result;
        }
        else if (o.equals("!")) {
            // ── 新增：確保先將運算元轉為布林值 (i1) ──
            String boolTmp = coerceToBool($ue.type, $ue.tmp);
            String result = newTemp();
            addInstruction(result + " = xor i1 " + boolTmp + ", true");
            $type = TypeInfo.Boolean;
            $tmp = result;
        }
        else if (o.equals("-")) {
            if ($ue.isConst) {
                $isConst = true;
                if ($ue.type == TypeInfo.Int) {
                    int cv = -(int)$ue.constVal;
                    $constVal = cv; $tmp = String.valueOf(cv);
                } else if ($ue.type == TypeInfo.Long) {
                    // ── Long 常數折疊：用 long 精度，直接從字串解析避開 double 精度損失 ──
                    long cv = -Long.parseLong($ue.tmp);
                    $constVal = (double)cv;
                    $tmp = String.valueOf(cv);
                } else if ($ue.type == TypeInfo.Double) {
                    double cv = -$ue.constVal;
                    long bits = Double.doubleToLongBits(cv);
                    $constVal = cv; $tmp = String.format("0x%016X", bits);
                } else {
                    float fv = -(float)$ue.constVal;
                    long bits = Double.doubleToLongBits((double)fv);
                    $constVal = fv; $tmp = String.format("0x%016X", bits);
                }
                $type = $ue.type;
            } else {
                String result = newTemp();
                String llvmType = toLLVMType($ue.type);
                String llvmOp = ($ue.type == TypeInfo.Float || $ue.type == TypeInfo.Double) ? "fsub" : "sub";
                String zero = ($ue.type == TypeInfo.Float || $ue.type == TypeInfo.Double) ? "0.0" : "0";
                addInstruction(result + " = " + llvmOp + " " + llvmType + " " + zero + ", " + $ue.tmp);
                $type = $ue.type;
                $tmp = result;
            }
        }
        else { 
            $type = $ue.type; $tmp = $ue.tmp;
            $isConst = $ue.isConst; $constVal = $ue.constVal;
        }
      }
    | p=primaryExpression
      {
        $type = $p.type; $tmp = $p.tmp;
        $isConst = $p.isConst; $constVal = $p.constVal;
      }
    ;
    
primaryExpression returns [TypeInfo type, String tmp, boolean isConst, double constVal]
: id=ID '(' callArgs? ')'
      {
        $isConst = false; $constVal = 0;
        String fname = $id.getText();
        List<Info> givenArgs = ($callArgs.ctx != null) ? $callArgs.argList : new ArrayList<>();


        // ── helper：取 i8* 引數（char 陣列）──
        // ── helper：取數值引數並升為 double ──

        if (fname.equals("getchar")) {
            if (!givenArgs.isEmpty()) System.err.println("Error! " + $id.getLine() + ": getchar() takes no arguments.");
            String r = newTemp(); addInstruction(r + " = call i32 @getchar()");
            $type = TypeInfo.Int; $tmp = r;

        } else if (fname.equals("putchar")) {
            if (givenArgs.size() != 1) { System.err.println("Error! " + $id.getLine() + ": putchar() takes 1 argument."); $type = TypeInfo.Int; $tmp = "0"; }
            else {
                String a = givenArgs.get(0).tmp;
                if (givenArgs.get(0).theType == TypeInfo.Char) { String c = newTemp(); addInstruction(c + " = sext i8 " + a + " to i32"); a = c; }
                String r = newTemp(); addInstruction(r + " = call i32 @putchar(i32 " + a + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        } else if (fname.equals("strlen")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": strlen() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String arg = givenArgs.get(0).tmp;
                // ✨ 修正：如果 charPtrTemps 有，或者小本本裡記它是 "i8*"，都算通過！
                boolean isCharPt = charPtrTemps.contains(arg) || "i8*".equals(exactTypeMap.get(arg));
                
                if (!isCharPt) {
                    System.err.println("Error! " + $id.getLine() + ": strlen() requires a char array or pointer argument.");
                    $type = TypeInfo.Int; $tmp = "0";
                } else {
                    String r64 = newTemp(); addInstruction(r64 + " = call i64 @strlen(i8* " + arg + ")");
                    String r = newTemp(); addInstruction(r + " = trunc i64 " + r64 + " to i32");
                    $type = TypeInfo.Int; $tmp = r;
                }
            }
        } else if (fname.equals("strcpy")) {
            if (givenArgs.size() != 2) { 
                System.err.println("Error! " + $id.getLine() + ": strcpy() takes 2 arguments."); 
                $type = TypeInfo.Char; $tmp = "0"; 
            } else {
                String dst = givenArgs.get(0).tmp; String src = givenArgs.get(1).tmp;
                // （可自由選擇是否對 strcpy 的參數做強型別檢查，原理同下方的 strcat）
                
                String r = newTemp(); addInstruction(r + " = call i8* @strcpy(i8* " + dst + ", i8* " + src + ")");
                exactTypeMap.put(r, "i8*"); 
                $type = TypeInfo.Pointer;   // ✨ 修正為 Pointer
                $tmp = r;
            }
        } else if (fname.equals("strcat")) {
            if (givenArgs.size() != 2) { 
                System.err.println("Error! " + $id.getLine() + ": strcat() takes 2 arguments."); 
                $type = TypeInfo.Char; $tmp = "0"; 
            } else {
                String dst = givenArgs.get(0).tmp; String src = givenArgs.get(1).tmp;
                
                // ✨ 修正：檢查 dst 與 src 是否為合法的 char 指標/陣列
                boolean dstValid = charPtrTemps.contains(dst) || "i8*".equals(exactTypeMap.get(dst));
                boolean srcValid = charPtrTemps.contains(src) || "i8*".equals(exactTypeMap.get(src));
                
                if (!dstValid || !srcValid) {
                    System.err.println("Error! " + $id.getLine() + ": strcat() requires char array or pointer arguments.");
                }
                
                String r = newTemp(); addInstruction(r + " = call i8* @strcat(i8* " + dst + ", i8* " + src + ")");
                exactTypeMap.put(r, "i8*"); 
                $type = TypeInfo.Pointer;   // ✨ 修正為 Pointer
                $tmp = r;
            }
        } else if (fname.equals("strcmp")) {
            if (givenArgs.size() != 2) { 
                System.err.println("Error! " + $id.getLine() + ": strcmp() takes 2 arguments."); 
                $type = TypeInfo.Int; $tmp = "0"; 
            } else {
                String s1 = givenArgs.get(0).tmp; String s2 = givenArgs.get(1).tmp;
                boolean s1Valid = charPtrTemps.contains(s1) || "i8*".equals(exactTypeMap.get(s1));
                boolean s2Valid = charPtrTemps.contains(s2) || "i8*".equals(exactTypeMap.get(s2));
                if (!s1Valid || !s2Valid) {
                    System.err.println("Error! " + $id.getLine() + ": strcmp() requires char array or pointer arguments.");
                }
                String r = newTemp(); addInstruction(r + " = call i32 @strcmp(i8* " + s1 + ", i8* " + s2 + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── strncpy(dst, src, n) → i8* ──
        } else if (fname.equals("strncpy")) {
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": strncpy() takes 3 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String dst = givenArgs.get(0).tmp;
                String src = givenArgs.get(1).tmp;
                String nTmp = givenArgs.get(2).tmp;
                TypeInfo nType = givenArgs.get(2).theType;
                if (nType == TypeInfo.Int) { String c = newTemp(); addInstruction(c + " = sext i32 " + nTmp + " to i64"); nTmp = c; }
                String r = newTemp(); addInstruction(r + " = call i8* @strncpy(i8* " + dst + ", i8* " + src + ", i64 " + nTmp + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }
        // ── strncat(dst, src, n) → i8* ──
        } else if (fname.equals("strncat")) {
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": strncat() takes 3 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String dst = givenArgs.get(0).tmp;
                String src = givenArgs.get(1).tmp;
                String nTmp = givenArgs.get(2).tmp;
                TypeInfo nType = givenArgs.get(2).theType;
                if (nType == TypeInfo.Int) { String c = newTemp(); addInstruction(c + " = sext i32 " + nTmp + " to i64"); nTmp = c; }
                String r = newTemp(); addInstruction(r + " = call i8* @strncat(i8* " + dst + ", i8* " + src + ", i64 " + nTmp + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }
        // ── strncmp(s1, s2, n) → i32 ──
        } else if (fname.equals("strncmp")) {
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": strncmp() takes 3 arguments."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String s1 = givenArgs.get(0).tmp;
                String s2 = givenArgs.get(1).tmp;
                String nTmp = givenArgs.get(2).tmp;
                TypeInfo nType = givenArgs.get(2).theType;
                if (nType == TypeInfo.Int) { String c = newTemp(); addInstruction(c + " = sext i32 " + nTmp + " to i64"); nTmp = c; }
                String r = newTemp(); addInstruction(r + " = call i32 @strncmp(i8* " + s1 + ", i8* " + s2 + ", i64 " + nTmp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── strstr(haystack, needle) → i8* ──
        } else if (fname.equals("strstr")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": strstr() takes 2 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String s1 = toPtr(givenArgs.get(0)); String s2 = toPtr(givenArgs.get(1));
                String r = newTemp(); addInstruction(r + " = call i8* @strstr(i8* " + s1 + ", i8* " + s2 + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }
        // ── strchr(s, c) → i8* ──
        } else if (fname.equals("strchr")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": strchr() takes 2 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String s1 = toPtr(givenArgs.get(0));
                String cTmp = givenArgs.get(1).tmp;
                TypeInfo cType = givenArgs.get(1).theType;
                if (cType == TypeInfo.Char) { String c = newTemp(); addInstruction(c + " = sext i8 " + cTmp + " to i32"); cTmp = c; }
                String r = newTemp(); addInstruction(r + " = call i8* @strchr(i8* " + s1 + ", i32 " + cTmp + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }
        // ── strrchr(s, c) → i8* ──
        } else if (fname.equals("strrchr")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": strrchr() takes 2 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String s1 = toPtr(givenArgs.get(0));
                String cTmp = givenArgs.get(1).tmp;
                TypeInfo cType = givenArgs.get(1).theType;
                if (cType == TypeInfo.Char) { String c = newTemp(); addInstruction(c + " = sext i8 " + cTmp + " to i32"); cTmp = c; }
                String r = newTemp(); addInstruction(r + " = call i8* @strrchr(i8* " + s1 + ", i32 " + cTmp + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }
        // ── strtok(s, delim) → i8*；第一次傳字串，後續傳 NULL（→ "null" → i8* null）──
        } else if (fname.equals("strtok")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": strtok() takes 2 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                // toPtr：NULL 巨集展開為整數 "0"，這裡統一轉成 LLVM null
                String sTmp  = toPtr(givenArgs.get(0));
                String delim = toPtr(givenArgs.get(1));
                String r = newTemp(); addInstruction(r + " = call i8* @strtok(i8* " + sTmp + ", i8* " + delim + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }
        // ── sprintf(buf, fmt, ...) → i32 ──
        } else if (fname.equals("sprintf")) {
            if (givenArgs.size() < 2) {
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                // arg0: char* buf, arg1: char* fmt, rest: varargs
                String bufPtr = givenArgs.get(0).tmp;
                String fmtPtr = givenArgs.get(1).tmp;
                StringBuilder spCall = new StringBuilder();
                String r = newTemp();
                spCall.append(r).append(" = call i32 (i8*, i8*, ...) @sprintf(i8* ").append(bufPtr)
                      .append(", i8* ").append(fmtPtr);
                for (int si = 2; si < givenArgs.size(); si++) {
                    Info ai = givenArgs.get(si);
                    String av = ai.tmp;
                    // float → double promotion for varargs
                    if (ai.theType == TypeInfo.Float) {
                        String promoted = newTemp();
                        addInstruction(promoted + " = fpext float " + av + " to double");
                        av = promoted;
                        spCall.append(", double ").append(av);
                    } else {
                        spCall.append(", ").append(toLLVMType(ai.theType)).append(" ").append(av);
                    }
                }
                spCall.append(")");
                addInstruction(spCall.toString());
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── snprintf(buf, n, fmt, ...) → i32 ──
        } else if (fname.equals("snprintf")) {
            if (givenArgs.size() < 3) {
                System.err.println("Error! " + $id.getLine() + ": snprintf() requires at least 3 arguments (buf, n, fmt).");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String bufPtr = givenArgs.get(0).tmp;
                // n: 第二引數提升為 i64
                String nVal = givenArgs.get(1).tmp;
                if (givenArgs.get(1).theType == TypeInfo.Int) {
                    String n64 = newTemp();
                    addInstruction(n64 + " = sext i32 " + nVal + " to i64");
                    nVal = n64;
                }
                String fmtPtr = givenArgs.get(2).tmp;
                StringBuilder snCall = new StringBuilder();
                String r = newTemp();
                snCall.append(r).append(" = call i32 (i8*, i64, i8*, ...) @snprintf(i8* ").append(bufPtr)
                      .append(", i64 ").append(nVal).append(", i8* ").append(fmtPtr);
                for (int si = 3; si < givenArgs.size(); si++) {
                    Info ai = givenArgs.get(si);
                    String av = ai.tmp;
                    if (ai.theType == TypeInfo.Float) {
                        String promoted = newTemp();
                        addInstruction(promoted + " = fpext float " + av + " to double");
                        av = promoted;
                        snCall.append(", double ").append(av);
                    } else {
                        snCall.append(", ").append(toLLVMType(ai.theType)).append(" ").append(av);
                    }
                }
                snCall.append(")");
                addInstruction(snCall.toString());
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── atoi(str) → i32 ──
        } else if (fname.equals("atoi")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": atoi() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String sPtr = givenArgs.get(0).tmp;
                
                // ✨ 修正：如果 charPtrTemps 有，或者小本本裡記它是 "i8*"，都算通過！
                boolean isCharPt = charPtrTemps.contains(sPtr) || "i8*".equals(exactTypeMap.get(sPtr));
                
                if (!isCharPt) {
                    System.err.println("Warning: " + $id.getLine() + ": atoi() expects a char array or pointer argument.");
                }
                
                String r = newTemp();
                addInstruction(r + " = call i32 @atoi(i8* " + sPtr + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── atof(str) → float（內部用 double 計算後截回 float）──
        } else if (fname.equals("atof")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": atof() takes 1 argument.");
                $type = TypeInfo.Float; $tmp = "0";
            } else {
                String sPtr = givenArgs.get(0).tmp;
                // ✨ 修正：如果 charPtrTemps 有，或者小本本裡記它是 "i8*"，都算通過！
                boolean isCharPt = charPtrTemps.contains(sPtr) || "i8*".equals(exactTypeMap.get(sPtr));
                
                if (!isCharPt) {
                    System.err.println("Warning: " + $id.getLine() + ": atof() expects a char array or pointer argument.");
                }

                String rd = newTemp();
                addInstruction(rd + " = call double @atof(i8* " + sPtr + ")");
                String rf = newTemp();
                addInstruction(rf + " = fptrunc double " + rd + " to float");
                $type = TypeInfo.Float; $tmp = rf;
            }
        // ── abs(i32) → i32 ──
        } else if (fname.equals("abs")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": abs() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String av = givenArgs.get(0).tmp;
                TypeInfo at = givenArgs.get(0).theType;
                if (at == TypeInfo.Float || at == TypeInfo.Double) {
                    // float/double 版自動導向 fabs
                    String ad = av;
                    if (at == TypeInfo.Float) { ad = newTemp(); addInstruction(ad + " = fpext float " + av + " to double"); }
                    String rd = newTemp(); addInstruction(rd + " = call double @fabs(double " + ad + ")");
                    String rf = newTemp(); addInstruction(rf + " = fptrunc double " + rd + " to float");
                    $type = TypeInfo.Float; $tmp = rf;
                } else {
                    // int 版
                    String r = newTemp();
                    addInstruction(r + " = call i32 @abs(i32 " + av + ")");
                    $type = TypeInfo.Int; $tmp = r;
                }
            }
        // ✨ 魔王功能 1：動態記憶體配置 (malloc) ✨
        // ── malloc(size) → 回傳 i8* ──
        } else if (fname.equals("malloc")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": malloc() takes exactly 1 argument.");
                $type = TypeInfo.Pointer; $tmp = "0";
            } else {
                String argTmp = givenArgs.get(0).tmp;
                TypeInfo argType = givenArgs.get(0).theType;
                
                // 確保傳入 malloc 的大小是 i32
                if (argType != TypeInfo.Int) {
                    System.err.println("Error! " + $id.getLine() + ": malloc() size argument must be integer.");
                    // 這裡可以做強制轉型，或是直接報錯，這裡選擇嚴格報錯
                }
                
                String r = newTemp();
                addInstruction(r + " = call i8* @malloc(i32 " + argTmp + ")");
                $type = TypeInfo.Pointer; 
                $tmp = r;
                
                // 👇 👇 ✨ 就是漏了這行！把它記進小本本裡，賦值防護網才抓得到它！ ✨ 👇 👇
                exactTypeMap.put(r, "i8*"); 
            }
        // ✨ 魔王功能 1：動態記憶體釋放 (free) ✨
        } else if (fname.equals("free")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": free() takes exactly 1 argument.");
            } else {
                String argTmp = givenArgs.get(0).tmp;
                TypeInfo argType = givenArgs.get(0).theType;
                
                // ── 檢查是否傳入錯誤的型別 ──
                if (argType != TypeInfo.Pointer) {
                    System.err.println("Error! " + $id.getLine() + ": free() expects a pointer argument.");
                    
                    // ✨ 防護網：如果亂傳整數，強制轉型成指標，防止 LLVM 崩潰 ✨
                    if (argType == TypeInfo.Int) {
                        String casted = newTemp();
                        addInstruction(casted + " = inttoptr i32 " + argTmp + " to i8*");
                        addInstruction("call void @free(i8* " + casted + ")");
                    } else {
                        addInstruction("call void @free(i8* null)"); // 其他型別直接塞 null
                    }
                } else {
                    // ── 正常的指標處理邏輯 ──
                    String srcLLVM = exactTypeMap.containsKey(argTmp) ? exactTypeMap.get(argTmp) : "i8*";
                    if (!srcLLVM.equals("i8*")) {
                        String casted = newTemp();
                        addInstruction(casted + " = bitcast " + srcLLVM + " " + argTmp + " to i8*");
                        addInstruction("call void @free(i8* " + casted + ")");
                    } else {
                        addInstruction("call void @free(i8* " + argTmp + ")");
                    }
                }
            }
            $type = TypeInfo.Void; 
            $tmp = "0";
        } else if (fname.equals("calloc")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": calloc() takes 2 arguments.");
                $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String nmemb = givenArgs.get(0).tmp; TypeInfo nt = givenArgs.get(0).theType;
                String sz    = givenArgs.get(1).tmp; TypeInfo st = givenArgs.get(1).theType;
                if (nt == TypeInfo.Long) { String c = newTemp(); addInstruction(c + " = trunc i64 " + nmemb + " to i32"); nmemb = c; }
                if (st == TypeInfo.Long) { String c = newTemp(); addInstruction(c + " = trunc i64 " + sz + " to i32"); sz = c; }
                String r = newTemp();
                addInstruction(r + " = call i8* @calloc(i32 " + nmemb + ", i32 " + sz + ")");
                exactTypeMap.put(r, "i8*"); charPtrTemps.add(r);
                $type = TypeInfo.Pointer; $tmp = r;
            }
        } else if (fname.equals("realloc")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": realloc() takes 2 arguments.");
                $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String ptr = givenArgs.get(0).tmp; TypeInfo st = givenArgs.get(1).theType;
                String sz  = givenArgs.get(1).tmp;
                // NULL (整數 "0") → "null"；非 i8* 指標 → bitcast
                if ("0".equals(ptr)) {
                    ptr = "null";
                } else {
                    String ptrLLVM = exactTypeMap.containsKey(ptr) ? exactTypeMap.get(ptr) : "i8*";
                    if (!ptrLLVM.equals("i8*") && !"null".equals(ptr)) {
                        String casted = newTemp();
                        addInstruction(casted + " = bitcast " + ptrLLVM + " " + ptr + " to i8*");
                        ptr = casted;
                    }
                }
                if (st == TypeInfo.Long) { String c = newTemp(); addInstruction(c + " = trunc i64 " + sz + " to i32"); sz = c; }
                String r = newTemp();
                addInstruction(r + " = call i8* @realloc(i8* " + ptr + ", i32 " + sz + ")");
                exactTypeMap.put(r, "i8*"); charPtrTemps.add(r);
                $type = TypeInfo.Pointer; $tmp = r;
            }
        } else if (fname.equals("memcpy") || fname.equals("memset") || fname.equals("memcmp")) {
            // ✨ 記憶體操作三劍客：memcpy / memset / memcmp ✨
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() requires 3 arguments.");
                $type = TypeInfo.Error; $tmp = "0";
            } else {
                // ── 1. 處理第一個參數 (dest / ptr1) ──
                String arg1Tmp = givenArgs.get(0).tmp;
                TypeInfo arg1Type = givenArgs.get(0).theType;
                String arg1LLVM = exactTypeMap.containsKey(arg1Tmp) ? exactTypeMap.get(arg1Tmp) : toLLVMPtrType(arg1Type);
                if (!arg1LLVM.equals("i8*")) {
                    String casted1 = newTemp();
                    addInstruction(casted1 + " = bitcast " + arg1LLVM + " " + arg1Tmp + " to i8*");
                    arg1Tmp = casted1;
                }

                // ── 2. 處理第二個參數 (src / ptr2 / val) ──
                String arg2Tmp = givenArgs.get(1).tmp;
                if (fname.equals("memset")) {
                    // C 標準庫的 memset 第二個參數本來就是 int (i32)，所以不截斷！
                    if (givenArgs.get(1).theType == TypeInfo.Char) {
                        String extVal = newTemp();
                        addInstruction(extVal + " = sext i8 " + arg2Tmp + " to i32");
                        arg2Tmp = extVal;
                    }
                } else { // memcpy, memcmp 都是傳指標
                    TypeInfo arg2Type = givenArgs.get(1).theType;
                    String arg2LLVM = exactTypeMap.containsKey(arg2Tmp) ? exactTypeMap.get(arg2Tmp) : toLLVMPtrType(arg2Type);
                    if (!arg2LLVM.equals("i8*")) {
                        String casted2 = newTemp();
                        addInstruction(casted2 + " = bitcast " + arg2LLVM + " " + arg2Tmp + " to i8*");
                        arg2Tmp = casted2;
                    }
                }

                // ── 3. 處理第三個參數 (size) ──
                String sizeTmp = givenArgs.get(2).tmp;
             
                // ── 4. 產生對應的 call 指令 ──
                String result = newTemp();
                if (fname.equals("memcpy")) {
                    addInstruction(result + " = call i8* @memcpy(i8* " + arg1Tmp + ", i8* " + arg2Tmp + ", i32 " + sizeTmp + ")");
                    $type = TypeInfo.Pointer; $tmp = result; exactTypeMap.put(result, "i8*");
                } else if (fname.equals("memset")) {
                    // ✨ 這裡的第二個參數型別從 i8 改成了 i32 ✨
                    addInstruction(result + " = call i8* @memset(i8* " + arg1Tmp + ", i32 " + arg2Tmp + ", i32 " + sizeTmp + ")");
                    $type = TypeInfo.Pointer; $tmp = result; exactTypeMap.put(result, "i8*");
                } else if (fname.equals("memcmp")) {
                    addInstruction(result + " = call i32 @memcmp(i8* " + arg1Tmp + ", i8* " + arg2Tmp + ", i32 " + sizeTmp + ")");
                    $type = TypeInfo.Int; $tmp = result; // memcmp 回傳的是整數！
                }
            }
        }
        // ✨ ── memmove(dst, src, n)：安全重疊記憶體移動 → i8* ──
        else if (fname.equals("memmove")) {
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": memmove() requires 3 arguments.");
                $type = TypeInfo.Error; $tmp = "0";
            } else {
                String dst = givenArgs.get(0).tmp;
                String src = givenArgs.get(1).tmp;
                // cast dst/src to i8* if needed
                String dstLLVM = exactTypeMap.containsKey(dst) ? exactTypeMap.get(dst) : "i8*";
                if (!dstLLVM.equals("i8*")) { String c = newTemp(); addInstruction(c + " = bitcast " + dstLLVM + " " + dst + " to i8*"); dst = c; }
                String srcLLVM = exactTypeMap.containsKey(src) ? exactTypeMap.get(src) : "i8*";
                if (!srcLLVM.equals("i8*")) { String c = newTemp(); addInstruction(c + " = bitcast " + srcLLVM + " " + src + " to i8*"); src = c; }
                // size: extend to i64
                String sz = givenArgs.get(2).tmp;
                String szExt = newTemp(); addInstruction(szExt + " = sext i32 " + sz + " to i64");
                String r = newTemp();
                addInstruction(r + " = call i8* @memmove(i8* " + dst + ", i8* " + src + ", i64 " + szExt + ")");
                $type = TypeInfo.Pointer; $tmp = r; exactTypeMap.put(r, "i8*");
            }
        // ── memchr(ptr, ch, n)：在記憶體裡找字元 → i8* ──
        } else if (fname.equals("memchr")) {
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": memchr() requires 3 arguments.");
                $type = TypeInfo.Error; $tmp = "0";
            } else {
                String ptr = givenArgs.get(0).tmp;
                String ptrLLVM = exactTypeMap.containsKey(ptr) ? exactTypeMap.get(ptr) : "i8*";
                if (!ptrLLVM.equals("i8*")) { String c = newTemp(); addInstruction(c + " = bitcast " + ptrLLVM + " " + ptr + " to i8*"); ptr = c; }
                String ch = givenArgs.get(1).tmp;
                if (givenArgs.get(1).theType == TypeInfo.Char) { String e = newTemp(); addInstruction(e + " = sext i8 " + ch + " to i32"); ch = e; }
                String sz = givenArgs.get(2).tmp;
                String szExt = newTemp(); addInstruction(szExt + " = sext i32 " + sz + " to i64");
                String r = newTemp();
                addInstruction(r + " = call i8* @memchr(i8* " + ptr + ", i32 " + ch + ", i64 " + szExt + ")");
                $type = TypeInfo.Pointer; $tmp = r; exactTypeMap.put(r, "i8*");
            }
        // ── strspn(s, accept)：前置匹配長度 → int (returned as i64, truncated to i32) ──
        } else if (fname.equals("strspn")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": strspn() requires 2 arguments.");
                $type = TypeInfo.Error; $tmp = "0";
            } else {
                String s = givenArgs.get(0).tmp;
                String acc = givenArgs.get(1).tmp;
                String r64 = newTemp(); addInstruction(r64 + " = call i64 @strspn(i8* " + s + ", i8* " + acc + ")");
                String r = newTemp(); addInstruction(r + " = trunc i64 " + r64 + " to i32");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── strcspn(s, reject)：前置不匹配長度 → int ──
        } else if (fname.equals("strcspn")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": strcspn() requires 2 arguments.");
                $type = TypeInfo.Error; $tmp = "0";
            } else {
                String s = givenArgs.get(0).tmp;
                String rej = givenArgs.get(1).tmp;
                String r64 = newTemp(); addInstruction(r64 + " = call i64 @strcspn(i8* " + s + ", i8* " + rej + ")");
                String r = newTemp(); addInstruction(r + " = trunc i64 " + r64 + " to i32");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── strpbrk(s, accept)：找第一個出現在字元集的位置 → char* ──
        } else if (fname.equals("strpbrk")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": strpbrk() requires 2 arguments.");
                $type = TypeInfo.Error; $tmp = "0";
            } else {
                String s = givenArgs.get(0).tmp;
                String acc = givenArgs.get(1).tmp;
                String r = newTemp(); addInstruction(r + " = call i8* @strpbrk(i8* " + s + ", i8* " + acc + ")");
                $type = TypeInfo.Pointer; $tmp = r; exactTypeMap.put(r, "i8*");
            }
        }
        // ── 檔案 I/O：fopen(filename, mode) → 回傳 FILE* (用 i8* 代替) ──
        else if (fname.equals("fopen")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": fopen() takes exactly 2 arguments (filename, mode).");
                $type = TypeInfo.Pointer; $tmp = "0";
            } else {
                String filenamePtr = givenArgs.get(0).tmp;
                String modePtr = givenArgs.get(1).tmp;
                String r = newTemp();
                addInstruction(r + " = call i8* @fopen(i8* " + filenamePtr + ", i8* " + modePtr + ")");
                $type = TypeInfo.Pointer; $tmp = r; 
                exactTypeMap.put(r, "i8*"); // 記進小本本，它是指標！
            }
        // ── 檔案 I/O：fclose(fp) → 回傳 int ──
        } else if (fname.equals("fclose")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": fclose() takes exactly 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fp = toFilePtr(givenArgs.get(0));
                String r = newTemp();
                addInstruction(r + " = call i32 @fclose(i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── 檔案 I/O：fputs(str, fp) → 將字串寫入檔案 ──
        } else if (fname.equals("fputs")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": fputs() takes 2 arguments (str, fp).");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String strPtr = givenArgs.get(0).tmp;
                String fp = toFilePtr(givenArgs.get(1));
                String r = newTemp();
                addInstruction(r + " = call i32 @fputs(i8* " + strPtr + ", i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── 檔案 I/O：fgetc(fp) → 從檔案讀取一個字元 (回傳 int) ──
        } else if (fname.equals("fgetc")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": fgetc() takes exactly 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fp = toFilePtr(givenArgs.get(0));
                String r = newTemp();
                addInstruction(r + " = call i32 @fgetc(i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── fprintf(fp, fmt, ...) → i32 ──
        } else if (fname.equals("fprintf")) {
            if (givenArgs.size() < 2) {
                System.err.println("Error! " + $id.getLine() + ": fprintf() requires at least 2 arguments (fp, fmt).");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fpArg  = toFilePtr(givenArgs.get(0));
                String fmtArg = givenArgs.get(1).tmp;
                StringBuilder fpCall = new StringBuilder();
                String fr = newTemp();
                fpCall.append(fr).append(" = call i32 (i8*, i8*, ...) @fprintf(i8* ").append(fpArg)
                      .append(", i8* ").append(fmtArg);
                for (int fi = 2; fi < givenArgs.size(); fi++) {
                    Info ai = givenArgs.get(fi);
                    String av = ai.tmp;
                    if (ai.theType == TypeInfo.Float) {
                        String prom = newTemp(); addInstruction(prom + " = fpext float " + av + " to double"); av = prom;
                        fpCall.append(", double ").append(av);
                    } else { fpCall.append(", ").append(toLLVMType(ai.theType)).append(" ").append(av); }
                }
                fpCall.append(")");
                addInstruction(fpCall.toString());
                $type = TypeInfo.Int; $tmp = fr;
            }

        // ── sscanf(buf, fmt, &var...) → i32 ──
        } else if (fname.equals("sscanf")) {
            if (givenArgs.size() < 2) {
                System.err.println("Error! " + $id.getLine() + ": sscanf() requires at least 2 arguments.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String bufArg = toPtr(givenArgs.get(0));
                String fmtArg = givenArgs.get(1).tmp;
                StringBuilder sc = new StringBuilder();
                String sr = newTemp();
                sc.append(sr).append(" = call i32 (i8*, i8*, ...) @__isoc99_sscanf(i8* ")
                  .append(bufArg).append(", i8* ").append(fmtArg);
                for (int si = 2; si < givenArgs.size(); si++) {
                    Info ai = givenArgs.get(si);
                    String argTmp = ai.tmp;
                    // &var 傳進來時 tmp 已經是指標（alloca addr 或陣列 base）
                    // 用 exactTypeMap 取實際 LLVM 型別，避免再加 *
                    if (charPtrTemps.contains(argTmp) || ai.theType == TypeInfo.Char) {
                        sc.append(", i8* ").append(argTmp);
                    } else {
                        String llvmPtrT = exactTypeMap.containsKey(argTmp)
                            ? exactTypeMap.get(argTmp)
                            : (toLLVMType(ai.theType) + "*");
                        sc.append(", ").append(llvmPtrT).append(" ").append(argTmp);
                    }
                }
                sc.append(")");
                addInstruction(sc.toString());
                $type = TypeInfo.Int; $tmp = sr;
            }

        // ── fscanf(fp, fmt, &var...) → i32 ──
        } else if (fname.equals("fscanf")) {
            if (givenArgs.size() < 2) {
                System.err.println("Error! " + $id.getLine() + ": fscanf() requires at least 2 arguments.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fpArg  = toFilePtr(givenArgs.get(0));
                String fmtArg = givenArgs.get(1).tmp;
                StringBuilder fsc = new StringBuilder();
                String fsr = newTemp();
                fsc.append(fsr).append(" = call i32 (i8*, i8*, ...) @__isoc99_fscanf(i8* ")
                   .append(fpArg).append(", i8* ").append(fmtArg);
                for (int si = 2; si < givenArgs.size(); si++) {
                    Info ai = givenArgs.get(si);
                    String argTmp = ai.tmp;
                    if (charPtrTemps.contains(argTmp) || ai.theType == TypeInfo.Char) {
                        fsc.append(", i8* ").append(argTmp);
                    } else {
                        String llvmPtrT = exactTypeMap.containsKey(argTmp)
                            ? exactTypeMap.get(argTmp)
                            : (toLLVMType(ai.theType) + "*");
                        fsc.append(", ").append(llvmPtrT).append(" ").append(argTmp);
                    }
                }
                fsc.append(")");
                addInstruction(fsc.toString());
                $type = TypeInfo.Int; $tmp = fsr;
            }

        // ── fgets(buf, n, fp) → i8* ──
        } else if (fname.equals("fgets")) {
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": fgets() takes 3 arguments (buf, n, fp).");
                $type = TypeInfo.Char; $tmp = "0";
            } else {
                String bufArg = givenArgs.get(0).tmp;
                String nArg   = givenArgs.get(1).tmp;
                String fpArg  = toFilePtr(givenArgs.get(2));
                if (givenArgs.get(1).theType != TypeInfo.Int) {
                    String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(givenArgs.get(1).theType) + " " + nArg + " to i32"); nArg = conv;
                }
                String r = newTemp();
                addInstruction(r + " = call i8* @fgets(i8* " + bufArg + ", i32 " + nArg + ", i8* " + fpArg + ")");
                exactTypeMap.put(r, "i8*");
                $type = TypeInfo.Pointer; $tmp = r;
            }

        // ── feof(fp) → i32 ──
        } else if (fname.equals("feof")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": feof() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fpArg = toFilePtr(givenArgs.get(0));
                String r = newTemp();
                addInstruction(r + " = call i32 @feof(i8* " + fpArg + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        } else if (fname.equals("feof")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": feof() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fpArg = toFilePtr(givenArgs.get(0));
                String r = newTemp();
                addInstruction(r + " = call i32 @feof(i8* " + fpArg + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── fread(ptr, size, nmemb, fp) → i64 ──
        } else if (fname.equals("fread")) {
            if (givenArgs.size() != 4) {
                System.err.println("Error! " + $id.getLine() + ": fread() takes 4 arguments.");
                $type = TypeInfo.Long; $tmp = "0";
            } else {
                // ✨ 使用 toCharPtr 統一處理指標轉型
                String ptr = toCharPtr(givenArgs.get(0));
                
                String sz = givenArgs.get(1).tmp; 
                TypeInfo st = givenArgs.get(1).theType;
                String nmemb = givenArgs.get(2).tmp; 
                TypeInfo nt = givenArgs.get(2).theType;
                String fp = toFilePtr(givenArgs.get(3));
                
                if (st == TypeInfo.Int) { 
                    String c = newTemp(); 
                    addInstruction(c + " = sext i32 " + sz + " to i64"); 
                    sz = c; 
                }
                if (nt == TypeInfo.Int) { 
                    String c = newTemp(); 
                    addInstruction(c + " = sext i32 " + nmemb + " to i64"); 
                    nmemb = c; 
                }
                
                String r = newTemp();
                addInstruction(r + " = call i64 @fread(i8* " + ptr + ", i64 " + sz + ", i64 " + nmemb + ", i8* " + fp + ")");
                $type = TypeInfo.Long; $tmp = r;
            }
            
        // ── fwrite(ptr, size, nmemb, fp) → i64 ──
        } else if (fname.equals("fwrite")) {
            if (givenArgs.size() != 4) {
                System.err.println("Error! " + $id.getLine() + ": fwrite() takes 4 arguments.");
                $type = TypeInfo.Long; $tmp = "0";
            } else {
                // ✨ 使用 toCharPtr 統一處理指標轉型
                String ptr = toCharPtr(givenArgs.get(0));
                
                String sz = givenArgs.get(1).tmp; 
                TypeInfo st = givenArgs.get(1).theType;
                String nmemb = givenArgs.get(2).tmp; 
                TypeInfo nt = givenArgs.get(2).theType;
                String fp = toFilePtr(givenArgs.get(3));
                
                if (st == TypeInfo.Int) { 
                    String c = newTemp(); 
                    addInstruction(c + " = sext i32 " + sz + " to i64"); 
                    sz = c; 
                }
                if (nt == TypeInfo.Int) { 
                    String c = newTemp(); 
                    addInstruction(c + " = sext i32 " + nmemb + " to i64"); 
                    nmemb = c; 
                }
                
                String r = newTemp();
                addInstruction(r + " = call i64 @fwrite(i8* " + ptr + ", i64 " + sz + ", i64 " + nmemb + ", i8* " + fp + ")");
                $type = TypeInfo.Long; $tmp = r;
            }

        // ── fseek(fp, offset, whence) → i32 ──
        } else if (fname.equals("fseek")) {
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": fseek() takes 3 arguments.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fp     = toFilePtr(givenArgs.get(0));
                String offset = givenArgs.get(1).tmp; TypeInfo ot = givenArgs.get(1).theType;
                String whence = givenArgs.get(2).tmp; TypeInfo wt = givenArgs.get(2).theType;
                if (ot == TypeInfo.Int) { String c = newTemp(); addInstruction(c + " = sext i32 " + offset + " to i64"); offset = c; }
                if (wt == TypeInfo.Long) { String c = newTemp(); addInstruction(c + " = trunc i64 " + whence + " to i32"); whence = c; }
                String r = newTemp();
                addInstruction(r + " = call i32 @fseek(i8* " + fp + ", i64 " + offset + ", i32 " + whence + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── ftell(fp) → i64 ──
        } else if (fname.equals("ftell")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": ftell() takes 1 argument.");
                $type = TypeInfo.Long; $tmp = "0";
            } else {
                String fp = toFilePtr(givenArgs.get(0));
                String r = newTemp();
                addInstruction(r + " = call i64 @ftell(i8* " + fp + ")");
                $type = TypeInfo.Long; $tmp = r;
            }

        // ── rewind(fp) → void ──
        } else if (fname.equals("rewind")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": rewind() takes 1 argument.");
            } else {
                String fp = toFilePtr(givenArgs.get(0));
                addInstruction("call void @rewind(i8* " + fp + ")");
            }
            $type = TypeInfo.Void; $tmp = "0";

        // ── ferror(fp) → i32 ──
        } else if (fname.equals("ferror")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": ferror() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fp = toFilePtr(givenArgs.get(0));
                String r = newTemp();
                addInstruction(r + " = call i32 @ferror(i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── perror(msg) → void ──
        } else if (fname.equals("perror")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": perror() takes 1 argument.");
            } else {
                String msg = toPtr(givenArgs.get(0));
                addInstruction("call void @perror(i8* " + msg + ")");
            }
            $type = TypeInfo.Void; $tmp = "0";

        // ── strerror(errnum) → i8* ──
        } else if (fname.equals("strerror")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": strerror() takes 1 argument.");
                $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String errnum = givenArgs.get(0).tmp;
                if (givenArgs.get(0).theType == TypeInfo.Long) { String c = newTemp(); addInstruction(c + " = trunc i64 " + errnum + " to i32"); errnum = c; }
                String r = newTemp();
                addInstruction(r + " = call i8* @strerror(i32 " + errnum + ")");
                charPtrTemps.add(r); exactTypeMap.put(r, "i8*");
                $type = TypeInfo.Pointer; $tmp = r;
            }

        // ── remove(path) → i32 ──
        } else if (fname.equals("remove")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": remove() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String r = newTemp();
                addInstruction(r + " = call i32 @remove(i8* " + givenArgs.get(0).tmp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── rename(old, new) → i32 ──
        } else if (fname.equals("rename")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": rename() takes 2 arguments.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String r = newTemp();
                addInstruction(r + " = call i32 @rename(i8* " + givenArgs.get(0).tmp + ", i8* " + givenArgs.get(1).tmp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── strdup(s) → i8* ──
        } else if (fname.equals("strdup")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": strdup() takes 1 argument.");
                $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String r = newTemp();
                addInstruction(r + " = call i8* @strdup(i8* " + givenArgs.get(0).tmp + ")");
                charPtrTemps.add(r); exactTypeMap.put(r, "i8*");
                $type = TypeInfo.Pointer; $tmp = r;
            }

        // ── getc(fp) → i32 ──
        } else if (fname.equals("getc")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": getc() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fp = toFilePtr(givenArgs.get(0));
                String r = newTemp();
                addInstruction(r + " = call i32 @fgetc(i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── fputc(c, fp) → i32 ──
        } else if (fname.equals("fputc")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": fputc() takes 2 arguments.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String c  = givenArgs.get(0).tmp; TypeInfo ct = givenArgs.get(0).theType;
                String fp = toFilePtr(givenArgs.get(1));
                if (ct == TypeInfo.Char) { String cv = newTemp(); addInstruction(cv + " = sext i8 " + c + " to i32"); c = cv; }
                String r = newTemp();
                addInstruction(r + " = call i32 @fputc(i32 " + c + ", i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── ungetc(c, fp) → i32 ──
        } else if (fname.equals("ungetc")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": ungetc() takes 2 arguments.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String c  = givenArgs.get(0).tmp; TypeInfo ct = givenArgs.get(0).theType;
                String fp = toFilePtr(givenArgs.get(1));
                if (ct == TypeInfo.Char) { String cv = newTemp(); addInstruction(cv + " = sext i8 " + c + " to i32"); c = cv; }
                String r = newTemp();
                addInstruction(r + " = call i32 @ungetc(i32 " + c + ", i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── exit(code) → void（noreturn）──
        } else if (fname.equals("assert")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": assert() takes 1 argument.");
                $type = TypeInfo.Void; $tmp = "0";
            } else {
                String condTmp = coerceToBool(givenArgs.get(0).theType, givenArgs.get(0).tmp);
                String passLabel = newLabel("Lassert_pass");
                String failLabel = newLabel("Lassert_fail");
                addInstruction("br i1 " + condTmp + ", label %" + passLabel + ", label %" + failLabel);
                lastInstrIsTerminator = true;
                addInstruction(failLabel + ":");
                lastInstrIsTerminator = false;
                addInstruction("call void @abort()");
                addInstruction("unreachable");
                lastInstrIsTerminator = true;
                addInstruction(passLabel + ":");
                lastInstrIsTerminator = false;
                $type = TypeInfo.Void; $tmp = "0";
            }

        // ══ 第一批新增函式 ══

        // ── clearerr(fp) → void ──
        } else if (fname.equals("clearerr")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": clearerr() takes 1 argument.");
            } else {
                String fp = toFilePtr(givenArgs.get(0));
                addInstruction("call void @clearerr(i8* " + fp + ")");
            }
            $type = TypeInfo.Void; $tmp = "0";

        // ── tmpfile() → FILE* ──
        } else if (fname.equals("tmpfile")) {
            String r = newTemp();
            addInstruction(r + " = call i8* @tmpfile()");
            charPtrTemps.add(r); exactTypeMap.put(r, "i8*");
            $type = TypeInfo.Pointer; $tmp = r;

        // ── tmpnam(buf) → char* ──
        } else if (fname.equals("tmpnam")) {
            String bufArg = (givenArgs.size() >= 1 && !"null".equals(givenArgs.get(0).tmp))
                            ? givenArgs.get(0).tmp : "null";
            String r = newTemp();
            addInstruction(r + " = call i8* @tmpnam(i8* " + bufArg + ")");
            charPtrTemps.add(r); exactTypeMap.put(r, "i8*");
            $type = TypeInfo.Pointer; $tmp = r;

        // ── popen(cmd, mode) → FILE* ──
        } else if (fname.equals("popen")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": popen() takes 2 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String cmd  = givenArgs.get(0).tmp;
                String mode = givenArgs.get(1).tmp;
                String r = newTemp();
                addInstruction(r + " = call i8* @popen(i8* " + cmd + ", i8* " + mode + ")");
                charPtrTemps.add(r); exactTypeMap.put(r, "i8*");
                $type = TypeInfo.Pointer; $tmp = r;
            }

        // ── pclose(fp) → i32 ──
        } else if (fname.equals("pclose")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": pclose() takes 1 argument."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fp = toFilePtr(givenArgs.get(0));
                String r = newTemp();
                addInstruction(r + " = call i32 @pclose(i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── setvbuf(fp, buf, mode, size) → i32 ──
        } else if (fname.equals("setvbuf")) {
            if (givenArgs.size() != 4) {
                System.err.println("Error! " + $id.getLine() + ": setvbuf() takes 4 arguments."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fp   = toFilePtr(givenArgs.get(0));
                String buf  = givenArgs.get(1).tmp;
                String mode = givenArgs.get(2).tmp; TypeInfo mt = givenArgs.get(2).theType;
                String sz   = givenArgs.get(3).tmp; TypeInfo st = givenArgs.get(3).theType;
                if ("null".equals(buf) || "0".equals(buf)) buf = "null";
                else if (!charPtrTemps.contains(buf)) {
                    String b2 = newTemp();
                    if (buf.matches("-?\\d+")) {
                        addInstruction(b2 + " = inttoptr i32 " + buf + " to i8*");
                    } else {
                        String bufT = exactTypeMap.containsKey(buf) ? exactTypeMap.get(buf) : "i8*";
                        addInstruction(b2 + " = bitcast " + bufT + " " + buf + " to i8*");
                    }
                    buf = b2;
                }
                if (isIntegerType(mt) && bitWidth(mt) < 32) { String c=newTemp(); addInstruction(c+" = sext "+toLLVMType(mt)+" "+mode+" to i32"); mode=c; }
                if (isIntegerType(st) && bitWidth(st) < 64) { String c=newTemp(); addInstruction(c+" = sext "+toLLVMType(st)+" "+sz+" to i64"); sz=c; }
                String r = newTemp();
                addInstruction(r + " = call i32 @setvbuf(i8* " + fp + ", i8* " + buf + ", i32 " + mode + ", i64 " + sz + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── setbuf(fp, buf) → void ──
        } else if (fname.equals("setbuf")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": setbuf() takes 2 arguments.");
            } else {
                String fp  = toFilePtr(givenArgs.get(0));
                String buf = toPtr(givenArgs.get(1));
                addInstruction("call void @setbuf(i8* " + fp + ", i8* " + buf + ")");
            }
            $type = TypeInfo.Void; $tmp = "0";

        // ── modf(x, &intpart) → double（小數部分），*intpart = 整數部分 ──
        } else if (fname.equals("modf")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": modf() takes 2 arguments (double, double*)."); $type = TypeInfo.Double; $tmp = "0.0";
            } else {
                String a = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String iptr = givenArgs.get(1).tmp;
                String ad;
                if (isIntegerType(at)) { ad=newTemp(); addInstruction(ad+" = sitofp "+toLLVMType(at)+" "+a+" to double"); }
                else if (at==TypeInfo.Float) { ad=newTemp(); addInstruction(ad+" = fpext float "+a+" to double"); }
                else ad = a;
                // 若 iptr 不是 double*，需要 bitcast
                String iptrT = exactTypeMap.containsKey(iptr) ? exactTypeMap.get(iptr) : "double*";
                String iptrD;
                if ("double*".equals(iptrT)) iptrD = iptr;
                else { iptrD=newTemp(); addInstruction(iptrD+" = bitcast "+iptrT+" "+iptr+" to double*"); }
                String r = newTemp();
                addInstruction(r + " = call double @modf(double " + ad + ", double* " + iptrD + ")");
                $type = TypeInfo.Double; $tmp = r;
            }

        // ── frexp(x, &exp) → double，*exp = 指數部分 ──
        } else if (fname.equals("frexp")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": frexp() takes 2 arguments (double, int*)."); $type = TypeInfo.Double; $tmp = "0.0";
            } else {
                String a = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String eptr = givenArgs.get(1).tmp;
                String ad;
                if (isIntegerType(at)) { ad=newTemp(); addInstruction(ad+" = sitofp "+toLLVMType(at)+" "+a+" to double"); }
                else if (at==TypeInfo.Float) { ad=newTemp(); addInstruction(ad+" = fpext float "+a+" to double"); }
                else ad = a;
                String eptrT = exactTypeMap.containsKey(eptr) ? exactTypeMap.get(eptr) : "i32*";
                String eptrI;
                if ("i32*".equals(eptrT)) eptrI = eptr;
                else { eptrI=newTemp(); addInstruction(eptrI+" = bitcast "+eptrT+" "+eptr+" to i32*"); }
                String r = newTemp();
                addInstruction(r + " = call double @frexp(double " + ad + ", i32* " + eptrI + ")");
                $type = TypeInfo.Double; $tmp = r;
            }

        // ── ldexp(x, n) → double ──
        } else if (fname.equals("ldexp") || fname.equals("scalbn")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 2 arguments."); $type = TypeInfo.Double; $tmp = "0.0";
            } else {
                String a = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String n = givenArgs.get(1).tmp; TypeInfo nt = givenArgs.get(1).theType;
                String ad;
                if (isIntegerType(at)) { ad=newTemp(); addInstruction(ad+" = sitofp "+toLLVMType(at)+" "+a+" to double"); }
                else if (at==TypeInfo.Float) { ad=newTemp(); addInstruction(ad+" = fpext float "+a+" to double"); }
                else ad = a;
                if (bitWidth(nt) != 32) { String c=newTemp(); addInstruction(c+(bitWidth(nt)>32?" = trunc i64 ":" = sext "+toLLVMType(nt)+" ")+n+" to i32"); n=c; }
                String r = newTemp();
                addInstruction(r + " = call double @" + fname + "(double " + ad + ", i32 " + n + ")");
                $type = TypeInfo.Double; $tmp = r;
            }

        // ── logb(x) → double ──
        } else if (fname.equals("logb")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": logb() takes 1 argument."); $type = TypeInfo.Double; $tmp = "0.0";
            } else {
                String a = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String ad;
                if (isIntegerType(at)) { ad=newTemp(); addInstruction(ad+" = sitofp "+toLLVMType(at)+" "+a+" to double"); }
                else if (at==TypeInfo.Float) { ad=newTemp(); addInstruction(ad+" = fpext float "+a+" to double"); }
                else ad = a;
                String r = newTemp(); addInstruction(r + " = call double @logb(double " + ad + ")");
                $type = TypeInfo.Double; $tmp = r;
            }

        // ── ilogb(x) → i32 ──
        } else if (fname.equals("ilogb")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": ilogb() takes 1 argument."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String a = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String ad;
                if (isIntegerType(at)) { ad=newTemp(); addInstruction(ad+" = sitofp "+toLLVMType(at)+" "+a+" to double"); }
                else if (at==TypeInfo.Float) { ad=newTemp(); addInstruction(ad+" = fpext float "+a+" to double"); }
                else ad = a;
                String r = newTemp(); addInstruction(r + " = call i32 @ilogb(double " + ad + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── signal(signum, handler) → 舊 handler (i8*) ──
        } else if (fname.equals("signal")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": signal() takes 2 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String sig = givenArgs.get(0).tmp; TypeInfo st2 = givenArgs.get(0).theType;
                if (bitWidth(st2) != 32) { String c=newTemp(); addInstruction(c+" = trunc "+toLLVMType(st2)+" "+sig+" to i32"); sig=c; }
                String handler = givenArgs.get(1).tmp;
                // ✨ (void*)0 / NULL / SIG_DFL / integer 0 → null（避免 i8* 0 非法）
                if ("0".equals(handler) || "null".equals(handler)) handler = "null";
                // 額外防護：如果 handler 是純整數字面值（如 "1"），也轉 inttoptr
                boolean handlerIsIntLiteral = handler.matches("-?\\d+");
                String handlerT = (!handlerIsIntLiteral && exactTypeMap.containsKey(handler))
                                  ? exactTypeMap.get(handler) : "i8*";
                String handlerI8;
                if ("null".equals(handler)) {
                    handlerI8 = "null";
                } else if (handlerIsIntLiteral) {
                    // 整數字面值必須用 inttoptr，不可直接作為 i8*
                    handlerI8 = newTemp();
                    addInstruction(handlerI8 + " = inttoptr i32 " + handler + " to i8*");
                } else if ("i8*".equals(handlerT)) {
                    handlerI8 = handler;
                } else {
                    handlerI8 = newTemp();
                    addInstruction(handlerI8 + " = bitcast " + handlerT + " " + handler + " to i8*");
                }
                String r = newTemp();
                addInstruction(r + " = call i8* @signal(i32 " + sig + ", i8* " + handlerI8 + ")");
                exactTypeMap.put(r, "i8*");
                $type = TypeInfo.Pointer; $tmp = r;
            }

        // ── raise(signum) → i32 ──
        } else if (fname.equals("raise")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": raise() takes 1 argument."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String sig = givenArgs.get(0).tmp; TypeInfo st2 = givenArgs.get(0).theType;
                if (bitWidth(st2) != 32) { String c=newTemp(); addInstruction(c+" = trunc "+toLLVMType(st2)+" "+sig+" to i32"); sig=c; }
                String r = newTemp(); addInstruction(r + " = call i32 @raise(i32 " + sig + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── vprintf(fmt, ap) / vfprintf(fp,fmt,ap) / vsprintf(buf,fmt,ap) / vsnprintf(buf,n,fmt,ap) ──
        // ap (va_list) 以 i8* 傳遞；上層呼叫者負責傳入正確的 va_list
        // ── ✨ stdio.h 補完 ──────────────────────────────────────────────────

        // puts(str)：輸出字串並自動換行，回傳非負整數
        } else if (fname.equals("puts")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": puts() takes 1 argument."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String strArg = givenArgs.get(0).tmp;
                String r = newTemp(); addInstruction(r + " = call i32 @puts(i8* " + strArg + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // gets(buf)：從 stdin 讀一行到 buf，回傳 i8*（不安全，但支援）
        } else if (fname.equals("gets")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": gets() takes 1 argument."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String buf = givenArgs.get(0).tmp;
                String r = newTemp(); addInstruction(r + " = call i8* @gets(i8* " + buf + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }

        // freopen(path, mode, fp)：重新導向串流，回傳 FILE*（i8*）
        } else if (fname.equals("freopen")) {
            if (givenArgs.size() != 3) {
                System.err.println("Error! " + $id.getLine() + ": freopen() takes 3 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String path = givenArgs.get(0).tmp;
                String mode = givenArgs.get(1).tmp;
                String fp   = toFilePtr(givenArgs.get(2));
                String r = newTemp(); addInstruction(r + " = call i8* @freopen(i8* " + path + ", i8* " + mode + ", i8* " + fp + ")");
                charPtrTemps.add(r); exactTypeMap.put(r, "i8*");
                $type = TypeInfo.Pointer; $tmp = r;
            }

        // fflush(fp)：排空緩衝區。fflush(NULL) 排空所有。回傳 i32
        } else if (fname.equals("fflush")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": fflush() takes 1 argument."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String fp = (givenArgs.get(0).tmp.equals("0") || givenArgs.get(0).tmp.equals("null"))
                    ? "null" : toFilePtr(givenArgs.get(0));
                String r = newTemp(); addInstruction(r + " = call i32 @fflush(i8* " + fp + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── ✨ stdlib.h 補完 ──────────────────────────────────────────────────

        // aligned_alloc(alignment, size)：C11 對齊記憶體配置，回傳 i8*
        } else if (fname.equals("aligned_alloc")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": aligned_alloc() takes 2 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String align = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String sz    = givenArgs.get(1).tmp; TypeInfo st = givenArgs.get(1).theType;
                if (bitWidth(at) < 64) { String c=newTemp(); addInstruction(c+" = sext "+toLLVMType(at)+" "+align+" to i64"); align=c; }
                if (bitWidth(st) < 64) { String c=newTemp(); addInstruction(c+" = sext "+toLLVMType(st)+" "+sz   +" to i64"); sz=c; }
                String r = newTemp(); addInstruction(r + " = call i8* @aligned_alloc(i64 " + align + ", i64 " + sz + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }

        // _Exit(status)：立即終止，不執行 atexit handlers
        } else if (fname.equals("_Exit")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": _Exit() takes 1 argument."); $type = TypeInfo.Void; $tmp = "0";
            } else {
                String code = givenArgs.get(0).tmp; TypeInfo ct = givenArgs.get(0).theType;
                if (bitWidth(ct) != 32) { String c=newTemp(); addInstruction(c+" = trunc "+toLLVMType(ct)+" "+code+" to i32"); code=c; }
                addInstruction("call void @_Exit(i32 " + code + ")");
                addInstruction("unreachable");
                lastInstrIsTerminator = true;
                $type = TypeInfo.Void; $tmp = "0";
            }

        // ── ✨ 字串補完 ──────────────────────────────────────────────────────

        // strsep(stringp, delim)：從 *stringp 切出下一個 token，回傳 i8*
        // 不同於 strtok：不使用全域狀態，支援空欄位，線程安全
        } else if (fname.equals("strsep")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": strsep() takes 2 arguments."); $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                // 第一個參數需要是 char**（i8**），即指向 char* 的指標
                Info spInfo = null;
                for (java.util.Map.Entry<String, Info> e : symtab.entrySet()) {
                    if (e.getValue().tmp.equals(givenArgs.get(0).tmp)) { spInfo = e.getValue(); break; }
                }
                String stringpPtr = (spInfo != null) ? spInfo.tmp : givenArgs.get(0).tmp;
                String delim = givenArgs.get(1).tmp;
                String r = newTemp(); addInstruction(r + " = call i8* @strsep(i8** " + stringpPtr + ", i8* " + delim + ")");
                charPtrTemps.add(r); $type = TypeInfo.Pointer; $tmp = r;
            }

        // asprintf(&ptr, fmt, ...)：自動配置記憶體的 sprintf，回傳 i32 長度
        } else if (fname.equals("asprintf")) {
            if (givenArgs.size() < 2) {
                System.err.println("Error! " + $id.getLine() + ": asprintf() takes at least 2 arguments."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                Info ptrInfo = givenArgs.get(0);
                // ptrInfo.tmp 是 alloca i8*（即 i8**），直接使用
                String ptrArgI8pp = ptrInfo.tmp;
                String fmtArg = givenArgs.get(1).tmp;
                StringBuilder asb = new StringBuilder();
                String r = newTemp();
                asb.append(r).append(" = call i32 (i8**, i8*, ...) @asprintf(i8** ").append(ptrArgI8pp)
                   .append(", i8* ").append(fmtArg);
                for (int ai2 = 2; ai2 < givenArgs.size(); ai2++) {
                    Info aInf = givenArgs.get(ai2);
                    asb.append(", ");
                    if (aInf.theType == TypeInfo.Float) {
                        String prom = newTemp(); addInstruction(prom + " = fpext float " + aInf.tmp + " to double");
                        asb.append("double ").append(prom);
                    } else {
                        asb.append(toLLVMType(aInf.theType)).append(" ").append(aInf.tmp);
                    }
                }
                asb.append(")");
                addInstruction(asb.toString());
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── ✨ setjmp / longjmp（非局部跳轉）──────────────────────────────────

        // setjmp(env)：儲存執行環境，首次呼叫回傳 0；longjmp 還原後回傳非 0
        } else if (fname.equals("setjmp")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": setjmp() takes 1 argument."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String env = givenArgs.get(0).tmp;
                String envI8 = newTemp();
                String envT = exactTypeMap.containsKey(env) ? exactTypeMap.get(env) : "%struct.__jmp_buf*";
                addInstruction(envI8 + " = bitcast " + envT + " " + env + " to i8*");
                String r = newTemp(); addInstruction(r + " = call i32 @setjmp(i8* " + envI8 + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // longjmp(env, val)：還原 setjmp 環境，讓 setjmp 回傳 val（val=0 時視為 1）
        } else if (fname.equals("longjmp")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": longjmp() takes 2 arguments."); $type = TypeInfo.Void; $tmp = "0";
            } else {
                String env = givenArgs.get(0).tmp;
                String val = givenArgs.get(1).tmp; TypeInfo vt = givenArgs.get(1).theType;
                String envI8 = newTemp();
                String envT = exactTypeMap.containsKey(env) ? exactTypeMap.get(env) : "%struct.__jmp_buf*";
                addInstruction(envI8 + " = bitcast " + envT + " " + env + " to i8*");
                if (bitWidth(vt) != 32) { String c=newTemp(); addInstruction(c+" = trunc "+toLLVMType(vt)+" "+val+" to i32"); val=c; }
                addInstruction("call void @longjmp(i8* " + envI8 + ", i32 " + val + ")");
                addInstruction("unreachable");
                lastInstrIsTerminator = true;
                $type = TypeInfo.Void; $tmp = "0";
            }

        } else if (fname.equals("va_start")) {
            if (givenArgs.size() == 2) {
                String apI8 = givenArgs.get(0).tmp; // 已是 i8*（bitcast [24 x i8]* → i8*）
                addInstruction("call void @llvm.va_start(i8* " + apI8 + ")");
            }
            $type = TypeInfo.Void; $tmp = "0";

        } else if (fname.equals("va_end")) {
            if (givenArgs.size() == 1) {
                String apI8 = givenArgs.get(0).tmp;
                addInstruction("call void @llvm.va_end(i8* " + apI8 + ")");
            }
            $type = TypeInfo.Void; $tmp = "0";

        } else if (fname.equals("va_copy")) {
            if (givenArgs.size() == 2) {
                String dstI8 = givenArgs.get(0).tmp;
                String srcI8 = givenArgs.get(1).tmp;
                addInstruction("call void @llvm.va_copy(i8* " + dstI8 + ", i8* " + srcI8 + ")");
            }
            $type = TypeInfo.Void; $tmp = "0";

        } else if (fname.equals("vprintf") || fname.equals("vfprintf")
                || fname.equals("vsprintf") || fname.equals("vsnprintf")) {
            int minArgs = fname.equals("vprintf") ? 2
                        : fname.equals("vfprintf") ? 3
                        : fname.equals("vsprintf") ? 3 : 4;
            if (givenArgs.size() < minArgs) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes " + minArgs + " arguments.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String r = newTemp();
                StringBuilder callSB = new StringBuilder(r + " = call i32 @" + fname + "(");
                int ai = 0;
                if (fname.equals("vfprintf")) {
                    callSB.append("i8* ").append(toFilePtr(givenArgs.get(ai++))).append(", ");
                }
                if (fname.equals("vsprintf") || fname.equals("vsnprintf")) {
                    callSB.append("i8* ").append(givenArgs.get(ai++).tmp).append(", ");
                }
                if (fname.equals("vsnprintf")) {
                    String n = givenArgs.get(ai).tmp; TypeInfo nt = givenArgs.get(ai++).theType;
                    if (bitWidth(nt) < 64) { String c=newTemp(); addInstruction(c+" = sext "+toLLVMType(nt)+" "+n+" to i64"); n=c; }
                    callSB.append("i64 ").append(n).append(", ");
                }
                // fmt
                callSB.append("i8* ").append(givenArgs.get(ai++).tmp).append(", ");
                // va_list → i8*
                String ap = givenArgs.get(ai).tmp;
                String apT = exactTypeMap.containsKey(ap) ? exactTypeMap.get(ap) : "i8*";
                String apI8 = "i8*".equals(apT) ? ap : newTemp();
                if (!"i8*".equals(apT)) addInstruction(apI8 + " = bitcast " + apT + " " + ap + " to i8*");
                callSB.append("i8* ").append(apI8).append(")");
                addInstruction(callSB.toString());
                $type = TypeInfo.Int; $tmp = r;
            }
        } else if (fname.equals("exit")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": exit() takes 1 argument.");
                $type = TypeInfo.Void; $tmp = "0";
            } else {
                String code = givenArgs.get(0).tmp;
                TypeInfo codeT = givenArgs.get(0).theType;
                if (codeT == TypeInfo.Float || codeT == TypeInfo.Double) {
                    String conv = newTemp(); addInstruction(conv + " = fptosi " + toLLVMType(codeT) + " " + code + " to i32"); code = conv;
                }
                addInstruction("call void @exit(i32 " + code + ")");
                // exit 是 noreturn，插入 unreachable 防 LLVM 報錯
                addInstruction("unreachable");
                lastInstrIsTerminator = true;
                $type = TypeInfo.Void; $tmp = "0";
            }

        // ── ctype.h：isdigit / isalpha / isalnum / isspace / isupper / islower / isprint / ispunct ──
        } else if (fname.equals("isdigit") || fname.equals("isalpha") || fname.equals("isalnum") ||
                   fname.equals("isspace") || fname.equals("isupper") || fname.equals("islower") ||
                   fname.equals("isprint") || fname.equals("ispunct") ||
                   fname.equals("isxdigit") || fname.equals("isblank") ||
                   fname.equals("iscntrl") || fname.equals("isgraph") ||
                   fname.equals("toupper") || fname.equals("tolower")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String arg = givenArgs.get(0).tmp;
                TypeInfo argT = givenArgs.get(0).theType;
                // char → sext to i32
                if (argT == TypeInfo.Char) {
                    String conv = newTemp(); addInstruction(conv + " = sext i8 " + arg + " to i32"); arg = conv;
                }
                String r = newTemp();
                addInstruction(r + " = call i32 @" + fname + "(i32 " + arg + ")");
                $type = TypeInfo.Int; $tmp = r;
            }

        // ── toupper / tolower ──
        } else if (fname.equals("toupper") || fname.equals("tolower")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String arg = givenArgs.get(0).tmp;
                TypeInfo argT = givenArgs.get(0).theType;
                if (argT == TypeInfo.Char) {
                    String conv = newTemp(); addInstruction(conv + " = sext i8 " + arg + " to i32"); arg = conv;
                }
                String r = newTemp();
                addInstruction(r + " = call i32 @" + fname + "(i32 " + arg + ")");
                // 回傳 i32，但語意上是 char；讓使用者決定如何用
                $type = TypeInfo.Int; $tmp = r;
            }
        }
        // ── fmod(x, y) → float ──
        else if (fname.equals("fmin") || fname.equals("fmax")
                || fname.equals("fma") || fname.equals("fdim") || fname.equals("copysign")) {
            int expectedArgs = fname.equals("fma") ? 3 : 2;
            if (givenArgs.size() != expectedArgs) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes " + expectedArgs + " argument(s).");
                $type = TypeInfo.Double; $tmp = "0.0";
            } else {
                StringBuilder callSB = new StringBuilder();
                String r = newTemp();
                callSB.append(r).append(" = call double @").append(fname).append("(");
                for (int ai = 0; ai < givenArgs.size(); ai++) {
                    if (ai > 0) callSB.append(", ");
                    String a = givenArgs.get(ai).tmp; TypeInfo at = givenArgs.get(ai).theType;
                    String ad;
                    if (isIntegerType(at)) { ad = newTemp(); addInstruction(ad + " = sitofp " + toLLVMType(at) + " " + a + " to double"); }
                    else if (at == TypeInfo.Float) { ad = newTemp(); addInstruction(ad + " = fpext float " + a + " to double"); }
                    else ad = a;
                    callSB.append("double ").append(ad);
                }
                callSB.append(")");
                addInstruction(callSB.toString());
                $type = TypeInfo.Double; $tmp = r;
            }
        // ── isnan / isinf / isfinite / signbit → i32 ──
        } else if (fname.equals("isnan") || fname.equals("isinf")
                || fname.equals("isfinite") || fname.equals("signbit")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String a = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String ad;
                if (isIntegerType(at)) { ad = newTemp(); addInstruction(ad + " = sitofp " + toLLVMType(at) + " " + a + " to double"); }
                else if (at == TypeInfo.Float) { ad = newTemp(); addInstruction(ad + " = fpext float " + a + " to double"); }
                else ad = a;
                String internalFn = fname.equals("isnan") ? "__isnan"
                                  : fname.equals("isinf") ? "__isinf"
                                  : fname.equals("signbit") ? "__signbit" : "__finite";
                String r = newTemp(); addInstruction(r + " = call i32 @" + internalFn + "(double " + ad + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── getenv(name) → i8* ──
        } else if (fname.equals("getenv")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": getenv() takes 1 argument.");
                $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String a0 = givenArgs.get(0).tmp;
                String r = newTemp(); addInstruction(r + " = call i8* @getenv(i8* " + a0 + ")");
                charPtrTemps.add(r); exactTypeMap.put(r, "i8*");
                $type = TypeInfo.Pointer; $tmp = r;
            }
        // ── putenv(str) → i32 ──
        } else if (fname.equals("putenv")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": putenv() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String a0 = givenArgs.get(0).tmp;
                String r = newTemp(); addInstruction(r + " = call i32 @putenv(i8* " + a0 + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── system(cmd) → i32 ──
        } else if (fname.equals("system")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": system() takes 1 argument.");
                $type = TypeInfo.Int; $tmp = "0";
            } else {
                String a0 = givenArgs.get(0).tmp;
                String r = newTemp(); addInstruction(r + " = call i32 @system(i8* " + a0 + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── atexit(fn) → i32 ──
        } else if (fname.equals("atexit")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": atexit() takes 1 argument."); $type = TypeInfo.Int; $tmp = "0";
            } else {
                String a0 = givenArgs.get(0).tmp;
                String a0T = exactTypeMap.containsKey(a0) ? exactTypeMap.get(a0) : "i8*";
                String fnI8 = "i8*".equals(a0T) ? a0 : newTemp();
                if (!"i8*".equals(a0T)) addInstruction(fnI8 + " = bitcast " + a0T + " " + a0 + " to i8*");
                String r = newTemp(); addInstruction(r + " = call i32 @atexit(i8* " + fnI8 + ")");
                $type = TypeInfo.Int; $tmp = r;
            }
        // ── _exit(status) → void ──
        } else if (fname.equals("_exit")) {
            String a0 = givenArgs.size() > 0 ? givenArgs.get(0).tmp : "0";
            TypeInfo t0 = givenArgs.size() > 0 ? givenArgs.get(0).theType : TypeInfo.Int;
            if (t0 == TypeInfo.Long) { String c = newTemp(); addInstruction(c + " = trunc i64 " + a0 + " to i32"); a0 = c; }
            addInstruction("call void @_exit(i32 " + a0 + ")");
            addInstruction("unreachable");
            $type = TypeInfo.Void; $tmp = "0";
        // ── fmod (既有，下方保留) ──
        } else if (fname.equals("fmod")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": fmod() takes 2 arguments.");
                $type = TypeInfo.Float; $tmp = "0";
            } else {
                String a1 = givenArgs.get(0).tmp; TypeInfo t1 = givenArgs.get(0).theType;
                String a2 = givenArgs.get(1).tmp; TypeInfo t2 = givenArgs.get(1).theType;
                String ad1 = a1, ad2 = a2;
                if (t1 == TypeInfo.Int)   { ad1 = newTemp(); addInstruction(ad1 + " = sitofp i32 " + a1 + " to double"); }
                else if (t1 == TypeInfo.Float) { ad1 = newTemp(); addInstruction(ad1 + " = fpext float " + a1 + " to double"); }
                if (t2 == TypeInfo.Int)   { ad2 = newTemp(); addInstruction(ad2 + " = sitofp i32 " + a2 + " to double"); }
                else if (t2 == TypeInfo.Float) { ad2 = newTemp(); addInstruction(ad2 + " = fpext float " + a2 + " to double"); }
                String rd = newTemp(); addInstruction(rd + " = call double @fmod(double " + ad1 + ", double " + ad2 + ")");
                String rf = newTemp(); addInstruction(rf + " = fptrunc double " + rd + " to float");
                $type = TypeInfo.Float; $tmp = rf;
            }
        } else if (fname.equals("sqrt") || fname.equals("fabs") || fname.equals("floor") ||
                   fname.equals("ceil")  || fname.equals("sin")  || fname.equals("cos")  ||
                   fname.equals("log")   || fname.equals("tan")  || fname.equals("asin") ||
                   fname.equals("acos")  || fname.equals("atan") || fname.equals("sinh") ||
                   fname.equals("cosh")  || fname.equals("tanh") || fname.equals("exp")  ||
                   fname.equals("exp2")  || fname.equals("log2") || fname.equals("log10")||
                   fname.equals("cbrt")  || fname.equals("round")|| fname.equals("trunc")||
                   fname.equals("nearbyint")) {
            // math.h 單引數：接受 int / float / double，統一提升到 double，回傳 double
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                $type = TypeInfo.Double; $tmp = "0.0";
            } else {
                String a = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String ad;
                if (at == TypeInfo.Int || isIntegerType(at))
                    { ad = newTemp(); addInstruction(ad + " = sitofp " + toLLVMType(at) + " " + a + " to double"); }
                else if (at == TypeInfo.Float)
                    { ad = newTemp(); addInstruction(ad + " = fpext float " + a + " to double"); }
                else ad = a;
                String rd = newTemp(); addInstruction(rd + " = call double @" + fname + "(double " + ad + ")");
                $type = TypeInfo.Double; $tmp = rd;
            }
        // ── lround / llround：double → i64 ──
        } else if (fname.equals("lround") || fname.equals("llround")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                $type = TypeInfo.Long; $tmp = "0";
            } else {
                String a = givenArgs.get(0).tmp; TypeInfo at = givenArgs.get(0).theType;
                String ad;
                if (isIntegerType(at))
                    { ad = newTemp(); addInstruction(ad + " = sitofp " + toLLVMType(at) + " " + a + " to double"); }
                else if (at == TypeInfo.Float)
                    { ad = newTemp(); addInstruction(ad + " = fpext float " + a + " to double"); }
                else ad = a;
                String r = newTemp(); addInstruction(r + " = call i64 @" + fname + "(double " + ad + ")");
                $type = TypeInfo.Long; $tmp = r;
            }
        } else if (fname.equals("pow") || fname.equals("atan2") || fname.equals("hypot")) {
            // math.h 雙引數：pow(base,exp) / atan2(y,x) / hypot(x,y)
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 2 arguments.");
                $type = TypeInfo.Double; $tmp = "0.0";
            } else {
                String a1 = givenArgs.get(0).tmp; TypeInfo t1 = givenArgs.get(0).theType;
                String a2 = givenArgs.get(1).tmp; TypeInfo t2 = givenArgs.get(1).theType;
                String ad1 = a1; String ad2 = a2;
                if (isIntegerType(t1)) { ad1 = newTemp(); addInstruction(ad1 + " = sitofp " + toLLVMType(t1) + " " + a1 + " to double"); }
                else if (t1 == TypeInfo.Float) { ad1 = newTemp(); addInstruction(ad1 + " = fpext float " + a1 + " to double"); }
                if (isIntegerType(t2)) { ad2 = newTemp(); addInstruction(ad2 + " = sitofp " + toLLVMType(t2) + " " + a2 + " to double"); }
                else if (t2 == TypeInfo.Float) { ad2 = newTemp(); addInstruction(ad2 + " = fpext float " + a2 + " to double"); }
                String rd = newTemp(); addInstruction(rd + " = call double @" + fname + "(double " + ad1 + ", double " + ad2 + ")");
                $type = TypeInfo.Double; $tmp = rd;
            }
        // ── difftime(time1, time0) → double ──
        } else if (fname.equals("difftime")) {
            if (givenArgs.size() != 2) {
                System.err.println("Error! " + $id.getLine() + ": difftime() takes 2 arguments.");
                $type = TypeInfo.Double; $tmp = "0.0";
            } else {
                String a0 = givenArgs.get(0).tmp; TypeInfo t0 = givenArgs.get(0).theType;
                String a1 = givenArgs.get(1).tmp; TypeInfo t1 = givenArgs.get(1).theType;
                if (t0 == TypeInfo.Int) { String c = newTemp(); addInstruction(c + " = sext i32 " + a0 + " to i64"); a0 = c; }
                if (t1 == TypeInfo.Int) { String c = newTemp(); addInstruction(c + " = sext i32 " + a1 + " to i64"); a1 = c; }
                String r = newTemp(); addInstruction(r + " = call double @difftime(i64 " + a0 + ", i64 " + a1 + ")");
                $type = TypeInfo.Double; $tmp = r;
            }
        // ── qsort(base, nmemb, size, comparator) → void ──
        } else if (fname.equals("qsort")) {
            if (givenArgs.size() != 4) {
                System.err.println("Error! " + $id.getLine() + ": qsort() takes 4 arguments (base, nmemb, size, cmp).");
                $type = TypeInfo.Void; $tmp = "0";
            } else {
                // arg0: base ptr → bitcast to i8*
                Info arg0 = givenArgs.get(0);
                String baseTmp = arg0.tmp;
                String baseI8;
                if (charPtrTemps.contains(baseTmp) || "i8*".equals(exactTypeMap.get(baseTmp))) {
                    baseI8 = baseTmp;
                } else {
                    String srcPtrT = exactTypeMap.containsKey(baseTmp) ? exactTypeMap.get(baseTmp)
                                   : (toLLVMType(arg0.theType) + "*");
                    baseI8 = newTemp();
                    addInstruction(baseI8 + " = bitcast " + srcPtrT + " " + baseTmp + " to i8*");
                }
                // arg1: nmemb (i64)
                String nm = givenArgs.get(1).tmp; TypeInfo nt = givenArgs.get(1).theType;
                if (isIntegerType(nt) && bitWidth(nt) < 64) { String c = newTemp(); addInstruction(c + " = sext " + toLLVMType(nt) + " " + nm + " to i64"); nm = c; }
                // arg2: element size (i64)
                String sz = givenArgs.get(2).tmp; TypeInfo st = givenArgs.get(2).theType;
                if (isIntegerType(st) && bitWidth(st) < 64) { String c = newTemp(); addInstruction(c + " = sext " + toLLVMType(st) + " " + sz + " to i64"); sz = c; }
                // arg3: comparator → 實際型別 → i32(i8*,i8*)* → i8*
                Info arg3 = givenArgs.get(3);
                String cmpTmp = arg3.tmp;
                String cmpI8;
                {
                    String cmpT = exactTypeMap.containsKey(cmpTmp) ? exactTypeMap.get(cmpTmp) : "i8*";
                    if ("i8*".equals(cmpT)) {
                        cmpI8 = cmpTmp;
                    } else if (arg3.isPointer && arg3.structName != null && arg3.structName.contains("(")) {
                        String fpT = arg3.structName;
                        String fpLoaded = newTemp(); addInstruction(fpLoaded + " = load " + fpT + ", " + fpT + "* " + cmpTmp + ", align 8");
                        String mid = newTemp(); addInstruction(mid + " = bitcast " + fpT + " " + fpLoaded + " to i32 (i8*, i8*)*");
                        cmpI8 = newTemp(); addInstruction(cmpI8 + " = bitcast i32 (i8*, i8*)* " + mid + " to i8*");
                    } else {
                        String mid = newTemp(); addInstruction(mid + " = bitcast " + cmpT + " " + cmpTmp + " to i32 (i8*, i8*)*");
                        cmpI8 = newTemp(); addInstruction(cmpI8 + " = bitcast i32 (i8*, i8*)* " + mid + " to i8*");
                    }
                }
                addInstruction("call void @qsort(i8* " + baseI8 + ", i64 " + nm + ", i64 " + sz + ", i8* " + cmpI8 + ")");
                $type = TypeInfo.Void; $tmp = "0";
            }
        // ── bsearch(key, base, nmemb, size, cmp) → i8* ──
        } else if (fname.equals("bsearch")) {
            if (givenArgs.size() != 5) {
                System.err.println("Error! " + $id.getLine() + ": bsearch() takes 5 arguments.");
                $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                // key → i8*
                Info arg0 = givenArgs.get(0);
                String keyI8;
                if (charPtrTemps.contains(arg0.tmp) || "i8*".equals(exactTypeMap.get(arg0.tmp))) {
                    keyI8 = arg0.tmp;
                } else {
                    String srcT = exactTypeMap.containsKey(arg0.tmp) ? exactTypeMap.get(arg0.tmp)
                                : (toLLVMType(arg0.theType) + "*");
                    keyI8 = newTemp(); addInstruction(keyI8 + " = bitcast " + srcT + " " + arg0.tmp + " to i8*");
                }
                // base → i8*
                Info arg1 = givenArgs.get(1);
                String baseI8;
                if (charPtrTemps.contains(arg1.tmp) || "i8*".equals(exactTypeMap.get(arg1.tmp))) {
                    baseI8 = arg1.tmp;
                } else {
                    String srcT = exactTypeMap.containsKey(arg1.tmp) ? exactTypeMap.get(arg1.tmp)
                                : (toLLVMType(arg1.theType) + "*");
                    baseI8 = newTemp(); addInstruction(baseI8 + " = bitcast " + srcT + " " + arg1.tmp + " to i8*");
                }
                String nm = givenArgs.get(2).tmp; TypeInfo nt = givenArgs.get(2).theType;
                if (isIntegerType(nt) && bitWidth(nt) < 64) { String c = newTemp(); addInstruction(c + " = sext " + toLLVMType(nt) + " " + nm + " to i64"); nm = c; }
                String sz = givenArgs.get(3).tmp; TypeInfo st = givenArgs.get(3).theType;
                if (isIntegerType(st) && bitWidth(st) < 64) { String c = newTemp(); addInstruction(c + " = sext " + toLLVMType(st) + " " + sz + " to i64"); sz = c; }
                Info arg4 = givenArgs.get(4);
                String cmpI8;
                {
                    String cmpT4 = exactTypeMap.containsKey(arg4.tmp) ? exactTypeMap.get(arg4.tmp) : "i8*";
                    if ("i8*".equals(cmpT4)) {
                        cmpI8 = arg4.tmp;
                    } else if (arg4.isPointer && arg4.structName != null && arg4.structName.contains("(")) {
                        String fpT = arg4.structName;
                        String fpLoaded = newTemp(); addInstruction(fpLoaded + " = load " + fpT + ", " + fpT + "* " + arg4.tmp + ", align 8");
                        String mid = newTemp(); addInstruction(mid + " = bitcast " + fpT + " " + fpLoaded + " to i32 (i8*, i8*)*");
                        cmpI8 = newTemp(); addInstruction(cmpI8 + " = bitcast i32 (i8*, i8*)* " + mid + " to i8*");
                    } else {
                        String mid = newTemp(); addInstruction(mid + " = bitcast " + cmpT4 + " " + arg4.tmp + " to i32 (i8*, i8*)*");
                        cmpI8 = newTemp(); addInstruction(cmpI8 + " = bitcast i32 (i8*, i8*)* " + mid + " to i8*");
                    }
                }
                String r = newTemp();
                addInstruction(r + " = call i8* @bsearch(i8* " + keyI8 + ", i8* " + baseI8 + ", i64 " + nm + ", i64 " + sz + ", i8* " + cmpI8 + ")");
                charPtrTemps.add(r); exactTypeMap.put(r, "i8*");
                $type = TypeInfo.Pointer; $tmp = r;
            }
        // ── localtime(time_t*) / gmtime(time_t*) → struct tm* ──
        } else if (fname.equals("localtime") || fname.equals("gmtime")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument (time_t*).");
                $type = TypeInfo.Pointer; $tmp = "null";
            } else {
                String a0 = givenArgs.get(0).tmp;
                // time_t* — 若傳入的是 i64 alloca ptr 直接使用，否則需要轉型
                String timePtrT = exactTypeMap.containsKey(a0) ? exactTypeMap.get(a0) : "i64*";
                String timeI64Ptr;
                if ("i64*".equals(timePtrT)) {
                    timeI64Ptr = a0;
                } else {
                    timeI64Ptr = newTemp(); addInstruction(timeI64Ptr + " = bitcast " + timePtrT + " " + a0 + " to i64*");
                }
                String r = newTemp();
                addInstruction(r + " = call %struct.tm* @" + fname + "(i64* " + timeI64Ptr + ")");
                exactTypeMap.put(r, "%struct.tm*");
                // 回傳 Info 讓 -> 存取知道是 struct tm
                Info tmInfo = new Info(); tmInfo.theType = TypeInfo.Pointer;
                tmInfo.structName = "tm"; tmInfo.isPointer = true; tmInfo.pointeeType = TypeInfo.Struct;
                $type = TypeInfo.Pointer; $tmp = r;
                exactTypeMap.put(r, "%struct.tm*");
            }
        // ── mktime(struct tm*) → time_t (i64) ──
        } else if (fname.equals("mktime")) {
            if (givenArgs.size() != 1) {
                System.err.println("Error! " + $id.getLine() + ": mktime() takes 1 argument (struct tm*).");
                $type = TypeInfo.Long; $tmp = "0";
            } else {
                String a0 = givenArgs.get(0).tmp;
                String tmPtr;
                String a0T = exactTypeMap.containsKey(a0) ? exactTypeMap.get(a0) : "%struct.tm*";
                if ("%struct.tm*".equals(a0T)) {
                    tmPtr = a0;
                } else {
                    tmPtr = newTemp(); addInstruction(tmPtr + " = bitcast " + a0T + " " + a0 + " to %struct.tm*");
                }
                String r = newTemp(); addInstruction(r + " = call i64 @mktime(%struct.tm* " + tmPtr + ")");
                $type = TypeInfo.Long; $tmp = r;
            }
        // ── strftime(buf, maxsize, format, tm*) → i64 ──
        } else if (fname.equals("strftime")) {
            if (givenArgs.size() != 4) {
                System.err.println("Error! " + $id.getLine() + ": strftime() takes 4 arguments (buf, maxsize, fmt, tm*).");
                $type = TypeInfo.Long; $tmp = "0";
            } else {
                String buf = givenArgs.get(0).tmp;
                String maxsz = givenArgs.get(1).tmp; TypeInfo mst = givenArgs.get(1).theType;
                String fmt = givenArgs.get(2).tmp;
                String tmPtr = givenArgs.get(3).tmp;
                if (isIntegerType(mst) && bitWidth(mst) < 64) { String c = newTemp(); addInstruction(c + " = sext " + toLLVMType(mst) + " " + maxsz + " to i64"); maxsz = c; }
                // tm* bitcast if needed
                String tmT = exactTypeMap.containsKey(tmPtr) ? exactTypeMap.get(tmPtr) : "%struct.tm*";
                if (!"%struct.tm*".equals(tmT)) {
                    String c = newTemp(); addInstruction(c + " = bitcast " + tmT + " " + tmPtr + " to %struct.tm*"); tmPtr = c;
                }
                String r = newTemp();
                addInstruction(r + " = call i64 @strftime(i8* " + buf + ", i64 " + maxsz + ", i8* " + fmt + ", %struct.tm* " + tmPtr + ")");
                $type = TypeInfo.Long; $tmp = r;
            }
        } else if (fname.equals("strtol") || fname.equals("strtoll") || fname.equals("strtoul")) {
            // strtol(str, &endptr, base) → i64
            if (givenArgs.size() != 3) { System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 3 arguments."); $type = TypeInfo.Long; $tmp = "0"; }
            else {
                String a0 = givenArgs.get(0).tmp;
                String a1 = givenArgs.get(1).tmp; // i8** (endptr 的位址)
                String a2 = givenArgs.get(2).tmp; TypeInfo t2 = givenArgs.get(2).theType;
                // base 必須是 i32
                if (t2 == TypeInfo.Long) { String c = newTemp(); addInstruction(c + " = trunc i64 " + a2 + " to i32"); a2 = c; }
                String result = newTemp();
                addInstruction(result + " = call i64 @" + fname + "(i8* " + a0 + ", i8** " + a1 + ", i32 " + a2 + ")");
                $type = TypeInfo.Long; $tmp = result;
            }
        } else if (fname.equals("strtod")) {
            // strtod(str, &endptr) → double
            if (givenArgs.size() != 2) { System.err.println("Error! " + $id.getLine() + ": strtod() takes 2 arguments."); $type = TypeInfo.Double; $tmp = "0"; }
            else {
                String a0 = givenArgs.get(0).tmp;
                String a1 = givenArgs.get(1).tmp;
                String result = newTemp();
                addInstruction(result + " = call double @strtod(i8* " + a0 + ", i8** " + a1 + ")");
                $type = TypeInfo.Double; $tmp = result;
            }
        } else if (fname.equals("strtof")) {
            // strtof(str, &endptr) → float
            if (givenArgs.size() != 2) { System.err.println("Error! " + $id.getLine() + ": strtof() takes 2 arguments."); $type = TypeInfo.Float; $tmp = "0"; }
            else {
                String a0 = givenArgs.get(0).tmp;
                String a1 = givenArgs.get(1).tmp;
                String result = newTemp();
                addInstruction(result + " = call float @strtof(i8* " + a0 + ", i8** " + a1 + ")");
                $type = TypeInfo.Float; $tmp = result;
            }
        } else if (fname.equals("rand")) {
            // rand() → i32
            String result = newTemp();
            addInstruction(result + " = call i32 @rand()");
            $type = TypeInfo.Int; $tmp = result;
        } else if (fname.equals("srand")) {
            // srand(seed)
            if (givenArgs.size() != 1) { System.err.println("Error! " + $id.getLine() + ": srand() takes 1 argument."); $type = TypeInfo.Void; $tmp = "0"; }
            else {
                String a0 = givenArgs.get(0).tmp; TypeInfo t0 = givenArgs.get(0).theType;
                if (t0 == TypeInfo.Long) { String c = newTemp(); addInstruction(c + " = trunc i64 " + a0 + " to i32"); a0 = c; }
                addInstruction("call void @srand(i32 " + a0 + ")");
                $type = TypeInfo.Void; $tmp = "0";
            }
        } else if (fname.equals("labs") || fname.equals("llabs")) {
            // labs(long) / llabs(long long) → i64
            if (givenArgs.size() != 1) { System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument."); $type = TypeInfo.Long; $tmp = "0"; }
            else {
                String a0 = givenArgs.get(0).tmp; TypeInfo t0 = givenArgs.get(0).theType;
                if (t0 == TypeInfo.Int) { String c = newTemp(); addInstruction(c + " = sext i32 " + a0 + " to i64"); a0 = c; }
                String result = newTemp();
                addInstruction(result + " = call i64 @" + fname + "(i64 " + a0 + ")");
                $type = TypeInfo.Long; $tmp = result;
            }
        } else if (fname.equals("time")) {
            // time(NULL) or time(ptr) → i64
            String a0 = (givenArgs.size() > 0) ? givenArgs.get(0).tmp : "null";
            String result = newTemp();
            addInstruction(result + " = call i64 @time(i8* " + a0 + ")");
            $type = TypeInfo.Long; $tmp = result;
        } else if (!funcRegistry.containsKey(fname) && !fname.equals("memset") && !fname.equals("memcpy") && !fname.equals("memcmp")
                   && !fname.equals("memmove") && !fname.equals("memchr") && !fname.equals("strspn") && !fname.equals("strcspn") && !fname.equals("strpbrk")) {
            // ── 函式指標呼叫：fp(args) ──
            Info fpInfo = symtab.get(fname);
            if (fpInfo == null) fpInfo = globalSymtab.get(fname);
            if (fpInfo != null && fpInfo.isPointer && fpInfo.structName != null && fpInfo.structName.contains("(")) {
                String fpType = fpInfo.structName; // e.g. "i32 (i32, i32)*"
                String fpVal = newTemp();
                addInstruction(fpVal + " = load " + fpType + ", " + fpType + "* " + fpInfo.tmp + ", align 8");
                // 函式型別 = 去掉末尾 '*'
                String callType = fpType.endsWith("*") ? fpType.substring(0, fpType.length() - 1) : fpType;
                StringBuilder fpCall = new StringBuilder();
                boolean fpReturnsVoid = callType.startsWith("void");
                String fpResult = fpReturnsVoid ? null : newTemp();
                // ── Bug 1 修正：void 回傳不能有 "%tN = " 前綴 ──
                if (!fpReturnsVoid) {
                    fpCall.append(fpResult).append(" = ");
                }
                fpCall.append("call ").append(callType).append(" ").append(fpVal).append("(");
                if ($callArgs.ctx != null) {
                    for (int ai = 0; ai < givenArgs.size(); ai++) {
                        if (ai > 0) fpCall.append(", ");
                        Info aInfo = givenArgs.get(ai);
                        String aLLVM = toLLVMType(aInfo.theType);
                        if (aInfo.theType == TypeInfo.Float) {
                            String ext = newTemp(); addInstruction(ext + " = fpext float " + aInfo.tmp + " to double");
                            fpCall.append("double ").append(ext);
                        } else {
                            fpCall.append(aLLVM).append(" ").append(aInfo.tmp);
                        }
                    }
                }
                fpCall.append(")");
                addInstruction(fpCall.toString());
                if (fpReturnsVoid) { $type = TypeInfo.Void; $tmp = "0"; }
                else if (callType.startsWith("float") || callType.startsWith("double")) { $type = TypeInfo.Float; $tmp = fpResult; }
                else { $type = TypeInfo.Int; $tmp = fpResult; }
            } else if (fname.equals("__builtin_popcount") || fname.equals("__builtin_popcountl")
                    || fname.equals("__builtin_popcountll")) {
                // ✨ popcount：計算整數中 1 的個數，映射至 LLVM llvm.ctpop intrinsic
                if (givenArgs.size() != 1) {
                    System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                    $type = TypeInfo.Int; $tmp = "0";
                } else {
                    Info aInfo = givenArgs.get(0);
                    // ── Fix 4：改用 endsWith 判斷後綴，避免 "builtin" 裡的 'l' 誤判 ──
                    boolean isLong = fname.endsWith("ll") || fname.endsWith("l") || aInfo.theType == TypeInfo.Long;
                    String llvmT = isLong ? "i64" : "i32";
                    String aVal = aInfo.tmp;
                    if (!isLong && isIntegerType(aInfo.theType) && aInfo.theType != TypeInfo.Int) {
                        String ext = newTemp(); addInstruction(ext + " = sext " + toLLVMType(aInfo.theType) + " " + aVal + " to i32"); aVal = ext;
                    } else if (isLong && aInfo.theType == TypeInfo.Int) {
                        String ext = newTemp(); addInstruction(ext + " = sext i32 " + aVal + " to i64"); aVal = ext;
                    }
                    String r = newTemp();
                    addInstruction(r + " = call " + llvmT + " @llvm.ctpop." + llvmT + "(" + llvmT + " " + aVal + ")");
                    if (isLong) {
                        String tr = newTemp(); addInstruction(tr + " = trunc i64 " + r + " to i32"); r = tr;
                    }
                    $type = TypeInfo.Int; $tmp = r;
                }
            } else if (fname.equals("__builtin_clz") || fname.equals("__builtin_clzl")
                    || fname.equals("__builtin_clzll")) {
                // ✨ clz：Count Leading Zeros，映射至 llvm.ctlz
                if (givenArgs.size() != 1) {
                    System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                    $type = TypeInfo.Int; $tmp = "0";
                } else {
                    Info aInfo = givenArgs.get(0);
                    // ── Fix 4：改用 endsWith 判斷後綴，避免 "builtin" 裡的 'l' 誤判 ──
                    boolean isLong = fname.endsWith("ll") || fname.endsWith("l") || aInfo.theType == TypeInfo.Long;
                    String llvmT = isLong ? "i64" : "i32";
                    String aVal = aInfo.tmp;
                    if (!isLong && isIntegerType(aInfo.theType) && aInfo.theType != TypeInfo.Int) {
                        String ext = newTemp(); addInstruction(ext + " = sext " + toLLVMType(aInfo.theType) + " " + aVal + " to i32"); aVal = ext;
                    } else if (isLong && aInfo.theType == TypeInfo.Int) {
                        String ext = newTemp(); addInstruction(ext + " = sext i32 " + aVal + " to i64"); aVal = ext;
                    }
                    String r = newTemp();
                    // is_zero_undef = false（安全版，不要求輸入非零）
                    addInstruction(r + " = call " + llvmT + " @llvm.ctlz." + llvmT + "(" + llvmT + " " + aVal + ", i1 false)");
                    if (isLong) {
                        String tr = newTemp(); addInstruction(tr + " = trunc i64 " + r + " to i32"); r = tr;
                    }
                    $type = TypeInfo.Int; $tmp = r;
                }
            } else if (fname.equals("__builtin_ctz") || fname.equals("__builtin_ctzl")
                    || fname.equals("__builtin_ctzll")) {
                // ✨ ctz：Count Trailing Zeros，映射至 llvm.cttz
                if (givenArgs.size() != 1) {
                    System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                    $type = TypeInfo.Int; $tmp = "0";
                } else {
                    Info aInfo = givenArgs.get(0);
                    // ── Fix 4：改用 endsWith 判斷後綴，避免 "builtin" 裡的 'l' 誤判 ──
                    boolean isLong = fname.endsWith("ll") || fname.endsWith("l") || aInfo.theType == TypeInfo.Long;
                    String llvmT = isLong ? "i64" : "i32";
                    String aVal = aInfo.tmp;
                    if (!isLong && isIntegerType(aInfo.theType) && aInfo.theType != TypeInfo.Int) {
                        String ext = newTemp(); addInstruction(ext + " = sext " + toLLVMType(aInfo.theType) + " " + aVal + " to i32"); aVal = ext;
                    } else if (isLong && aInfo.theType == TypeInfo.Int) {
                        String ext = newTemp(); addInstruction(ext + " = sext i32 " + aVal + " to i64"); aVal = ext;
                    }
                    String r = newTemp();
                    addInstruction(r + " = call " + llvmT + " @llvm.cttz." + llvmT + "(" + llvmT + " " + aVal + ", i1 false)");
                    if (isLong) {
                        String tr = newTemp(); addInstruction(tr + " = trunc i64 " + r + " to i32"); r = tr;
                    }
                    $type = TypeInfo.Int; $tmp = r;
                }
            } else if (fname.equals("__builtin_bswap16") || fname.equals("__builtin_bswap32")
                    || fname.equals("__builtin_bswap64")) {
                // ✨ bswap：位元組反轉，映射至 llvm.bswap
                if (givenArgs.size() != 1) {
                    System.err.println("Error! " + $id.getLine() + ": " + fname + "() takes 1 argument.");
                    $type = TypeInfo.Int; $tmp = "0";
                } else {
                    Info aInfo = givenArgs.get(0);
                    String bits = fname.contains("64") ? "i64" : fname.contains("16") ? "i16" : "i32";
                    String aVal = aInfo.tmp;
                    if (bits.equals("i32") && aInfo.theType != TypeInfo.Int) {
                        String ext = newTemp(); addInstruction(ext + " = sext " + toLLVMType(aInfo.theType) + " " + aVal + " to i32"); aVal = ext;
                    }
                    String r = newTemp();
                    addInstruction(r + " = call " + bits + " @llvm.bswap." + bits + "(" + bits + " " + aVal + ")");
                    $type = bits.equals("i64") ? TypeInfo.Long : TypeInfo.Int; $tmp = r;
                }
            } else {
                System.err.println("Error! " + $id.getLine() + ": Undeclared function " + fname + ".");
                $type = TypeInfo.Error; $tmp = "0";
            }
        } else {
            List<TypeInfo> sig = funcRegistry.get(fname);
            TypeInfo retType = sig.get(0);
            StringBuilder callInstr = new StringBuilder();
            int expectedParams = sig.size() - 1;
            
            // ✨ variadic 函式允許傳入 >= 固定參數數的引數
            boolean isUserVariadic = funcIsVariadic.containsKey(fname) && Boolean.TRUE.equals(funcIsVariadic.get(fname));
            String _vts = "";
            if (isUserVariadic) {
                List<TypeInfo> _ptR = funcPointerRegistry.get(fname);
                List<String>   _psR = funcPointerStructRegistry.get(fname);
                StringBuilder  _sb  = new StringBuilder(" (");
                for (int _i = 0; _i < expectedParams; _i++) {
                    if (_i > 0) _sb.append(", ");
                    TypeInfo _pt = sig.get(_i + 1);
                    if (_pt == TypeInfo.Pointer) {
                        TypeInfo _pe = (_ptR != null && _i < _ptR.size()) ? _ptR.get(_i) : null;
                        String   _ps = (_psR != null && _i < _psR.size()) ? _psR.get(_i) : null;
                        _sb.append(_pe != null ? toLLVMPtrType(_pe, _ps) : "i8*");
                    } else { _sb.append(toLLVMType(_pt)); }
                }
                _sb.append(", ...)");
                _vts = _sb.toString();
            }
            if (!isUserVariadic && givenArgs.size() != expectedParams) {
                System.err.println("Error! " + $id.getLine() + ": Function '" + fname + "' expects " + expectedParams + " argument(s), but " + givenArgs.size() + " provided.");
                $type = TypeInfo.Error;
                $tmp = "0";
            } else {
                if (retType == TypeInfo.Void) {
                    callInstr.append("call void").append(_vts).append(" @").append(fname).append("(");
                    $tmp = "0";
                    $type = TypeInfo.Void;
                } else if (retType == TypeInfo.Struct) {
                    // struct 回傳：需要 alloca 接收，用 structName
                    // 取得回傳 struct name（從 funcStructRetRegistry）
                    String retSname = funcStructRetRegistry.containsKey(fname) ? funcStructRetRegistry.get(fname) : null;
                    String retStructT = (retSname != null) ? "%struct." + retSname : "i32";
                    String result = newTemp();
                    callInstr.append(result).append(" = call ").append(retStructT).append(_vts).append(" @").append(fname).append("(");
                    $tmp = result;
                    $type = TypeInfo.Struct;
                } else if (retType == TypeInfo.Pointer) {
                   // ✨ 終極修正：精準查出函式真正回傳的指標型別（包含結構體名稱）✨
                    String llvmRetT;
                    if (funcRetPointeeRegistry.containsKey(fname)) {
                        TypeInfo pointeeT = funcRetPointeeRegistry.get(fname);
                        
                        // 檢查：如果這個指標是「指向結構體」，就去查結構體的名字！
                        if (pointeeT == TypeInfo.Struct && funcStructRetRegistry.containsKey(fname)) {
                            String sName = funcStructRetRegistry.get(fname);
                            llvmRetT = "%struct." + sName + "*"; // 手動拼出 %struct.Node*
                        } else {
                            // 如果是一般指標 (如 int*)，就交給 toLLVMPtrType
                            llvmRetT = toLLVMPtrType(pointeeT);
                        }
                    } else {
                        // 預設給未登記的函數，例如 malloc 預設通常是 i8*
                        llvmRetT = "i8*"; 
                    }
                    
                    String result = newTemp();
                    callInstr.append(result).append(" = call ").append(llvmRetT).append(_vts).append(" @").append(fname).append("(");
                    $tmp = result;
                    $type = TypeInfo.Pointer;
                    
                    // ✨ 記進小本本，確保後面解參考(-> 或 *)時不會又忘記型別 ✨
                    exactTypeMap.put(result, llvmRetT);
                } else {
                    // ── 一般純量型別 (int, float, char, double 等) ──
                    String result = newTemp();
                    callInstr.append(result).append(" = call ").append(toLLVMType(retType)).append(_vts).append(" @").append(fname).append("(");
                    $tmp = result;
                    $type = retType;
                    // （如果原本底下有 char 提升為 i32 的邏輯，請保留在這邊）
                }
                
                int fixedArgCount = isUserVariadic ? Math.min(givenArgs.size(), expectedParams) : givenArgs.size();
                for (int ci = 0; ci < fixedArgCount; ci++) {
                    if (ci > 0) callInstr.append(", ");
                    
                    TypeInfo expectedType = sig.get(ci + 1);
                    TypeInfo actualType = givenArgs.get(ci).theType;
                    String argTmp = givenArgs.get(ci).tmp;
                    
                    // ── 指標參數：取得正確的 pointeeType 來決定 LLVM 型別 ──
                    if (expectedType == TypeInfo.Pointer) {
                        List<TypeInfo> ptReg = funcPointerRegistry.get(fname);
                        List<String> psReg = funcPointerStructRegistry.get(fname);
                        TypeInfo pointee = (ptReg != null && ci < ptReg.size()) ? ptReg.get(ci) : null;

                        String pointeeStruct = (psReg != null && ci < psReg.size()) ? psReg.get(ci) : null;

                        // ✨ FIX: Check if pointeeStruct contains "()" to identify the function pointer signature
                        String expectedPtrType;
                        if (pointeeStruct != null && pointeeStruct.contains("(")) {
                            expectedPtrType = pointeeStruct;
                        } else if (pointeeStruct != null && pointeeStruct.startsWith("[") && pointeeStruct.endsWith("]*")) {
                            // ✨ 2D array param: structName IS the expected LLVM type, e.g. "[4 x i32]*"
                            expectedPtrType = pointeeStruct;
                        } else if (pointee != null) {
                            expectedPtrType = toLLVMPtrType(pointee, pointeeStruct);
                        } else {
                            expectedPtrType = "i8*";
                        }

                        // 決定實際傳入的指標型別
                        String actualPtrType = null;
                        
                        // ✨ 修正 3-A：如果參數預期是指標，但傳入了整數，必須用 inttoptr ✨
                        if (actualType == TypeInfo.Int) {
                            if (argTmp.equals("0")) {
                                argTmp = "null";
                                actualPtrType = expectedPtrType; // 0 自動轉 null，過關
                            } else {
                                String casted = newTemp();
                                addInstruction(casted + " = inttoptr i32 " + argTmp + " to " + expectedPtrType);
                                argTmp = casted;
                                actualPtrType = expectedPtrType; // 騙過後面的 bitcast 檢查，因為已經轉好了
                            }
                        }
                        else if (actualType == TypeInfo.Float)  actualPtrType = "float*";
                        
                        else if (actualType == TypeInfo.Double) actualPtrType = "double*";
                        else if (actualType == TypeInfo.Char)   actualPtrType = "i8*";
                        else if (actualType == TypeInfo.Pointer) {
                            Info argInfo = givenArgs.get(ci);
                            actualPtrType = exactTypeMap.containsKey(argTmp)
                                ? exactTypeMap.get(argTmp)
                                : (argInfo.structName != null && argInfo.structName.contains("(")) // ✨ FIX: Function pointer check
                                    ? argInfo.structName
                                    : (argInfo.pointeeType != null)
                                        ? toLLVMPtrType(argInfo.pointeeType, argInfo.structName)
                                        : expectedPtrType;
                        }
                        if (actualPtrType != null && !actualPtrType.equals(expectedPtrType)) {
                            String casted = newTemp();
                            addInstruction(casted + " = bitcast " + actualPtrType + " " + argTmp + " to " + expectedPtrType);
                            argTmp = casted;
                        }
                        callInstr.append(expectedPtrType).append(" ").append(argTmp);
                        continue;
                    }
                    // ── 一般型別隱式轉換 ──
                    // ✨ 修正 3-B：如果預期是整數，但傳入了指標，必須用 ptrtoint ✨
                    if ((expectedType == TypeInfo.Int || expectedType == TypeInfo.Error) && actualType == TypeInfo.Pointer) {
                        String srcT = exactTypeMap.containsKey(argTmp) ? exactTypeMap.get(argTmp) : "i8*";
                        String conv = newTemp();
                        addInstruction(conv + " = ptrtoint " + srcT + " " + argTmp + " to i32");
                        argTmp = conv;
                    } else if (expectedType == TypeInfo.Int && actualType == TypeInfo.Char) {
                        String conv = newTemp();
                        addInstruction(conv + " = sext i8 " + argTmp + " to i32");
                        argTmp = conv;
                    } else if (expectedType == TypeInfo.Int && actualType == TypeInfo.Boolean) {
                            String conv = newTemp();
                            addInstruction(conv + " = zext i1 " + argTmp + " to i32");
                            argTmp = conv;
                    } else if (expectedType == TypeInfo.Float && actualType == TypeInfo.Char) {
                        String c1 = newTemp(); addInstruction(c1 + " = sext i8 " + argTmp + " to i32");
                        String c2 = newTemp(); addInstruction(c2 + " = sitofp i32 " + c1 + " to float");
                        argTmp = c2;
                    } else if (expectedType == TypeInfo.Float && actualType == TypeInfo.Double) {
                        String conv = newTemp();
                        addInstruction(conv + " = fptrunc double " + argTmp + " to float");
                        argTmp = conv;
                    } else if (expectedType == TypeInfo.Float && actualType == TypeInfo.Int) {
                        String conv = newTemp();
                        addInstruction(conv + " = sitofp i32 " + argTmp + " to float");
                        argTmp = conv;
                    } else if (expectedType == TypeInfo.Int && (actualType == TypeInfo.Float || actualType == TypeInfo.Double)) {
                        String conv = newTemp();
                        addInstruction(conv + " = fptosi " + toLLVMType(actualType) + " " + argTmp + " to i32");
                        argTmp = conv;
                    } else if (expectedType == TypeInfo.Double && actualType == TypeInfo.Float) {
                        String conv = newTemp();
                        addInstruction(conv + " = fpext float " + argTmp + " to double");
                        argTmp = conv;
                    } else if (expectedType == TypeInfo.Double && actualType == TypeInfo.Int) {
                        String conv = newTemp();
                        addInstruction(conv + " = sitofp i32 " + argTmp + " to double");
                        argTmp = conv;
                    }
                    // ── Struct 傳值：需要 load 出 struct 值 ──
                    if (expectedType == TypeInfo.Struct) {
                        // 從 funcRegistry 取得 struct name（需查 funcStructRegistry）
                        // 傳 struct by value：用 symtab 找 structName
                        String sname = null;
                        Info argInfoS = givenArgs.get(ci);
                        if (argInfoS.structName != null) sname = argInfoS.structName;
                        if (sname == null) {
                            // fallback: 從 symtab 反查
                            for (Info sv : symtab.values()) {
                                if (sv.theType == TypeInfo.Struct && sv.tmp != null && sv.tmp.equals(argTmp)) {
                                    sname = sv.structName; break;
                                }
                            }
                        }
                        if (sname != null) {
                            String structT = "%struct." + sname;
                            // struct 的 alloca 指標 → load 出值
                            String loaded = newTemp();
                            addInstruction(loaded + " = load " + structT + ", " + structT + "* " + argTmp + ", align 4");
                            callInstr.append(structT).append(" ").append(loaded);
                        } else {
                            callInstr.append("i32 ").append(argTmp); // fallback
                        }
                        continue;
                    }
                    // ── char 陣列參數：傳 i8* 而非 i8 ──
                    if (expectedType == TypeInfo.Char) {
                        if (charPtrTemps.contains(argTmp) || (givenArgs.get(ci).arraySize > 0)) {
                            callInstr.append("i8* ").append(argTmp);
                        } else {
                            // ✨ 修正：純 char 純量必須嚴格傳遞 i8！
                            // 若使用者傳入的是 int，則產生 trunc 指令截斷為 i8
                            if (actualType == TypeInfo.Int) {
                                String conv2 = newTemp();
                                addInstruction(conv2 + " = trunc i32 " + argTmp + " to i8");
                                callInstr.append("i8 ").append(conv2);
                            } else {
                                callInstr.append("i8 ").append(argTmp);
                            }
                        }
                    } else {
                        callInstr.append(toLLVMType(expectedType)).append(" ").append(argTmp);
                    }
                }
                // ✨ variadic 函式 call：固定參數後追加多餘引數（float→double 提升）
                if (isUserVariadic && givenArgs.size() > expectedParams) {
                    for (int vi = expectedParams; vi < givenArgs.size(); vi++) {
                        callInstr.append(", ");
                        Info varg = givenArgs.get(vi);
                        TypeInfo vt = varg.theType;
                        String vtmp = varg.tmp;
                        if (vt == TypeInfo.Float) {
                            String promoted = newTemp();
                            addInstruction(promoted + " = fpext float " + vtmp + " to double");
                            vtmp = promoted; vt = TypeInfo.Double;
                        }
                        callInstr.append(toLLVMType(vt)).append(" ").append(vtmp);
                    }
                }
                callInstr.append(")");
                addInstruction(callInstr.toString());
                // ── char 回傳值：sext i8 → i32，讓後續算術/比較/printf 都能用 ──
                if (retType == TypeInfo.Char) {
                    String promoted = newTemp();
                    addInstruction(promoted + " = sext i8 " + $tmp + " to i32");
                    $tmp = promoted;
                    $type = TypeInfo.Int; // 對外表現為 Int
                } else if (retType == TypeInfo.Boolean) {
                    String promoted = newTemp();
                    addInstruction(promoted + " = zext i1 " + $tmp + " to i32");
                    $tmp = promoted;
                    $type = TypeInfo.Int;
                } else {
                    $type = retType;
                }
            }
        }
      }
    // ── 陣列元素存取 a[idx1][idx2][idx3]? ──
    | id=ID '[' idx=expression ']' ('[' idx2=expression ']')? ('[' idx3=expression ']')?
      {
        $isConst = false; $constVal = 0;
        Info info = symtab.get($id.getText());
        if (info == null) info = globalSymtab.get($id.getText());
        
        if (info == null) {
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier " + $id.getText() + ".");
            $type = TypeInfo.Error; $tmp = "0";
        // ── argv[i] 特殊處理：argv 是 i8**，argv[i] 是 i8*（字串）──
        } else if ($id.getText().equals("argv") && info.structName != null && info.structName.equals("i8**")) {
            String argvVal = newTemp();
            addInstruction(argvVal + " = load i8**, i8*** " + info.tmp + ", align 8");
            String elemPtr = newTemp();
            addInstruction(elemPtr + " = getelementptr inbounds i8*, i8** " + argvVal + ", i32 " + $idx.tmp);
            String result = newTemp();
            addInstruction(result + " = load i8*, i8** " + elemPtr + ", align 8");
            charPtrTemps.add(result);
            $type = TypeInfo.Char; $tmp = result;
        } else {
            String elemPtr = newTemp();
            TypeInfo actualElemType;
            String elemLLVMType;
            
            if (info.arrayDim3 > 0 && $idx3.ctx != null && info.arrayDim2 > 0 && info.arraySize > 0) {
                // 三維本地陣列 GEP
                // ✨ 邊界檢查
                emitBoundsCheck($id.getLine(), $id.getText()+"[0]", $idx.tmp, $idx.isConst, (int)$idx.constVal, info.arraySize);
                emitBoundsCheck($id.getLine(), $id.getText()+"[1]", $idx2.tmp, $idx2.isConst, (int)$idx2.constVal, info.arrayDim2);
                emitBoundsCheck($id.getLine(), $id.getText()+"[2]", $idx3.tmp, $idx3.isConst, (int)$idx3.constVal, info.arrayDim3);
                actualElemType = info.theType;
                elemLLVMType = toLLVMType(actualElemType);
                String dim3TypeStrR = "[" + info.arrayDim3 + " x " + elemLLVMType + "]";
                String dim2TypeStrR = "[" + info.arrayDim2 + " x " + dim3TypeStrR + "]";
                String arrType3DR = "[" + info.arraySize + " x " + dim2TypeStrR + "]";
                addInstruction(elemPtr + " = getelementptr inbounds " + arrType3DR + ", " + arrType3DR + "* " + info.tmp
                    + ", i32 0, i32 " + $idx.tmp + ", i32 " + $idx2.tmp + ", i32 " + $idx3.tmp);
            } else if (info.arrayDim2 > 0 && $idx2.ctx != null && info.arraySize > 0) {
                // 二維本地陣列 GEP
                // ✨ 邊界檢查
                emitBoundsCheck($id.getLine(), $id.getText()+"[0]", $idx.tmp, $idx.isConst, (int)$idx.constVal, info.arraySize);
                emitBoundsCheck($id.getLine(), $id.getText()+"[1]", $idx2.tmp, $idx2.isConst, (int)$idx2.constVal, info.arrayDim2);
                actualElemType = info.theType;
                if (actualElemType == TypeInfo.Pointer) actualElemType = TypeInfo.Int;
                elemLLVMType = toLLVMType(actualElemType);
                String arrType = "[" + info.arraySize + " x [" + info.arrayDim2 + " x " + elemLLVMType + "]]";
                addInstruction(elemPtr + " = getelementptr inbounds " + arrType + ", " + arrType + "* " + info.tmp + ", i32 0, i32 " + $idx.tmp + ", i32 " + $idx2.tmp);
            } else if (info.arraySize > 0) {
                // 一維陣列 GEP
                // ✨ 邊界檢查
                emitBoundsCheck($id.getLine(), $id.getText(), $idx.tmp, $idx.isConst, (int)$idx.constVal, info.arraySize);
                actualElemType = info.theType;
                elemLLVMType = toLLVMType(actualElemType);
                String arrType = "[" + info.arraySize + " x " + elemLLVMType + "]";
                addInstruction(elemPtr + " = getelementptr inbounds " + arrType + ", " + arrType + "* " + info.tmp + ", i32 0, i32 " + $idx.tmp);
            } else if (info.arraySize == -2) {
                // ── VLA 讀取：直接 GEP ──
                // Bug 3 修正：VLA 用 i64 alloca，GEP index 也必須用 i64
                actualElemType = info.theType;
                elemLLVMType = toLLVMType(actualElemType);
                String vlaIdxTmp2 = $idx.tmp;
                if ($idx.type != TypeInfo.Long) {
                    String sextIdx2 = newTemp();
                    addInstruction(sextIdx2 + " = sext i32 " + $idx.tmp + " to i64");
                    vlaIdxTmp2 = sextIdx2;
                }
                addInstruction(elemPtr + " = getelementptr inbounds " + elemLLVMType + ", " + elemLLVMType + "* " + info.tmp + ", i64 " + vlaIdxTmp2);
           } else if (info.isPointer || info.arraySize == -1) {
                // ✨ 特殊：3D 陣列參數 grid[][M][N]
                if (info.arrayDim3 > 0 && $idx3.ctx != null && info.arrayDim2 > 0) {
                    actualElemType = info.baseType != null ? info.baseType : TypeInfo.Int;
                    elemLLVMType = toLLVMType(actualElemType);
                    String sliceTypeR3 = "[" + info.arrayDim3 + " x " + elemLLVMType + "]";
                    String rowTypeR3  = "[" + info.arrayDim2 + " x " + sliceTypeR3 + "]";
                    String rowPtrTR3  = rowTypeR3 + "*";
                    String basePtrR3 = newTemp();
                    addInstruction(basePtrR3 + " = load " + rowPtrTR3 + ", " + rowPtrTR3 + "* " + info.tmp + ", align 8");
                    String rowPtrR3 = newTemp();
                    addInstruction(rowPtrR3 + " = getelementptr inbounds " + rowTypeR3 + ", " + rowPtrTR3 + " " + basePtrR3 + ", i32 " + $idx.tmp);
                    String slicePtrR3 = newTemp();
                    addInstruction(slicePtrR3 + " = getelementptr inbounds " + rowTypeR3 + ", " + rowPtrTR3 + " " + rowPtrR3 + ", i32 0, i32 " + $idx2.tmp);
                    addInstruction(elemPtr + " = getelementptr inbounds " + sliceTypeR3 + ", " + sliceTypeR3 + "* " + slicePtrR3 + ", i32 0, i32 " + $idx3.tmp);
                // ✨ 特殊：2D 陣列參數 arr[][N]（info.arrayDim2 > 0 且 isPointer）
                } else if (info.arrayDim2 > 0 && $idx2.ctx != null) {
                    actualElemType = info.baseType != null ? info.baseType : TypeInfo.Int;
                    if (actualElemType == TypeInfo.Pointer) actualElemType = TypeInfo.Int;
                    elemLLVMType = toLLVMType(actualElemType);
                    String rowType = "[" + info.arrayDim2 + " x " + elemLLVMType + "]";
                    String rowPtrT = rowType + "*";
                    // load base pointer: [4 x i32]** → [4 x i32]*
                    String basePtr = newTemp();
                    addInstruction(basePtr + " = load " + rowPtrT + ", " + rowPtrT + "* " + info.tmp + ", align 8");
                    // GEP to i-th row
                    String rowPtr = newTemp();
                    addInstruction(rowPtr + " = getelementptr inbounds " + rowType + ", " + rowPtrT + " " + basePtr + ", i32 " + $idx.tmp);
                    // GEP to j-th element within row
                    addInstruction(elemPtr + " = getelementptr inbounds " + rowType + ", " + rowPtrT + " " + rowPtr + ", i32 0, i32 " + $idx2.tmp);
                } else {
                // ✨ 修正：多層指標陣列讀取
                // ✨ 特殊：2D array param single-index (arr[i] returns row pointer)
                if (info.structName != null && info.structName.startsWith("[") && info.structName.endsWith("]*")) {
                    // e.g. structName = "[4 x i32]*": load the [4 x i32]* then GEP to row
                    String rowPtrT2 = info.structName; // "[4 x i32]*"
                    String rowTypeStr = rowPtrT2.substring(0, rowPtrT2.length() - 1); // "[4 x i32]"
                    actualElemType = TypeInfo.Pointer;
                    elemLLVMType = rowPtrT2;
                    String basePtr2 = newTemp();
                    addInstruction(basePtr2 + " = load " + rowPtrT2 + ", " + rowPtrT2 + "* " + info.tmp + ", align 8");
                    addInstruction(elemPtr + " = getelementptr inbounds " + rowTypeStr + ", " + rowPtrT2 + " " + basePtr2 + ", i32 " + $idx.tmp);
                } else {
                actualElemType = (info.ptrDepth > 1) ? TypeInfo.Pointer : info.baseType;
                elemLLVMType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth > 0 ? info.ptrDepth - 1 : 0);
                String ptrLLVMType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
                
                String loadedPtr = newTemp();
                addInstruction(loadedPtr + " = load " + ptrLLVMType + ", " + ptrLLVMType + "* " + info.tmp + ", align 8");
                addInstruction(elemPtr + " = getelementptr inbounds " + elemLLVMType + ", " + ptrLLVMType + " " + loadedPtr + ", i32 " + $idx.tmp);
                }
                }
            } else {
                // 一般指標 fallback
                actualElemType = info.theType;
                elemLLVMType = toLLVMType(actualElemType);
                addInstruction(elemPtr + " = getelementptr inbounds " + elemLLVMType + ", " + elemLLVMType + "* " + info.tmp + ", i32 " + $idx.tmp);
            }
            
            String result = newTemp();
            addInstruction(result + " = load " + elemLLVMType + ", " + elemLLVMType + "* " + elemPtr + ", align 4");
            $type = actualElemType;
            $tmp = result;
        } // end argv / else
      }
    | id=ID op=('++' | '--')   
      {
        $isConst = false;
        $constVal = 0;
        Info info = symtab.get($id.getText());
        if (info == null) {
            System.err.println("Error! " + $id.getLine() + ": Undeclared identifier " + $id.getText() + ".");
            $type = TypeInfo.Error;
            $tmp = "0";
        } else {
            String llvmT = toLLVMType(info.theType);
            String oldVal = newTemp();
            addInstruction(oldVal + " = load " + llvmT + ", " + llvmT + "* " + info.tmp + ", align 4");
            String newVal = newTemp();
            boolean isFloat = (info.theType == TypeInfo.Float || info.theType == TypeInfo.Double);
            String llvmOp = $op.getText().equals("++")
                ? (isFloat ? "fadd" : "add")
                : (isFloat ? "fsub" : "sub");
            String one = isFloat ? "1.0" : "1";
            addInstruction(newVal + " = " + llvmOp + " " + llvmT + " " + oldVal + ", " + one);
            addInstruction("store " + llvmT + " " + newVal + ", " + llvmT + "* " + info.tmp + ", align 4");
            $type = info.theType;
            $tmp = oldVal; // postfix 回傳舊值
        }
      }
    | id=ID
      {
        $isConst = false; $constVal = 0;
        // ── enum 常數：優先查 enumConstants ──
        if (enumConstants.containsKey($id.getText())) {
            int ev = enumConstants.get($id.getText());
            $type = TypeInfo.Int; $tmp = String.valueOf(ev);
            $isConst = true; $constVal = ev;
        } 
        // ── ✨ 核心修正：讓編譯器認識函式名稱，將其轉為指標 ✨ ──
        else if (funcRegistry.containsKey($id.getText())) {
            $type = TypeInfo.Pointer;
            $tmp = "@" + $id.getText();
            $isConst = true; $constVal = 0;

            // ✨ 修正：用 funcPointerRegistry 取得各參數的 pointee 型別，
            //    才能正確還原 i32* / double* 等指標參數，而非一律輸出 i8*
            List<TypeInfo> sig        = funcRegistry.get($id.getText());
            List<TypeInfo> pointees   = funcPointerRegistry.containsKey($id.getText())
                                        ? funcPointerRegistry.get($id.getText()) : null;
            List<String>   pStructs   = funcPointerStructRegistry.containsKey($id.getText())
                                        ? funcPointerStructRegistry.get($id.getText()) : null;
            if (sig != null && !sig.isEmpty()) {
                // 回傳型別
                String retLL = toLLVMType(sig.get(0));
                StringBuilder fpTypeStr = new StringBuilder(retLL).append(" (");
                for (int i = 1; i < sig.size(); i++) {
                    if (i > 1) fpTypeStr.append(", ");
                    TypeInfo ptype   = sig.get(i);
                    TypeInfo pointee = (pointees != null && (i-1) < pointees.size()) ? pointees.get(i-1) : null;
                    String   psname  = (pStructs != null && (i-1) < pStructs.size()) ? pStructs.get(i-1) : null;
                    if (ptype == TypeInfo.Pointer && pointee != null) {
                        // 指標參數：用 pointee 型別建構正確 LLVM 指標型別
                        fpTypeStr.append(toLLVMPtrType(pointee, psname));
                    } else {
                        fpTypeStr.append(toLLVMType(ptype));
                    }
                }
                fpTypeStr.append(")*");
                exactTypeMap.put($tmp, fpTypeStr.toString());
            } else {
                exactTypeMap.put($tmp, "i8*");
            }
        } 
       // ── 一般變數 ──
        else {
            Info info = symtab.get($id.getText());
            if (info == null) info = globalSymtab.get($id.getText());
            
            if (info == null) {
                System.err.println("Error! " + $id.getLine() + ": Undeclared identifier " + $id.getText() + ".");
                $type = TypeInfo.Error;
                $tmp = "0";
        } else if (info.isPointer) {
            // ── 指標變數：load 指標值（得到位址），型別標記為 Pointer ──
            String ptrLLVM;
            
            // ✨ 終極防呆：如果是函式指標，絕對不加 %struct. ✨
            if (info.structName != null && info.structName.contains("(")) {
                ptrLLVM = info.structName; 
            } else {
                ptrLLVM = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
            }
        
            String result = newTemp();
            
            // ✨【修正處】：動態檢查 info.tmp 是否已被存在 exactTypeMap 中
            // 如果 info.tmp (例如 %t29) 在表中的型態已經是 i32**，那我們直接用該型態來 load
            String expectedPtrType = exactTypeMap.containsKey(info.tmp) ? exactTypeMap.get(info.tmp) : (ptrLLVM + "*");
            
            addInstruction(result + " = load " + ptrLLVM + ", " + expectedPtrType + " " + info.tmp + ", align 8");
            
            // 記錄這個暫存器的真實型別 (例如 i32** 或 %struct.Node*)
            exactTypeMap.put(result, ptrLLVM);

                $type = TypeInfo.Pointer; 
                $tmp = result;
                
            } else if (info.arraySize > 0) {
            // ✨ 陣列退化 (Array Decay)
            // ✨ 3D 陣列退化：[M x [N x [K x T]]]* → [N x [K x T]]*
            if (info.arrayDim3 > 0 && info.arrayDim2 > 0) {
                String elemLLVM3 = toLLVMType(info.theType);
                String sliceType3 = "[" + info.arrayDim3 + " x " + elemLLVM3 + "]";
                String rowType3   = "[" + info.arrayDim2  + " x " + sliceType3 + "]";
                String aType3     = "[" + info.arraySize   + " x " + rowType3   + "]";
                String ptr3 = newTemp();
                addInstruction(ptr3 + " = getelementptr inbounds " + aType3 + ", " + aType3 + "* " + info.tmp + ", i32 0, i32 0");
                $type = TypeInfo.Pointer;
                $tmp  = ptr3;
                exactTypeMap.put(ptr3, rowType3 + "*");
            // ✨ 2D 陣列退化：[M x [N x T]]* → [N x T]*
            } else if (info.arrayDim2 > 0) {
                String elemLLVM2 = toLLVMType(info.theType);
                String rowType2  = "[" + info.arrayDim2 + " x " + elemLLVM2 + "]";
                String aType2    = "[" + info.arraySize  + " x " + rowType2  + "]";
                String ptr2 = newTemp();
                addInstruction(ptr2 + " = getelementptr inbounds " + aType2 + ", " + aType2 + "* " + info.tmp + ", i32 0, i32 0");
                $type = TypeInfo.Pointer;
                $tmp  = ptr2;
                exactTypeMap.put(ptr2, rowType2 + "*");
            } else {
            // 1D 陣列退化：[N x T]* → T*
            String llvmT = toLLVMType(info.theType);
            String aType = "[" + info.arraySize + " x " + llvmT + "]";
            String ptr = newTemp();
            addInstruction(ptr + " = getelementptr inbounds " + aType + ", " + aType + "* " + info.tmp + ", i32 0, i32 0");
            $type = TypeInfo.Pointer;
            $tmp  = ptr;
            exactTypeMap.put(ptr, llvmT + "*");
            }
        } else if (info.theType == TypeInfo.Struct) {
            // ── struct 變數：直接回傳 alloca 指標，不做 load ──
            $type = TypeInfo.Struct;
            $tmp  = info.tmp;
        } else {
            // ── va_list 特殊處理：[24 x i8] alloca，用 bitcast 取 i8* ──
            if ("__va_list".equals(info.structName)) {
                String result = newTemp();
                addInstruction(result + " = bitcast [24 x i8]* " + info.tmp + " to i8*");
                exactTypeMap.put(result, "i8*");
                charPtrTemps.add(result);
                $type = TypeInfo.Pointer; $tmp = result;
            } else {
                // 純量（int、float、char 純量）
                $type = info.theType;
                String result = newTemp();
                String loadAlign = (info.theType == TypeInfo.Boolean) ? "1" : "4";
                addInstruction(result + " = load " + toLLVMType($type) + ", " + toLLVMType($type) + "* " + info.tmp + ", align " + loadAlign);
                $tmp = result;
            }
        }
        } // end else (not enum)
      }
// ── 讀取結構體成員下標 (例如 p->data[i], s.arr[i]) ──
    | id1r=ID opPtrR=(PERIOD | POINTTO) id2r=ID '[' idxR=expression ']'
      {
        $isConst = false; $constVal = 0;
        Info info = symtab.get($id1r.getText());
        if (info == null) info = globalSymtab.get($id1r.getText());
        boolean isArrowR = $opPtrR.getText().equals("->");

        if (info == null) {
            System.err.println("Error! " + $id1r.getLine() + ": Undeclared identifier '" + $id1r.getText() + "'.");
            $type = TypeInfo.Error; $tmp = "0";
        } else if (info.structName == null) {
            System.err.println("Error! " + $id1r.getLine() + ": Cannot resolve struct type for '" + $id1r.getText() + "'.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            StructDef sdefR = structRegistry.get(info.structName);
            int[] resR = (sdefR != null) ? resolveAnonField(sdefR, $id2r.getText()) : null;
            int fIdxR = (resR != null && resR.length >= 1) ? resR[0] : -1;

            if (fIdxR < 0 || sdefR == null) {
                System.err.println("Error! " + $id2r.getLine() + ": No field '" + $id2r.getText() + "' in struct " + info.structName + ".");
                $type = TypeInfo.Error; $tmp = "0";
            } else {
                String structTR = "%struct." + info.structName;
                // ── 取 struct 基底指標 ──
                String baseAddrR;
                if (isArrowR) {
                    baseAddrR = newTemp();
                    addInstruction(baseAddrR + " = load " + structTR + "*, " + structTR + "** " + info.tmp + ", align 8");
                } else {
                    baseAddrR = info.tmp;
                }

                TypeInfo fTypeR = sdefR.fTypes.get(fIdxR);
                TypeInfo fPointeeR = sdefR.fPointeeTypes.get(fIdxR);
                int famMarkR = sdefR.bitWidths.get(fIdxR);  // 0 = FAM

                String elemLLVMTypeR;
                String elemPtrR;

                if (famMarkR == 0 && fPointeeR != null) {
                    // FAM：[0 x T]*
                    elemLLVMTypeR = toLLVMType(fPointeeR);
                    String arrTypeR = "[0 x " + elemLLVMTypeR + "]";
                    String famFPR = newTemp();
                    addInstruction(famFPR + " = getelementptr inbounds " + structTR
                                   + ", " + structTR + "* " + baseAddrR
                                   + ", i32 0, i32 " + fIdxR);
                    exactTypeMap.put(famFPR, arrTypeR + "*");
                    elemPtrR = newTemp();
                    addInstruction(elemPtrR + " = getelementptr inbounds " + arrTypeR
                                   + ", " + arrTypeR + "* " + famFPR
                                   + ", i32 0, i32 " + $idxR.tmp);
                    exactTypeMap.put(elemPtrR, elemLLVMTypeR + "*");
                    $type = fPointeeR;
                } else if (fTypeR == TypeInfo.Pointer && fPointeeR != null) {
                    // 一般指標欄位
                    elemLLVMTypeR = toLLVMType(fPointeeR);
                    String fPtrPtrR = newTemp();
                    addInstruction(fPtrPtrR + " = getelementptr inbounds " + structTR
                                   + ", " + structTR + "* " + baseAddrR
                                   + ", i32 0, i32 " + fIdxR);
                    String fPtrValR = newTemp();
                    addInstruction(fPtrValR + " = load " + elemLLVMTypeR + "*, "
                                   + elemLLVMTypeR + "** " + fPtrPtrR + ", align 8");
                    elemPtrR = newTemp();
                    addInstruction(elemPtrR + " = getelementptr inbounds " + elemLLVMTypeR
                                   + ", " + elemLLVMTypeR + "* " + fPtrValR
                                   + ", i32 " + $idxR.tmp);
                    $type = fPointeeR;
                } else {
                    System.err.println("Error! " + $id2r.getLine() + ": Field '" + $id2r.getText() + "' is not subscriptable.");
                    $type = TypeInfo.Error; $tmp = "0";
                    // ── 錯誤路徑：直接跳出，不執行下面的 load ──
                    elemLLVMTypeR = null; elemPtrR = null;
                }

                // ── load 元素值（錯誤路徑略過）──
                if (elemPtrR != null && $type != TypeInfo.Error) {
                    elemLLVMTypeR = ($type == TypeInfo.Char)   ? "i8"
                                   : ($type == TypeInfo.Double) ? "double"
                                   : ($type == TypeInfo.Long)   ? "i64"
                                   : toLLVMType($type);
                    String loadAlign = ($type == TypeInfo.Char)   ? "1"
                                     : ($type == TypeInfo.Double) ? "8"
                                     : ($type == TypeInfo.Long)   ? "8"
                                     : "4";  // int / float → 4
                    String resultR = newTemp();
                    addInstruction(resultR + " = load " + elemLLVMTypeR + ", " + elemLLVMTypeR + "* " + elemPtrR + ", align " + loadAlign);
                    // char → int promotion
                    if ($type == TypeInfo.Char) {
                        String promoted = newTemp();
                        addInstruction(promoted + " = sext i8 " + resultR + " to i32");
                        $tmp = promoted; $type = TypeInfo.Int;
                    } else {
                        $tmp = resultR;
                    }
                }
            }
        }
      }
// ── 讀取結構體成員 (例如 p.x 或 p->x, 以及 (*pp)->x) ──
    |
    ( id1=ID | '(' s1='*' s2='*'? id1=ID ')' ) opPtr=(PERIOD | POINTTO) id2=ID
      {
        $isConst = false;
        $constVal = 0;
        Info info = symtab.get($id1.getText());
        if (info == null) info = globalSymtab.get($id1.getText());
        
        boolean isArrow = $opPtr.getText().equals("->");
        int derefs = ($s1 != null) ? (($s2 != null) ? 2 : 1) : 0;

        if (info == null) {
            System.err.println("Error! Undeclared identifier.");
            $type = TypeInfo.Error; $tmp = "0";
        } else if (isArrow && !info.isPointer && derefs == 0) {
            System.err.println("Error! '" + $id1.getText() + "' is not a pointer.");
            $type = TypeInfo.Error; $tmp = "0";
        } else {
            // 若為指標，要反查當初指向的 structName
            String sName = info.structName; 
            StructDef sdef = structRegistry.get(sName);

            // ✨ 匿名成員透傳查詢（支援多層遞迴）
            int[] anonRes = resolveAnonField(sdef, $id2.getText());
            // anonRes 格式：[outerIdx, innerIdx, ...] 長度>=2，最後一個 != -1 是終端欄位索引
            // 若長度==2 且 anonRes[1]==-1 → 直接在外層
            // 若長度==2 且 anonRes[1]>=0  → 外層[0]的匿名sub[1]
            // 若長度==3                   → 外層[0]的匿名sub[1]的匿名sub[2]
            int fIdx = -1;
            StructDef effectiveSdef = sdef;
            int realFIdx = -1;

            if (anonRes != null && anonRes.length >= 2) {
                fIdx = anonRes[0];
                int lastIdx = anonRes[anonRes.length - 1];
                if (anonRes.length == 2 && lastIdx == -1) {
                    // 直接在外層
                    realFIdx = fIdx;
                    effectiveSdef = sdef;
                } else {
                    // 欄位在某個深層的匿名 sub-struct 裡
                    // 從 sdef 出發，沿 path[0..length-2] 逐層進入匿名 def，
                    // 最後一步 path[length-1] 是在那個 def 裡的欄位索引
                    StructDef curDef = sdef;
                    for (int pi = 0; pi < anonRes.length - 1; pi++) {
                        String aSN = curDef.fStructNames.get(anonRes[pi]);
                        StructDef next = structRegistry.get(aSN);
                        if (next == null) break;
                        curDef = next;
                    }
                    effectiveSdef = curDef;
                    realFIdx = lastIdx;
                }
            }

            if (fIdx < 0 || realFIdx < 0 || effectiveSdef == null) {
                System.err.println("Error! No field '" + $id2.getText() + "'.");
                $type = TypeInfo.Error; $tmp = "0";
            } else {
                TypeInfo fType = effectiveSdef.fTypes.get(realFIdx);
                $type = fType;
                String structT = "%struct." + sName;

                String fPtr = newTemp();
                // Pointer field：用 pointeeType 決定型別，而非 struct 本身
                String fLlvmT;
                List<TypeInfo> fPointees = effectiveSdef.fPointeeTypes;
                TypeInfo fPointee = (fPointees != null && realFIdx < fPointees.size()) ? fPointees.get(realFIdx) : null;
                if (fType == TypeInfo.Struct && effectiveSdef.fStructNames != null && realFIdx < effectiveSdef.fStructNames.size() && effectiveSdef.fStructNames.get(realFIdx) != null) {
                    fLlvmT = "%struct." + effectiveSdef.fStructNames.get(realFIdx);
                } else if (fType == TypeInfo.Pointer && fPointee != null) {
                    if (fPointee == TypeInfo.Struct && effectiveSdef.fStructNames.get(realFIdx) != null) {
                        fLlvmT = "%struct." + effectiveSdef.fStructNames.get(realFIdx) + "*";
                    } else if (fPointee == TypeInfo.Void) {
                        fLlvmT = "i8*";
                    } else {
                        fLlvmT = toLLVMType(fPointee) + "*";
                    }
                } else {
                    fLlvmT = toLLVMType(fType);
                }

                // ✨ 括號解參考處理邏輯 (*pp)->data
                String baseVal = info.tmp;
                if (derefs > 0) {
                    String ptrLLVM = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth);
                    String currentVal = newTemp();
                    addInstruction(currentVal + " = load " + ptrLLVM + ", " + ptrLLVM + "* " + info.tmp + ", align 8");
                    String currentType = ptrLLVM;
                    for (int i = 0; i < derefs; i++) {
                        String nextType = toLLVMPtrType(info.baseType, info.structName, info.ptrDepth - 1 - i);
                        String result = newTemp();
                        addInstruction(result + " = load " + nextType + ", " + currentType + " " + currentVal + ", align 8");
                        currentVal = result;
                        currentType = nextType;
                    }
                    baseVal = currentVal;
                }

                // ✨ 多層匿名成員 GEP：沿著 anonRes path 逐層 GEP/bitcast
                String realBase = baseVal;
                boolean isDirect = (anonRes.length == 2 && anonRes[1] == -1);

                if (!isDirect) {
                    StructDef curDef = sdef;
                    String curBase = realBase;
                    String curStructT = structT;

                    for (int pi = 0; pi < anonRes.length - 1; pi++) {
                        int stepIdx = anonRes[pi];
                        String anonSN2 = curDef.fStructNames.get(stepIdx);
                        String anonStructT2 = "%struct." + anonSN2;
                        String stepPtr = newTemp();

                        if (curDef.isUnion) {
                            // ✨ union 的所有成員共享起始地址，直接 bitcast 到子型別指標
                            addInstruction(stepPtr + " = bitcast " + curStructT + "* " + curBase + " to " + anonStructT2 + "*");
                        } else if (pi == 0 && isArrow && derefs == 0) {
                            String structAddr = newTemp();
                            addInstruction(structAddr + " = load " + curStructT + "*, " + curStructT + "** " + info.tmp + ", align 8");
                            addInstruction(stepPtr + " = getelementptr inbounds " + curStructT + ", " + curStructT + "* " + structAddr + ", i32 0, i32 " + stepIdx);
                        } else {
                            addInstruction(stepPtr + " = getelementptr inbounds " + curStructT + ", " + curStructT + "* " + curBase + ", i32 0, i32 " + stepIdx);
                        }

                        curBase = stepPtr;
                        curStructT = anonStructT2;
                        StructDef nextDef = structRegistry.get(anonSN2);
                        if (nextDef != null) curDef = nextDef;
                    }

                    // 最後一步：進入終端欄位
                    int lastStep = anonRes[anonRes.length - 1];
                    if (curDef != null && curDef.isUnion) {
                        // union：bitcast 整個 union 指標到目標型別
                        addInstruction(fPtr + " = bitcast " + curStructT + "* " + curBase + " to " + fLlvmT + "*");
                    } else {
                        addInstruction(fPtr + " = getelementptr inbounds " + curStructT + ", " + curStructT + "* " + curBase + ", i32 0, i32 " + lastStep);
                    }
                } else {
                    // 直接在外層
                    if (isArrow && derefs == 0) {
                        String structAddr = newTemp();
                        addInstruction(structAddr + " = load " + structT + "*, " + structT + "** " + info.tmp + ", align 8");
                        if (sdef != null && sdef.isUnion) {
                            addInstruction(fPtr + " = bitcast " + structT + "* " + structAddr + " to " + fLlvmT + "*");
                        } else {
                            addInstruction(fPtr + " = getelementptr inbounds " + structT + ", " + structT + "* " + structAddr + ", i32 0, i32 " + fIdx);
                        }
                    } else {
                        if (sdef != null && sdef.isUnion) {
                            addInstruction(fPtr + " = bitcast " + structT + "* " + realBase + " to " + fLlvmT + "*");
                        } else {
                            addInstruction(fPtr + " = getelementptr inbounds " + structT + ", " + structT + "* " + realBase + ", i32 0, i32 " + fIdx);
                        }
                    }
                }
                
                String result = newTemp();
                int fieldAlign = (fType == TypeInfo.Double || fType == TypeInfo.Pointer) ? 8 : (fType == TypeInfo.Char) ? 1 : 4;

                // ✨ bit-field 讀取：load i32 → lshr → and → result
                int bfWidthR = (effectiveSdef.hasBitFields && realFIdx < effectiveSdef.bitWidths.size()) ? effectiveSdef.bitWidths.get(realFIdx) : -1;
                if (bfWidthR > 0) {
                    int bfShiftR = bitFieldOffset(effectiveSdef, realFIdx);
                    int bfMaskR  = (1 << bfWidthR) - 1;
                    // GEP to i32 container
                    String bfCPtr = newTemp();
                    addInstruction(bfCPtr + " = getelementptr inbounds " + structT + ", " + structT + "* " + realBase + ", i32 0, i32 0");
                    // load packed i32
                    String packed = newTemp();
                    addInstruction(packed + " = load i32, i32* " + bfCPtr + ", align 4");
                    // logical shift right
                    String shifted2 = newTemp();
                    addInstruction(shifted2 + " = lshr i32 " + packed + ", " + bfShiftR);
                    // mask to field width
                    addInstruction(result + " = and i32 " + shifted2 + ", " + bfMaskR);
                    $type = TypeInfo.UnsignedInt; // bit-fields are unsigned when declared unsigned
                } else {
                addInstruction(result + " = load " + fLlvmT + ", " + fLlvmT + "* " + fPtr + ", align " + fieldAlign);
                if (fType == TypeInfo.Pointer) exactTypeMap.put(result, fLlvmT);
                }
                
                // ✨ 將讀出來的數值賦予給 $tmp 回傳！
                $tmp = result;
            }
        }
      }
    | c=constant
      {
        $type = $c.type; 
        $tmp = $c.value; // 預設值
        $isConst = true;
        // 解析常數值供常數折疊使用
        try {
            if ($c.type == TypeInfo.Int) {
                String val = $c.value.toLowerCase();
                if (val.startsWith("0x") || val.startsWith("0X")) {
                    // ✨ 用 Long 解析避免超過 Integer.MAX_VALUE 時拋例外（如 0xFF8040A0）
                    //    再強轉成 int 讓 Java 做 wrap-around，與 C 的 unsigned→signed 轉換一致
                    long parsedLong = Long.parseUnsignedLong(val.substring(2), 16);
                    int parsedInt = (int) parsedLong; // wrap-around：0xFF8040A0 → -8372064
                    $constVal = parsedInt;
                    $tmp = String.valueOf(parsedInt);
                } else if (val.startsWith("0b")) {
                    int parsedInt = Integer.parseInt(val.substring(2), 2);
                    $constVal = parsedInt;
                    $tmp = String.valueOf(parsedInt);
                } else {
                    $constVal = Integer.parseInt($c.value);
                }
            } else if ($c.type == TypeInfo.Long) {
                // ── Long 型別：用 long 精度，不能用 double（會損失精度）──
                long parsedLong = Long.parseLong($c.value);
                $constVal = (double) parsedLong; // constVal 是 double，大 long 可能有精度損失
                $tmp = String.valueOf(parsedLong);
            } else if ($c.type == TypeInfo.Float || $c.type == TypeInfo.Double) {
                // LLVM hex float 格式：先還原為 double
                if ($c.value.startsWith("0x") || $c.value.startsWith("0X")) {
                    long bits = Long.parseUnsignedLong($c.value.substring(2), 16);
                    $constVal = Double.longBitsToDouble(bits);
                } else {
                    $constVal = Double.parseDouble($c.value);
                }
            } else {
                $constVal = Double.parseDouble($c.value);
            }
        } catch (Exception ex) { $isConst = false; $constVal = 0; }
      }
    | '(' e=expression ')'
      {
        $type = $e.type;
        $tmp = $e.tmp;
        // ✨ 修正：不該寫死 false，要接住括號裡面的常數屬性！
        $isConst = $e.isConst; 
        $constVal = $e.constVal;
      }
    // ── ✨ 複合字面值（Compound Literal）：(type[sz]){v1,v2,...} / (struct S){...} ──
    // 語意謂詞：看 '(' 後面的 token 是不是型別關鍵字，才 match 這條規則
    | { _input.LA(1) == LPAR && (
          _input.LT(2).getText().equals("int")    || _input.LT(2).getText().equals("float") ||
          _input.LT(2).getText().equals("double") || _input.LT(2).getText().equals("char")  ||
          _input.LT(2).getText().equals("long")   || _input.LT(2).getText().equals("short") ||
          _input.LT(2).getText().equals("unsigned")|| _input.LT(2).getText().equals("struct")||
          _input.LT(3).getType() == LBRACKET      || typedefMap.containsKey(_input.LT(2).getText())
        ) }?
      '(' clType=typeSpecifier (clLb='[' clSz=arraySize? ']')? ')' '{'
          { clLiteralStack.push(new java.util.ArrayList<>()); }
          clInitElem (',' clInitElem)* '}'
      {
        $isConst = false; $constVal = 0;
        TypeInfo clt = $clType.type;
        // ── 從 stack 取出本層的元素列表 ──
        java.util.List<Info> clVals = clLiteralStack.pop();
        boolean isArrayLiteral = ($clLb != null);
        int clArrSz = isArrayLiteral && $clSz.ctx != null ? $clSz.value : -1;
        // (int[]){...} 沒有明確大小時，用元素個數作為大小；(int){...} 保持純量
        if (isArrayLiteral && clArrSz <= 0 && clt != TypeInfo.Struct) clArrSz = clVals.size();

        if (isArrayLiteral && clArrSz > 0 && clt != TypeInfo.Struct) {
            // ── 陣列複合字面值：(int[3]){1,2,3} / (int[]){1,2,3} ──
            String elemLLVM = toLLVMType(clt);
            String arrLLVM  = "[" + clArrSz + " x " + elemLLVM + "]";
            String clSlot   = newTemp();
            addInstruction(clSlot + " = alloca " + arrLLVM + ", align 4");
            addInstruction("store " + arrLLVM + " zeroinitializer, " + arrLLVM + "* " + clSlot + ", align 4");
            for (int ci = 0; ci < clVals.size() && ci < clArrSz; ci++) {
                String ep = newTemp();
                addInstruction(ep + " = getelementptr inbounds " + arrLLVM + ", " + arrLLVM + "* " + clSlot + ", i32 0, i32 " + ci);
                String valTmp = clVals.get(ci).tmp;
                TypeInfo valType = clVals.get(ci).theType;
                // ✨ 隱式轉型：元素值型別與陣列元素型別不符時轉型
                if (valType != clt) {
                    valTmp = emitConvert(valType, valTmp, clt);
                }
                addInstruction("store " + elemLLVM + " " + valTmp + ", " + elemLLVM + "* " + ep + ", align 4");
            }
            String headPtr = newTemp();
            addInstruction(headPtr + " = getelementptr inbounds " + arrLLVM + ", " + arrLLVM + "* " + clSlot + ", i32 0, i32 0");
            charPtrTemps.add(headPtr);
            exactTypeMap.put(headPtr, elemLLVM + "*");
            $type = TypeInfo.Pointer; $tmp = headPtr;
        } else if (clt == TypeInfo.Struct && $clType.sname != null) {
            // ── 結構體複合字面值：(struct Point){1, 2} 或 (struct Point){.x=1, .y=2} ──
            StructDef sdef2 = structRegistry.get($clType.sname);
            String structLLVM = "%struct." + $clType.sname;
            String clSlot2 = newTemp();
            addInstruction(clSlot2 + " = alloca " + structLLVM + ", align 4");
            addInstruction("store " + structLLVM + " zeroinitializer, " + structLLVM + "* " + clSlot2 + ", align 4");
            if (sdef2 != null) {
                for (int ci2 = 0; ci2 < clVals.size() && ci2 < sdef2.fNames.size(); ci2++) {
                    TypeInfo fType2 = sdef2.fTypes.get(ci2);
                    String fLLVM2 = toLLVMType(fType2);
                    String fp2 = newTemp();
                    addInstruction(fp2 + " = getelementptr inbounds " + structLLVM + ", " + structLLVM + "* " + clSlot2 + ", i32 0, i32 " + ci2);
                    String valTmp2 = clVals.get(ci2).tmp;
                    TypeInfo valType2 = clVals.get(ci2).theType;
                    // ✨ 隱式轉型
                    if (valType2 != fType2 && valType2 != TypeInfo.Error) {
                        valTmp2 = emitConvert(valType2, valTmp2, fType2);
                    }
                    addInstruction("store " + fLLVM2 + " " + valTmp2 + ", " + fLLVM2 + "* " + fp2 + ", align 4");
                }
            }
            $type = TypeInfo.Pointer; $tmp = clSlot2;
            // 並在 exactTypeMap 記錄正確型別
            exactTypeMap.put(clSlot2, "%struct." + $clType.sname + "*");
        } else {
            // ── 純量複合字面值：(int){42} ──
            if (!clVals.isEmpty()) {
                $type = clVals.get(0).theType; $tmp = clVals.get(0).tmp;
            } else {
                $type = clt; $tmp = "0";
            }
        }
      }
    | 'true'
      {
        $type = TypeInfo.Boolean;
        $tmp = "1";
        // ✨ 漏了這行：標記 true 是常數
        $isConst = true; 
        $constVal = 1; 
      }
    | 'false'
      {
        $type = TypeInfo.Boolean;
        $tmp = "0";
        $isConst = true; 
        $constVal = 0;
      }
    | NULL
      {
        // NULL → i8* null（零指標）
        $type = TypeInfo.Pointer;
        $tmp = "null";
        $isConst = true;
        $constVal = 0;
      }
    | s=STRINGLITERALS
      {
        // 字串字面值在任意 expression 位置（如 char *p = "hello"）
        $isConst = false; $constVal = 0;
        String rawStr2 = $s.getText();
        String inner3 = rawStr2.substring(1, rawStr2.length() - 1);
        int strLen3 = calcLLVMStrLen(inner3);
        String llvmStr3 = toIRString(inner3);
        String strGlobal3;
        if (stringLiterals.containsKey(rawStr2)) {
            strGlobal3 = stringLiterals.get(rawStr2);
        } else {
            strGlobal3 = "@.str." + (strCnt++);
            stringLiterals.put(rawStr2, strGlobal3);
            stringDefs.add(strGlobal3 + " = private unnamed_addr constant [" + strLen3 + " x i8] c\"" + llvmStr3 + "\", align 1");
            strLengths.put(strGlobal3, strLen3);
        }
        int gepLen3 = strLengths.containsKey(strGlobal3) ? strLengths.get(strGlobal3) : strLen3;
        String strPtr3 = newTemp();
        addInstruction(strPtr3 + " = getelementptr inbounds [" + gepLen3 + " x i8], [" + gepLen3 + " x i8]* " + strGlobal3 + ", i64 0, i64 0");
        charPtrTemps.add(strPtr3);
        exactTypeMap.put(strPtr3, "i8*");
        $type = TypeInfo.Pointer;
        $tmp = strPtr3;
      }
    ;

callArgs returns [List<Info> argList]
    : { $argList = new ArrayList<>(); }
      a1=callArg
      { $argList.add($a1.info); }
      (',' a2=callArg
      { $argList.add($a2.info); })*
    ;

// 單一 callArg：expression 或 字串字面值（用於 sprintf/snprintf 的 format）
callArg returns [Info info]
    : e=assignmentExpression
      {
        $info = new Info();
        $info.theType = $e.type;
        $info.tmp = $e.tmp;
        // ── 若是 &x 取址，補上 pointeeType ──
        if ($e.type == TypeInfo.Pointer && lastAddrOfTmp != null && lastAddrOfTmp.equals($e.tmp)) {
            $info.pointeeType = lastAddrOfPointee;
            $info.isPointer   = true;
        }
        // ── 若是 struct，從 symtab 查 structName ──
        if ($e.type == TypeInfo.Struct) {
            for (java.util.Map.Entry<String, Info> se : symtab.entrySet()) {
                if (se.getValue().tmp != null && se.getValue().tmp.equals($e.tmp) && se.getValue().theType == TypeInfo.Struct) {
                    $info.structName = se.getValue().structName; break;
                }
            }
            if ($info.structName == null) {
                for (java.util.Map.Entry<String, Info> se : globalSymtab.entrySet()) {
                    if (se.getValue().tmp != null && se.getValue().tmp.equals($e.tmp) && se.getValue().theType == TypeInfo.Struct) {
                        $info.structName = se.getValue().structName; break;
                    }
                }
            }
        }
      }
    | s=STRINGLITERALS
      {
        // 字串字面值引數：建立全域字串常數，回傳 i8* GEP
        $info = new Info();
        String rawStr = $s.getText();
        String inner = rawStr.substring(1, rawStr.length() - 1);
            // ── 使用輔助方法計算正確 byte 長度（支援中文等非 ASCII）──
            int strLen = calcLLVMStrLen(inner);
            String llvmStr = toIRString(inner);
        // 查重複字串（key 統一用含引號的 rawStr）
        String strGlobal;
        if (stringLiterals.containsKey(rawStr)) {
            strGlobal = stringLiterals.get(rawStr);
        } else {
            strGlobal = "@.str." + (strCnt++);
            stringLiterals.put(rawStr, strGlobal);
            stringDefs.add(strGlobal + " = private unnamed_addr constant [" + strLen + " x i8] c\"" + llvmStr + "\", align 1");
            strLengths.put(strGlobal, strLen);
        }
        int gepLen2 = strLengths.containsKey(strGlobal) ? strLengths.get(strGlobal) : strLen;
        String strPtr = newTemp();
        addInstruction(strPtr + " = getelementptr inbounds [" + gepLen2 + " x i8], [" + gepLen2 + " x i8]* " + strGlobal + ", i64 0, i64 0");
        charPtrTemps.add(strPtr);
        $info.theType = TypeInfo.Char;
        $info.tmp = strPtr;
      }
    ;

// ── ✨ 複合字面值的單一初始化元素 ──
// 三種形式：.field=val（struct designator）、[idx]=val（array designator）、val（無 designator）
// designator 直接忽略，值按順序存入 clLiteralStack 頂層列表
clInitElem
    : '.' ID '=' e=assignmentExpression
      {
        Info _cli = new Info(); _cli.theType = $e.type; _cli.tmp = $e.tmp;
        if (!clLiteralStack.isEmpty()) clLiteralStack.peek().add(_cli);
      }
    | '[' assignmentExpression ']' '=' e2=assignmentExpression
      {
        Info _cli2 = new Info(); _cli2.theType = $e2.type; _cli2.tmp = $e2.tmp;
        if (!clLiteralStack.isEmpty()) clLiteralStack.peek().add(_cli2);
      }
    | e3=assignmentExpression
      {
        Info _cli3 = new Info(); _cli3.theType = $e3.type; _cli3.tmp = $e3.tmp;
        if (!clLiteralStack.isEmpty()) clLiteralStack.peek().add(_cli3);
      }
    ;

constant
    returns [TypeInfo type, String value]
    : DEC_NUM       {
          // ── Bug 2 修正：超過 i32 最大值的整數字面值自動升型為 Long（i64）──
          long numVal = Long.parseLong($DEC_NUM.getText());
          if (numVal > 2147483647L || numVal < -2147483648L) {
              $type = TypeInfo.Long;
          } else {
              $type = TypeInfo.Int;
          }
          $value = $DEC_NUM.getText();
      }
    | HEX_NUM   { $type = TypeInfo.Int; $value = $HEX_NUM.getText(); }
    | BIN_NUM   { $type = TypeInfo.Int; $value = $BIN_NUM.getText(); }
    | c=FLOAT_NUM   {
          String txt = $c.getText().toLowerCase();
          if (txt.endsWith("f")) {
              // ── 'f' 後綴：float 字面值 ──
              $type = TypeInfo.Float;
              String numStr = txt.substring(0, txt.length() - 1);
              float fVal = Float.parseFloat(numStr);
              // LLVM float 以 64-bit double bits 格式表示
              long bits = Double.doubleToLongBits((double) fVal);
              $value = String.format("0x%016X", bits);
          } else {
              // ── 無後綴：C 標準規定為 double 字面值（如 0.1、3.14、1.5e2）──
              $type = TypeInfo.Double;
              double dVal = Double.parseDouble(txt);
              long bits = Double.doubleToLongBits(dVal);
              $value = String.format("0x%016X", bits);
          }
      }
    | CHARLITERALS  {
          $type = TypeInfo.Char;
          String raw = $CHARLITERALS.getText(); // e.g. '\n' or 'a'
          char c;
          if (raw.charAt(1) == '\\') {
              switch (raw.charAt(2)) {
                  case 'n':  c = '\n'; break;
                  case 't':  c = '\t'; break;
                  case '0':  c = '\0'; break;
                  case 'r':  c = '\r'; break;
                  case '\\': c = '\\'; break;
                  case '\'': c = '\''; break;
                  case '\"': c = '\"'; break;
                  case 'a':  c = '\007'; break;
                  case 'b':  c = '\b';  break;
                  case 'f':  c = '\f';  break;
                  case 'v':  c = '\013'; break;
                  case 'x':
                      // ✨ \xNN：十六進位字元，例如 '\x41' → 'A'
                      try {
                          c = (char) Integer.parseInt(raw.substring(3, raw.length()-1), 16);
                      } catch (NumberFormatException _ef) { c = '\0'; }
                      break;
                  default:
                      // ✨ \ooo：八進位字元，例如 '\101' → 'A'
                      char dc = raw.charAt(2);
                      if (dc >= '0' && dc <= '7') {
                          try {
                              c = (char) Integer.parseInt(raw.substring(2, raw.length()-1), 8);
                          } catch (NumberFormatException _eo) { c = '\0'; }
                      } else {
                          c = dc;
                      }
                      break;
              }
          } else {
              c = raw.charAt(1);
          }
          $value = String.valueOf((int) c);
      }
    | TRUE_T        { $type = TypeInfo.Boolean; $value = "true"; }
    | FALSE_T       { $type = TypeInfo.Boolean; $value = "false"; }
    ;

/*----------------------*/
/* Keywords       */
/*----------------------*/
IF_TH     : 'if';
ELSE_TH   : 'else';
SWITCH_T  : 'switch';
CASE_T    : 'case';
FOR_T     : 'for';
WHILE_T   : 'while';
DO_T      : 'do';
GOTO_T    : 'goto';
RETURN_T  : 'return';
CONST_T   : 'const';
SIZEOF_T  : 'sizeof';
AUTO_T    : 'auto';
BREAK_T   : 'break';
CONTINUE_T: 'continue';
DEFAULT_T : 'default';
ENUM_T    : 'enum';
EXTERN_T  : 'extern';
REGISTER_T: 'register';
STATIC_T  : 'static';
STRUCT_T  : 'struct';
TYPEDEF_T : 'typedef';
UNION_T   : 'union';
VOLATILE_T: 'volatile';
NULL      : 'NULL';
TRUE_T    : 'true';
FALSE_T   : 'false';

/*---other keyword---*/
INCLUDE_H : 'include';
ELSEIF_H  : 'elif';
ENDIF_H   : 'endif';
IFDEF_H   : 'ifdef';
IFNDEF_H  : 'ifndef';
DEFINE_H  : 'define';
UNDEF_H   : 'undef';
ERROR_H   : 'error';
PROGMA_H  : 'progma';

/*---✨ 新增 GCC 擴充關鍵字---*/
TYPEOF_T  : '__typeof__' | 'typeof';
ALIGNOF_T : '_Alignof' | '__alignof__';

/*----------------------*/
/* Data Type      */
/*----------------------*/
INT_TYPE  : 'int';
CHAR_TYPE : 'char';
VOID_TYPE : 'void';
FLOAT_TYPE: 'float';
DOUBLE_TYPE: 'double';
LONG_TYPE : 'long';
SHORT_TYPE: 'short';
UNSIGNED_TYPE: 'unsigned';
SIGNED_TYPE: 'signed';

/*----------------------*/
/* Operators      */
/*----------------------*/
PLUSPLUS  : '++';
MINUSMINUS: '--';
POINTTO   : '->';
PLUS      : '+';
MINUS     : '-';
LOGICNOT  : '!';
BITNOT    : '~';
MUL_POINTER: '*';
BITAND_ADDRESS: '&';
DIV       : '/';
MODULE    : '%';
BITRSHIFT : '>>';
BITLSHIFT : '<<';
LT        : '<';
GT        : '>';
LEQ       : '<=';
GEQ       : '>=';
EQ        : '==';
NEQ       : '!=';
BITXOR    : '^';
BITOR     : '|';
LOGICAND  : '&&';
LOGICOR   : '||';
TERNARY_QM: '?';
TERNARY_CL: ':';
ASSIGN    : '=';
PLUSEQ    : '+=';
MINUSEQ   : '-=';
MULEQ     : '*=';
DIVEQ     : '/=';
MODULEEQ  : '%=';
BITANDEQ  : '&=';
BITXOREQ  : '^=';
BITOREQ   : '|=';
BITLSHIFTEQ: '<<=';
BITRSHIFTEQ: '>>=';

/*---other operator---*/
HASHHASH  : '##';
LPAR      : '(';
RPAR      : ')';
LBRACKET  : '[';
RBRACKET  : ']';
LBRACE    : '{';
RBRACE    : '}';
COMMA     : ',';
SEMICOLON : ';';
ELLIPSIS  : '...';   // ✨ GNU range: [lo ... hi]，必須在 PERIOD 前，否則被拆成三個 '.'
PERIOD    : '.';

/*----------------------*/
/* Literals       */
/*----------------------*/
// 支援所有跳脫字元、支援中文，精準避開引號
STRINGLITERALS : '"'  ( '\\' . | ~["\\] )* '"' ;
CHARLITERALS   : '\'' ( '\\' . | ~['\\] )+ '\'' ;
fragment LETTER: 'a'..'z' | 'A'..'Z' | '_';
fragment DIGIT: '0'..'9';

/*----------------------*/
/* Numbers        */
/*----------------------*/
DEC_NUM : ('0' | ('1'..'9')(DIGIT)*);
// 新增十六進位支援
HEX_NUM : '0' ('x'|'X') ('0'..'9' | 'a'..'f' | 'A'..'F')+ ;
BIN_NUM : '0' ('b'|'B') [01]+ ;
// ── 支援科學記號：1.5e3  2.0E-4  1e10  3.14f ──
FLOAT_NUM : FLOAT_NUM1 | FLOAT_NUM2 | FLOAT_NUM3 | FLOAT_NUM4;
fragment FLOAT_NUM1 : (DIGIT)+ '.' (DIGIT)* EXPONENT? ('f'|'F')?;
fragment FLOAT_NUM2 : '.' (DIGIT)+ EXPONENT? ('f'|'F')?;
fragment FLOAT_NUM3 : (DIGIT)+ ('f'|'F');
fragment FLOAT_NUM4 : (DIGIT)+ EXPONENT ('f'|'F')?;   // 純整數帶指數：1e5
fragment EXPONENT   : ('e'|'E') ('+'|'-')? (DIGIT)+;

/*----------------------*/
/* Identifiers      */
/*----------------------*/
ID: (LETTER)(LETTER | DIGIT)*;
 
/*----------------------*/
/* Comments       */
/*----------------------*/
COMMENT1 : '//' ~[\r\n]* -> skip;
COMMENT2 : '/*' .*? '*/' -> skip;
PREPROC : '#' [ \t]* [a-zA-Z] ~[\r\n]* -> skip ;
/*----------------------*/
/* Whites        */
/*----------------------*/
NEW_LINE: '\n' -> skip;
WS  : (' '|'\r'|'\t')+ -> skip;
