FROM humble_base:latest

SHELL ["/bin/bash", "-c"]
USER user

RUN cd /home/user \
    && source venv/bin/activate \
    && pip install build numpy pytest wheel

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

COPY sphere_description /home/user/ros_ws/src/sphere_description
COPY sphere_mapping /home/user/ros_ws/src/sphere_mapping
# mapping
USER root
RUN cd /home/user/ros_ws/src \
    && git clone https://github.com/norlab-ulaval/ros_rslidar.git \
    && git clone https://github.com/norlab-ulaval/imu_tools.git \
    && cd .. \
    && rosdep update
RUN apt update \
    && apt install libpcap-dev ros-humble-foxglove-bridge -y \
    && cd /home/user/ros_ws/ \
    && rosdep install --from-paths src --ignore-src -r -y \
    && chown -R user:user .
USER user
RUN cd /home/user/ros_ws \
    && source install/setup.sh \
    && source /opt/ros/humble/setup.bash \
    && colcon build --symlink-install

# expose ports for Jupyter notebook
EXPOSE 9000
EXPOSE 8080

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

WORKDIR /home/user/
