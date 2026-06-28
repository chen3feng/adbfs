FUSE_PKG ?= fuse
CXXFLAGS=-Wall $(if $(filter fuse-t,$(FUSE_PKG)),-D_FILE_OFFSET_BITS=64) $(shell pkg-config $(FUSE_PKG) --cflags)
LDFLAGS=-Wall $(shell pkg-config $(FUSE_PKG) --libs)

TARGET=adbfs
DESTDIR?=/
INSTALL_DIR?=${DESTDIR}/usr/

all:	$(TARGET)

debug: CXXFLAGS += -DDEBUG -g
debug: $(TARGET)

adbfs.o: adbfs.cpp utils.h
	$(CXX) -c -o adbfs.o adbfs.cpp $(CXXFLAGS) $(CPPFLAGS)

$(TARGET): adbfs.o
	$(CXX) -o $(TARGET) adbfs.o $(LDFLAGS)

# macOS convenience: build both FUSE backends side by side as adbfs-macfuse
# and adbfs-fuset. Each is a separate sub-build because the FUSE library is
# selected at compile/link time.
.PHONY: both
both:
	rm -f adbfs.o $(TARGET)
	$(MAKE) FUSE_PKG=fuse
	mv -f $(TARGET) $(TARGET)-macfuse
	rm -f adbfs.o $(TARGET)
	$(MAKE) FUSE_PKG=fuse-t
	mv -f $(TARGET) $(TARGET)-fuset
	rm -f adbfs.o
	@echo "Built $(TARGET)-macfuse (macFUSE) and $(TARGET)-fuset (fuse-t)"

.PHONY: clean

clean:
	rm -rf *.o html/ latex/ $(TARGET) $(TARGET)-macfuse $(TARGET)-fuset

doc: Doxyfile
	doxygen $<

install: ${TARGET}
	install -d ${INSTALL_DIR}/bin
	install -s $< ${INSTALL_DIR}/bin/
