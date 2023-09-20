FROM humble_base:latest

SHELL ["/bin/bash", "-c"]
USER root

RUN apt update \
	&& apt upgrade -y \
    && apt install libpcap-dev ros-humble-foxglove-bridge -y

USER user

COPY requirements.txt /home/user/requirements.txt
RUN cd /home/user \
    && source venv/bin/activate \
    && pip install -r requirements.txt \
    && rm requirements.txt

## install python bindings for libraries

# libpointmatcher
RUN source /home/user/venv/bin/activate \
	&& cd /home/user/libraries/libpointmatcher/build/ \
	&& cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON_MODULE=ON \
		PYTHON_INSTALL_TARGET=/home/user/libraries/venv/lib/python3.10/site-packages/ .. \
	&& make \
	&& echo password | sudo -S make install

# norlab_icp_mapper
RUN source /home/user/venv/bin/activate \
	&& cd /home/user/libraries/norlab_icp_mapper/build/ \
	&& cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON_MODULE=ON \
        PYTHON_INSTALL_TARGET=/home/user/libraries/venv/lib/python3.10/site-packages/ .. \
	&& make \
	&& echo password | sudo -S make install

# mapping
USER root
RUN cd /home/user/ros_ws/src \
    && git clone https://github.com/norlab-ulaval/ros_rslidar.git \
    && git clone https://github.com/norlab-ulaval/sphere_description.git \
    && git clone https://github.com/norlab-ulaval/sphere_mapping.git \
    && git clone https://github.com/norlab-ulaval/imu_tools.git \
    && git clone -b ros2 https://github.com/norlab-ulaval/vectornav.git \
    && git clone https://github.com/norlab-ulaval/norlab_xsens_driver.git \
    && cd .. \
    && rosdep update
RUN cd /home/user/ros_ws/ \
    && rosdep install --from-paths src --ignore-src -r -y \
    && chown -R user:user .
USER user

RUN cd /home/user/ros_ws \
    && source install/setup.sh \
    && source /opt/ros/humble/setup.bash \
    && colcon build --symlink-install

COPY api_keys /home/user/api_keys
RUN echo -e "\nsource $HOME/api_keys\n" >> /home/user/.bashrc

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

WORKDIR /home/user/
