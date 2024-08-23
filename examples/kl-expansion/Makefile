######################################################################
# Use the MOOSE submodule if it exists and MOOSE_DIR is not set
MOOSE_SUBMODULE    := $(CURDIR)/../../moose
ifneq ($(wildcard $(MOOSE_SUBMODULE)/framework/Makefile),)
  MOOSE_DIR        ?= $(MOOSE_SUBMODULE)
else
  MOOSE_DIR        ?= $(CURDIR)/../../../moose
endif

######################################################################
# Set LIBMESH_DIR if it is not already set in the environment (try our best to guess!)
LIBMESH_DIR       ?= $(MOOSE_DIR)/libmesh/installed
# include the library options determined by configure
include $(LIBMESH_DIR)/Make.common
# boost
libmesh_INCLUDE   += -I$(BOOST_DIR)

###############################################################################
# source files
srcfiles 	         := $(wildcard *.C)

srcfiles_factorize := $(filter-out sample.C, $(srcfiles))
objects_factorize  := $(patsubst %.C, %.$(obj-suffix), $(srcfiles_factorize))

srcfiles_sample    := $(filter-out factorize.C, $(srcfiles))
objects_sample     := $(patsubst %.C, %.$(obj-suffix), $(srcfiles_sample))

###############################################################################
.PHONY: dust clean clobber distclean

all:: factorize-$(METHOD) sample-$(METHOD)

# Factorization
factorize-$(METHOD): $(objects_factorize)
	@echo "Linking "$@"..."
	@$(libmesh_LIBTOOL) --tag=CXX $(LIBTOOLFLAGS) --mode=link \
	  $(libmesh_CXX) $(libmesh_CXXFLAGS) $(objects_factorize) -o $@ $(libmesh_LIBS) $(libmesh_LDFLAGS) $(EXTERNAL_FLAGS)

# Sampling
sample-$(METHOD): $(objects_sample)
	@echo "Linking "$@"..."
	@$(libmesh_LIBTOOL) --tag=CXX $(LIBTOOLFLAGS) --mode=link \
	  $(libmesh_CXX) $(libmesh_CXXFLAGS) $(objects_sample) -o $@ $(libmesh_LIBS) $(libmesh_LDFLAGS) $(EXTERNAL_FLAGS)

dust:
	@echo "Deleting old output and runtime files"
	@rm -f out*.m job_output.txt output.txt* *.gmv.* *.plt.* out*.xdr* out*.xda* PI* complete

clean: dust
	@rm -f $(objects) *.$(obj-suffix) *.lo

clobber: clean
	@rm -f *-$(METHOD)

distclean: clean
	@rm -rf *.o .libs
