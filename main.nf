#!/usr/bin/env nextflow

def columns = 
  file(params.inputlist)
  .readLines()
  .first()
  .split(",")
  .drop(1)
  .collect()

def sampleIDs =
  file(params.inputlist)
  .readLines()
  .drop(1)
  .collect { it.split(",")[0] }

Ch_input = Channel.empty()
columns.eachWithIndex { 
  it, index ->
  listChannel = Channel
    .fromPath(params.inputlist)
    .splitCsv(header:false, skip:1)
    .map { cols -> file("${cols[index+1]}".trim()) }
    .toList()
  def tupleChannel = listChannel.map { list ->
    tuple("${it}", sampleIDs, list)
  }
  //channel of [caller1,[ID1,ID2,..],[file1,file2,..],...]
  Ch_input=Ch_input.concat(tupleChannel)
}

//Multiple input lists are created from the input CSV file
//The transformed lists for each caller are sent to PrepareData
process createLists {
  label 'awscli_bcftools'
  
  input:
  tuple val(caller), val(sampleIDs), path(input_data, stageAs: "?/*")

  output:
  tuple val(caller), file("${caller}.txt"), file(input_data)

  script:
  def sampls=sampleIDs.join("\t")
  """
  paste <(printf "%s\n" ${sampls}) <(printf "%s\n" ${input_data}) > ${caller}.txt
  """
}

//Filter and reformat the input data 
process prepareData {
  label 'utility_scripts'
  publishDir "${params.outdir}", mode: 'copy'

  input:
  tuple val(caller), file(data_files_list), path(input_data, stageAs: "?/*")
  
  output:
  tuple val(caller), file("prepareData_${caller}/"), emit: out

  script:
  prepareData_options = params.prepareData_params ? params.prepareData_params : ""

  """
  /opt/conda/bin/Rscript /utility.scripts/scripts/prepareData \
    --outdir prepareData_${caller} --${caller} ${data_files_list} \
    --genomev $params.genome_version $prepareData_options
  """
}

//Main signatureFit analysis
process signatureFit {
  label 'signature_tools_lib'
  publishDir "${params.outdir}", mode: 'copy'

  input:
  tuple val(caller), file(prepared_datadir)

  output:
  tuple val(caller), file("signatureFit_${caller}/"), emit: out

  when:
  caller =~ /caveman|strelka|strelkasnv|brass|manta/

  script:
  signaturefit_options = params."signatureFit_params_${caller}" ? params."signatureFit_params_${caller}" : ""
  prepared_filetable = "$prepared_datadir/preparedFilesTable.tsv"

  """
  sed -i '/^sample\\t/d' $prepared_filetable

  case ${caller} in
  
  caveman | strelka | strelkasnv)
    
    /opt/conda/bin/Rscript /signature.tools.lib/scripts/signatureFit \
    --outdir signatureFit_${caller} --snvvcf ${prepared_filetable} \
    --organ $params.organ --genomev $params.genome_version \
    $signaturefit_options -n $params.cpus
    ;;

  brass | manta)

    /opt/conda/bin/Rscript /signature.tools.lib/scripts/signatureFit \
    --outdir signatureFit_${caller} --svbedpe ${prepared_filetable} \
    --organ $params.organ --genomev $params.genome_version \
    $signaturefit_options -n $params.cpus
    ;;

  *)

    echo -n "unknown"
    ;;

  esac
  """
}

// Selects a signature and updates the solutions
// only if param solutionSelectionForFitMS is set
process selectSigFitSolutions {
  label 'signature_tools_lib'
  publishDir "${params.outdir}", mode: 'copy'

  input:
  tuple val(caller), file(signaturefit_datadir)

  output:
  tuple val(caller), file("signatureFit_${caller}_selectedSolutions/"), emit: out

  when:
  params.solutionSelectionForFitMS != null && params."signatureFit_params_${caller}" =~ /FitMS/

  script:
  """
  echo "$params.solutionSelectionForFitMS" \
  | sed 's/,/\\n/g;s/:/\\t/g' > selectionTableSNVs.tsv
  /opt/conda/bin/Rscript /signature.tools.lib/scripts/solutionSelectionForFitMS \
  --infile $signaturefit_datadir/fitData.rData --selectiontable selectionTableSNVs.tsv \
  --outdir signatureFit_${caller}_selectedSolutions/
  """
}

// Runs hrDetect when all required variant data 
// SNVs, Indels, CNVs and SVs are provided
process hrDetect {
  label 'signature_tools_lib'
  publishDir "${params.outdir}", mode: 'copy'

  input:
  tuple val(callers), file(prepared_datadir)
  tuple val(callersSS), file(selectedSolution_datadir)

  output:
  file("hrDetect/")

  when:
  callers=~/ascat|canvas/ && callers=~/brass|manta/ && callers=~/pindel|strelka|strelkaindels/ && callers=~/caveman|strelka|strelkasnv/

  script:
  def fileTables = callers
  .collect { "prepareData_${it}/preparedFilesTable.tsv" }.join("\t")

  def replacementFlags = [
    /caveman/ : "snv",
    /brass/   : "sv",
    /strelka/ : "snv",
    /strelkasnv/ : "snv",
    /manta/ : "sv",
  ]

  def selectedSolution_fitData = callersSS.collect { "--${it}fitfile signatureFit_${it}_selectedSolutions/fitData.rData" }.join(" ")
  replacementFlags.each { regex, replacement ->
      selectedSolution_fitData = selectedSolution_fitData.replaceFirst(regex, replacement)
  }
  if (selectedSolution_fitData=~/novalue/) {
    selectedSolution_fitData=" "
  }

  def replacementHeaders = [
    /caveman/ : "SNV_vcf_files",
    /pindel/  : "Indels_vcf_files",
    /ascat/   : "CNV_tab_files",
    /brass/   : "SV_bedpe_files",
    /strelka/ : "SNV_vcf_files",
    /strelkasnv/ : "SNV_vcf_files",
    /strelkaindels/ : "Indels_vcf_files",
    /manta/ : "SV_bedpe_files",
    /canvas/  : "CNV_tab_files",
  ]

  def header = callers.join("\t")
  replacementHeaders.each { regex, replacement ->
      header = header.replaceAll(regex, replacement)
  }

  """
  sed -i '/^sample\\t/d' ${fileTables}

  mkdir hrDetect
  (echo "sample\t${header}" && paste ${fileTables} | cut -f1,2,5,8,11) > hrDetect/combinedFilesTable.tsv

  /opt/conda/bin/Rscript /signature.tools.lib/scripts/hrDetect \
  --outdir hrDetect --input hrDetect/combinedFilesTable.tsv \
  --organ $params.organ --genomev $params.genome_version \
  -n $params.cpus $selectedSolution_fitData $params.hrDetect_params
  """
}

workflow {
  inputLists = createLists(Ch_input)
  prepData = prepareData(inputLists)

  sigFitData = signatureFit(prepData.out)
  selectSigFitData = selectSigFitSolutions(sigFitData.out)

  // flatten the channels for input into hrDetect
  prepData_tr = prepData.out
    .collect(flat:false).map {it.transpose()}
  selectSigFitData_tr = selectSigFitData.out
    // must output a dummy file when channel is empty
    .ifEmpty(['novalue', file("${params.outdir}/no_sig_selection.txt")])
    .collect(flat:false).map {it.transpose()}

  hrDetect(prepData_tr, selectSigFitData_tr)
}
