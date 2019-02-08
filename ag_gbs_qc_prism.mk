# ag_gbs_qc_prism.mk prism main makefile
#***************************************************************************************
# references:
#***************************************************************************************
# make: 
#     http://www.gnu.org/software/make/manual/make.html
#

########## non-standard analysis - these not (currently) part of "all" as expensive
%.annotation:   %.blast_analysis
	$@.sh > $@.mk.log 2>&1
	date > $@

%.blast_analysis:   %.fasta_sample
	$@.sh > $@.mk.log 2>&1
	date > $@

########## standard analysis 
%.all:  %.allkmer_analysis %.bwa_mapping 
	date > $@

%.allkmer_analysis:   %.kmer_analysis
	$@.sh > $@.mk.log 2>&1
	date > $@

%.kmer_analysis:   %.fasta_sample
	$@.sh > $@.mk.log 2>&1
	date > $@

%.fasta_sample:   %.unblind
	$@.sh > $@.mk.log 2>&1
	date > $@

%.unblind:   %.kgd
	$@.sh > $@.mk.log 2>&1
	date > $@

%.kgd:   %.demultiplex
	$@.sh > $@.mk.log 2>&1
	date > $@

%.demultiplex:
	$@.sh > $@.mk.log 2>&1
	date > $@

%.bwa_mapping:
	$@.sh > $@.mk.log 2>&1
	date > $@

.PHONY: %.clean
%.clean: 
	$@.sh > $@.mk.log 2>&1


##############################################
# specify the intermediate files to keep 
##############################################
.PRECIOUS: %.log %.ag_gbs_qc_prism %.blast_analysis %.kmer_analysis %.kgd %.demultiplex %.all %.fasta_sample
