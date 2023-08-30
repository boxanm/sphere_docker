#!/bin/bash
source /home/user/venv/bin/activate
cd $HOME/ros_ws
colcon build --symlink-install
cd

echo "Launching Foxglove bridge"
screen -d -m -S foxglove_bridge ros2 launch foxglove_bridge foxglove_bridge_launch.xml send_buffer_limit:=1000000000

# Execute the command passed into this entrypoint
exec "$@"
