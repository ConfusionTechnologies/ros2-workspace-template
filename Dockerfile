# syntax=docker/dockerfile:1

# Dockerfile for production
# Referring to Dockerfile.dev might be useful here.

# Example:
FROM nvidia/cuda:11.6.2-cudnn8-runtime-ubuntu20.04
ENV LANG="C.UTF-8" LC_ALL="C.UTF-8"

RUN echo 'Etc/UTC' > /etc/timezone \
  && ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime

RUN apt-get update && apt-get install -y \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  && add-apt-repository universe \
  && rm -rf /var/lib/apt/lists/*


RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" > /etc/apt/sources.list.d/ros2.list

WORKDIR /code
COPY . .

ARG ROS_DISTRO=foxy
ENV ROS_DISTRO=$ROS_DISTRO

RUN apt-get update && apt-get install -y \
  ros-${ROS_DISTRO}-ros-core \
  python3-rosdep \
  python3-colcon-common-extensions \
  python3-pip \
  && rosdep init \
  && rosdep update \
  && . /opt/ros/$ROS_DISTRO/setup.sh \
  && rosdep install -i --from-path /code -y \
  && colcon build \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf log/

# Optionally add VNC for debugging
# COPY ./.devcontainer/scripts/desktop-lite-debian.sh /tmp/scripts/desktop-lite-debian.sh
# ENV DBUS_SESSION_BUS_ADDRESS="autolaunch:" \
#   VNC_RESOLUTION="1440x768x16" \
#   VNC_DPI="96" \
#   VNC_PORT="5901" \
#   NOVNC_PORT="6080" \
#   DISPLAY=":1"
# RUN bash /tmp/scripts/desktop-lite-debian.sh root password

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 10

RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash\nsource /code/install/local_setup.bash" >> ~/.bashrc
ENTRYPOINT [ \
  # VNC entrypoint
  # "/usr/local/share/desktop-init.sh" \
  # ROS entrypoint
  "./entrypoint.sh" \
  ]
CMD [ "bash" ]