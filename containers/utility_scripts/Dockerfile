FROM continuumio/miniconda3 

LABEL description="Dockerfile containing all the tool dependency for https://github.com/Nik-Zainal-Group/utility.scripts"

ARG ENV_NAME="base"

COPY environment.yml /
RUN conda install mamba -c conda-forge -y \
  && mamba env update -n ${ENV_NAME} -f environment.yml && conda clean -a

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH=/opt/conda/envs/${ENV_NAME}/bin:$PATH

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name ${ENV_NAME} > ${ENV_NAME}_exported.yml

# Initialise bash for conda
RUN conda init bash

# Downloaded https://github.com/Nik-Zainal-Group/utility.scripts
COPY utility.scripts /utility.scripts

RUN Rscript -e 'devtools::install_github("PapenfussLab/StructuralVariantAnnotation@cb584be9474318e7f91c2cd8fca99f1212cab021")'
RUN Rscript -e 'devtools::install("/utility.scripts")'
