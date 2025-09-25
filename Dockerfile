FROM kalilinux/kali-rolling:latest

LABEL maintainer="admin@csalab.id" \
      org.opencontainers.image.title="Klaide (Kali Linux AI Desktop)"

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN --mount=type=cache,target=/var/cache/apt \
    sed -i 's|http.kali.org|mirrors.ocf.berkeley.edu|g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
      ca-certificates apt-utils curl wget gnupg2 lsb-release software-properties-common \
      liblzma-dev dialog \
      metasploit-framework nuclei subfinder \
      build-essential git sudo dbus-x11 locales \
      xfce4 xfce4-terminal \
      tigervnc-standalone-server tigervnc-tools \
      novnc websockify \
      firefox-esr \
      python3 python3-pip python3-venv python3-dev \
      golang \
      nodejs npm \
      default-jdk \
      ruby-full \
      wordlists \
      nmap sqlmap nikto wpscan gobuster ffuf \
      seclists masscan whatweb \
      netcat-traditional tcpdump iproute2 iputils-ping && \
    apt-get -y autoremove && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:/usr/local/go/bin:$PATH"

ENV GOPATH=/root/go
ENV PATH="$GOPATH/bin:$PATH"
RUN go install github.com/projectdiscovery/katana/cmd/katana@latest || true && \
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest || true && \
    go install github.com/hahwul/dalfox@latest || true && \
    go install github.com/jaeles-project/jaeles@latest || true && \
    go install github.com/lc/gau@latest || true && \
    go install github.com/tomnomnom/waybackurls@latest || true && \
    go install github.com/tomnomnom/anew@latest || true && \
    go install github.com/tomnomnom/qsreplace@latest || true

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN /root/.cargo/bin/cargo install rustscan
RUN /root/.cargo/bin/cargo install pwninit

RUN gem install zsteg || true

RUN npm install -g social-analyzer shodan-cli censys-cli pwned || true

RUN git clone https://github.com/0x4m4/hexstrike-ai /opt/hexstrike
WORKDIR /opt/hexstrike/

RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install --upgrade pip && \
    pip3 install -r /opt/hexstrike/requirements.txt || true && \
    pip3 install \
      volatility3 ROPGadget pwntools \
      prowler scout-suite checkov terrascan \
      kube-hunter kube-bench docker-bench-security falco || true

RUN useradd -m -c "Kali Linux" -s /bin/bash -d /home/kali kali && \
    echo "kali ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /run/dbus

RUN chown -R kali:kali /opt/hexstrike
USER kali
WORKDIR /home/kali
ENV SHELL=/bin/bash

EXPOSE 8080 8888

COPY startup-dev.sh /startup.sh
ENTRYPOINT ["/bin/bash", "/startup.sh"]
