FROM mambaorg/micromamba:git-86a1dd8-debian13-slim

LABEL description="Dockerfile containing all the tool dependencies for https://github.com/Nik-Zainal-Group/signature.tools.lib"

COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/env.yaml

USER $MAMBA_USER
RUN micromamba install -y -n base -c conda-forge r-base=4.6.0 \
    && micromamba install -y -n base -f /tmp/env.yaml \
	&& micromamba clean --all --yes

# Point PATH to the base environment's bin folder
ENV PATH=/opt/conda/bin:$PATH

# Downloaded https://github.com/Nik-Zainal-Group/indelsig.tools.lib
COPY indelsig.tools.lib /indelsig.tools.lib

# Downloaded https://github.com/Nik-Zainal-Group/signature.tools.lib
COPY signature.tools.lib /signature.tools.lib

RUN Rscript -e 'devtools::install_github("linxihui/NNLM")'
RUN Rscript -e 'devtools::install("/indelsig.tools.lib")'
RUN Rscript -e 'devtools::install("/signature.tools.lib")'
