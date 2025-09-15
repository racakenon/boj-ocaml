# Language selection (default: ocaml)
L ?= ocaml

# Language-specific settings
ifeq ($(L),ocaml)
SRC := Main.ml
EXEC := Main
COMPILE := ocamlopt -O2 -o $(EXEC) $(SRC)
RUN := ./$(EXEC)
else ifeq ($(L),scheme)
SRC := Main.scm
EXEC := Main
COMPILE := csc -output-file $(EXEC) -O5 $(SRC)
RUN := ./$(EXEC)
else ifeq ($(L),rust)
SRC := Main.rs
EXEC := Main
COMPILE := rustc --edition 2021 -O -o $(EXEC) $(SRC)
RUN := ./$(EXEC)
else ifeq ($(L),python)
SRC := Main.py
EXEC := Main.py
COMPILE := python3 -W ignore -c "import py_compile; py_compile.compile(r'$(SRC)')"
RUN := python3 -W ignore $(EXEC)
else ifeq ($(L),c++)
SRC := Main.cc
EXEC := Main
COMPILE := clang++ $(SRC) -o $(EXEC) -O2 -Wall -lm -static -std=c++17 -DONLINE_JUDGE -DBOJ
RUN := ./$(EXEC)
else
$(error Unsupported language: $(L). Use: ocaml, scheme, rust, python, c++)
endif

# Find all test cases
CASES := $(patsubst input%,%,$(wildcard input*))

# Default: build and run all tests
all: run

# Build executable
$(EXEC): $(SRC)
	@$(COMPILE)

# Run all test cases
run: $(EXEC)
	@for case in $(CASES); do \
		$(MAKE) -s test case=$$case L=$(L); \
	done

# Test a single case
test: $(EXEC)
	@if [ -z "$(case)" ]; then \
		echo "Error: specify case number"; \
		exit 1; \
	fi
	@INPUT="input$(case)"; \
	EXPECTED="output$(case)"; \
	ACTUAL="actual$(case)"; \
	\
	echo "===== Test Case #$(case) ($(L)) ====="; \
	$(RUN) < "$$INPUT" > "$$ACTUAL"; \
	\
	if diff -q "$$ACTUAL" "$$EXPECTED" > /dev/null 2>&1; then \
		echo "PASS"; \
	else \
		echo "FAIL"; \
		diff -u "$$ACTUAL" "$$EXPECTED"; \
	fi; \
	rm -f "$$ACTUAL"

# Clean build artifacts
clean:
	@rm -f Main actual* *.pyc __pycache__
	@rm -rf Main.dSYM

# Move solution to problem directory (organized by 100s and language)
# sol1 -> 00000/1/ocaml/ (or python/, rust/, etc.)
# sol234 -> 00200/234/ocaml/
# sol1234 -> 01200/1234/ocaml/
sol%:
	@if [ ! -f "$(SRC)" ]; then \
		echo "Error: $(SRC) not found"; \
		exit 1; \
	fi
	@num=$*; \
	parent=$$((num / 100 * 100)); \
	dir="$$(printf "%05d/%d/$(L)" $$parent $$num)"; \
	mkdir -p "$$dir"; \
	mv $(SRC) input* output* "$$dir/" 2>/dev/null || true; \
	if [ -f "$(EXEC)" ] && [ "$(EXEC)" != "$(SRC)" ]; then \
		rm -f "$(EXEC)"; \
	fi; \
	touch $(SRC); \
	echo "Moved to $$dir/"

.PHONY: all run test clean sol%
