.PHONY: all clean test get-deps

CXX=g++
CXXFLAGS=-O3 -std=c++11 -fopenmp -g
LIBS=cpp/vg.pb.o xg.o # main.o not included for easier libxg.a creation
INCLUDES=-I./ -Icpp -Istream/protobuf/build/include -Isdsl-lite/build/include -Isdsl-lite/build/external/libdivsufsort-2.0.1/include -Istream
LDSEARCH=-L./ -Lstream/protobuf -Lsdsl-lite/build/lib -Lsdsl-lite/build/external/libdivsufsort-2.0.1/lib
LDFLAGS=-lprotobuf -lsdsl -lz -ldivsufsort -ldivsufsort64 -lgomp -lm -lpthread
STREAM=stream
PROTOBUF=$(STREAM)/protobuf
LIBPROTOBUF=stream/protobuf/libprotobuf.a
LIBSDSL=sdsl-lite/build/lib/libsdsl.a
CMAKE_BIN=cmake-3.3.0-rc2-Linux-x86_64/bin/cmake
EXECUTABLE=xg

all: $(EXECUTABLE)

doc: README.md
README.md: README.base.md
	pandoc -o README.html -s README.base.md
	pandoc -o DESIGN.html -s DESIGN.md
	cat README.base.md >README.md
	cat DESIGN.html | tail -7| perl -p -e 's/<p>/\n/g' | sed 's%</p>%%g' | head -10 >>README.md

$(LIBPROTOBUF):
	cd $(STREAM) && $(MAKE)

$(LIBSDSL): $(CMAKE_BIN)
	PATH=cmake-3.3.0-rc2-Linux-x86_64/bin/:${PATH} cmake --version
	cd sdsl-lite/build && PATH=../../cmake-3.3.0-rc2-Linux-x86_64/bin/:${PATH} cmake .. -Wno-dev && $(MAKE)

cpp/vg.pb.cc: cpp/vg.pb.h
cpp/vg.pb.h: vg.proto $(LIBPROTOBUF)
	mkdir -p cpp
	$(PROTOBUF)/build/bin/protoc vg.proto --cpp_out=cpp
cpp/vg.pb.o: cpp/vg.pb.h cpp/vg.pb.cc
	$(CXX) $(CXXFLAGS) -c -o cpp/vg.pb.o cpp/vg.pb.cc $(INCLUDES)

main.o: main.cpp $(LIBSDSL) cpp/vg.pb.h xg.hpp 
	$(CXX) $(CXXFLAGS) -c -o main.o main.cpp $(INCLUDES)

xg.o: xg.cpp xg.hpp $(LIBSDSL) cpp/vg.pb.h
	$(CXX) $(CXXFLAGS) -c -o xg.o xg.cpp $(INCLUDES)

$(EXECUTABLE): $(LIBS) main.o
	$(CXX) $(CXXFLAGS) -o $(EXECUTABLE) $(LIBS) main.o $(INCLUDES) $(LDSEARCH) -static -static-libstdc++ -static-libgcc -Wl,-Bstatic $(LDFLAGS)

libxg.a: $(LIBS)
	ar rs libxg.a $(LIBS)

$(CMAKE_BIN):
	wget http://www.cmake.org/files/v3.3/cmake-3.3.0-rc2-Linux-x86_64.tar.gz
	tar xzvf cmake-3.3.0-rc2-Linux-x86_64.tar.gz

get-deps: $(CMAKE_BIN)


test:
	cd test && make

clean-xg:
	rm -f *.o xg cpp/*

clean:
	rm -rf cpp
	rm -f $(EXECUTABLE)
	rm -f *.o
	rm $(LIBPROTOBUF)
	cd $(PROTOBUF) && $(MAKE) clean && rm -rf build
	rm -rf cmake-3.3.0-rc2-Linux-x86_64.tar.gz cmake-3.3.0-rc2-Linux-x86_64
