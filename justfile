# Justfile for ARM64 assembly + C

# Build and run (default)
default: run

# Build the program
build:
	mkdir -p ./build
	gcc main.c defang_ip_addr.s -o ./build/defang

run: build
	./build/defang

# Clean up
clean:
	rm -f ./build/*.o ./build/defang