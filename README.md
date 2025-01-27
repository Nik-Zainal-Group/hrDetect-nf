# hrDetect-nf

A Nextflow pipeline that analyses somatic mutation signatures and generates hrDetect scores. It functions as a wrapper for several other tools. The steps included are:

1) prepareData. This step runs [prepareData](https://github.com/Nik-Zainal-Group/utility.scripts/blob/master/prepareData/prepareData.R) that filters and prepares raw variant data for use as input to signatureFit and hrDetect steps.
2) signatureFit. The signature fit [script](https://github.com/Nik-Zainal-Group/signature.tools.lib/blob/master/scripts/signatureFit) is executed for each of the supported variant callers using the provided input parameters.
3) solutionSelectionForFitMS. In the instance when the signatureFit method is FitMS, a specific signature can be chosen to pass into the hrDetect step.
4) hrDetect. If all of the necessary data files, including CNV, SNV, Indels, and SVs, are provided, the pipeline can complete this [phase](https://github.com/Nik-Zainal-Group/signature.tools.lib/blob/master/scripts/hrDetect).


The tools listed above have been [dockerised](https://quay.io/organization/nikzainalgroup). During execution, Nexflow pulls the docker images and utilised them.

## Usage

The simple example command run is as

nextflow run hrDetect-nf --inputlist inputlist.csv --organ "Breast" --prepareData_params "-c -a 115 -p" --solutionSelectionForFitMS "sample1:common,sampleN:rareSigs_2" --signatureFit_params_caveman "-b -m FitMS" --signatureFit_params_brass "-b -m Fit"


## Input

inputlist.csv is the path to a list of data files separated by commas. 'sample' must appear in the first column, followed by variant caller names. Example:

cat inputlist.csv
```
sample,ascat,brass,caveman,pindel
name1,s1.ascat.csv,s1.brass.bedpe.gz,s1.caveman.vcf.gz,s1.pindel.vcf.gz
name2,s2.ascat.csv,s2.brass.bedpe.gz,s2.caveman.vcf.gz,s2.pindel.vcf.gz
...
```

The algorithms can appear in any order and must be one of ascat, caveman, pindel, strelka, strelkasnv, strelkaindels, brass, manta, canvas supported by [prepareData](https://github.com/Nik-Zainal-Group/utility.scripts/blob/master/prepareData/prepareData.R). The script requires Tabix-indexed VCF input data, except for ascat and brass where the input data format should be .csv and .bedpe.gz respectively.

## Parameters


| param | default | description | 
|---|---|---|
| `inputlist` | `null` | A CSV file list of input data to be analysed |
| `organ` | `"Breast"` | Organ-specific signatures defined in [signatureFit](https://github.com/Nik-Zainal-Group/signature.tools.lib/blob/master/scripts/signatureFit) |
| `genome_version` | `hg38` | Genome reference versions, Options - `hg19`, `hg38` or `mm10` accepted by [signatureFit](https://github.com/Nik-Zainal-Group/signature.tools.lib/blob/master/scripts/signatureFit) |
| `prepareData_params` | PASS + standard filters (See inside [nextflow.config](nextflow.config)) | Optional parameters to be passed to [prepareData](https://github.com/Nik-Zainal-Group/utility.scripts/blob/master/prepareData/prepareData.R) |
| `signatureFit_params_${snv_caller}` | `"-b -m FitMS -p 5 -a errorReduction -q T2 -T T2 -E 20 -f 200 -r 1"` | $snv_caller can be one of 'caveman', 'strelka' or 'strelkasnv' |
| `signatureFit_params_${sv_caller}` | `"-b -m Fit -p 5 -P 5 -q T2 -f 200 -r 1"` | $sv_caller can be one of 'brass' or 'manta' |
| `solutionSelectionForFitMS` | null | Comma-separated string of the type "sampleNames:signatureNames"
| `hrDetect_params` | `"-b -r 1 -g"` | Parameters to pass to [hrDetect](https://github.com/Nik-Zainal-Group/signature.tools.lib/blob/master/scripts/hrDetect)
