UNAME_KERNEL  := $(shell uname -s)
UNAME_MACHINE := $(shell uname -m)

# To make everything be rebuilt if the Makefile changes, uncomment
#ALL_DEPEND := Makefile

ifeq "${UNAME_KERNEL}" "OS/390"
OSTYPE := zOS
else
ifeq "${UNAME_KERNEL}" "Linux"
ifeq "${UNAME_MACHINE}" "s390x"
OSTYPE := zLinux
else
OSTYPE := Linux
endif
else
$(error "Unknown kernel type ${UNAME_KERNEL}")
endif
endif

EMPTY = 

#DEBUG = -g
ifneq "${DEBUG}"  "-g"
  OPT = -O2
  DEBUG = -DNDEBUG
endif

ifeq "${OSTYPE}" "zLinux"
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td

CPPFLAGS = \
 -I. \
 -m32 \
 -Wall \
 -D__STDC_FORMAT_MACROS \
 -D_XOPEN_SOURCE=600 \
 ${SORT_DEFINITIONS} \
 ${EMPTY}

CC = gcc
CFLAGS = \
 ${OPT} ${DEBUG} \
 -std=c99 \
 ${EMPTY}

CXX = g++
CXXFLAGS = \
 ${OPT} ${DEBUG} \
 ${EMPTY}

LINK = g++ -m32 -lpthread ${DEBUG}
endif

ifeq "${OSTYPE}" "zOS"
LOADLIB := x.load

DEPFLAGS = -MT $@ -MG -qmakedep=gcc -MF $(DEPDIR)/$*.Td

SYS_INCLUDE = /usr/include

CPPFLAGS = \
 -I. -I${SYS_INCLUDE} \
 -D${OSTYPE} \
 -D_XOPEN_SOURCE=600 -D_XOPEN_SOURCE_EXTENDED=1 \
 -D__STDC_FORMAT_MACROS \
 -D__MV17195__ \
 ${EMPTY}

CC = xlc \
 -q32 \
 -qasm \
 -qlanglvl=extc99 \
 -qseverity=e=CCN3296 -qseverity=e=CCN3950 \
 -qnocse -qnosearch \
 ${EMPTY}

ifneq "${LIST}" ""
LISTOPT = -V -qlist=${basename $<}.lst
endif

CFLAGS = \
 ${OPT} ${DEBUG} ${LISTOPT} \
 -qsuppress=CCN4108\
 ${EMPTY}

CXX := xlC \
 -q32 \
 -qasm \
 -qasmlib="//'SYS1.MACLIB'" \
 ${EMPTY}

CXXFLAGS = \
 ${OPT} ${DEBUG} ${LISTOPT} \
 -qsuppress=CCN6639 \
 ${EMPTY}

# Assembly code stuff
AS := as
ASLIST := -aegmrsx
ASOPTS := \
 -mgoff \
 -mobject \
 -msectalgn=4096 \
 -mflag=nocont \
 --"TERM,LC(0)" \
 -g \
 --gadata \
 -I vendor.xdc.xdcmacs \
 -I . \
 -I SYS1.SICEUSER \
 ${EMPTY}

ASDEPEND := \
	${EMPTY}

# Assemble a .s source file if the corresponding .o is older
%.o : %.s ${ASDEPEND}
	${AS} ${ASLIST}=$(basename $<).lst ${ASOPTS}  -o $@ $<

LINK = xlC ${DEBUG} -q32
endif

ifeq "${OSTYPE}" "zOS"
ZOS_SRCS = \
 ${EMPTY}
endif

# List all source files (NOT headers) in SRCS; these will be
# processed to have dependencies auto-generated
SRCS = \
 sysevent.cpp \
 ${ZOS_SRCS} \
 ${EMPTY}

# Targets start here

ifeq "${OSTYPE}" "zOS"
default: test
endif

ifeq "${OSTYPE}" "zLinux"
default: 
endif

ifeq "${OSTYPE}" "zOS"
MVSOBJS := \
 ${EMPTY}
endif

test: sysevent
	./sysevent

sysevent: sysevent.o \
 ${EMPTY}
	${LINK} -o $@ $^


ifeq "${OSTYPE}" "zOS"
MVS_PROGRAMS := \
 sysevent \
 ${EMPTY}
endif

PROGRAMS := \
 ${MVS_PROGRAMS} \
 ${EMPTY}

programs: ${PROGRAMS}

clean:
	rm -f ${PROGRAMS} ${EXITS} ${EXITFLAGS} *.o *.dbg *.lst *.ad $(DEPDIR)/*

veryclean: clean
	rm -f *~ 
	rmdir $(DEPDIR)

# Stolen dependency generation code
DEPDIR := .d
$(shell mkdir -p $(DEPDIR) >/dev/null)

COMPILE.c = $(CC) $(DEPFLAGS) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE.cc = $(CXX) $(DEPFLAGS) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
POSTCOMPILE = mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d

%.o : %.c
%.o : %.c $(DEPDIR)/%.d ${ALL_DEPEND}
	$(COMPILE.c) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)

%.o : %.cpp
%.o : %.cpp $(DEPDIR)/%.d ${ALL_DEPEND}
	$(COMPILE.cc) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

-include $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS)))
