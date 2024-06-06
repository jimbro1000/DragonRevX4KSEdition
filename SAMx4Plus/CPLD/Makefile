# Xilinx ISE build rules
#
# Ensure you have sourced the ISE settings script before attempting to use this
# Makefile.
#
# Requires GNU Make.

PROJECT = samx4

ENTITY = samx4

WORKFILES = div2.vhd div3.vhd div4.vhd samx4.vhd

VARIANTS = $(PROJECT) $(PROJECT)-785 \
	$(PROJECT)-rockyhill $(PROJECT)-785-rockyhill

ALL_VARIANTS = $(VARIANTS) \
	$(PROJECT)-scroll $(PROJECT)-785-scroll \
	$(PROJECT)-scroll-rockyhill $(PROJECT)-785-scroll-rockyhill

.PHONY: default
default: $(foreach var,$(VARIANTS),$(var).jed $(var).svf $(var)_timing.html)

.PHONY: all
all: $(foreach var,$(ALL_VARIANTS),$(var).jed $(var).svf $(var)_timing.html)

.PHONY: timing
timing: $(foreach var,$(VARIANTS),$(var)_timing.html)

## General options

FAMILY = xc9500xl
DEVICE = xc95144xl
PACKAGE = TQ100
SPEED = -5

## XST options

# Optimization Goal
# Speed | Area
XST_OPT_MODE = Speed

# Optimization Effort
# 1 | 2
XST_OPT_LEVEL = 2

# FSM Encoding Algorithm
# One-Hot | Compact | Sequential | Gray | ...
XST_FSM_ENCODING = One-Hot

## NGDBUILD options

# Uncomment if a pin spec file is included
NGDBUILD_UC = $(PROJECT).ucf

## CPLDFIT options

# Output Slew Rate
# slow | fast | auto
CPLDFIT_SLEW = slow

# Default Powerup Value of Registers
# low | high | fpga
CPLDFIT_INIT = low

# I/O Pin Termination
# keeper | float
CPLDFIT_TERMINATE = keeper

# Create Programmable GND Pins on Unused I/O
# float | ground
CPLDFIT_UNUSED = ground

# Macrocell Power Setting
# std | low | auto
CPLDFIT_POWER = low

# Logic Optimization
# speed | density
CPLDFIT_OPTIMIZE = speed

# Use Multi-Level Logic Optimization
# Uncomment to disable
#CPLDFIT_NOMLOPT = -nomlopt

# Collapsing Input Limit (2-54)
CPLDFIT_INPUTS = 54

# Collapsing Pterm Limit (1-90)
CPLDFIT_PTERMS = 25

###

# Variant overrides

$(PROJECT)-785.ngc: XST_GENERICS = want_785=true

$(PROJECT)-rockyhill.ngd: NGDBUILD_UC = $(PROJECT)-rockyhill.ucf
$(PROJECT)-rockyhill.vm6: CPLDFIT_INPUTS = 17

$(PROJECT)-785-rockyhill.ngc: XST_GENERICS = want_785=true
$(PROJECT)-785-rockyhill.ngd: NGDBUILD_UC = $(PROJECT)-rockyhill.ucf
$(PROJECT)-785-rockyhill.vm6: CPLDFIT_INPUTS = 17

$(PROJECT)-scroll.ngc: XST_GENERICS = want_scroll=true want_4K=false want_16K=false
$(PROJECT)-scroll.vm6: CPLDFIT_PTERMS = 14

$(PROJECT)-785-scroll.ngc: XST_GENERICS = want_785=true want_scroll=true want_4K=false want_16K=false
$(PROJECT)-785-scroll.vm6: CPLDFIT_PTERMS = 14

# Need to disable 256K support as well to fit scroll registers into the
# rockyhill pinning

$(PROJECT)-scroll-rockyhill.ngc: XST_GENERICS = want_scroll=true want_256K=false want_4K=false want_16K=false
$(PROJECT)-scroll-rockyhill.ngd: NGDBUILD_UC = $(PROJECT)-rockyhill.ucf
$(PROJECT)-scroll-rockyhill.vm6: CPLDFIT_INPUTS = 54
$(PROJECT)-scroll-rockyhill.vm6: CPLDFIT_PTERMS = 15

$(PROJECT)-785-scroll-rockyhill.ngc: XST_GENERICS = want_785=true want_scroll=true want_256K=false want_4K=false want_16K=false
$(PROJECT)-785-scroll-rockyhill.ngd: NGDBUILD_UC = $(PROJECT)-rockyhill.ucf
$(PROJECT)-785-scroll-rockyhill.vm6: CPLDFIT_INPUTS = 30
$(PROJECT)-785-scroll-rockyhill.vm6: CPLDFIT_PTERMS = 15

###

CPLDFIT_OPTS += \
	$(if $(CPLDFIT_SLEW),-slew $(CPLDFIT_SLEW),) \
	$(if $(CPLDFIT_INIT),-init $(CPLDFIT_INIT),) \
	$(if $(CPLDFIT_TERMINATE),-terminate $(CPLDFIT_TERMINATE),) \
	$(if $(CPLDFIT_UNUSED),-unused $(CPLDFIT_UNUSED),) \
	$(if $(CPLDFIT_POWER),-power $(CPLDFIT_POWER),) \
	$(if $(CPLDFIT_OPTIMIZE),-optimize $(CPLDFIT_OPTIMIZE),) \
	$(if $(CPLDFIT_INPUTS),-inputs $(CPLDFIT_INPUTS),) \
	$(if $(CPLDFIT_PTERMS),-pterms $(CPLDFIT_PTERMS),)

NGDBUILD_OPTS += \
	$(if $(NGDBUILD_UC),-uc $(NGDBUILD_UC),)

###

CLEAN =
DISTCLEAN =

###

DISTCLEAN += \
	$(PROJECT).cmd_log \
	$(PROJECT).gise \
	$(PROJECT).stx \
	$(PROJECT).tim \
	$(PROJECT)_envsettings.html \
	$(PROJECT)_summary.html \
	tmperr.err \
	webtalk_pn.xml

###

.PHONY: xst
xst: $(PROJECT).ngc
	@awk '/^\*  *Final Report/{a=2} a; /====/{if(a > 0){a--}}' $(PROJECT).syr

.PHONY: fit
fit: $(PROJECT).vm6
	@head -30 $(PROJECT).rpt

.PHONY: jed
jed: $(PROJECT).jed

.PHONY: svf
svf: $(PROJECT).svf

###

# Generate XST input files

%.xst: xst.tmpl
	sed -e 's/%FILENAME%/$(@:.xst=)/g' \
		-e 's/%ENTITY%/$(ENTITY)/g' \
		-e 's/%FAMILY%/$(FAMILY)/g' \
		-e 's/%OPT_MODE%/$(XST_OPT_MODE)/g' \
		-e 's/%OPT_LEVEL%/$(XST_OPT_LEVEL)/g' \
		-e 's/%FSM_ENCODING%/$(XST_FSM_ENCODING)/g' \
		-e 's/%GENERICS%/$(XST_GENERICS)/g' \
		$< > $@

%.prj: $(WORKFILES)
	for i in $(WORKFILES); do echo vhdl work \""$$i"\"; done > $@

CLEAN += $(foreach ext,.xst .prj,$(foreach var,$(ALL_VARIANTS),$(var)$(ext)))

# Synthesis

%.ngc: %.xst %.prj
	@if test -z "$(XILINX)"; then echo "XILINX not set" >&2; exit 1; fi
	mkdir -p xst/projnav.tmp
	xst -intstyle xflow -ifn $< -ofn $(@:.ngc=.syr)

CLEAN += $(foreach ext,.lso .ngr .ngc .syr _xst.xrpt,$(foreach var,$(ALL_VARIANTS),$(var)$(ext)))

%.ngd: %.ngc
	@if test -z "$(XILINX)"; then echo "XILINX not set" >&2; exit 1; fi
	ngdbuild -intstyle ise -dd _ngo $(NGDBUILD_OPTS) \
		-p $(DEVICE)-$(PACKAGE)$(SPEED) $< $@

CLEAN += $(foreach ext,.ngd .bld _ngdbuild.xrpt,$(foreach var,$(ALL_VARIANTS),$(var)$(ext)))

%.vm6: %.ngd
	@if test -z "$(XILINX)"; then echo "XILINX not set" >&2; exit 1; fi
	cpldfit -intstyle ise -p $(DEVICE)$(SPEED)-$(PACKAGE) -ofmt vhdl \
		$(CPLDFIT_OPTS) -htmlrpt -loc on $<

CLEAN += $(foreach ext,.rpt _build.xml .xml .pad _pad.csv .vm6 .pnx .mfd .gyd,$(foreach var,$(ALL_VARIANTS),$(var)$(ext)))

%.nga: %.vm6
	@if test -z "$(XILINX)"; then echo "XILINX not set" >&2; exit 1; fi
	tsim -intstyle ise $(<:.vm6=) $@

CLEAN += $(foreach ext,.nga,$(foreach var,$(ALL_VARIANTS),$(var)$(ext)))

%.jed: %.vm6
	@if test -z "$(XILINX)"; then echo "XILINX not set" >&2; exit 1; fi
	hprep6 -s IEEE1149 -n $(PROJECT) -i $<

CLEAN += $(foreach ext,.jed,$(foreach var,$(ALL_VARIANTS),$(var)$(ext)))

%.to-svf.script: jed-to-svf.tmpl
	sed -e 's/%FILENAME%/$(@:.to-svf.script=)/g' $< > $@

%.svf: %.jed %.to-svf.script
	@if test -z "$(XILINX)"; then echo "XILINX not set" >&2; exit 1; fi
	impact -batch $(<:.jed=.to-svf.script)

CLEAN += $(foreach ext,.svf .to-svf.script,$(foreach var,$(ALL_VARIANTS),$(var)$(ext)))
CLEAN += _impactbatch.log

%_timing.html: %.vm6
	@if test -z "$(XILINX)"; then echo "XILINX not set" >&2; exit 1; fi
	touch tagui.out
	taengine -intstyle xflow -f $< -w --format html1 -l $@
	rm -f tagui.out

CLEAN += $(foreach ext,_timing.html .tspec,$(foreach var,$(ALL_VARIANTS),$(var)$(ext)))

###

.PHONY: clean
clean:
	test -d "_ngo" && rm -rf "_ngo" || true
	test -d "_xmsgs" && rm -rf "_xmsgs" || true
	test -d "iseconfig" && rm -rf "iseconfig" || true
	for v in $(ALL_VARIANTS); do test -d "$${v}_html" && rm -rf "$${v}_html" || true; done
	test -d "xlnx_auto_0_xdb" && rm -rf "xlnx_auto_0_xdb" || true
	test -d "xst" && rm -rf "xst" || true
	rm -f $(CLEAN)

.PHONY: clena
clena: clean
	@echo "How much clena do you want it?"

.PHONY: distclean
distclean: clean
	rm -f $(DISTCLEAN)
