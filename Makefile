ANTLR_JAR    = antlr-4.13.2-complete.jar
CLASSPATH    = .:$(ANTLR_JAR)
JAVA         = java
JAVAC        = javac
CC           = clang
CFLAGS       = -Wno-override-module -lm

GRAMMAR      = myCompiler.g4
RUNTIME_SRC  = myRuntime.c
MAIN_CLASS   = myCompiler_test

TEST_DIR     = test
EXPECTED_DIR = expected
TEST_SRCS    = $(wildcard $(TEST_DIR)/*.c)
TESTS        = $(patsubst $(TEST_DIR)/%.c, %, $(TEST_SRCS))

TARGET       = $(basename $(notdir $(TEST)))

# ── ANSI 顏色 ──
GREEN  = \033[0;32m
RED    = \033[0;31m
YELLOW = \033[0;33m
CYAN   = \033[0;36m
BOLD   = \033[1m
RESET  = \033[0m

# ── helper shell snippet：讀取 test/NAME.deps，回傳帶路徑的 .c 清單 ──
# 用法：在 shell 裡 $(call read_deps,NAME) → "test/math_utils.c ..."
# 若 .deps 不存在則回傳空字串
READ_DEPS = \
  if [ -f $(TEST_DIR)/$(1).deps ]; then \
    sed 's|^|$(TEST_DIR)/|' $(TEST_DIR)/$(1).deps | tr '\n' ' '; \
  fi

# ──────────────────────────────────────────
all: gen compile run_all
# ──────────────────────────────────────────

gen:
	$(JAVA) -jar $(ANTLR_JAR) -visitor $(GRAMMAR)

compile: gen
	$(JAVAC) -cp $(CLASSPATH) *.java

run_all: compile
	@if [ -z "$(TESTS)" ]; then \
		echo "No test files found in $(TEST_DIR)/"; exit 1; \
	fi
	@$(MAKE) $(addsuffix .run, $(TESTS))

# ── .in 與 .c 放同一個 test/ 資料夾 ──
%.run: $(TEST_DIR)/%.c $(RUNTIME_SRC)
	@echo "=============================="
	@echo "  Testing $<"
	@echo "=============================="
	@$(JAVA) -cp $(CLASSPATH) $(MAIN_CLASS) $< > $*.ll 2>$*_err.txt || true
	@if [ -s $*_err.txt ]; then \
		echo "[Compiler STDERR]"; cat $*_err.txt; \
	fi
	@DEP_SRCS=$$($(call READ_DEPS,$*)); \
	if $(CC) $(RUNTIME_SRC) $$DEP_SRCS $*.ll -o $* $(CFLAGS) 2>/dev/null; then \
		echo "[Output of $*]"; \
		if [ -f $(TEST_DIR)/$*.in ]; then \
			echo "[stdin < $(TEST_DIR)/$*.in]"; \
			./$* < $(TEST_DIR)/$*.in || true; \
		else \
			./$* || true; \
		fi; \
	else \
		echo "[Clang 停止] LLVM IR 無法編譯"; \
	fi
	@echo ""

run: compile
	@if [ -z "$(TEST)" ]; then \
		echo "Usage: make run TEST=test1"; exit 1; \
	fi
	@echo "=============================="
	@echo "  Testing $(TEST_DIR)/$(TARGET).c"
	@echo "=============================="
	@DEP_SRCS=$$($(call READ_DEPS,$(TARGET))); \
	$(JAVA) -cp $(CLASSPATH) $(MAIN_CLASS) $(TEST_DIR)/$(TARGET).c \
		> $(TARGET).ll 2>$(TARGET)_err.txt || true; \
	if [ -s $(TARGET)_err.txt ]; then \
		echo "[Compiler STDERR]"; cat $(TARGET)_err.txt; \
	fi; \
	$(CC) $(RUNTIME_SRC) $$DEP_SRCS $(TARGET).ll -o $(TARGET) $(CFLAGS); \
	echo "[Output of $(TARGET)]"; \
	if [ -f $(TEST_DIR)/$(TARGET).in ]; then \
		echo "[stdin < $(TEST_DIR)/$(TARGET).in]"; \
		./$(TARGET) < $(TEST_DIR)/$(TARGET).in $(ARGS) || true; \
	else \
		./$(TARGET) $(ARGS) || true; \
	fi

ll: compile
	@if [ -z "$(TEST)" ]; then \
		echo "Usage: make ll TEST=test1"; exit 1; \
	fi
	$(JAVA) -cp $(CLASSPATH) $(MAIN_CLASS) $(TEST_DIR)/$(TARGET).c > $(TARGET).ll
	@echo "Generated $(TARGET).ll"

# ──────────────────────────────────────────
# gen_expected：用 gcc 編譯原始 .c 執行，產生正確的預期輸出
# ──────────────────────────────────────────
gen_expected:
	@mkdir -p $(EXPECTED_DIR)
	@which gcc > /dev/null 2>&1 || (echo "$(RED)找不到 gcc，請先安裝$(RESET)"; exit 1)
	@pass=0; manual=0; \
	for src in $(TEST_SRCS); do \
		name=$$(basename $$src .c); \
		tmpbin=_ref_$$name; \
		dep_srcs=$$($(call READ_DEPS,$$name)); \
		if gcc -o $$tmpbin $$src $$dep_srcs -lm 2>/dev/null; then \
			if [ -f $(TEST_DIR)/$$name.in ]; then \
				./$$tmpbin < $(TEST_DIR)/$$name.in > $(EXPECTED_DIR)/$$name.txt 2>&1 || true; \
				printf "  $(GREEN)SAVED$(RESET)  $(EXPECTED_DIR)/$$name.txt  $(YELLOW)[stdin < $(TEST_DIR)/$$name.in]$(RESET)\n"; \
			else \
				./$$tmpbin > $(EXPECTED_DIR)/$$name.txt 2>&1 || true; \
				printf "  $(GREEN)SAVED$(RESET)  $(EXPECTED_DIR)/$$name.txt\n"; \
			fi; \
			rm -f $$tmpbin; \
			pass=$$((pass+1)); \
		else \
			printf "  $(YELLOW)MANUAL$(RESET) $$name  (gcc 無法編譯，請手動建立 $(EXPECTED_DIR)/$$name.txt)\n"; \
			rm -f $$tmpbin; \
			manual=$$((manual+1)); \
		fi; \
	done; \
	echo ""; \
	echo "$(BOLD)gen_expected 完成：$$pass 筆由 gcc 產生，$$manual 筆需手動處理$(RESET)"

# ──────────────────────────────────────────
# gen_expected1：只為單一測試產生預期輸出
# ──────────────────────────────────────────
gen_expected1:
	@if [ -z "$(TEST)" ]; then \
		echo "Usage: make gen_expected1 TEST=test_scanf"; exit 1; \
	fi
	@mkdir -p $(EXPECTED_DIR)
	@name=$(TARGET); src=$(TEST_DIR)/$(TARGET).c; \
	tmpbin=_ref_$$name; \
	dep_srcs=$$($(call READ_DEPS,$(TARGET))); \
	if gcc -o $$tmpbin $$src $$dep_srcs -lm 2>/dev/null; then \
		if [ -f $(TEST_DIR)/$$name.in ]; then \
			./$$tmpbin < $(TEST_DIR)/$$name.in > $(EXPECTED_DIR)/$$name.txt 2>&1 || true; \
			echo "$(GREEN)SAVED$(RESET) $(EXPECTED_DIR)/$$name.txt  (stdin < $(TEST_DIR)/$$name.in)"; \
		else \
			./$$tmpbin > $(EXPECTED_DIR)/$$name.txt 2>&1 || true; \
			echo "$(GREEN)SAVED$(RESET) $(EXPECTED_DIR)/$$name.txt"; \
		fi; \
		echo "[預期輸出內容:]"; cat $(EXPECTED_DIR)/$$name.txt; \
		rm -f $$tmpbin; \
	else \
		echo "$(RED)gcc 無法編譯 $$src$(RESET)"; \
		echo "請手動建立 $(EXPECTED_DIR)/$$name.txt"; \
		rm -f $$tmpbin; \
	fi

# ──────────────────────────────────────────
# check：執行所有測試，與 expected/ 比對，印出 PASS/FAIL
# ──────────────────────────────────────────
check: compile
	@mkdir -p $(EXPECTED_DIR)
	@total=0; pass=0; fail=0; skip=0; noexp=0; \
	for src in $(TEST_SRCS); do \
		name=$$(basename $$src .c); \
		total=$$((total+1)); \
		$(JAVA) -cp $(CLASSPATH) $(MAIN_CLASS) $$src > $$name.ll 2>$$name_err.txt || true; \
		compiler_err=""; \
		if [ -s $$name_err.txt ]; then \
			compiler_err=$$(cat $$name_err.txt); \
		fi; \
		dep_srcs=$$($(call READ_DEPS,$$name)); \
		if $(CC) $(RUNTIME_SRC) $$dep_srcs $$name.ll -o $$name $(CFLAGS) 2>/dev/null; then \
			if [ -f $(TEST_DIR)/$$name.in ]; then \
				./$$name < $(TEST_DIR)/$$name.in > $$name_actual.txt 2>&1 || true; \
			else \
				./$$name > $$name_actual.txt 2>&1 || true; \
			fi; \
			if [ ! -f $(EXPECTED_DIR)/$$name.txt ]; then \
				printf "  $(YELLOW)NO_EXP$(RESET)  %-30s (make gen_expected1 TEST=$$name)\n" $$name; \
				noexp=$$((noexp+1)); \
			elif diff -q $(EXPECTED_DIR)/$$name.txt $$name_actual.txt > /dev/null 2>&1; then \
				if [ -f $(TEST_DIR)/$$name.in ]; then \
					printf "  $(GREEN)PASS$(RESET)    %-30s $(YELLOW)[stdin]$(RESET)\n" $$name; \
				else \
					printf "  $(GREEN)PASS$(RESET)    %-30s\n" $$name; \
				fi; \
				pass=$$((pass+1)); \
			else \
				if [ -f $(TEST_DIR)/$$name.in ]; then \
					printf "  $(RED)FAIL$(RESET)    %-30s $(YELLOW)[stdin]$(RESET)\n" $$name; \
				else \
					printf "  $(RED)FAIL$(RESET)    %-30s\n" $$name; \
				fi; \
				fail=$$((fail+1)); \
				if [ "$(DIFF)" = "1" ]; then \
					echo "    --- expected  +++ actual"; \
					diff $(EXPECTED_DIR)/$$name.txt $$name_actual.txt | sed 's/^/    /'; \
				else \
					diff $(EXPECTED_DIR)/$$name.txt $$name_actual.txt | head -8 | sed 's/^/    /'; \
				fi; \
				if [ -n "$$compiler_err" ]; then \
					echo "    [compiler stderr]"; \
					echo "$$compiler_err" | head -5 | sed 's/^/      /'; \
				fi; \
			fi; \
		else \
			printf "  $(YELLOW)SKIP$(RESET)    %-30s (clang 無法編譯 .ll)\n" $$name; \
			skip=$$((skip+1)); \
			if [ -n "$$compiler_err" ]; then \
				echo "$$compiler_err" | head -3 | sed 's/^/      /'; \
			fi; \
		fi; \
	done; \
	echo ""; \
	echo "$(BOLD)══════════════════════════════════════$(RESET)"; \
	printf "$(BOLD)  總計 %-3d │ $(GREEN)PASS %-3d$(RESET)$(BOLD) │ $(RED)FAIL %-3d$(RESET)$(BOLD) │ $(YELLOW)SKIP %-3d$(RESET)$(BOLD) │ NO_EXP %-3d$(RESET)\n" \
		$$total $$pass $$fail $$skip $$noexp; \
	echo "$(BOLD)══════════════════════════════════════$(RESET)"; \
	if [ $$fail -gt 0 ]; then exit 1; fi

# ──────────────────────────────────────────
# check1：只跑單一測試並比對
# ──────────────────────────────────────────
check1: compile
	@if [ -z "$(TEST)" ]; then \
		echo "Usage: make check1 TEST=test_array"; exit 1; \
	fi
	@name=$(TARGET); src=$(TEST_DIR)/$(TARGET).c; \
	echo "=============================="; \
	echo "  Checking $$src"; \
	if [ -f $(TEST_DIR)/$(TARGET).in ]; then \
		echo "  stdin  < $(TEST_DIR)/$(TARGET).in"; \
	fi; \
	echo "=============================="; \
	$(JAVA) -cp $(CLASSPATH) $(MAIN_CLASS) $$src > $$name.ll 2>$$name_err.txt || true; \
	if [ -s $$name_err.txt ]; then echo "[Compiler STDERR]"; cat $$name_err.txt; fi; \
	dep_srcs=$$($(call READ_DEPS,$(TARGET))); \
	if $(CC) $(RUNTIME_SRC) $$dep_srcs $$name.ll -o $$name $(CFLAGS) 2>/dev/null; then \
		if [ -f $(TEST_DIR)/$$name.in ]; then \
			./$$name < $(TEST_DIR)/$$name.in > $$name_actual.txt 2>&1 || true; \
		else \
			./$$name > $$name_actual.txt 2>&1 || true; \
		fi; \
		echo "[Actual output:]"; cat $$name_actual.txt; \
		if [ ! -f $(EXPECTED_DIR)/$$name.txt ]; then \
			echo ""; echo "$(YELLOW)NO EXPECTED FILE$(RESET): $(EXPECTED_DIR)/$$name.txt"; \
			echo "執行 make gen_expected1 TEST=$$name 用 gcc 產生"; \
		else \
			echo ""; \
			if diff -q $(EXPECTED_DIR)/$$name.txt $$name_actual.txt > /dev/null 2>&1; then \
				echo "$(GREEN)$(BOLD)✓ PASS$(RESET)"; \
			else \
				echo "$(RED)$(BOLD)✗ FAIL — diff (expected vs actual):$(RESET)"; \
				diff $(EXPECTED_DIR)/$$name.txt $$name_actual.txt; \
			fi; \
		fi; \
	else \
		echo "$(RED)[Clang 停止] LLVM IR 無法編譯$(RESET)"; \
	fi

# ──────────────────────────────────────────
clean:
	rm -f *.s *.class *_err.txt *_actual.txt _ref_*
	rm -f myCompilerLexer.java myCompilerParser.java myCompilerListener.java
	rm -f myCompilerBaseListener.java myCompilerVisitor.java myCompilerBaseVisitor.java
	rm -f myCompiler.tokens myCompilerLexer.tokens
	rm -f $(TESTS)

clean_all: clean
	rm -f *.interp *.ll

.PHONY: all gen compile run_all run ll check check1 gen_expected gen_expected1 clean clean_all