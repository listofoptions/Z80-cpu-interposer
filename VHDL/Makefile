# VHDL CODE OF THE NABU Z80 CPU INTERPOSER
# Copyright (C) 2022  LISTOFOPTIONS, PURDEAANDREI
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# three backends for ghdl can be used: *-gcc/-llvm, and *-mcode
# change to *-mcode when/if you cant use the compiled backend



# analysis flags
AFLAGS     := --warn-error --warn-reserved --warn-default-binding --warn-library --warn-body --warn-specs
# elaboration flags
EFLAGS     := --warn-error --warn-binding --warn-library --warn-specs
# run flags
RFLAGS     := --warn-error
GHDL       := ghdl-gcc
PACKAGES   := mapper.vhd
BUILDABLES := bank_device.vhd test_bench.vhd
# order of files is annoyingly required
WORK       := $(PACKAGES) $(BUILDABLES)
# entity names for testing device
TENTITIES  := test_bench
# entity names for building device
BENTITIES  := bank_device



all            : test

clean          :
	$(GHDL) --clean

clean-all      : clean
	rm *.cf

analyze        : $(WORK) clean
	$(GHDL) -a $(AFLAGS) $(WORK)

elaborate      : analyze
	$(GHDL) -e $(EFLAGS) $(BENTITIES)

elaborate-test : elaborate
	$(GHDL) -e $(EFLAGS) $(TENTITIES)

test           : elaborate-test
	$(GHDL) -r $(RFLAGS) $(TENTITIES)
