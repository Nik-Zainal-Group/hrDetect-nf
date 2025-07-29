FROM continuumio/miniconda3:24.11.1-0

LABEL description="Dockerfile containing all the tool dependency for https://github.com/Nik-Zainal-Group/signature.tools.lib"

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

# Downloaded https://github.com/Nik-Zainal-Group/signature.tools.lib
COPY signature.tools.lib /signature.tools.lib

RUN Rscript -e 'devtools::install_github("linxihui/NNLM")'
RUN Rscript -e 'devtools::install("/signature.tools.lib")'
