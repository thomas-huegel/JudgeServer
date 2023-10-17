FROM archlinux

ENV BASE="base gcc make python"
ENV BUILD_DEPENDENCIES="git cmake libtool"
ENV RUNTIME="rust"
ENV PIP_PACKAGES="psutil gunicorn flask requests"

RUN yes | pacman -Syu; \
    yes | pacman -Sy $BASE; \
    yes | pacman -Sy $BUILD_DEPENDENCIES

RUN yes | pacman -Sy $RUNTIME
#RUN pip3 install --no-cache-dir $PIP_PACKAGES
RUN python -m venv /python-venv
RUN /python-venv/bin/pip install --no-cache-dir $PIP_PACKAGES
RUN cd /tmp && git clone -b newnew --depth 1 https://github.com/thomas-huegel/Judger && cd Judger && \
    mkdir build && cd build && cmake .. && make && make install && cd ../bindings/Python && /python-venv/bin/python setup.py install;
RUN mkdir -p /code && \
    useradd -u 12001 compiler && useradd -u 12002 code && useradd -u 12003 spj && usermod -a -G code spj

RUN yes | pacman -Rns $BUILD_DEPENDENCIES; \
    yes | pacman -Scc

HEALTHCHECK --interval=5s --retries=3 CMD /python-venv/bin/python /code/service.py
ADD server /code
WORKDIR /code
RUN gcc -shared -fPIC -o unbuffer.so unbuffer.c
EXPOSE 8080
ENTRYPOINT /code/entrypoint.sh