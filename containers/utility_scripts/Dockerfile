FROM mambaorg/micromamba:git-86a1dd8-debian13-slim

LABEL description="Dockerfile containing all the tool dependency for https://github.com/Nik-Zainal-Group/utility.scripts"

COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/env.yaml

USER $MAMBA_USER
RUN micromamba install -y -n base -c conda-forge r-base=4.6.0 \
    && micromamba install -y -n base -f /tmp/env.yaml \
	&& micromamba clean --all --yes

# Point PATH to the base environment's bin folder
ENV PATH=/opt/conda/bin:$PATH

# Downloaded https://github.com/Nik-Zainal-Group/utility.scripts
COPY utility.scripts /utility.scripts

RUN Rscript -e 'pak::pak("PapenfussLab/StructuralVariantAnnotation@f787e1fdf64baea7468a39f02a327bc00ff33531")'
RUN Rscript -e 'devtools::install("/utility.scripts")'
