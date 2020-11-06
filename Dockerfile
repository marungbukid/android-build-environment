# Android Dockerfile

FROM ubuntu:18.04

MAINTAINER Mobile Builds Eng "deguzman.maru@gmail.com"

ENV ANDROID_SDK_TOOLS_VERSION="4333796"

# Sets language to UTF8 : this works in pretty much all cases
ENV LANG en_US.UTF-8 
ENV LANGUAGE en_US.UTF-8 
ENV LC_ALL en_US.UTF-8

RUN apt-get clean
RUN apt-get update
RUN apt-get install -qq -y apt-utils locales
RUN locale-gen $LANG

ENV DOCKER_ANDROID_LANG en_US
ENV DOCKER_ANDROID_DISPLAY_NAME mobileci-docker

# Never ask for confirmations
ENV DEBIAN_FRONTEND noninteractive

# Update apt-get
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get update
RUN apt-get dist-upgrade -y

# Installing packages
RUN apt-get install -y \
  autoconf \
  build-essential \
  bzip2 \
  curl \
  gcc \
  git \
  groff \
  lib32stdc++6 \
  lib32z1 \
  lib32z1-dev \
  lib32ncurses5 \
  libc6-dev \
  libgmp-dev \
  libmpc-dev \
  libmpfr-dev \
  libxslt-dev \
  libxml2-dev \
  m4 \
  make \
  ncurses-dev \
  ocaml \
  openssh-client \
  pkg-config \
  rsync \
  software-properties-common \
  unzip \
  wget \
  zip \
  zlib1g-dev \
  --no-install-recommends

# Install Java
RUN apt-add-repository ppa:openjdk-r/ppa
RUN apt-get update
RUN apt-get -y install openjdk-8-jdk

# Clean Up Apt-get
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get clean

# Install Android SDK
RUN wget --output-document=android-sdk-tools.zip https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip
RUN unzip -d android-sdk-tools android-sdk-tools.zip
RUN mv android-sdk-tools /usr/local/android-sdk
RUN rm android-sdk-tools.zip


ENV ANDROID_COMPONENTS platform-tools,android-30,build-tools-30.0.2

# Install Android tools
RUN echo y | /usr/local/android-sdk/tools/android update sdk --filter "${ANDROID_COMPONENTS}" --no-ui -a

# Environment variables
ENV ANDROID_HOME /usr/local/android-sdk
ENV ANDROID_SDK_HOME $ANDROID_HOME
ENV JENKINS_HOME $HOME
ENV PATH ${INFER_HOME}/bin:${PATH}
ENV PATH $PATH:$ANDROID_SDK_HOME/tools
ENV PATH $PATH:$ANDROID_SDK_HOME/platform-tools
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/30.0.2

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Support Gradle
ENV TERM dumb
ENV JAVA_OPTS "-Xms4096m -Xmx4096m"
ENV GRADLE_OPTS "-XX:+UseG1GC -XX:MaxGCPauseMillis=1000"

RUN mkdir --parents "$HOME/.android/"
RUN touch "$HOME/.android/repositories.cfg"
RUN  echo '### User Sources for Android SDK Manager' > \
        "$HOME/.android/repositories.cfg" && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager --licenses > /dev/null

RUN echo "platforms" && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "platforms;android-30" > /dev/null

RUN echo "platform tools" && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "platform-tools" > /dev/null

RUN echo "build tools" && \
    yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
        "build-tools;30.0.0" \
        "build-tools;29.0.3" > /dev/null


RUN yes | "$ANDROID_HOME"/tools/bin/sdkmanager "emulator" > /dev/null

RUN wget --quiet -O sdk.install.sh "https://get.sdkman.io" && \
    bash -c "bash ./sdk.install.sh > /dev/null && source ~/.sdkman/bin/sdkman-init.sh && sdk install kotlin" && \
    rm -f sdk.install.sh

# Cleaning
RUN apt-get clean

# Fix permissions
RUN chown -R $RUN_USER:$RUN_USER $ANDROID_HOME $ANDROID_SDK_HOME
RUN chmod -R a+rx $ANDROID_HOME $ANDROID_SDK_HOME
RUN echo "sdk.dir=$ANDROID_HOME" > local.properties

# Add Keystore properties in the environment
ENV KEYSTORE_FILE technistock-key.jks
ENV KEYSTORE_PASSWORD T3chnist0ck
ENV KEYSTORE_ALIAS streamingmobilekey
ENV KEYSTORE_KEY_PASSWORD T3chnist0ck

