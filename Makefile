WEB_TREE_SITTER=README.md package.json tree-sitter-web.d.ts tree-sitter.js tree-sitter.wasm
TREE_SITTER_VERSION=v0.20.1

all: node_modules/web-tree-sitter tree-sitter-haskell.wasm

# build parser.c
src/parser.c: grammar.js
	npx tree-sitter generate

# build patched version of web-tree-sitter
node_modules/web-tree-sitter:
	if [ ! -d "tmp/tree-sitter" ]; then git clone https://github.com/tree-sitter/tree-sitter.git tmp/tree-sitter; fi
	cd tmp/tree-sitter && git checkout $(TREE_SITTER_VERSION)
	cp tree-sitter.patch tmp/tree-sitter/
	cd tmp/tree-sitter\
		&& git apply tree-sitter.patch\
		&& ./script/build-wasm
	mkdir -p node_modules/web-tree-sitter
	cp tmp/tree-sitter/LICENSE node_modules/web-tree-sitter
	cp $(addprefix tmp/tree-sitter/lib/binding_web/,$(WEB_TREE_SITTER)) node_modules/web-tree-sitter
	rm -rf tmp/tree-sitter

# build web version of tree-sitter-haskell
# NOTE: requires patched version of web-tree-sitter
tree-sitter-haskell.wasm: src/parser.c src/scanner.c
	npx tree-sitter build-wasm

CC := cc
OURCFLAGS := -shared -fPIC -g -O0 -I src

clean:
	rm -f debug *.o *.a

debug.so: src/parser.c src/scanner.c
	$(CC) $(OURCFLAGS) $(CFLAGS) -o parser.o src/parser.c
	$(CC) $(OURCFLAGS) $(CFLAGS) -o scanner.o src/scanner.c
	$(CC) $(OURCFLAGS) $(CFLAGS) -o debug.so $(PWD)/scanner.o $(PWD)/parser.o
	rm -f $(HOME)/.cache/tree-sitter/lib/haskell.so
	cp $(PWD)/debug.so $(HOME)/.cache/tree-sitter/lib/haskell.so
